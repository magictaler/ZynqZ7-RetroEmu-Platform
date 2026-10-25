----------------------------------------------------------------------------------
-- Company: Magictale Electronics http://magictale.com
-- Engineer: Dmitry Pakhomenko
-- 
-- Create Date: 25.11.2023 9:25:00 PM
-- Design Name: video stream to memory mapper
-- Module Name: emu2mem - RTL
-- Project Name: Retro computer emulator on Arty Z7 board
-- Target Devices: Zynq 7020
-- Tool Versions: Vivado 2017.3
-- Description: This module reads a scandoubled video frame from an enulated retro system 
--     and stores it in RAM
-- Dependencies: fifo_2048_32_vin_cdc
-- 
-- Revision:
-- 
-- Revision 0.01 - Copied across from Speccy2022 project and refactored
-- Revision 0.02 - Reworked the state machine and cleaned the logic - 2024.01.26
-- 
-- Additional Comments:
-- 
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library xil_defaultlib;
use work.types_arty_video.all;

entity emu2mem is
    generic (
      g_axi_data_width : integer := 32;
      g_axi_lite_data_width : integer := 32;
      g_axi_addr_width : integer := 32
    );
    port(
      i_resetn_sys : in std_logic;
      i_aclk_sys : in std_logic;
      i_ce_emu_video_out : in std_logic;
      -- Aux signals
      i_enable : in std_logic;
      i_aspect_ratio_16_9 : in std_logic;
      o_ram_page : out std_logic;
      -- AXI
      o_axi_s2mm_awaddr : out std_logic_vector(g_axi_addr_width - 1 downto 0);
      o_axi_s2mm_awburst : out std_logic_vector(1 downto 0);
      o_axi_s2mm_awcache : out std_logic_vector(3 downto 0);
      o_axi_s2mm_awlen : out std_logic_vector(7 downto 0);
      o_axi_s2mm_awprot : out std_logic_vector(2 downto 0);
      i_axi_s2mm_awready : in std_logic;
      o_axi_s2mm_awsize : out std_logic_vector(2 downto 0);
      o_axi_s2mm_awvalid : out std_logic;
      o_axi_s2mm_wdata : out std_logic_vector(g_axi_data_width - 1 downto 0);
      o_axi_s2mm_wlast : out std_logic;
      i_axi_s2mm_wready : in std_logic;
      i_axi_s2mm_bresp : in std_logic_vector(1 downto 0);
      o_axi_s2mm_wvalid : out std_logic;
      o_axi_s2mm_wstrb : out std_logic_vector(3 downto 0);
      i_axi_s2mm_bvalid : in std_logic;
      o_axi_s2mm_bready : out std_logic;
      -- Scandoubled video from a retro system with ~28MHz pixel clock
      i_hsync : in std_logic;
      i_vsync : in std_logic;
      i_video_active : in std_logic;
      i_margin : in std_logic;
      i_red : in std_logic_vector(c_color_component_width - 1 downto 0);
      i_green : in std_logic_vector(c_color_component_width - 1 downto 0);
      i_blue : in std_logic_vector(c_color_component_width - 1 downto 0);
      -- Detected horizontal resolution
      i_emu_h_resolution : in std_logic_vector(9 downto 0);
      -- Calculated framebuf offsets
      i_ram_stride : in std_logic_vector(11 downto 0);
      i_rgb_data_addr_start : in std_logic_vector(31 downto 0)
  );
end emu2mem;

architecture rtl of emu2mem is

  type t_state_amba is (t_wait_frame_start_amba, t_idle_amba, t_set_addr_amba, t_wait_addr_ack_amba, t_write_amba, 
    t_write_amba_last, t_write_ack_amba, t_error_amba, t_done_amba);

  -- AMBA specific (DMA)
  signal s_state_amba : t_state_amba := t_wait_frame_start_amba;
  signal s_axi_s2mm_wvalid : std_logic;
  --signal s_axi_s2mm_wstrb_adj : std_logic_vector(3 downto 0);
  -- RGB data FIFO
  signal s_rgb_data_dout : std_logic_vector(g_axi_data_width - 1 downto 0);
  signal s_rgb_data_din : std_logic_vector(g_axi_data_width - 1 downto 0);
  signal s_rgb_data_fifo_full : std_logic;
  signal s_rgb_data_fifo_empty : std_logic;
  signal s_rgb_data_fifo_overflow : std_logic;
  signal s_rgb_data_fifo_underflow : std_logic;
  signal s_rgb_data_fifo_wr_en : std_logic;
  signal s_rgb_data_fifo_rd_en : std_logic;
  signal s_rgb_data_fifo_prog_empty : std_logic;
  signal s_rgb_data_fifo_prog_full : std_logic;
  signal s_rgb_data_fifo_reset : std_logic;
  signal s_fifo_init_counter : integer range 0 to 10 := c_fifo_init_counter;
  signal s_fifo_ready : std_logic := '0';

  signal s_framebuf_address : unsigned(g_axi_addr_width - 1 downto 0);
  signal s_beat_count : unsigned(8 downto 0);
  signal s_active_count : unsigned(9 downto 0);
  signal s_hsync_received : std_logic;
  signal s_vsync_received : std_logic;
  signal s_bytes_transferred : unsigned(10 downto 0);
  signal s_active_scanline : std_logic;
  signal s_hsync_vec : std_logic_vector(2 downto 0) := (others => '0');
  signal s_vsync_vec : std_logic_vector(2 downto 0) := (others => '0');
  signal s_enable_synced_vec : std_logic_vector(2 downto 0) := (others => '0');

  signal s_active_ram_page : std_logic;
  signal s_enable_synced : std_logic := '0';
  signal s_vsync_event : std_logic;
  signal s_hsync_event : std_logic;

  component fifo_2048_32_vin_cdc -- TODO: no need for CDC FIFO, replace it with a regular FIFO
    port (
      clk : in std_logic;
      rst : in std_logic;
      din : in std_logic_vector(g_axi_data_width - 1 downto 0);
      wr_en : in std_logic;
      rd_en : in std_logic;
      dout : out std_logic_vector(g_axi_data_width - 1 downto 0);
      full : out std_logic;
      overflow : out std_logic;
      empty : out std_logic;
      underflow : out std_logic;
      prog_full : out std_logic;
      prog_empty : out std_logic
    );
  end component;

begin

  i_rgb_data_fifo : fifo_2048_32_vin_cdc
    port map (
      clk => i_aclk_sys,
      rst => s_rgb_data_fifo_reset,
      din => s_rgb_data_din,
      wr_en => (s_rgb_data_fifo_wr_en) and (i_ce_emu_video_out) and (s_fifo_ready), 
      rd_en => (s_rgb_data_fifo_rd_en) and (s_fifo_ready),
      dout => s_rgb_data_dout,
      full => s_rgb_data_fifo_full,
      overflow => s_rgb_data_fifo_overflow,
      empty => s_rgb_data_fifo_empty,
      underflow => s_rgb_data_fifo_underflow,
      prog_full => s_rgb_data_fifo_prog_full,
      prog_empty => s_rgb_data_fifo_prog_empty
    );

  p_fifo_init_state : process(i_aclk_sys)
  begin
    if rising_edge(i_aclk_sys) then
      if (i_resetn_sys = '0') then
        s_fifo_init_counter <= c_fifo_init_counter;
        s_fifo_ready <= '0';
      else
        if (s_rgb_data_fifo_reset = '0') then
          if (s_fifo_init_counter /= 0) then
            s_fifo_init_counter <= s_fifo_init_counter - 1; -- FIFO is ready for use only after 4 clock cycles after coming out of reset
            s_fifo_ready <= '0';
          else
            s_fifo_ready <= '1';
          end if;
        else
          s_fifo_init_counter <= c_fifo_init_counter;
          s_fifo_ready <= '0';
        end if;
      end if;
    end if;
  end process;

  p_din_latch : process(i_aclk_sys)
  begin
    if rising_edge(i_aclk_sys) then
      if (i_resetn_sys = '0') then
        s_rgb_data_din <= (others => '0');
        s_rgb_data_fifo_wr_en <= '0';
      else
         if i_video_active = '1' then 
          s_rgb_data_din <= i_red & i_green & i_blue & c_zero_intensity(7 downto 1) & i_margin;
          s_rgb_data_fifo_wr_en <= '1';
        elsif (s_hsync_vec(2 downto 1) = c_active_high_raising_edge) or (s_vsync_vec(2 downto 1) = c_active_high_raising_edge) then
          -- Hsync or Vsync or both
          s_rgb_data_din <= c_zero_intensity & c_zero_intensity & c_zero_intensity & '1' & "00000" & s_vsync_event & s_hsync_event;
          s_rgb_data_fifo_wr_en <= '1';
        else
          s_rgb_data_din <= (others => '0');
          s_rgb_data_fifo_wr_en <= '0';
        end if; 
      end if;
    end if;
  end process;

  s_vsync_event <= '1' when s_vsync_vec(2 downto 1) = c_active_high_raising_edge else '0';
  s_hsync_event <= '1' when s_hsync_vec(2 downto 1) = c_active_high_raising_edge else '0';

  s_rgb_data_fifo_reset <= '1' when i_resetn_sys = '0' or (s_enable_synced = '0' and s_state_amba = t_wait_frame_start_amba) else '0';
  o_axi_s2mm_awcache <= c_axi_s2mm_awcache;
  o_axi_s2mm_wvalid <= s_axi_s2mm_wvalid;
  -- if not an event and not margin then strobe to write
  o_axi_s2mm_wstrb <= (others => '1') when s_active_scanline = '1' and s_rgb_data_dout(0) = '0' and s_rgb_data_dout(c_vid_event_bit) = '0' else (others => '0');
  o_axi_s2mm_wdata <= s_rgb_data_dout;
  o_ram_page <= s_active_ram_page;

  -- TODO use it when start address is configurable through a register
  --s_framebuf_addr_2 <= std_logic_vector(to_unsigned(f_get_ram_rgb_data_wraddress_start(i_aspect_ratio_16_9), s_framebuf_addr_2'length));

  -- p_edge_det: HSYNC, VSYNC edge detection
  -----------------------------------------=
  p_edge_det : process(i_aclk_sys)
  begin
    if rising_edge(i_aclk_sys) then
      if (i_ce_emu_video_out = '1') then
        if (i_resetn_sys = '0') then
          s_hsync_vec <= (others => '0');
          s_vsync_vec <= (others => '0');
          s_enable_synced <= '0';
        else
          s_hsync_vec <= s_hsync_vec(1 downto 0) & i_hsync;
          s_vsync_vec <= s_vsync_vec(1 downto 0) & i_vsync;
          if s_vsync_vec(2 downto 1) = c_active_high_raising_edge then
            s_enable_synced <= i_enable;
          end if;
          s_enable_synced_vec <= s_enable_synced_vec(1 downto 0) & s_enable_synced;
        end if;
      end if;
    end if;
  end process;

  -- p_amba_fsm: AMBA FSM to write into RAM
  -----------------------------------------
  p_amba_fsm : process(i_aclk_sys)
  variable v_rgb_data_fifo_rd_en : std_logic;
  begin
    if rising_edge(i_aclk_sys) then
      if (i_resetn_sys = '0') then
        s_state_amba <= t_wait_frame_start_amba;
        s_framebuf_address <= unsigned(i_rgb_data_addr_start);
        s_active_count <= unsigned(i_emu_h_resolution);
        s_active_scanline <= '0';
        s_active_ram_page <= '1';
        s_rgb_data_fifo_rd_en <= '0';
        s_hsync_received <= '0';
        s_beat_count <= (others => '0');
        s_bytes_transferred <= (others => '0');
      else
        if s_enable_synced_vec(1 downto 0) = c_active_high_raising_edge then
          s_framebuf_address <= unsigned(i_rgb_data_addr_start);
        end if;

        case s_state_amba is
          when t_wait_frame_start_amba =>
            -- skip data from FIFO until finding VSYNC to synchronise with the frame beginning
            if (s_enable_synced = '1') then
              if s_rgb_data_dout(c_vid_event_bit) = '1' and s_rgb_data_dout(c_vsync_event_bit) = '1' then
                s_active_count <= unsigned(i_emu_h_resolution);
                s_active_scanline <= '0';
                s_state_amba <= t_idle_amba;
              end if;
              if (s_rgb_data_fifo_prog_empty = '0') then
                s_rgb_data_fifo_rd_en <= '1';
              else
                s_rgb_data_fifo_rd_en <= '0';
              end if;
            else
              s_rgb_data_fifo_rd_en <= '0';
            end if;
          when t_idle_amba =>
            if (s_enable_synced = '0') then
              s_state_amba <= t_wait_frame_start_amba;
            elsif (s_rgb_data_fifo_prog_empty = '0') then
              -- Skipping all events (hsync and vsync) before starting a new AXI transaction
              if s_rgb_data_dout(c_vid_event_bit) = '0' then
                s_state_amba <= t_set_addr_amba;
                s_rgb_data_fifo_rd_en <= '0';
              else
                s_rgb_data_fifo_rd_en <= '1';
              end if;
            else
              s_rgb_data_fifo_rd_en <= '0';
            end if;
          when t_set_addr_amba =>
            s_rgb_data_fifo_rd_en <= '0';
            if (s_rgb_data_fifo_prog_empty = '0') then
              -- resetting the two least significant bits as we read in chunks of 32 bits and have to be 32 bits aligned
              o_axi_s2mm_awaddr <= std_logic_vector(s_framebuf_address);
              o_axi_s2mm_awsize <= std_logic_vector(to_unsigned(c_axi_awsize, o_axi_s2mm_awsize'length));
              o_axi_s2mm_awlen <= std_logic_vector(to_unsigned(c_axi_awlen, o_axi_s2mm_awlen'length));
              o_axi_s2mm_awburst <= std_logic_vector(to_unsigned(c_axi_awburst, o_axi_s2mm_awburst'length));
              o_axi_s2mm_awvalid <= '1';
              s_axi_s2mm_wvalid <= '0';
              o_axi_s2mm_wlast <= '0';
              s_hsync_received <= '0';
              s_state_amba <= t_wait_addr_ack_amba;
            end if;
          when t_wait_addr_ack_amba =>
            s_rgb_data_fifo_rd_en <= '0';
            if i_axi_s2mm_awready = '1' then
              o_axi_s2mm_awvalid <= '0';
              o_axi_s2mm_wlast <= '0';
              s_beat_count <= to_unsigned(c_axi_awlen, s_beat_count'length);
              s_bytes_transferred <= (others => '0');
              s_vsync_received <= '0';
              s_state_amba <= t_write_amba;
            end if;
          when t_write_amba =>
            if s_rgb_data_dout(c_vid_event_bit) = '1' then
              s_hsync_received <= '1'; -- set the flag for both cases, be it hsync or vsync
              s_axi_s2mm_wvalid <= '0';
              v_rgb_data_fifo_rd_en := '0';
              if s_rgb_data_dout(c_vsync_event_bit) = '1' then
                -- vsync
                s_vsync_received <= '1';
              end if;
              if s_rgb_data_dout(c_hsync_event_bit) = '1' then
                -- hsync
                if (s_active_scanline = '1') and (s_active_count = 0) then
                  s_active_scanline <= '0';
                else
                  v_rgb_data_fifo_rd_en := '1';
                end if;
                s_active_count <= unsigned(i_emu_h_resolution);
              end if;
              s_rgb_data_fifo_rd_en <= v_rgb_data_fifo_rd_en;

            elsif (i_axi_s2mm_wready = '1') then
              s_axi_s2mm_wvalid <= '1';
              if (s_beat_count = 0) then
                o_axi_s2mm_wlast <= '1';
                s_rgb_data_fifo_rd_en <= '0';
                s_state_amba <= t_write_amba_last;
              else
                o_axi_s2mm_wlast <= '0';
                s_beat_count <= s_beat_count - 1;
                if (s_hsync_received = '0') then
                  s_rgb_data_fifo_rd_en <= '1';
                else
                  s_rgb_data_fifo_rd_en <= '0';
                end if;
              end if;
              if (s_active_count /= 0) and (s_hsync_received = '0') then
                s_active_count <= s_active_count - 1;
                s_bytes_transferred <= s_bytes_transferred + 4;
                s_active_scanline <= '1'; -- set a flag indicating active scanline
              else
                -- Active scanline has already ended but the AXI transaction is still going 
                -- so the address cannot jump to the beginning of the next scanline, stop reading the FIFO
                -- and set the axi_s2mm_wstrb to "0000" to stop writing to the DDRAM. The wstrb is driven by
                -- the s_active_scanline
                s_active_scanline <= '0'; 
              end if;
            else
              s_rgb_data_fifo_rd_en <= '0';
            end if;
          when t_write_amba_last => 
            s_rgb_data_fifo_rd_en <= '0';
            if (s_hsync_received = '1') then
              s_framebuf_address <= s_framebuf_address + unsigned(i_ram_stride);
            end if;
            s_hsync_received <= '0';
            if (i_axi_s2mm_wready = '1') then
              s_axi_s2mm_wvalid <= '0';
              o_axi_s2mm_wlast <= '0';
              s_state_amba <= t_write_ack_amba;
            end if;
          when t_write_ack_amba => 
             s_rgb_data_fifo_rd_en <= '0';
             if (i_axi_s2mm_bvalid = '1') then
               if (i_axi_s2mm_bresp = "00") then
                 if (s_vsync_received = '0') then 
                   s_framebuf_address <= s_framebuf_address + s_bytes_transferred;
                 else
                   if (s_active_ram_page = '0') then
                     s_framebuf_address <= unsigned(i_rgb_data_addr_start);
                   else
                     s_framebuf_address <= unsigned(i_rgb_data_addr_start) + 
                       to_unsigned(f_get_ram_rgb_data_length(i_aspect_ratio_16_9), s_framebuf_address'length);
                   end if;
                   s_active_ram_page <= not s_active_ram_page;
                 end if;
                 s_state_amba <= t_done_amba;
               else
                 s_state_amba <= t_error_amba; 
               end if;
               o_axi_s2mm_bready <= '1';
             end if;
          when t_error_amba =>
            s_rgb_data_fifo_rd_en <= '0';
            o_axi_s2mm_bready <= '0';
            s_state_amba <= t_idle_amba;
          when t_done_amba =>
            s_rgb_data_fifo_rd_en <= '0';
            o_axi_s2mm_bready <= '0';
            if (s_vsync_received = '1') then
              s_state_amba <= t_wait_frame_start_amba;
            else
              s_state_amba <= t_idle_amba;
            end if;
          when others => null;
        end case;
      end if;
    end if;
  end process;

  --o_axi_s2mm_awprot <= ???

end rtl;

