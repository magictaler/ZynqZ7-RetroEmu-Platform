----------------------------------------------------------------------------------
-- Company: Magictale Electronics http://magictale.com
-- Engineer: Dmitry Pakhomenko
-- 
-- Create Date: 25.11.2023 6:53:00 PM
-- Design Name: memory to HDMI datastream mapper
-- Module Name: mem2hdmi - RTL
-- Project Name: Retro computer emulator on Arty Z7 board
-- Target Devices: Zynq 7020
-- Tool Versions: Vivado 2017.3
-- Description: This module reads a video frame from RAM and generates RGB stream
--     in accordance with HDMI timings provided externally
-- Dependencies: fifo_2048_32_vout_cdc
-- 
-- Revision:
-- 
-- Revision 0.01 - Copied across from Speccy2022 project and refactored
-- Additional Comments:
-- 
----------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

library xil_defaultlib;
  use work.types_arty_video.all;
  use work.types_emulator_top.all;


entity mem2hdmi is
  generic (
    g_axi_data_width : integer := 32;
    g_axi_lite_data_width : integer := 32;
    g_axi_addr_width : integer := 32
  );
  port (
    i_resetn_sys : in std_logic;
    i_resetn_video : in std_logic;
    i_aclk_video : in std_logic;
    i_aclk_sys : in std_logic;
    -- Aux signals
    i_aspect_ratio_16_9 : in std_logic;
    i_enable_sys : in std_logic;
    i_enable_hdmi : in std_logic;
    i_ram_page : in std_logic;
    -- AXI
    o_axi_mm2s_araddr : out std_logic_vector(g_axi_addr_width - 1 downto 0);
    o_axi_mm2s_arburst : out std_logic_vector(1 downto 0);
    o_axi_mm2s_arcache : out std_logic_vector(3 downto 0);
    o_axi_mm2s_arlen : out std_logic_vector(7 downto 0);
    o_axi_mm2s_arprot : out std_logic_vector(2 downto 0);
    i_axi_mm2s_arready : in std_logic;
    o_axi_mm2s_arsize : out std_logic_vector(2 downto 0);
    o_axi_mm2s_arvalid : out std_logic;
    i_axi_mm2s_rdata : in std_logic_vector(c_mms_data_width - 1 downto 0);
    i_axi_mm2s_rlast : in std_logic;
    o_axi_mm2s_rready : out std_logic;
    i_axi_mm2s_rresp : in std_logic_vector(1 downto 0);
    i_axi_mm2s_rvalid : in std_logic;
    -- HDMI timings
    i_hsync : in std_logic;
    i_vsync : in std_logic;
    i_video_active : in std_logic;
    -- HDMI RGB data
    o_red : out std_logic_vector(c_color_component_width - 1 downto 0);
    o_green : out std_logic_vector(c_color_component_width - 1 downto 0);
    o_blue : out std_logic_vector(c_color_component_width - 1 downto 0)
  );
end mem2hdmi;

architecture rtl of mem2hdmi is

  type t_state_amba is (t_idle_amba, t_set_addr_amba, t_wait_addr_ack_amba, t_wait_data_start_amba, t_read_amba, t_done_amba);

  -- AMBA specific (DMA)
  signal s_state_amba : t_state_amba := t_idle_amba;
  -- RGB data FIFO
  signal s_rgb_data_dout : std_logic_vector(c_mms_data_width - 1 downto 0);
  signal s_rgb_data_fifo_full : std_logic;
  signal s_rgb_data_fifo_empty : std_logic;
  signal s_rgb_data_fifo_overflow : std_logic;
  signal s_rgb_data_fifo_underflow : std_logic;
  signal s_rgb_data_fifo_wr_en : std_logic;
  signal s_rgb_data_fifo_rd_en : std_logic;
  signal s_rgb_data_fifo_prog_empty : std_logic;
  signal s_rgb_data_fifo_prog_full : std_logic;
  signal s_fifo_init_counter : integer range 0 to 10 := c_fifo_init_counter;
  signal s_fifo_ready : std_logic := '0';
  -- Ungrouped signals
  -- The doubled buffered start address from a register, currenty set to a constant and not configurable
  signal s_framebuf_addr_2 : std_logic_vector(g_axi_lite_data_width - 1 downto 0); 
  signal s_framebuf_address : unsigned(g_axi_addr_width - 1 downto 0);
  signal s_frame_start_vec : std_logic_vector(2 downto 0) := (others => '0');
  signal s_frame_synced : std_logic;
  signal s_fifo_reset : std_logic;

  signal s_color_data_selector : std_logic;
  signal s_color_bit_shift : integer range 0 to c_mms_data_width / 2;

  component fifo_2048_32_vout_cdc
    port (
      wr_clk : in std_logic;
      rd_clk : in std_logic;
      rst : in std_logic;
      din : in std_logic_vector(c_mms_data_width - 1 downto 0);
      wr_en : in std_logic;
      rd_en : in std_logic;
      dout : out std_logic_vector(c_mms_data_width - 1 downto 0);
      full : out std_logic;
      overflow : out std_logic;
      empty : out std_logic;
      underflow : out std_logic;
      prog_full : out std_logic;
      prog_empty : out std_logic
    );
  end component;

begin

  i_rgb_data_fifo : fifo_2048_32_vout_cdc
    port map (
      wr_clk => i_aclk_sys,
      rd_clk => i_aclk_video,
      rst => s_fifo_reset,
      din => i_axi_mm2s_rdata,
      wr_en => s_rgb_data_fifo_wr_en and s_fifo_ready,
      rd_en => s_rgb_data_fifo_rd_en and s_fifo_ready,
      dout => s_rgb_data_dout,
      full => s_rgb_data_fifo_full,
      overflow => s_rgb_data_fifo_overflow,
      empty => s_rgb_data_fifo_empty,
      underflow => s_rgb_data_fifo_underflow,
      prog_full => s_rgb_data_fifo_prog_full,
      prog_empty => s_rgb_data_fifo_prog_empty
    );

  s_fifo_reset <= '1' when i_resetn_sys = '0' or (i_enable_sys = '0' and s_state_amba = t_idle_amba) else '0';
  s_rgb_data_fifo_wr_en <= i_axi_mm2s_rvalid;
  o_axi_mm2s_arcache <= c_axi_mm2s_arcache;
  s_rgb_data_fifo_rd_en <= '1' when i_video_active = '1' and s_frame_synced = '1' and s_color_data_selector = '0' else '0';
  s_color_bit_shift <= 0 when s_color_data_selector = '1' else c_mms_data_width / 2;
  o_blue <= s_rgb_data_dout(c_color_component_width * 2 - 1 + s_color_bit_shift downto c_color_component_width + s_color_bit_shift) when i_video_active = '1' else (others => '0');
  o_green <= s_rgb_data_dout(c_color_component_width * 3 - 1 + s_color_bit_shift downto c_color_component_width * 2 + s_color_bit_shift) when i_video_active = '1' else (others => '0');
  o_red <= s_rgb_data_dout(c_color_component_width * 4 - 1 + s_color_bit_shift downto c_color_component_width * 3 + s_color_bit_shift) when i_video_active = '1' else (others => '0');

  -- TODO: make this configurable through an AXI register
  s_framebuf_addr_2 <= std_logic_vector(to_unsigned(c_axi_ram_rgb_data_rdaddress, s_framebuf_addr_2'length));

  p_fifo_init_state : process(i_aclk_video)
  begin
    if rising_edge(i_aclk_video) then
      if (i_resetn_video = '0') then
        s_fifo_init_counter <= c_fifo_init_counter;
        s_fifo_ready <= '0';
      else
        if (s_fifo_reset = '0') then
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

  -- p_frame_sync: syncrhonize the beginning of 
  -- reading a frame from memory with the 
  -- beginning of a frame from timing signals
  ---------------------------------------------
  p_frame_sync : process(i_aclk_video)
  begin
    if rising_edge(i_aclk_video) then
      if (i_resetn_video = '0') or (i_enable_hdmi = '0') then
        s_frame_start_vec <= (others => '0');
        s_frame_synced <= '0';
        s_color_data_selector <= '0';
      else
        s_frame_start_vec <= s_frame_start_vec(1 downto 0) & i_vsync;
        if (s_frame_start_vec(2 downto 1) = "01" and (s_rgb_data_fifo_prog_empty = '0')) then
          s_frame_synced <= '1';
        end if;

        if i_video_active = '1' and s_frame_synced = '1' then
          s_color_data_selector <= not s_color_data_selector;
        end if;
      end if;
    end if;
  end process;

  -- p_amba_fsm: AMBA FSM to read from RAM
  ----------------------------------------
  p_amba_fsm : process(i_aclk_sys)
  begin
    if rising_edge(i_aclk_sys) then
      if (i_resetn_sys = '0') then
        s_state_amba <= t_idle_amba;
        o_axi_mm2s_rready <= '0';
        o_axi_mm2s_arvalid <= '0';
        s_framebuf_address <= unsigned(s_framebuf_addr_2);
      else
        case s_state_amba is
          when t_idle_amba =>
            if (i_enable_sys = '0') then
              o_axi_mm2s_rready <= '0';
              o_axi_mm2s_arvalid <= '0';
              s_framebuf_address <= unsigned(s_framebuf_addr_2);
            -- Don't start if there is no space in the FIFOs for at least one scanline worth of data
            elsif (s_rgb_data_fifo_prog_full = '0') then
              s_state_amba <= t_set_addr_amba;
            end if;
          when t_set_addr_amba =>
            o_axi_mm2s_araddr <= std_logic_vector(s_framebuf_address);
            o_axi_mm2s_arsize <= std_logic_vector(to_unsigned(c_axi_arsize, o_axi_mm2s_arsize'length));
            o_axi_mm2s_arlen <= std_logic_vector(to_unsigned(c_axi_arlen, o_axi_mm2s_arlen'length));
            o_axi_mm2s_arburst <= std_logic_vector(to_unsigned(c_axi_arburst, o_axi_mm2s_arburst'length));
            o_axi_mm2s_arprot <= (others => '0');
            o_axi_mm2s_arvalid <= '1';
            s_state_amba <= t_wait_addr_ack_amba;
          when t_wait_addr_ack_amba =>
            if i_axi_mm2s_arready = '1' then
              o_axi_mm2s_arvalid <= '0';
              o_axi_mm2s_rready <= '1';
              s_state_amba <= t_wait_data_start_amba;
            end if;
          when t_wait_data_start_amba =>
            if i_axi_mm2s_rvalid = '1' and i_axi_mm2s_rlast = '0' then
              -- Read first portion of data
              s_state_amba <= t_read_amba;
            end if;
          when t_read_amba =>
            if i_axi_mm2s_rvalid = '1' then
              if i_axi_mm2s_rlast = '1' then
                -- Valid transmission
                s_state_amba <= t_done_amba;
              end if;
            end if;
          when t_done_amba =>
            o_axi_mm2s_rready <= '0';
            -- TODO: maybe optimise this if expression as it doesn't look neat for the case with two pages in RAM
            if s_framebuf_address = (f_get_ram_rgb_data_length(i_aspect_ratio_16_9) - c_rgb_data_per_axi_transfer + unsigned(s_framebuf_addr_2)) or 
                s_framebuf_address = (f_get_ram_rgb_data_length(i_aspect_ratio_16_9) - c_rgb_data_per_axi_transfer + unsigned(s_framebuf_addr_2) + 
                f_get_ram_rgb_data_length(i_aspect_ratio_16_9)) then
              if i_ram_page = '1' then
                s_framebuf_address <= unsigned(s_framebuf_addr_2) + f_get_ram_rgb_data_length(i_aspect_ratio_16_9);
              else
                s_framebuf_address <= unsigned(s_framebuf_addr_2);
              end if;
            else
              s_framebuf_address <= s_framebuf_address + c_rgb_data_per_axi_transfer;
            end if;
            s_state_amba <= t_idle_amba;
          when others => null;
        end case;
      end if;
    end if;
  end process;

end rtl;

