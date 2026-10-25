----------------------------------------------------------------------------------
-- Company: Magictale Electronics http://magictale.com
-- Engineer: Dmitry Pakhomenko
-- 
-- Create Date: 25.11.2023 10:52:00 PM
-- Design Name: type definitions, constant definitions
-- Module Name: types_arty_video - RTL
-- Project Name: Retro computer emulator on Arty Z7 board
-- Target Devices: Zynq 7020
-- Tool Versions: Vivado 2017.3
-- Description: types and constants for arty_video modules
-- 
-- Dependencies: 
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

package types_arty_video is

  type video_timing_type is record
    h_video : integer;
    h_fp    : integer;
    h_sync  : integer;
    h_bp    : integer;
    h_total : integer;
    v_video : integer;
    v_fp    : integer;
    v_sync  : integer;
    v_bp    : integer;
    v_total : integer;
    h_pol   : std_logic;
    v_pol   : std_logic;
    active  : std_logic;
  end record;

  constant c_emu_video_clk : integer := 85909080; -- MSX specific
  constant c_active_high_raising_edge : std_logic_vector(1 downto 0) := "01";
  constant c_active_high_falling_edge : std_logic_vector(1 downto 0) := "10";
  constant c_zero_intensity : std_logic_vector(7 downto 0) := "00000000";
  constant c_hsync_event : std_logic_vector(7 downto 0) := "10000001";
  constant c_vsync_event : std_logic_vector(7 downto 0) := "10000010";
  constant c_vid_event_bit : integer range 0 to 7 := 7;
  constant c_hsync_event_bit : integer range 0 to 7 := 0;
  constant c_vsync_event_bit : integer range 0 to 7 := 1;
  -- Registers
  constant c_control_reg_sw_enable_bit    : integer range 0 to 31 := 0;
  constant c_control_reg_update_bit       : integer range 0 to 31 := 1;
  constant c_control_reg_aspect_ratio_bit : integer range 0 to 31 := 2;
  constant c_control_reg_emu_screen_en_bit : integer range 0 to 31 := 3;
  constant c_control_reg_bypass_bit       : integer range 0 to 31 := 4;
  constant c_control_reg_test_patt_bit    : integer range 0 to 31 := 5;
  constant c_control_reg_upscaler_en_bit     : integer range 0 to 31 := 8;
  constant c_control_reg_latch_brd_clr_bit: integer range 0 to 31 := 30;
  constant c_control_reg_sw_reset_bit     : integer range 0 to 31 := 31;

  constant c_axi_rgb_data_width_bytes : integer range 1 to 8 := 4;
  constant c_axi_rgb_data_half_width : integer range 1 to 8 := c_axi_rgb_data_width_bytes / 2;
  constant c_axi_ram_rgb_data_rdaddress  : integer := 91226112;                  -- 0x5700000 (used to be 0x8000000) default start address of the frame buffer
  constant c_avalon_upscaler_baseaddress  : integer := 82837504;                 -- 0x5700000 - 0x800000 = 0x4F00000

  constant c_rgb_data_per_axi_transfer : integer range 1 to 2048 := 2048;
  -- AMBA specific (DMA)
  constant c_axi_arsize : integer range 0 to 7 := c_axi_rgb_data_width_bytes - 2 + 1; -- burst size. '3' means 8 bytes per transfer
  constant c_axi_arlen : integer range 0 to 255 := 255;                           -- burst length. '255' means 256 transfers in a burst
  constant c_axi_arburst : integer range 0 to 3 := 1;                             -- burst type. '1' means incrementing
  constant c_axi_awsize : integer range 0 to 7 := c_axi_rgb_data_width_bytes - 2; -- burst size. '0' means 1 byte per transfer, '2' means 4 bytes
  constant c_axi_awlen : integer range 0 to 255 := 255;                           -- burst length. '255' means 256 transfer in a burst
  constant c_axi_awburst : integer range 0 to 3 := 1;                             -- burst type. '1' means incrementing
  constant c_axi_mm2s_arcache : std_logic_vector(3 downto 0) := "0011";
  constant c_axi_s2mm_awcache : std_logic_vector(3 downto 0) := "0011";
  -- FIFO
  constant c_fifo_init_counter : integer range 0 to 10 := 6;

  constant c_color_component_width : integer range 1 to 24 := 8;
  constant c_r0 : integer range 0 to 2 := 0;
  constant c_r1 : integer range 0 to 2 := 1;
  constant c_r2 : integer range 0 to 2 := 2;
  constant c_color_component_arr_len : integer range 0 to 3 := 3;
  subtype t_color_component is std_logic_vector(7 downto 0);
  subtype t_cdc_stretch_factor is integer range 0 to 8;

  constant c_initial_skip_frames : integer range 1 to 255 := 2;

  -- HD720p timing
  --      screen area 1280x720 @60 Hz
  --      horizontal : 1280 visible + 72 front porch (fp) + 80 hsync + 216 back porch = 1648 pixels
  --      vertical   :  720 visible +  3 front porch (fp) +  5 vsync +  22 back porch =  750 pixels
  --      Total area 1648x750
  --      clk input should be 74.25 MHz signal (1650 * 750 * 60)
  --      clk input should be 61.256250 MHz for 49.5 Hz (61.250, 5x = 306.250)
  --      hsync and vsync are positive polarity
  constant c_hd720p_timing : video_timing_type := (
    h_video => 1280,
    h_fp    =>   72,
    h_sync  =>   80,
    h_bp    =>  216,
    h_total => 1648,
    v_video =>  720,
    v_fp    =>    3,
    v_sync  =>    5,
    v_bp    =>   22,
    v_total =>  750,
    h_pol   =>  '1',
    v_pol   =>  '1',
    active  =>  '1'
  );

  -- 720x576 for most retro systems VGA-to-HDMA timing
  --      screen area 720x576 @50 Hz
  --      horizontal : 720 visible + 12 front porch (fp) + 64 hsync + 68 back porch = 864 pixels (144 total blanking pixels)
  --      vertical   : 576 visible + 5 front porch (fp) +  5 vsync + 39 back porch = 625 pixels (49 total blanking lines)
  --      Total area 864x625
  --      standard clk input should be 27 MHz signal (864 * 625 * 50)
  --      clk input should be 26.730 for 49.5 Hz (26.700, 5x = 133.500)
  --      hsync and vsync are negative polarity
  constant c_emu720x576 : video_timing_type := (
    h_video =>  720,
    h_fp    =>  12,
    h_sync  =>  64,
    h_bp    =>  68,
    h_total =>  864,
    v_video =>  576,
    v_fp    =>  5,
    v_sync  =>  5,
    v_bp    =>  39,
    v_total =>  625,
    h_pol   =>  '0',
    v_pol   =>  '0',
    active  =>  '1'
  );

  -- Scandoubler
  type t_sm_vid_out_state is (s_vo_idle, s_vo_hsync_out_sync, s_vo_start_delay, s_vo_scanline, s_vo_vsync_fp, s_vo_vsync);
  type t_sm_hsync_gen_state is (s_hs_repeater, s_hs_gen_start, s_hs_gen_end);

  constant c_in_scanline_start_delay : integer range 0 to 640 := 150;
  constant c_out_scanline_start_delay : integer range 0 to 640 := 300;
  constant c_active_duration_threshold : integer range 0 to 32 := 32;
  constant c_half_hvideo : integer range 0 to 360 := c_emu720x576.h_video / 2;
  constant c_slow_scanline_length : integer range 0 to 720 := c_half_hvideo;
  constant c_hfp : integer range 0 to 6 := c_emu720x576.h_fp / 2;
  constant c_hsync_width : integer range 0 to 100 := c_emu720x576.h_sync / 2;
  constant c_sd_gen_counter_width : integer range 0 to 10 := 10;
  -- Timing generator
  constant c_tg_data_width : integer range 0 to 16 := 16;
  type t_gen_state is (s_gs_normal, s_gs_frame_sync, s_gs_hsync);

  function f_get_ram_rgb_data_length(aspect_ratio_16_9 : std_logic := '1') return integer;

  -- Emulator specific config
  constant c_bypass_scandoubler : std_logic := '1'; -- if the emulated video controller already generates scandoubled video as in case of MSX2+ emulator
 
end;-- package types_arty_video;

package body types_arty_video is

 function f_get_ram_rgb_data_length(aspect_ratio_16_9 : std_logic := '1') return integer is
  begin
    if (aspect_ratio_16_9 = '1') then
      return c_hd720p_timing.h_video * c_hd720p_timing.v_video * c_axi_rgb_data_width_bytes;
    else
      return c_emu720x576.h_video * c_emu720x576.v_video * c_axi_rgb_data_width_bytes;
    end if;
  end function;

end package body;-- types_arty_video;