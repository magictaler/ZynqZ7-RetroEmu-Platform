----------------------------------------------------------------------------------
-- Company: Magictale Electronics http://magictale.com
-- Engineer: Dmitry Pakhomenko
-- 
-- Create Date: 26/03/2024 9:53:00 PM
-- Design Name: 
-- Module Name: scandoubler_tb - RTL
-- Project Name: 
-- Target Devices: Zynq 7020
-- Tool Versions: Vivado 2017.3
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------

library ieee; 
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use std.textio.all;
use ieee.std_logic_textio.all;

--library xil_defaultlib;
--use xil_defaultlib.all;

library xil_defaultlib;
  use work.types_arty_video.all;
  use work.types_emulator_top.all;

entity emu_top_tb is
end emu_top_tb;

architecture rtl of emu_top_tb is

  constant c_sys_clock_period : time := 2.9 ns;
  constant c_video_clock_period : time := 11.6 ns;  -- MSX2+ VDP

  constant g_axi_lite_data_width : integer := 32;

  signal s_sys_clk, s_video_clk, s_sys_reset, s_video_reset : std_logic;

  type ddr_memory_emu is array (0 to 65535) of std_logic_vector (7 downto 0);
  signal ddr_mem : ddr_memory_emu;


  -- axi_s2mm_slave_wr_stub
  signal s_axi_ddr_awaddr : std_logic_vector(31 downto 0);
  signal s_axi_ddr_awburst : std_logic_vector(1 downto 0);
  signal s_axi_ddr_awcache : std_logic_vector(3 downto 0);
  signal s_axi_ddr_awlen : std_logic_vector(7 downto 0);
  signal s_axi_ddr_awprot : std_logic_vector(2 downto 0);
  signal s_axi_ddr_awready : std_logic;
  signal s_axi_ddr_awsize : std_logic_vector(2 downto 0);
  signal s_axi_ddr_awvalid : std_logic;
  signal s_axi_ddr_wdata : std_logic_vector(31 downto 0);
  signal s_axi_ddr_wlast : std_logic;
  signal s_axi_ddr_wready : std_logic;
  signal s_axi_ddr_bresp : std_logic_vector(1 downto 0);
  signal s_axi_ddr_wvalid : std_logic;
  signal s_axi_ddr_wstrb : std_logic_vector(3 downto 0);
  signal s_axi_ddr_bvalid : std_logic;
  signal s_axi_ddr_bready : std_logic;

  -- axi_s2mm_slave_wr_stub
  signal s_axi_ddr_araddr : std_logic_vector (31 downto 0);
  signal s_axi_ddr_arburst : std_logic_vector (1 downto 0);
  signal s_axi_ddr_arcache : std_logic_vector (3 downto 0);
  signal s_axi_ddr_arlen : std_logic_vector (7 downto 0);
  signal s_axi_ddr_arprot : std_logic_vector (2 downto 0);
  signal s_axi_ddr_arready : std_logic;
  signal s_axi_ddr_arsize : std_logic_vector (2 downto 0);
  signal s_axi_ddr_arvalid : std_logic;
  signal s_axi_ddr_rdata : std_logic_vector (31 downto 0);
  signal s_axi_ddr_rlast : std_logic;
  signal s_axi_ddr_rready : std_logic;
  signal s_axi_ddr_rresp : std_logic_vector (1 downto 0);
  signal s_axi_ddr_rvalid : std_logic;

  signal s_ddr_address : std_logic_vector(c_ddr_addr_width - 1 downto 0);
  signal s_ddr_data_in : std_logic_vector(c_ddr_data_width - 1 downto 0);
  signal s_ddr_data_out : std_logic_vector(c_ddr_data_width - 1 downto 0);
  signal s_ddr_mem_wr : std_logic;
  signal s_ddr_mem_req : std_logic;
  signal s_ddr_mem_busy : std_logic;

  signal s_emu_ce_cntr : unsigned(c_ddr_data_width - 1 downto 0) := x"00";
  signal s_ce_42mp : std_logic; -- 42.95454
  signal s_ce_21mp : std_logic; -- 21.47727

  signal s_registers_latched : std_logic;
  signal s_wr_en : std_logic;
  signal s_register_data_out : std_logic_vector(g_axi_lite_data_width - 1 downto 0);
  signal s_video_control_en : std_logic;

  component axi_s2mm_slave_wr_stub is
    port(
      i_resetn_sys : in std_logic;
      i_aclk_sys : in std_logic;

      -- AXI
      i_axi_s2mm_awaddr : in std_logic_vector(31 downto 0);
      i_axi_s2mm_awburst : in std_logic_vector(1 downto 0);
      i_axi_s2mm_awcache : in std_logic_vector(3 downto 0);
      i_axi_s2mm_awlen : in std_logic_vector(7 downto 0);
      i_axi_s2mm_awprot : in std_logic_vector(2 downto 0);
      o_axi_s2mm_awready : out std_logic;
      i_axi_s2mm_awsize : in std_logic_vector(2 downto 0);
      i_axi_s2mm_awvalid : in std_logic;
      i_axi_s2mm_wdata : in std_logic_vector(31 downto 0);
      i_axi_s2mm_wlast : in std_logic;
      o_axi_s2mm_wready : out std_logic;
      o_axi_s2mm_bresp : out std_logic_vector(1 downto 0);
      i_axi_s2mm_wvalid : in std_logic;
      i_axi_s2mm_wstrb : in std_logic_vector(3 downto 0);
      o_axi_s2mm_bvalid : out std_logic;
      i_axi_s2mm_bready : in std_logic
    );
  end component;

  component axi_s2mm_slave_rd_stub is
    generic (
      g_axi_data_width : integer := 32;
      g_axi_lite_data_width : integer := 32;
      g_axi_addr_width : integer := 32
    );
    port(
      i_resetn_sys : in std_logic;
      i_aclk_sys : in std_logic;

      -- AXI
      i_axi_s2mm_araddr : in std_logic_vector (g_axi_addr_width - 1 downto 0);
      i_axi_s2mm_arburst : in std_logic_vector (1 downto 0);
      i_axi_s2mm_arcache : in std_logic_vector (3 downto 0);
      i_axi_s2mm_arlen : in std_logic_vector (7 downto 0);
      i_axi_s2mm_arprot : in std_logic_vector (2 downto 0);
      o_axi_s2mm_arready : out std_logic;
      i_axi_s2mm_arsize : in std_logic_vector (2 downto 0);
      i_axi_s2mm_arvalid : in std_logic;
      o_axi_s2mm_rdata : out std_logic_vector (g_axi_data_width - 1 downto 0);
      o_axi_s2mm_rlast : out std_logic;
      i_axi_s2mm_rready : in std_logic;
      o_axi_s2mm_rresp : out std_logic_vector (1 downto 0);
      o_axi_s2mm_rvalid : out std_logic
  );
  end component;


  component emsx_top is
    generic (
      g_axi_lite_data_width : integer := 32;
      g_rst_seq : unsigned(4 downto 0) := "11100"
    );
    port ( 
      i_resetn_sys : in std_logic;
      i_aclk_sys : in std_logic; -- 85.90908 MHz
      i_aclk_emu : in std_logic; -- 21.4815 MHz
      i_aclk_mem : in std_logic; -- TODO
      i_p_cold_reset : in std_logic; -- TODO: connect it to the upper level

      -- DDRAM interface
      o_ddr_address : out std_logic_vector(c_ddr_addr_width - 1 downto 0);
      i_ddr_data : in std_logic_vector(c_ddr_data_width - 1 downto 0);
      o_ddr_data : out std_logic_vector(c_ddr_data_width - 1 downto 0);
      o_ddr_mem_wr : out std_logic;
      o_ddr_mem_req : out std_logic;
      i_ddr_mem_busy : in std_logic;

      -- Registers
      i_wr_en : in std_logic;    
      i_rd_en : in std_logic;    
      i_register_data_out : in std_logic_vector(c_register_width - 1 downto 0);
      i_video_control_en : in std_logic;
      o_video_control : out std_logic_vector(g_axi_lite_data_width - 1 downto 0);
      i_emu_control_en : in std_logic;
      o_emu_control : out std_logic_vector(g_axi_lite_data_width - 1 downto 0);
      i_emu_keyboard_1_en : in std_logic;
      i_emu_keyboard_2_en : in std_logic;
      --i_emu_io_ports_en : in std_logic;
      --o_emu_io_ports : out std_logic_vector(g_axi_lite_data_width - 1 downto 0);
      --i_emu_tape_fifo_en : in std_logic;
      --o_emu_tape_fifo : out std_logic_vector(g_axi_lite_data_width - 1 downto 0);
      --i_emu_bram_en : in std_logic;
      --o_emu_bram : out std_logic_vector(g_axi_lite_data_width - 1 downto 0);
      --i_shadow_emu_bram_en : in std_logic;
      --o_shadow_emu_bram : out std_logic_vector(g_axi_lite_data_width - 1 downto 0);
      i_border_color_en : in std_logic;
      o_border_color : out std_logic_vector(g_axi_lite_data_width - 1 downto 0);

      -- Z80 registers
      --i_z80_hl_de_alt_en : in std_logic;
      --o_z80_hl_de_alt : out std_logic_vector(g_axi_lite_data_width - 1 downto 0);
      --i_z80_bc_af_alt_en : in std_logic;
      --o_z80_bc_af_alt : out std_logic_vector(g_axi_lite_data_width - 1 downto 0);
      --i_z80_hl_de_en : in std_logic;
      --o_z80_hl_de : out std_logic_vector(g_axi_lite_data_width - 1 downto 0);
      --i_z80_bc_af_en : in std_logic;
      --o_z80_bc_af : out std_logic_vector(g_axi_lite_data_width - 1 downto 0);
      --i_z80_ix_iy_en : in std_logic;
      --o_z80_ix_iy : out std_logic_vector(g_axi_lite_data_width - 1 downto 0);
      --i_z80_r_sp_iff_im_en : in std_logic;
      --o_z80_r_sp_iff_im : out std_logic_vector(g_axi_lite_data_width - 1 downto 0);

      -- Audio
      o_aud_pwm : out std_logic;
      o_aud_sd : out std_logic;

      -- Emulator video out
      o_emu_hsync : out std_logic;
      o_emu_vsync : out std_logic;
      o_emu_de : out std_logic;
      o_emu_r : out std_logic_vector(c_color_component_width - 1 downto 0);
      o_emu_g : out std_logic_vector(c_color_component_width - 1 downto 0);
      o_emu_b : out std_logic_vector(c_color_component_width - 1 downto 0);

      -- For scandoubler in upstream
      --o_ce_7mp : out std_logic;
      --o_ce_14mp : out std_logic;

      -- Chip enable @ 28 MHz for ZX Spectrum
      --o_ce_28mp : out std_logic;

      -- Chip enable @ 21.48 MHz for MSX2+
      o_ce_21mp : out std_logic;

      -- PS/2 keyboard ports
      i_ps2_key : in std_logic_vector(10 downto 0); -- TODO: connect this
      o_p_caps : out std_logic;

      -- DIP switch, Lamp ports
      i_p_dip : in std_logic_vector(7 downto 0);     -- 0=On,    1=Off (default on shipment)
      o_p_led : out std_logic_vector(7 downto 0);     -- 0=Off,   1=On  (green)
      o_p_led_pwr : out std_logic; -- 0=Off,   1=On  (red)
      i_p_r800 : in std_logic;

      i_rtc_setup : in std_logic;
      i_rtc_time : in std_logic_vector(64 downto 0);

      o_p_audio_psg : out std_logic_vector(9 downto 0);
      o_p_audio_opll : out std_logic_vector(13 downto 0);
      o_p_audio_pcm : out std_logic_vector(15 downto 0);
      o_p_audio_trpcm : out std_logic_vector(7 downto 0);

      i_mmc_miso : in std_logic;
      o_mmc_cs : out std_logic;
      o_mmc_mosi : out std_logic;
      o_mmc_clk : out std_logic
    );
  end component;



begin

  s_sys_reset <= '1', '0' after (c_sys_clock_period / 2 * 100);
  s_video_reset <= '1', '0' after (c_video_clock_period / 2 * 100);

  p_emu_clk_en_generator : process(s_sys_clk)
  begin
    if rising_edge(s_sys_clk) then
      s_emu_ce_cntr <= s_emu_ce_cntr + 1;

      s_ce_42mp <= s_emu_ce_cntr(0);
      s_ce_21mp <= s_emu_ce_cntr(1) and (s_emu_ce_cntr(0));
    end if;
  end process;

  p_emu_ddr_latch : process(s_sys_clk)
  begin
    if rising_edge(s_sys_clk) then
      if (s_sys_reset = '1') then
        s_ddr_data_out <= (others => '1');
      else
        if (s_ddr_mem_req = '1') then
          if (s_ddr_mem_wr = '1') then
            ddr_mem(to_integer(unsigned(s_ddr_address(15 downto 0)))) <= s_ddr_data_in;
          else
            s_ddr_data_out <= ddr_mem(to_integer(unsigned(s_ddr_address(15 downto 0))));
          end if;
        end if;
      end if;
    end if;
  end process;

  



  p_emu_registers_latch : process(s_sys_clk)
  begin
    if rising_edge(s_sys_clk) then
      if (s_sys_reset = '1') then
        s_registers_latched <= '0';
        s_wr_en <= '0';
        s_video_control_en <= '0';
        s_register_data_out <= (others => '0');
      else
        if (s_registers_latched = '0') then
          s_wr_en <= '1';
          s_video_control_en <= '1';
          s_registers_latched <= '1';
          s_register_data_out <= "00000000000000000000000000001101";
        else
          s_wr_en <= '0';
          s_video_control_en <= '0';
          s_register_data_out <= (others => '0');
        end if;
      end if;
    end if;
  end process;


  p_sys_clock_generator : process 
    begin
      s_sys_clk <= '0';
      wait for c_sys_clock_period / 2;
      s_sys_clk <= '1';
      wait for c_sys_clock_period / 2;
  end process;

  p_video_clock_generator : process 
    begin
      s_video_clk <= '0';
      wait for c_video_clock_period / 2;
      s_video_clk <= '1';
      wait for c_video_clock_period / 2;
  end process;


  i_axi_s2mm_slave_wr_stub : axi_s2mm_slave_wr_stub
    port map(
      i_resetn_sys => not s_sys_reset,
      i_aclk_sys => s_sys_clk,

      -- AXI
      i_axi_s2mm_awaddr => s_axi_ddr_awaddr,
      i_axi_s2mm_awburst => s_axi_ddr_awburst,
      i_axi_s2mm_awcache => s_axi_ddr_awcache,
      i_axi_s2mm_awlen => s_axi_ddr_awlen,
      i_axi_s2mm_awprot => s_axi_ddr_awprot,
      o_axi_s2mm_awready => s_axi_ddr_awready,
      i_axi_s2mm_awsize => s_axi_ddr_awsize,
      i_axi_s2mm_awvalid => s_axi_ddr_awvalid,
      i_axi_s2mm_wdata => s_axi_ddr_wdata,
      i_axi_s2mm_wlast => s_axi_ddr_wlast,
      o_axi_s2mm_wready => s_axi_ddr_wready,
      o_axi_s2mm_bresp => s_axi_ddr_bresp,
      i_axi_s2mm_wvalid => s_axi_ddr_wvalid,
      i_axi_s2mm_wstrb => s_axi_ddr_wstrb,
      o_axi_s2mm_bvalid => s_axi_ddr_bvalid,
      i_axi_s2mm_bready => s_axi_ddr_bready
  );

  i_axi_s2mm_slave_rd_stub : axi_s2mm_slave_rd_stub
    port map(
      i_resetn_sys => not s_sys_reset,
      i_aclk_sys => s_sys_clk,

      -- AXI
      i_axi_s2mm_araddr => s_axi_ddr_araddr,
      i_axi_s2mm_arburst => s_axi_ddr_arburst,
      i_axi_s2mm_arcache => s_axi_ddr_arcache,
      i_axi_s2mm_arlen => s_axi_ddr_arlen,
      i_axi_s2mm_arprot => s_axi_ddr_arprot,
      o_axi_s2mm_arready => s_axi_ddr_arready,
      i_axi_s2mm_arsize => s_axi_ddr_arsize,
      i_axi_s2mm_arvalid => s_axi_ddr_arvalid,
      o_axi_s2mm_rdata => s_axi_ddr_rdata,
      o_axi_s2mm_rlast => s_axi_ddr_rlast,
      i_axi_s2mm_rready => s_axi_ddr_rready,
      o_axi_s2mm_rresp => s_axi_ddr_rresp,
      o_axi_s2mm_rvalid => s_axi_ddr_rvalid
  );

  axi_ddr_top_i : axi_ddr_top
    generic map(
      g_axi_data_width => c_smm_data_width,
      g_axi_lite_data_width => c_axi_lite_data_width,
      g_axi_addr_width => c_axi_addr_width,
      g_axi_ddr_data_width => c_ddr_data_width,
      g_axi_ddr_addr_width => c_ddr_addr_width
    )
    port map(
      i_resetn_sys => not s_sys_reset,
      i_aclk_sys => s_sys_clk,
 
      o_axi_ddr_araddr => s_axi_ddr_araddr,
      o_axi_ddr_arburst => s_axi_ddr_arburst,
      o_axi_ddr_arcache => s_axi_ddr_arcache,
      o_axi_ddr_arlen => s_axi_ddr_arlen,
      o_axi_ddr_arprot => s_axi_ddr_arprot,
      i_axi_ddr_arready => s_axi_ddr_arready,
      o_axi_ddr_arsize => s_axi_ddr_arsize,
      o_axi_ddr_arvalid => s_axi_ddr_arvalid,
      i_axi_ddr_rdata => s_axi_ddr_rdata,
      i_axi_ddr_rlast => s_axi_ddr_rlast,
      o_axi_ddr_rready => s_axi_ddr_rready,
      i_axi_ddr_rresp => s_axi_ddr_rresp,
      i_axi_ddr_rvalid => s_axi_ddr_rvalid,

      o_axi_ddr_awaddr => s_axi_ddr_awaddr,
      o_axi_ddr_awburst => s_axi_ddr_awburst,
      o_axi_ddr_awcache => s_axi_ddr_awcache,
      o_axi_ddr_awlen => s_axi_ddr_awlen,
      o_axi_ddr_awprot => s_axi_ddr_awprot,
      i_axi_ddr_awready => s_axi_ddr_awready,
      o_axi_ddr_awsize => s_axi_ddr_awsize,
      o_axi_ddr_awvalid => s_axi_ddr_awvalid,
      o_axi_ddr_wdata => s_axi_ddr_wdata,
      o_axi_ddr_wlast => s_axi_ddr_wlast,
      i_axi_ddr_wready => s_axi_ddr_wready,
      i_axi_ddr_bresp => s_axi_ddr_bresp,
      o_axi_ddr_wvalid => s_axi_ddr_wvalid,
      o_axi_ddr_wstrb => s_axi_ddr_wstrb,
      i_axi_ddr_bvalid => s_axi_ddr_bvalid,
      o_axi_ddr_bready => s_axi_ddr_bready,

      i_ddr_address => s_ddr_address,
      i_ddr_data => s_ddr_data_in,
      o_ddr_data => open, --s_ddr_data_out,
      i_ddr_mem_wr => s_ddr_mem_wr,
      i_ddr_mem_req => s_ddr_mem_req,
      o_ddr_mem_busy => s_ddr_mem_busy
  );

 i_emsx_top : emsx_top
    --generic map(
    --  g_axi_lite_data_width : integer := 32
    --)
    port map( 
      i_resetn_sys => not s_sys_reset,
      i_aclk_sys => s_sys_clk,
      i_aclk_emu => s_video_clk,
      i_aclk_mem => s_sys_clk,
      i_p_cold_reset => '0',

      -- DDRAM interface
      o_ddr_address => s_ddr_address,
      i_ddr_data => s_ddr_data_out,
      o_ddr_data => s_ddr_data_in,
      o_ddr_mem_wr => s_ddr_mem_wr,
      o_ddr_mem_req => s_ddr_mem_req,
      i_ddr_mem_busy => s_ddr_mem_busy,

      -- Registers
      i_wr_en => s_wr_en,
      i_rd_en => '0',
      i_register_data_out => s_register_data_out,
      i_video_control_en => s_video_control_en,
      o_video_control => open,
      i_emu_control_en => '0',
      o_emu_control => open,
      i_emu_keyboard_1_en => '0',
      i_emu_keyboard_2_en => '0',
      --i_emu_io_ports_en
      --o_emu_io_ports
      --i_emu_tape_fifo_en
      --o_emu_tape_fifo
      --i_emu_bram_en
      --o_emu_bram
      --i_shadow_emu_bram_en
      --o_shadow_emu_bram
      i_border_color_en => '0',
      o_border_color => open,

      -- Z80 registers
      --i_z80_hl_de_alt_en
      --o_z80_hl_de_alt
      --i_z80_bc_af_alt_en
      --o_z80_bc_af_alt
      --i_z80_hl_de_en
      --o_z80_hl_de
      --i_z80_bc_af_en
      --o_z80_bc_af
      --i_z80_ix_iy_en
      --o_z80_ix_iy
      --i_z80_r_sp_iff_im_en
      --o_z80_r_sp_iff_im

      -- Audio
      o_aud_pwm => open,
      o_aud_sd => open,

      -- Emulator video out
      o_emu_hsync => open,
      o_emu_vsync => open,
      o_emu_de => open,
      o_emu_r => open,
      o_emu_g => open,
      o_emu_b => open,

      -- For scandoubler in upstream
      --o_ce_7mp
      --o_ce_14mp

      -- Chip enable @ 28 MHz for ZX Spectrum
      --o_ce_28mp

      -- Chip enable @ 21.48 MHz for MSX2+
      o_ce_21mp => open,

      -- PS/2 keyboard ports
      i_ps2_key => (others => '0'),
      o_p_caps => open,

      -- DIP switch, Lamp ports
      i_p_dip => (others => '0'),
      o_p_led => open,
      o_p_led_pwr => open,
      i_p_r800 => '0',

      i_rtc_setup => '0',
      i_rtc_time => (others => '0'),

      o_p_audio_psg => open,
      o_p_audio_opll => open,
      o_p_audio_pcm => open,
      o_p_audio_trpcm => open,

      i_mmc_miso => '1',
      o_mmc_cs => open,
      o_mmc_mosi => open,
      o_mmc_clk => open
     
  );

end rtl;


