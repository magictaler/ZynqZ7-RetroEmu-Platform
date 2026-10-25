--------------------------------------------------------------------------------
-- bicubic_scaler.vhd
--
-- Bicubic (Catmull-Rom) video upscaler for Xilinx 7-series / UltraScale.
-- VHDL-2008.  Not simulated or synthesised by the author: treat as a
-- reviewed first implementation, run a testbench before trusting it.
--
-- Data path
--   i_clk  : input video -> size autodetect -> pixel packer -> async FIFO
--   avl_clk: FIFO -> Avalon burst writes into 3 frame buffers (triple buffer)
--            Avalon burst reads -> 8 line slots in 4 BRAM banks
--   o_clk  : output timing generator, 4x4 window, separable bicubic filter
--
-- Memory model
--   * avl_address is a WORD address (one word = N_DW bits).
--   * 3 frame buffers of 64 MiB each, back to back from address 0
--     (add an offset in the interconnect if you need another base).
--   * Pixels: 16bpp (format=00) RGB565, otherwise 32 bit {00,R,G,B}
--     (format=01 "24bpp" is stored in a 32 bit slot).
--   * Every line is padded to a whole number of N_BURST bursts, so a line
--     can be fetched with plain burst reads.  One extra marker burst per
--     frame carries {format,height,width}; writer publishes the buffer
--     when it sees it.
--
-- Scaling
--   Per axis: src = (dst+0.5)*in/out - 0.5, Q16 fixed point, edge clamped.
--   Horizontal step is limited to 1.0 (no horizontal downscale; the image
--   is cropped instead).  Vertical step is limited to <4.0.
--
-- Assumptions / limits (read before use)
--   1. Output timing: htotal >= hdisp + 10 (preroll of the 4 pixel window
--      and weight switch happen in the horizontal blanking).
--   2. hs/vs/de outputs are active high.  o_vbl = line >= vdisp.
--      Window (hmin..hmax, vmin..vmax) is inclusive; the rest of the
--      active area is filled with o_border and o_brd='1'.
--   3. Avalon bandwidth must exceed the input pixel rate; FIFO overflow
--      corrupts a frame (no back-pressure possible on a video input).
--   4. Input blanking must be >= N_BURST/(N_DW/8) i_clk cycles per line
--      (pad words are pushed during blanking).
--   5. iauto='0' freezes the detected size and crops the input to it.
--   6. Config inputs (htotal.., o_border) and "format" are assumed static
--      or synchronous to o_clk / i_clk respectively.
--   7. The line-fetch engine is real-time: if Avalon cannot deliver a line
--      within an output line time you get repeated/wrong lines.
--   8. Constraints: ASYNC_REG on all synchronisers; set_max_delay
--      -datapath_only (or false path) on rinfo, ln_m and the FIFO gray
--      pointers.  Line buffers use 4 x (2*2^(14-log2(N_DW/8)) x N_DW) bits.
--   9. vrr: output frame is extended (up to vrrmax lines) until a new
--      input frame has been published and 4 lines are prefetched.
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

--------------------------------------------------------------------------------
package bicubic_pkg is
  function clog2 (n : natural) return natural;
  function imax  (a, b : integer) return integer;
  function to_sl (b : boolean) return std_logic;
  subtype wgt_t is signed(11 downto 0);                 -- Q1.10
  type wrom_t  is array (0 to 255) of wgt_t;
  type wrom4_t is array (0 to 3) of wrom_t;
  function init_wrom return wrom4_t;
  constant WROM : wrom4_t := init_wrom;
end package;

package body bicubic_pkg is
  function clog2 (n : natural) return natural is
    variable r : natural := 0;
    variable v : natural := 1;
  begin
    while v < n loop
      v := v * 2;
      r := r + 1;
    end loop;
    return r;
  end function;

  function imax (a, b : integer) return integer is
  begin
    if a > b then return a; else return b; end if;
  end function;

  function to_sl (b : boolean) return std_logic is
  begin
    if b then return '1'; else return '0'; end if;
  end function;

  -- Catmull-Rom weights, 256 fractional positions, sum forced to 1024
  function init_wrom return wrom4_t is
    variable t, t2, t3 : real;
    variable w : wrom4_t;
    variable a0, a1, a2, a3 : integer;
  begin
    for i in 0 to 255 loop
      t  := real(i) / 256.0;
      t2 := t * t;
      t3 := t2 * t;
      a0 := integer(round(1024.0 * (-t3 + 2.0*t2 - t) / 2.0));
      a1 := integer(round(1024.0 * (3.0*t3 - 5.0*t2 + 2.0) / 2.0));
      a2 := integer(round(1024.0 * (-3.0*t3 + 4.0*t2 + t) / 2.0));
      a3 := 1024 - a0 - a1 - a2;
      w(0)(i) := to_signed(a0, 12);
      w(1)(i) := to_signed(a1, 12);
      w(2)(i) := to_signed(a2, 12);
      w(3)(i) := to_signed(a3, 12);
    end loop;
    return w;
  end function;
end package body;

--------------------------------------------------------------------------------
-- Reset synchroniser: async assert, sync release, active-high output
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

entity bicubic_rsync is
  port (clk : in std_logic; arst_n : in std_logic; srst : out std_logic);
end entity;

architecture rtl of bicubic_rsync is
  signal q : std_logic_vector(2 downto 0) := (others => '0');
  attribute ASYNC_REG : string;
  attribute ASYNC_REG of q : signal is "TRUE";
begin
  process (clk, arst_n)
  begin
    if arst_n = '0' then
      q <= (others => '0');
    elsif rising_edge(clk) then
      q <= q(1 downto 0) & '1';
    end if;
  end process;
  srst <= not q(2);
end architecture;

--------------------------------------------------------------------------------
-- Two flop single-bit synchroniser
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

entity bicubic_sync is
  port (clk : in std_logic; d : in std_logic; q : out std_logic);
end entity;

architecture rtl of bicubic_sync is
  signal s : std_logic_vector(1 downto 0) := "00";
  attribute ASYNC_REG : string;
  attribute ASYNC_REG of s : signal is "TRUE";
begin
  process (clk)
  begin
    if rising_edge(clk) then
      s <= s(0) & d;
    end if;
  end process;
  q <= s(1);
end architecture;

--------------------------------------------------------------------------------
-- Simple dual port RAM, independent clocks, registered read (infers BRAM)
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity bicubic_ram is
  generic (DW : natural; AW : natural);
  port (
    wclk  : in  std_logic;
    we    : in  std_logic;
    waddr : in  unsigned(AW-1 downto 0);
    wdata : in  std_logic_vector(DW-1 downto 0);
    rclk  : in  std_logic;
    ren   : in  std_logic;
    raddr : in  unsigned(AW-1 downto 0);
    rdata : out std_logic_vector(DW-1 downto 0));
end entity;

architecture rtl of bicubic_ram is
  type ram_t is array (0 to 2**AW-1) of std_logic_vector(DW-1 downto 0);
  signal ram : ram_t;
  attribute ram_style : string;
  attribute ram_style of ram : signal is "block";
begin
  process (wclk)
  begin
    if rising_edge(wclk) then
      if we = '1' then
        ram(to_integer(waddr)) <= wdata;
      end if;
    end if;
  end process;

  process (rclk)
  begin
    if rising_edge(rclk) then
      if ren = '1' then
        rdata <= ram(to_integer(raddr));
      end if;
    end if;
  end process;
end architecture;

--------------------------------------------------------------------------------
-- Asynchronous FIFO, first-word-fall-through read side.
-- wfull is asserted 4 words before the FIFO is really full, so the producer
-- may push up to 3 words after seeing wfull='0' without overflow.
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity bicubic_afifo is
  generic (DW : natural; AW : natural);
  port (
    wclk  : in  std_logic;
    wrst  : in  std_logic;
    wr    : in  std_logic;
    wdata : in  std_logic_vector(DW-1 downto 0);
    wfull : out std_logic;
    rclk  : in  std_logic;
    rrst  : in  std_logic;
    rd    : in  std_logic;
    rdata : out std_logic_vector(DW-1 downto 0);
    rused : out unsigned(AW downto 0));
end entity;

architecture rtl of bicubic_afifo is
  function b2g (b : unsigned) return std_logic_vector is
  begin
    return std_logic_vector(b xor shift_right(b, 1));
  end function;

  function g2b (g : std_logic_vector) return unsigned is
    variable b : unsigned(g'range);
  begin
    b(g'high) := g(g'high);
    for i in g'high - 1 downto g'low loop
      b(i) := b(i + 1) xor g(i);
    end loop;
    return b;
  end function;

  signal wbin, wbin_n : unsigned(AW downto 0) := (others => '0');
  signal rbin, rbin_n : unsigned(AW downto 0) := (others => '0');
  signal wgray, rgray : std_logic_vector(AW downto 0) := (others => '0');
  signal wg_s1, wg_s2 : std_logic_vector(AW downto 0) := (others => '0');
  signal rg_s1, rg_s2 : std_logic_vector(AW downto 0) := (others => '0');
  signal wfull_r      : std_logic := '0';
  attribute ASYNC_REG : string;
  attribute ASYNC_REG of wg_s1, wg_s2, rg_s1, rg_s2 : signal is "TRUE";
begin
  wbin_n <= wbin + 1 when wr = '1' else wbin;
  rbin_n <= rbin + 1 when rd = '1' else rbin;

  process (wclk)
    variable v_used : unsigned(AW downto 0);
  begin
    if rising_edge(wclk) then
      rg_s1 <= rgray;
      rg_s2 <= rg_s1;
      if wrst = '1' then
        wbin    <= (others => '0');
        wgray   <= (others => '0');
        wfull_r <= '0';
      else
        wbin  <= wbin_n;
        wgray <= b2g(wbin_n);
        v_used := wbin_n - g2b(rg_s2);
        if v_used >= 2**AW - 4 then
          wfull_r <= '1';
        else
          wfull_r <= '0';
        end if;
      end if;
    end if;
  end process;
  wfull <= wfull_r;

  process (rclk)
  begin
    if rising_edge(rclk) then
      wg_s1 <= wgray;
      wg_s2 <= wg_s1;
      if rrst = '1' then
        rbin  <= (others => '0');
        rgray <= (others => '0');
      else
        rbin  <= rbin_n;
        rgray <= b2g(rbin_n);
      end if;
    end if;
  end process;
  rused <= g2b(wg_s2) - rbin;

  u_ram : entity work.bicubic_ram
    generic map (DW => DW, AW => AW)
    port map (wclk => wclk, we => wr, waddr => wbin(AW-1 downto 0), wdata => wdata,
              rclk => rclk, ren => '1', raddr => rbin_n(AW-1 downto 0), rdata => rdata);
end architecture;

--------------------------------------------------------------------------------
-- Top level
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.bicubic_pkg.all;

entity bicubic_scaler is
  generic (
    N_DW    : natural range 64 to 128 := 128;
    N_AW    : natural range 8 to 32   := 32;
    N_BURST : natural                 := 256  -- bytes per burst
  );
  port (
    -- Input video
    i_r   : in  unsigned(7 downto 0);
    i_g   : in  unsigned(7 downto 0);
    i_b   : in  unsigned(7 downto 0);
    i_hs  : in  std_logic;
    i_vs  : in  std_logic;
    i_de  : in  std_logic;
    i_ce  : in  std_logic;
    i_clk : in  std_logic;
    -- Output video
    o_r   : out unsigned(7 downto 0);
    o_g   : out unsigned(7 downto 0);
    o_b   : out unsigned(7 downto 0);
    o_hs  : out std_logic;
    o_vs  : out std_logic;
    o_de  : out std_logic;
    o_vbl : out std_logic;
    o_brd : out std_logic;
    o_ce  : in  std_logic;
    o_clk : in  std_logic;
    -- Border colour R G B
    o_border : in unsigned(23 downto 0) := x"000000";
    -- Input video parameters
    iauto : in std_logic := '1';
    -- Detected input image size (pixels / lines)
    i_hdmax : out natural range 0 to 4095;
    i_vdmax : out natural range 0 to 4095;
    -- Output video parameters
    htotal  : in natural range 0 to 4095;
    hsstart : in natural range 0 to 4095;
    hsend   : in natural range 0 to 4095;
    hdisp   : in natural range 0 to 4095;
    hmin    : in natural range 0 to 4095;
    hmax    : in natural range 0 to 4095;
    vtotal  : in natural range 0 to 4095;
    vsstart : in natural range 0 to 4095;
    vsend   : in natural range 0 to 4095;
    vdisp   : in natural range 0 to 4095;
    vmin    : in natural range 0 to 4095;
    vmax    : in natural range 0 to 4095;
    vrr     : in std_logic := '0';
    vrrmax  : in natural range 0 to 4095 := 0;
    -- Scaler format. 00=16bpp 565, 01=24bpp 10=32bpp
    format  : in unsigned(1 downto 0) := "01";
    -- Avalon
    avl_clk           : in  std_logic;
    avl_waitrequest   : in  std_logic;
    avl_readdata      : in  std_logic_vector(N_DW-1 downto 0);
    avl_readdatavalid : in  std_logic;
    avl_burstcount    : out std_logic_vector(7 downto 0);
    avl_writedata     : out std_logic_vector(N_DW-1 downto 0);
    avl_address       : out std_logic_vector(N_AW-1 downto 0);
    avl_write         : out std_logic;
    avl_read          : out std_logic;
    avl_byteenable    : out std_logic_vector(N_DW/8-1 downto 0);
    reset_na          : in  std_logic
  );
end entity;

architecture rtl of bicubic_scaler is

  ---------------------------------------------------------------------------
  -- Constants
  ---------------------------------------------------------------------------
  constant BPW    : natural := N_DW / 8;                 -- bytes per word
  constant BPW_L2 : natural := clog2(BPW);
  constant WPB    : natural := N_BURST / BPW;            -- words per burst
  constant WPB_L2 : natural := clog2(WPB);
  constant LBW    : natural := 14 - BPW_L2;              -- log2(max words/line)
  constant BUF_AW : natural := 26 - BPW_L2;              -- words per frame buffer
  constant FAW    : natural := imax(9, WPB_L2 + 5);      -- FIFO address bits
  constant PPW16  : natural := N_DW / 16;
  constant PPW32  : natural := N_DW / 32;

  function pick (a, b : unsigned(1 downto 0)) return unsigned is
  begin
    for i in 0 to 2 loop
      if to_unsigned(i, 2) /= a and to_unsigned(i, 2) /= b then
        return to_unsigned(i, 2);
      end if;
    end loop;
    return "00";
  end function;

  ---------------------------------------------------------------------------
  -- Resets
  ---------------------------------------------------------------------------
  signal i_rst, a_rst, o_rst : std_logic;

  ---------------------------------------------------------------------------
  -- Input domain
  ---------------------------------------------------------------------------
  signal fmt_s1, fmt_i : unsigned(1 downto 0) := "01";
  signal f_wr, f_wfull : std_logic;
  signal f_wd          : std_logic_vector(N_DW downto 0);
  type   ist_t is (S_RUN, S_PAD, S_MARK);
  signal ist           : ist_t;
  signal lw_mod, mk_cnt : natural range 0 to WPB-1;
  signal mk_pend, de_q, vs_q, de_seen, ovf : std_logic;
  signal mk_info       : std_logic_vector(25 downto 0);
  signal wreg          : std_logic_vector(N_DW-1 downto 0);
  signal pslot         : natural range 0 to PPW16-1;
  signal hcnt, hlast, vcnt, w_det, h_det : natural range 0 to 4095;

  ---------------------------------------------------------------------------
  -- Avalon domain
  ---------------------------------------------------------------------------
  signal f_rd   : std_logic;
  signal f_q    : std_logic_vector(N_DW downto 0);
  signal f_used : unsigned(FAW downto 0);

  type abus_t is (A_IDLE, A_WR, A_RDCMD);
  signal abus : abus_t;
  type jst_t is (J_IDLE, J_C1, J_C2, J_C3, J_RUN);
  signal jst : jst_t;

  signal wbuf, latest, rbuf : unsigned(1 downto 0);
  signal woff        : unsigned(BUF_AW-1 downto 0);
  signal wbeat       : natural range 0 to 255;
  signal seen_last, latest_valid, rvalid, rr, cmd_pend : std_logic;
  signal cap_info, latest_info, rinfo : std_logic_vector(25 downto 0);
  signal fs_req_s, fs_req_p, ln_req_s, ln_req_p : std_logic;
  signal fs_ack_tog, ln_ack_tog, pub_tog : std_logic;
  signal ld_m        : unsigned(12 downto 0);
  signal ld_off      : unsigned(BUF_AW-1 downto 0);
  signal cmds_left, rx_cnt, total_w, words_c, nb_c, src_line : integer range 0 to 65535;
  signal widx        : unsigned(LBW-1 downto 0);
  signal lb_we       : std_logic_vector(3 downto 0);
  signal lb_waddr    : unsigned(LBW downto 0);

  ---------------------------------------------------------------------------
  -- Output domain
  ---------------------------------------------------------------------------
  signal ln_m        : unsigned(12 downto 0);
  signal fs_req_tog, ln_req_tog : std_logic;
  signal fs_ack_s, fs_ack_p, ln_ack_s, ln_ack_p, pub_s : std_logic;
  type gst_t is (G_IDLE, G_WAIT, G_DX, G_DY);
  signal gst : gst_t;
  signal grab_req, grabbed, fresh, loaded4, ld_busy, finfo_valid, steps_ok, pub_seen : std_logic;
  signal iw, ih      : natural range 0 to 4095;
  signal ifmt16      : std_logic;
  signal m_next, r_use : natural range 0 to 8191;
  signal div_num, div_q : unsigned(27 downto 0);
  signal div_den     : unsigned(11 downto 0);
  signal div_rem     : unsigned(12 downto 0);
  signal div_cnt     : natural range 0 to 27;
  signal stepx, stepy : unsigned(17 downto 0);

  signal hc, vc      : natural range 0 to 4095;
  signal last_line, row_n_ok, row_cur_ok : std_logic;
  signal xpos, rpos  : unsigned(28 downto 0);
  signal cprev       : natural range 0 to 8191;
  signal half_r      : std_logic_vector(3 downto 0);

  type raddr_t is array (0 to 3) of unsigned(LBW downto 0);
  type rq_t    is array (0 to 3) of std_logic_vector(N_DW-1 downto 0);
  signal lb_raddr    : raddr_t;
  signal lb_rq       : rq_t;

  -- pipeline registers
  signal e1_v, e2_v, e3_v : std_logic;
  signal e1_col      : unsigned(13 downto 0);
  signal e2_widx     : unsigned(LBW-1 downto 0);
  signal e2_sel, e3_sel : natural range 0 to PPW16-1;
  signal m1, m2, m3  : unsigned(7 downto 0);

  type pix3_t is array (0 to 2) of unsigned(7 downto 0);
  type win_t  is array (0 to 3) of pix3_t;
  type winb_t is array (0 to 3) of win_t;
  signal win : winb_t;
  type wgt4_t is array (0 to 3) of signed(11 downto 0);
  signal wh_r, wy_n, wy_r : wgt4_t;
  type prod_t  is array (0 to 3, 0 to 3, 0 to 2) of signed(20 downto 0);
  type hsum_t  is array (0 to 3, 0 to 2) of signed(19 downto 0);
  type vprod_t is array (0 to 3, 0 to 2) of signed(31 downto 0);
  type vsum_t  is array (0 to 2) of signed(33 downto 0);
  signal prod  : prod_t;
  signal hsum  : hsum_t;
  signal vprod : vprod_t;
  signal vsum  : vsum_t;
  type fl_t is array (1 to 8) of std_logic_vector(4 downto 0); -- de hs vs vbl win
  signal fl : fl_t;

begin

  ---------------------------------------------------------------------------
  -- Resets and static outputs
  ---------------------------------------------------------------------------
  u_ri : entity work.bicubic_rsync port map (i_clk,   reset_na, i_rst);
  u_ra : entity work.bicubic_rsync port map (avl_clk, reset_na, a_rst);
  u_ro : entity work.bicubic_rsync port map (o_clk,   reset_na, o_rst);

  i_hdmax <= w_det;
  i_vdmax <= h_det;

  ---------------------------------------------------------------------------
  -- Clock domain crossing (toggle handshakes; data buses are held stable)
  ---------------------------------------------------------------------------
  u_s_fsreq : entity work.bicubic_sync port map (avl_clk, fs_req_tog, fs_req_s);
  u_s_lnreq : entity work.bicubic_sync port map (avl_clk, ln_req_tog, ln_req_s);
  u_s_fsack : entity work.bicubic_sync port map (o_clk,   fs_ack_tog, fs_ack_s);
  u_s_lnack : entity work.bicubic_sync port map (o_clk,   ln_ack_tog, ln_ack_s);
  u_s_pub   : entity work.bicubic_sync port map (o_clk,   pub_tog,    pub_s);

  ---------------------------------------------------------------------------
  -- Input -> Avalon FIFO
  ---------------------------------------------------------------------------
  u_fifo : entity work.bicubic_afifo
    generic map (DW => N_DW + 1, AW => FAW)
    port map (wclk => i_clk, wrst => i_rst, wr => f_wr, wdata => f_wd, wfull => f_wfull,
              rclk => avl_clk, rrst => a_rst, rd => f_rd, rdata => f_q, rused => f_used);

  ---------------------------------------------------------------------------
  -- Line buffer banks (avl_clk write, o_clk read)
  ---------------------------------------------------------------------------
  gen_lb : for b in 0 to 3 generate
    lb_we(b)    <= avl_readdatavalid when (jst = J_RUN and to_integer(ld_m(1 downto 0)) = b) else '0';
    lb_raddr(b) <= half_r(b) & e2_widx;
    u_lb : entity work.bicubic_ram
      generic map (DW => N_DW, AW => LBW + 1)
      port map (wclk => avl_clk, we => lb_we(b), waddr => lb_waddr, wdata => avl_readdata,
                rclk => o_clk, ren => o_ce, raddr => lb_raddr(b), rdata => lb_rq(b));
  end generate;
  lb_waddr <= ld_m(2) & widx;

  ---------------------------------------------------------------------------
  -- Input domain: size detection, packing, FIFO feed
  ---------------------------------------------------------------------------
  p_in : process (i_clk)
    variable v_word : std_logic_vector(N_DW-1 downto 0);
    variable v_slot, v_last : natural;
    variable v_w, v_h : natural range 0 to 4095;
  begin
    if rising_edge(i_clk) then
      fmt_s1 <= format;
      fmt_i  <= fmt_s1;
      f_wr   <= '0';
      if i_rst = '1' then
        ist <= S_RUN; lw_mod <= 0; mk_cnt <= 0; mk_pend <= '0';
        pslot <= 0; wreg <= (others => '0');
        hcnt <= 0; hlast <= 0; vcnt <= 0; w_det <= 0; h_det <= 0;
        de_q <= '0'; vs_q <= '0'; de_seen <= '0'; ovf <= '0';
        mk_info <= (others => '0');
        f_wd <= (others => '0');
      else
        -- padding / marker sequencer (runs on i_clk, not on i_ce)
        case ist is
          when S_RUN => null;
          when S_PAD =>
            if lw_mod = 0 then
              if mk_pend = '1' then
                ist <= S_MARK; mk_pend <= '0';
              else
                ist <= S_RUN;
              end if;
            elsif f_wfull = '0' then
              f_wr <= '1';
              f_wd <= (others => '0');
              if lw_mod = WPB - 1 then lw_mod <= 0; else lw_mod <= lw_mod + 1; end if;
            end if;
          when S_MARK =>
            if f_wfull = '0' then
              f_wr <= '1';
              f_wd(N_DW) <= '1';
              f_wd(N_DW-1 downto 26) <= (others => '0');
              f_wd(25 downto 0) <= mk_info;
              if mk_cnt = WPB - 1 then
                mk_cnt <= 0; ist <= S_RUN;
              else
                mk_cnt <= mk_cnt + 1;
              end if;
            end if;
        end case;

        if i_ce = '1' then
          de_q <= i_de;
          vs_q <= i_vs;

          if i_de = '1' and de_q = '0' then
            de_seen <= '1';
          end if;

          -- pixel
          if i_de = '1' then
            if hcnt < 4095 then hcnt <= hcnt + 1; end if;
            if iauto = '1' or (hcnt < w_det and vcnt < h_det) then
              v_word := wreg;
              v_slot := pslot;
              if fmt_i = "00" then

                --v_last := PPW16 - 1;
                --if v_slot > v_last then v_slot := 0; end if;
                --v_word(16*v_slot+15 downto 16*v_slot) :=
                --  std_logic_vector(std_logic_vector(i_r(7 downto 3)) & std_logic_vector(i_g(7 downto 2)) & std_logic_vector(i_b(7 downto 3)));

		v_last := PPW16 - 1;
		if v_slot > v_last then
	          v_slot := 0;
		end if;
		v_word(16*v_slot+15 downto 16*v_slot+11) := std_logic_vector(i_r(7 downto 3));
	        v_word(16*v_slot+10 downto 16*v_slot+5) := std_logic_vector(i_g(7 downto 2));
                v_word(16*v_slot+4 downto 16*v_slot) := std_logic_vector(i_b(7 downto 3));

              else
                v_last := PPW32 - 1;
                if v_slot > v_last then v_slot := 0; end if;
                v_word(32*v_slot+31 downto 32*v_slot) :=
                  x"00" & std_logic_vector(i_r) & std_logic_vector(i_g) & std_logic_vector(i_b);
              end if;
              if v_slot >= v_last then
                if ist = S_RUN and f_wfull = '0' then
                  f_wr <= '1';
                  f_wd <= '0' & v_word;
                  if lw_mod = WPB - 1 then lw_mod <= 0; else lw_mod <= lw_mod + 1; end if;
                else
                  ovf <= '1';
                end if;
                wreg  <= (others => '0');
                pslot <= 0;
              else
                wreg  <= v_word;
                pslot <= v_slot + 1;
              end if;
            end if;
          end if;

          -- end of line
          if de_q = '1' and i_de = '0' then
            hlast <= hcnt;
            hcnt  <= 0;
            if vcnt < 4095 then vcnt <= vcnt + 1; end if;
            if pslot /= 0 then
              if ist = S_RUN and f_wfull = '0' then
                f_wr <= '1';
                f_wd <= '0' & wreg;
                if lw_mod = WPB - 1 then lw_mod <= 0; else lw_mod <= lw_mod + 1; end if;
              end if;
              wreg  <= (others => '0');
              pslot <= 0;
            end if;
            if ist = S_RUN then ist <= S_PAD; end if;
          end if;

          -- frame start: any VS edge that follows video lines
          if i_vs /= vs_q then
            if de_seen = '1' then
              de_seen <= '0';
              if iauto = '1' then
                v_w := hlast; v_h := vcnt;
                w_det <= v_w; h_det <= v_h;
              else
                v_w := w_det; v_h := h_det;
              end if;
              mk_info <= std_logic_vector(fmt_i) &
                         std_logic_vector(to_unsigned(v_h, 12)) &
                         std_logic_vector(to_unsigned(v_w, 12));
              vcnt    <= 0;
              mk_pend <= '1';
              if ist = S_RUN then ist <= S_PAD; end if;
            end if;
          end if;
        end if;
      end if;
    end if;
  end process;

  ---------------------------------------------------------------------------
  -- Avalon domain: frame writer, line reader, buffer management
  ---------------------------------------------------------------------------
  avl_write      <= '1' when abus = A_WR    else '0';
  avl_read       <= '1' when abus = A_RDCMD else '0';
  avl_burstcount <= std_logic_vector(to_unsigned(WPB, 8));
  avl_writedata  <= f_q(N_DW-1 downto 0);
  avl_byteenable <= (others => '1');
  avl_address    <= std_logic_vector(resize(wbuf & woff, N_AW)) when abus = A_WR else
                    std_logic_vector(resize(rbuf & ld_off, N_AW));
  f_rd           <= '1' when (abus = A_WR and avl_waitrequest = '0') else '0';

  p_avl : process (avl_clk)
    variable v_last  : boolean;
    variable v_grab  : boolean;
    variable v_rb    : unsigned(1 downto 0);
    variable v_m, v_h : integer;
    variable v_wd    : integer;
  begin
    if rising_edge(avl_clk) then
      fs_req_p <= fs_req_s;
      ln_req_p <= ln_req_s;
      if a_rst = '1' then
        abus <= A_IDLE; jst <= J_IDLE;
        wbuf <= "00"; latest <= "00"; rbuf <= "10";
        woff <= (others => '0'); wbeat <= 0;
        seen_last <= '0'; latest_valid <= '0'; rvalid <= '0'; rr <= '0'; cmd_pend <= '0';
        fs_ack_tog <= '0'; ln_ack_tog <= '0'; pub_tog <= '0';
        cap_info <= (others => '0'); latest_info <= (others => '0'); rinfo <= (others => '0');
        ld_m <= (others => '0'); ld_off <= (others => '0');
        cmds_left <= 0; rx_cnt <= 0; total_w <= 0; words_c <= 0; nb_c <= 0; src_line <= 0;
        widx <= (others => '0');
        fs_req_p <= fs_req_s; ln_req_p <= ln_req_s;
      else
        -----------------------------------------------------------------
        -- frame grab request from the output domain
        -----------------------------------------------------------------
        v_grab := (fs_req_s /= fs_req_p);
        if v_grab then
          rbuf       <= latest;
          rinfo      <= latest_info;
          rvalid     <= latest_valid;
          fs_ack_tog <= not fs_ack_tog;
        end if;

        -----------------------------------------------------------------
        -- bus arbitration
        -----------------------------------------------------------------
        case abus is
          when A_IDLE =>
            if cmd_pend = '1' and (f_used < WPB or rr = '0') then
              abus <= A_RDCMD; rr <= '1';
            elsif f_used >= WPB then
              abus <= A_WR;    rr <= '0';
            end if;

          when A_WR =>
            if avl_waitrequest = '0' then
              v_last := (f_q(N_DW) = '1');
              if v_last then
                cap_info  <= f_q(25 downto 0);
                seen_last <= '1';
              end if;
              if wbeat = WPB - 1 then
                wbeat <= 0;
                abus  <= A_IDLE;
                woff  <= woff + WPB;
                if v_last or seen_last = '1' then
                  -- frame complete: publish and pick a new write buffer
                  seen_last    <= '0';
                  latest       <= wbuf;
                  latest_valid <= '1';
                  pub_tog      <= not pub_tog;
                  if v_last then
                    latest_info <= f_q(25 downto 0);
                  else
                    latest_info <= cap_info;
                  end if;
                  if v_grab then v_rb := latest; else v_rb := rbuf; end if;
                  wbuf <= pick(wbuf, v_rb);
                  woff <= (others => '0');
                end if;
              else
                wbeat <= wbeat + 1;
              end if;
            end if;

          when A_RDCMD =>
            if avl_waitrequest = '0' then
              ld_off <= ld_off + WPB;
              if cmds_left <= 1 then cmd_pend <= '0'; end if;
              cmds_left <= cmds_left - 1;
              abus <= A_IDLE;
            end if;
        end case;

        -----------------------------------------------------------------
        -- line fetch job
        -----------------------------------------------------------------
        case jst is
          when J_IDLE =>
            if ln_req_s /= ln_req_p then
              ld_m <= ln_m;
              jst  <= J_C1;
            end if;

          when J_C1 =>
            v_wd := to_integer(unsigned(rinfo(11 downto 0)));
            v_h  := to_integer(unsigned(rinfo(23 downto 12)));
            if rvalid = '0' or v_wd = 0 or v_h = 0 then
              jst        <= J_IDLE;
              ln_ack_tog <= not ln_ack_tog;
            else
              if rinfo(25 downto 24) = "00" then
                words_c <= (v_wd * 2 + BPW - 1) / BPW;
              else
                words_c <= (v_wd * 4 + BPW - 1) / BPW;
              end if;
              v_m := to_integer(ld_m) - 2;
              if v_m < 0 then v_m := 0; end if;
              if v_m > v_h - 1 then v_m := v_h - 1; end if;
              src_line <= v_m;
              jst <= J_C2;
            end if;

          when J_C2 =>
            nb_c <= (words_c + WPB - 1) / WPB;
            jst  <= J_C3;

          when J_C3 =>
            ld_off    <= resize(to_unsigned(src_line * (nb_c * WPB), 32), BUF_AW);
            cmds_left <= nb_c;
            total_w   <= nb_c * WPB;
            rx_cnt    <= 0;
            widx      <= (others => '0');
            cmd_pend  <= '1';
            jst       <= J_RUN;

          when J_RUN =>
            if avl_readdatavalid = '1' then
              rx_cnt <= rx_cnt + 1;
              widx   <= widx + 1;
              if rx_cnt >= total_w - 1 then
                jst        <= J_IDLE;
                ln_ack_tog <= not ln_ack_tog;
              end if;
            end if;
        end case;
      end if;
    end if;
  end process;

  ---------------------------------------------------------------------------
  -- Output domain: control, timing, 4x4 window and bicubic filter
  ---------------------------------------------------------------------------
  p_out : process (o_clk)
    variable v_fsack, v_lnack : boolean;
    variable v_rem2   : unsigned(12 downto 0);
    variable v_q      : unsigned(27 downto 0);
    variable v_ow, v_oh : integer;
    variable v_nv, v_c0, v_c, v_col, v_o, v_r0, v_k, v_widx, v_sel : integer;
    variable v_rp, v_x0 : unsigned(28 downto 0);
    variable v_fl     : std_logic_vector(4 downto 0);
    variable v_win, v_ev, v_pre, v_lastl : boolean;
    variable v_hs     : signed(22 downto 0);
    variable v_vs     : signed(33 downto 0);
    variable v_px     : unsigned(7 downto 0);
    variable v_pix    : pix3_t;
    variable v_p16    : std_logic_vector(15 downto 0);
    variable v_p32    : std_logic_vector(31 downto 0);
    variable v_newav  : boolean;
  begin
    if rising_edge(o_clk) then
      fs_ack_p <= fs_ack_s;
      ln_ack_p <= ln_ack_s;
      if o_rst = '1' then
        hc <= 0; vc <= 0; last_line <= '0'; row_n_ok <= '0'; row_cur_ok <= '0';
        gst <= G_IDLE; fs_req_tog <= '0'; ln_req_tog <= '0';
        grab_req <= '0'; grabbed <= '0'; fresh <= '0'; loaded4 <= '0';
        ld_busy <= '0'; finfo_valid <= '0'; steps_ok <= '0'; pub_seen <= pub_s;
        iw <= 0; ih <= 0; ifmt16 <= '0'; m_next <= 0; r_use <= 0;
        stepx <= (others => '0'); stepy <= (others => '0');
        xpos <= (others => '0'); rpos <= (others => '0'); cprev <= 0;
        half_r <= (others => '0');
        e1_v <= '0'; e2_v <= '0'; e3_v <= '0';
        ln_m <= (others => '0');
        div_num <= (others => '0'); div_q <= (others => '0'); div_den <= to_unsigned(1, 12);
        div_rem <= (others => '0'); div_cnt <= 0;
        fl <= (others => (others => '0'));
        o_r <= (others => '0'); o_g <= (others => '0'); o_b <= (others => '0');
        o_hs <= '0'; o_vs <= '0'; o_de <= '0'; o_vbl <= '0'; o_brd <= '0';
      else
        v_fsack := (fs_ack_s /= fs_ack_p);
        v_lnack := (ln_ack_s /= ln_ack_p);
        v_newav := (pub_s /= pub_seen);

        if hmax >= hmin then v_ow := hmax - hmin + 1; else v_ow := 1; end if;
        if vmax >= vmin then v_oh := vmax - vmin + 1; else v_oh := 1; end if;

        -------------------------------------------------------------------
        -- Ungated: frame grab, step dividers, line loader
        -------------------------------------------------------------------
        case gst is
          when G_IDLE =>
            if grab_req = '1' and ld_busy = '0' then
              fs_req_tog <= not fs_req_tog;
              grab_req   <= '0';
              steps_ok   <= '0';
              gst        <= G_WAIT;
            end if;

          when G_WAIT =>
            if v_fsack then
              iw      <= to_integer(unsigned(rinfo(11 downto 0)));
              ih      <= to_integer(unsigned(rinfo(23 downto 12)));
              if rinfo(25 downto 24) = "00" then ifmt16 <= '1'; else ifmt16 <= '0'; end if;
              m_next  <= 0;
              loaded4 <= '0';
              r_use   <= 0;
              if rvalid = '1' and unsigned(rinfo(11 downto 0)) /= 0
                 and unsigned(rinfo(23 downto 12)) /= 0 then
                finfo_valid <= '1';
                div_num <= unsigned(rinfo(11 downto 0)) & to_unsigned(0, 16);
                div_den <= to_unsigned(v_ow, 12);
                div_rem <= (others => '0');
                div_q   <= (others => '0');
                div_cnt <= 27;
                gst     <= G_DX;
              else
                finfo_valid <= '0';
                gst         <= G_IDLE;
              end if;
            end if;

          when G_DX | G_DY =>
            v_rem2 := div_rem(11 downto 0) & div_num(27);
            v_q    := div_q;
            div_num <= div_num(26 downto 0) & '0';
            if v_rem2 >= resize(div_den, 13) then
              div_rem <= v_rem2 - resize(div_den, 13);
              v_q(div_cnt) := '1';
            else
              div_rem <= v_rem2;
              v_q(div_cnt) := '0';
            end if;
            div_q <= v_q;
            if div_cnt = 0 then
              if gst = G_DX then
                if v_q > 65536 then stepx <= to_unsigned(65536, 18);
                else stepx <= resize(v_q, 18); end if;
                div_num <= to_unsigned(ih, 12) & to_unsigned(0, 16);
                div_den <= to_unsigned(v_oh, 12);
                div_rem <= (others => '0');
                div_q   <= (others => '0');
                div_cnt <= 27;
                gst     <= G_DY;
              else
                if v_q > 262143 then stepy <= to_unsigned(262143, 18);
                else stepy <= resize(v_q, 18); end if;
                steps_ok <= '1';
                gst      <= G_IDLE;
              end if;
            else
              div_cnt <= div_cnt - 1;
            end if;
        end case;

        -- line loader: raw line m is stored in slot m mod 8 (bank m mod 4)
        if ld_busy = '0' then
          if finfo_valid = '1' and gst /= G_WAIT and grab_req = '0'
             and m_next <= r_use + 7 and m_next <= ih + 4 then
            ln_m       <= to_unsigned(m_next, 13);
            ln_req_tog <= not ln_req_tog;
            ld_busy    <= '1';
          end if;
        elsif v_lnack then
          ld_busy <= '0';
          m_next  <= m_next + 1;
          if m_next >= 3 then loaded4 <= '1'; end if;
        end if;

        -------------------------------------------------------------------
        -- Gated by o_ce: timing generator and pixel pipeline
        -------------------------------------------------------------------
        if o_ce = '1' then
          -- sizes of window origin (Q16, +1 offset so that values stay >= 0)
          v_x0 := resize(stepx(17 downto 1), 29) + to_unsigned(32768, 29);
          v_c0 := to_integer(v_x0(28 downto 16));

          -- timing counters
          if hc >= htotal - 1 then
            hc <= 0;
            if last_line = '1' then
              vc <= 0; last_line <= '0'; grabbed <= '0'; fresh <= '0';
            elsif vc < 4095 then
              vc <= vc + 1;
            end if;
          else
            hc <= hc + 1;
          end if;

          -- per-line events in the horizontal blanking
          if hc = hdisp + 3 then
            -- last line of the frame?
            v_lastl := (vc >= vtotal - 1) and
                       (vrr = '0' or (fresh = '1' and loaded4 = '1') or vc >= vrrmax - 1);
            last_line <= to_sl(v_lastl);
            if v_lastl then v_nv := 0; else v_nv := vc + 1; end if;

            -- grab newest frame once the image window is finished
            if vc >= vmax and (grabbed = '0' or v_newav) then
              grab_req <= '1';
              grabbed  <= '1';
              fresh    <= to_sl(v_newav);
              pub_seen <= pub_s;
            end if;

            -- vertical position of the next line
            if finfo_valid = '1' and steps_ok = '1' and v_nv >= vmin and v_nv <= vmax then
              if v_nv = vmin then
                v_rp := resize(stepy(17 downto 1), 29) + to_unsigned(32768, 29);
              else
                v_rp := rpos + resize(stepy, 29);
              end if;
              rpos     <= v_rp;
              row_n_ok <= '1';
              r_use    <= to_integer(v_rp(28 downto 16));
              v_r0     := to_integer(v_rp(17 downto 16));
              for b in 0 to 3 loop
                if b < v_r0 then half_r(b) <= not v_rp(18); else half_r(b) <= v_rp(18); end if;
                v_k := (b + 4 - v_r0) mod 4;
                wy_n(b) <= WROM(v_k)(to_integer(v_rp(15 downto 8)));
              end loop;
            else
              row_n_ok <= '0';
            end if;
          end if;

          if hc = hdisp + 8 then
            row_cur_ok <= row_n_ok;
            wy_r       <= wy_n;
          end if;

          -- stage 0: position / event generation
          v_fl(4) := to_sl(hc < hdisp and vc < vdisp);
          v_fl(3) := to_sl(hc >= hsstart and hc < hsend);
          v_fl(2) := to_sl(vc >= vsstart and vc < vsend);
          v_fl(1) := to_sl(vc >= vdisp);
          v_win   := (hc >= hmin and hc <= hmax and vc >= vmin and vc <= vmax and row_cur_ok = '1');
          v_fl(0) := to_sl(v_win);
          fl(1)   <= v_fl;

          v_pre := (hc >= hdisp + 4) and (hc <= hdisp + 7);
          v_ev  := false;
          v_col := 0;
          if v_pre and row_n_ok = '1' then
            v_ev  := true;
            v_col := v_c0 + (hc - hdisp - 4);
          elsif v_win then
            v_c := to_integer(xpos(28 downto 16));
            if v_c /= cprev then
              v_ev  := true;
              v_col := v_c + 3;
              cprev <= v_c;
            end if;
          end if;
          if v_win then
            xpos <= xpos + resize(stepx, 29);
          end if;
          if hc = hdisp + 4 then
            xpos  <= v_x0;
            cprev <= v_c0;
          end if;
          m1    <= xpos(15 downto 8);
          e1_v  <= to_sl(v_ev);
          e1_col <= to_unsigned(v_col, 14);

          -- stage 1: clamp column, split into word index / pixel select
          v_o := to_integer(e1_col) - 2;
          if v_o > iw - 1 then v_o := iw - 1; end if;
          if v_o < 0 then v_o := 0; end if;
          if ifmt16 = '1' then
            v_widx := v_o / (2 ** (BPW_L2 - 1));
            v_sel  := v_o mod (2 ** (BPW_L2 - 1));
          else
            v_widx := v_o / (2 ** (BPW_L2 - 2));
            v_sel  := v_o mod (2 ** (BPW_L2 - 2));
          end if;
          e2_v    <= e1_v;
          e2_widx <= to_unsigned(v_widx, LBW);
          e2_sel  <= v_sel;
          m2      <= m1;

          -- stage 2: (BRAM read happens here, address = half_r & e2_widx)
          e3_v   <= e2_v;
          e3_sel <= e2_sel;
          m3     <= m2;

          -- stage 3: window shift + horizontal weights
          for b in 0 to 3 loop
            if ifmt16 = '1' then
              --v_p16 := lb_rq(b)(16*e3_sel+15 downto 16*e3_sel);
              --v_pix(0) := unsigned(v_p16(15 downto 11) & v_p16(15 downto 13));
              --v_pix(1) := unsigned(v_p16(10 downto 5)  & v_p16(10 downto 9));
              --v_pix(2) := unsigned(v_p16(4 downto 0)   & v_p16(4 downto 2));
               v_p16 := lb_rq(b)(16*e3_sel+15 downto 16*e3_sel);
               v_pix(0)(7 downto 3) := unsigned(v_p16(15 downto 11));
               v_pix(0)(2 downto 0) := unsigned(v_p16(15 downto 13));
               v_pix(1)(7 downto 2) := unsigned(v_p16(10 downto 5));
               v_pix(1)(1 downto 0) := unsigned(v_p16(10 downto 9));
               v_pix(2)(7 downto 3) := unsigned(v_p16(4 downto 0));
               v_pix(2)(2 downto 0) := unsigned(v_p16(4 downto 2));
            else
              v_p32 := lb_rq(b)(32*e3_sel+31 downto 32*e3_sel);
              v_pix(0) := unsigned(v_p32(23 downto 16));
              v_pix(1) := unsigned(v_p32(15 downto 8));
              v_pix(2) := unsigned(v_p32(7 downto 0));
            end if;
            if e3_v = '1' then
              win(b)(0) <= win(b)(1);
              win(b)(1) <= win(b)(2);
              win(b)(2) <= win(b)(3);
              win(b)(3) <= v_pix;
            end if;
          end loop;
          for k in 0 to 3 loop
            wh_r(k) <= WROM(k)(to_integer(m3));
          end loop;

          -- stage 4: horizontal products
          for b in 0 to 3 loop
            for k in 0 to 3 loop
              for c in 0 to 2 loop
                prod(b, k, c) <= signed(resize(win(b)(k)(c), 9)) * wh_r(k);
              end loop;
            end loop;
          end loop;

          -- stage 5: horizontal sums (scale 2^7 after >>3)
          for b in 0 to 3 loop
            for c in 0 to 2 loop
              v_hs := resize(prod(b, 0, c), 23) + resize(prod(b, 1, c), 23)
                    + resize(prod(b, 2, c), 23) + resize(prod(b, 3, c), 23);
              hsum(b, c) <= v_hs(22 downto 3);
            end loop;
          end loop;

          -- stage 6: vertical products (bank b carries tap (b-R) mod 4)
          for b in 0 to 3 loop
            for c in 0 to 2 loop
              vprod(b, c) <= hsum(b, c) * wy_r(b);
            end loop;
          end loop;

          -- stage 7: vertical sum (+ rounding), scale 2^17
          for c in 0 to 2 loop
            vsum(c) <= resize(vprod(0, c), 34) + resize(vprod(1, c), 34)
                     + resize(vprod(2, c), 34) + resize(vprod(3, c), 34)
                     + to_signed(65536, 34);
          end loop;

          -- stage 8: clamp, border / blank mux, output registers
          for c in 0 to 2 loop
            v_vs := shift_right(vsum(c), 17);
            if v_vs < 0 then
              v_px := to_unsigned(0, 8);
            elsif v_vs > 255 then
              v_px := to_unsigned(255, 8);
            else
              v_px := unsigned(v_vs(7 downto 0));
            end if;
            if fl(8)(0) = '0' then
              if fl(8)(4) = '1' then
                v_px := o_border(23 - 8*c downto 16 - 8*c);
              else
                v_px := to_unsigned(0, 8);
              end if;
            end if;
            case c is
              when 0 => o_r <= v_px;
              when 1 => o_g <= v_px;
              when others => o_b <= v_px;
            end case;
          end loop;
          o_de  <= fl(8)(4);
          o_hs  <= fl(8)(3);
          o_vs  <= fl(8)(2);
          o_vbl <= fl(8)(1);
          o_brd <= fl(8)(4) and not fl(8)(0);

          -- control flag delay line
          for n in 2 to 8 loop
            fl(n) <= fl(n-1);
          end loop;
        end if;
      end if;
    end if;
  end process;

end architecture;
