----------------------------------------------------------------------------------
-- Company: Magictale Electronics http://magictale.com
-- Engineer: Dmitry Pakhomenko
-- 
-- Create Date: 07.12.2023 10:47:00 PM
-- Design Name: Arty generic videocontroller 
-- Module Name: arty_video_top - RTL
-- Project Name: Retro computer emulator on Arty Z7 board
-- Target Devices: Zynq 7020
-- Tool Versions: Vivado 2017.3
-- Description: This module is designed to work as a drop in replacement for
-- the standard AXI Video Direct Memory Access IP Core from Xilinx to emulate
-- functionality of a generic video controller emulator
-- 
-- Dependencies: TBA
-- 
-- Revision:
-- Revision 0.01 - Copied across from Speccy2022 project and refactored
-- Additional Comments:
-- 
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


library xil_defaultlib;
  use work.types_arty_video.all;

library xil_defaultlib;
  use work.types_emulator_top.all;

entity arty_video_top is
    generic (
      g_axi_data_width : integer := 32;
      g_axi_lite_data_width : integer := 32;
      g_axi_addr_width : integer := 32
    );
    port ( 
      i_resetn_sys : in std_logic;
      i_resetn_video : in std_logic; 
      i_aclk_sys : in std_logic;
      i_aclk_video : in std_logic; -- ARTY HDMI and VGA out clock
      i_aclk_avalon : in std_logic;
      -- AXI interface      
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

      o_avalon_upscale_address : out std_logic_vector(31 downto 0);
      o_avalon_upscale_burstcount : out std_logic_vector(10 downto 0);
      o_avalon_upscale_byteenable : out std_logic_vector(15 downto 0);
      o_avalon_upscale_read : out std_logic;
      i_avalon_upscale_readdata : in std_logic_vector(127 downto 0);
      i_avalon_upscale_readdatavalid : in std_logic;
      i_avalon_upscale_waitrequest : in std_logic;
      o_avalon_upscale_write : out std_logic;
      o_avalon_upscale_writedata : out std_logic_vector(127 downto 0);

      -- Registers
      i_wr_en : in std_logic;
      i_rd_en : in std_logic;
      i_register_data_out : in std_logic_vector(g_axi_lite_data_width - 1 downto 0);
      i_video_control_en : in std_logic;
      i_video_control : in std_logic_vector(g_axi_lite_data_width - 1 downto 0); -- currently not used for setting values

      -- Emulator video out - ARTY video in
      i_emu_hsync : in std_logic;
      i_emu_vsync : in std_logic;
      i_emu_de : in std_logic;
      i_emu_r : in std_logic_vector(c_color_component_width - 1 downto 0);
      i_emu_g : in std_logic_vector(c_color_component_width - 1 downto 0);
      i_emu_b : in std_logic_vector(c_color_component_width - 1 downto 0);

      -- Clock enable signals for ARTY video core
      i_ce_pixel_clock_in : in std_logic;
      i_ce_pixel_clock_scandoubled : in std_logic;
      -- Normally twice as fast as the i_ce_pixel_clock_scandoubled or the emulated video controller clock. 
      -- May be pulled high if the same as i_aclk_sys
      i_ce_emu_video_out : in std_logic; 
      i_ce_upscaler_video_out : in std_logic; 

      -- ARTY VGA video out (clocked by i_aclk_video)
      o_vga_hs : out std_logic;
      o_vga_vs : out std_logic;
      o_vga_r : out std_logic_vector (3 downto 0); -- 4 bits per color, 12 bits total color depth due to the VGA PMOD limitations
      o_vga_b : out std_logic_vector (3 downto 0);
      o_vga_g : out std_logic_vector (3 downto 0);

      -- ARTY HDMI video out (clocked by i_aclk_video)
      o_hdmi_out_data : out std_logic_vector (c_color_component_width * 3 - 1 downto 0);
      o_hdmi_out_hsync : out std_logic;
      o_hdmi_out_vsync : out std_logic;
      o_hdmi_out_active_video : out std_logic
    );

end arty_video_top;

architecture rtl of arty_video_top is

  type t_color_component_arr is array(c_color_component_arr_len - 1 downto 0) of t_color_component;

  signal s_reg_rd_en : std_logic;
  signal s_reg_wr_en : std_logic;
  signal s_register_data_out : std_logic_vector(g_axi_lite_data_width - 1 downto 0);

  -- Scandoubler in
  signal s_sd_red_in : std_logic_vector(c_color_component_width - 1 downto 0);
  signal s_sd_green_in : std_logic_vector(c_color_component_width - 1 downto 0);
  signal s_sd_blue_in : std_logic_vector(c_color_component_width - 1 downto 0);
  -- Scandoubler out
  signal s_sd_red_out : std_logic_vector(c_color_component_width - 1 downto 0);
  signal s_sd_green_out : std_logic_vector(c_color_component_width - 1 downto 0);
  signal s_sd_blue_out : std_logic_vector(c_color_component_width - 1 downto 0);
  signal s_sd_hsync_out : std_logic;
  signal s_sd_vsync_out : std_logic;
  signal s_sd_video_active_out : std_logic;
  -- Upscaler out
  signal s_upscale_hsync_out : std_logic;
  signal s_upscale_vsync_out : std_logic;
  signal s_upscale_de_out : std_logic;
  -- Timing generator
  signal s_tg_hsync_out : std_logic;
  signal s_tg_vsync_out : std_logic;
  signal s_tg_video_active_out : std_logic;
  -- Mem2HDMI out
  signal s_mem2hdmi_red_out : std_logic_vector(c_color_component_width - 1 downto 0);
  signal s_mem2hdmi_green_out : std_logic_vector(c_color_component_width - 1 downto 0);
  signal s_mem2hdmi_blue_out : std_logic_vector(c_color_component_width - 1 downto 0);
  -- Modes of operation
  signal s_bypass_upscaler : std_logic := '0';
  signal s_ram_page : std_logic;
  signal s_aspect_ratio_16_9 : std_logic := '1';
  signal s_emu_screen_en : std_logic := '1';
  signal s_sw_enable : std_logic := '0';
  signal s_margin : std_logic;
  signal s_upscaler_en : std_logic;
  -- Emulator resolution detector
  signal s_h_cntr : std_logic_vector(9 downto 0);
  signal s_v_cntr : std_logic_vector(9 downto 0);
  signal s_resolution_locked : std_logic;
  -- Upscaler resolution detector
  signal s_upscale_red_out : unsigned(c_color_component_width - 1 downto 0);
  signal s_upscale_green_out : unsigned(c_color_component_width - 1 downto 0);
  signal s_upscale_blue_out : unsigned(c_color_component_width - 1 downto 0);
  signal s_upscale_red_out_v : std_logic_vector(c_color_component_width - 1 downto 0);
  signal s_upscale_green_out_v : std_logic_vector(c_color_component_width - 1 downto 0);
  signal s_upscale_blue_out_v : std_logic_vector(c_color_component_width - 1 downto 0);
  signal s_h_upscale_cntr : std_logic_vector(9 downto 0);
  signal s_v_upscale_cntr : std_logic_vector(9 downto 0);
  signal s_upscale_resolution_locked : std_logic;
  -- Framebuf calc
  signal s_ram_stride : std_logic_vector(11 downto 0);
  signal s_rgb_data_addr_start : std_logic_vector(31 downto 0);
  signal s_fb_c_ready : std_logic;

  -- Crossing clock domain
  signal s_bypass_upscaler_cdc : std_logic_vector(2 downto 0) := (others => '0');
  signal s_bypass_upscaler_hdmi : std_logic;

  signal s_sw_enable_cdc : std_logic_vector(2 downto 0) := (others => '0');
  signal s_sw_enable_hdmi : std_logic;
  signal s_sw_enable_stretched : std_logic;
  signal s_sw_enable_counter : t_cdc_stretch_factor := 0;

  signal s_aspect_ratio_16_9_cdc : std_logic_vector(2 downto 0) := (others => '0');
  signal s_aspect_ratio_16_9_hdmi : std_logic;
  signal s_aspect_ratio_16_9_stretched : std_logic;
  signal s_aspect_ratio_16_9_counter : t_cdc_stretch_factor := 0;

  signal s_sd_vsync_out_cdc : std_logic_vector(2 downto 0) := (others => '0');
  signal s_sd_vsync_out_hdmi : std_logic;
  signal s_sd_vsync_out_stretched : std_logic;
  signal s_sd_vsync_out_counter : t_cdc_stretch_factor := 0;

  signal s_sd_red_cdc : t_color_component_arr;
  signal s_sd_green_cdc : t_color_component_arr;
  signal s_sd_blue_cdc : t_color_component_arr;
  signal s_sd_hsync_out_cdc : std_logic_vector(2 downto 0) := (others => '0');
  signal s_sd_video_active_out_cdc : std_logic_vector(2 downto 0) := (others => '0');

  -- Upscaler
  signal s_hdmax_detected : natural range 0 to 4095;
  signal s_vdmax_detected : natural range 0 to 4095;
  signal s_avalon_upscale_address : std_logic_vector(27 downto 0);
  signal s_avalon_upscale_burstcount : std_logic_vector(7 downto 0);

    component emu2mem
      generic (
        g_axi_data_width : integer := 32;
        g_axi_lite_data_width : integer := 32;
        g_axi_addr_width : integer := 32
      );
      port(
        i_resetn_sys : in std_logic;
        i_aclk_sys : in std_logic;
        i_ce_emu_video_out : in std_logic;

        i_aspect_ratio_16_9 : in std_logic;
        i_enable : in std_logic;

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

        i_hsync : in std_logic;
        i_vsync : in std_logic;
        i_video_active : in std_logic;
        i_margin : in std_logic;
        i_red : in std_logic_vector(c_color_component_width - 1 downto 0);
        i_green : in std_logic_vector(c_color_component_width - 1 downto 0);
        i_blue : in std_logic_vector(c_color_component_width - 1 downto 0);

        o_ram_page : out std_logic;

        i_emu_h_resolution : in std_logic_vector(9 downto 0);
        i_ram_stride : in std_logic_vector(11 downto 0);
        i_rgb_data_addr_start : in std_logic_vector(31 downto 0)
    );
  end component;

  component mem2hdmi
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

      i_aspect_ratio_16_9 : in std_logic;
      i_enable_sys : in std_logic;
      i_enable_hdmi : in std_logic;

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

      i_hsync : in std_logic;
      i_vsync : in std_logic;
      i_video_active : in std_logic;
      o_red : out std_logic_vector(c_color_component_width - 1 downto 0);
      o_green : out std_logic_vector(c_color_component_width - 1 downto 0);
      o_blue : out std_logic_vector(c_color_component_width - 1 downto 0);

      i_ram_page : in std_logic
    );
  end component;

  component timing_generator is
    port(
        i_clk : in std_logic;
        i_frame_start : in std_logic;
        i_enable : in std_logic;
        i_aspect_ratio_16_9 : in std_logic;
        o_hsync, o_vsync : out std_logic;
        o_video_active : out std_logic
    );
  end component;

  component scandoubler is
    port(
        i_clk_sys : in std_logic;
        i_ce_pixel_clock_in : in std_logic;
        i_ce_pixel_clock_scandoubled : in std_logic;
        i_enable : in std_logic;

        i_hsync, i_vsync : in std_logic;
        i_hblank, i_vblank : in std_logic;
        i_r, i_g, i_b : in std_logic_vector(c_color_component_width - 1 downto 0);

        o_hsync, o_vsync : out std_logic;
        o_video_active : out std_logic;
        o_margin : out std_logic;
        o_r, o_g, o_b : out std_logic_vector(c_color_component_width - 1 downto 0)
    );
  end component;

  component resolution_detector is
    port(
      i_clk_sys : in std_logic;
      i_resetn : in std_logic;
      i_ce_pixel_clock : in std_logic;
      i_hsync : in std_logic; 
      i_vsync : in std_logic;
      i_video_active : in std_logic;
  
      o_h_cntr : out std_logic_vector(9 downto 0);
      o_v_cntr : out std_logic_vector(9 downto 0);
      o_locked : out std_logic
    );
  end component;

  component framebuf_calc is
    port(
      i_clk_sys : in std_logic;
      i_resetn : in std_logic;
      i_locked : in std_logic;
      i_aspect_ratio_16_9 : in std_logic;
      i_emu_h_resolution : in std_logic_vector(9 downto 0);
      i_emu_v_resolution : in std_logic_vector(9 downto 0);
      o_ram_stride : out std_logic_vector(11 downto 0);
      o_rgb_data_addr_start : out std_logic_vector(31 downto 0);
      o_ready : out std_logic
    );
  end component;

  component bicubic_scaler is
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
  end component;

begin

  p_video_in_route: process(i_aclk_sys)
  begin
    if rising_edge(i_aclk_sys) then
      if (c_bypass_scandoubler = '1') then
        s_sd_hsync_out <= i_emu_hsync; -- TODO: control active HIGH/LOW in centralized configuration 
        s_sd_vsync_out <= i_emu_vsync; -- TODO: control active HIGH/LOW in centralized configuration 
        s_sd_video_active_out <= i_emu_de;
        s_margin <= '0'; -- no transparent regions in non-scandoubled mode
        s_sd_red_out <= i_emu_r;
        s_sd_green_out <= i_emu_g;
        s_sd_blue_out <= i_emu_b;
      else
        -- TODO: connect scandoubler
      end if;
    end if;
  end process;

  i_resolution : resolution_detector
    port map(
      i_clk_sys => i_aclk_sys,
      i_resetn => i_resetn_sys,
      i_ce_pixel_clock => i_ce_emu_video_out,
      i_hsync => s_sd_hsync_out, --i_emu_hsync,
      i_vsync => s_sd_vsync_out, --i_emu_vsync,
      i_video_active => i_emu_de,
  
      o_h_cntr => s_h_cntr,
      o_v_cntr => s_v_cntr,
      o_locked => s_resolution_locked
    );

  i_upscaler_resolution : resolution_detector
    port map(
      i_clk_sys => i_aclk_sys,
      i_resetn => i_resetn_sys,
      i_ce_pixel_clock => i_ce_upscaler_video_out,
      i_hsync => s_upscale_hsync_out,
      i_vsync => s_upscale_vsync_out,
      i_video_active => s_upscale_de_out,

      o_h_cntr => s_h_upscale_cntr,
      o_v_cntr => s_v_upscale_cntr,
      o_locked => s_upscale_resolution_locked
    );

  i_framebuf_calc : framebuf_calc
    port map(
      i_clk_sys => i_aclk_sys,
      i_resetn => i_resetn_sys,
      i_aspect_ratio_16_9 => s_aspect_ratio_16_9,

      -- Directly from emulator video... or after upscaler
      i_locked => s_resolution_locked when s_bypass_upscaler else s_upscale_resolution_locked,
      i_emu_h_resolution => s_h_cntr when s_bypass_upscaler else s_h_upscale_cntr,
      i_emu_v_resolution => s_v_cntr when s_bypass_upscaler else s_v_upscale_cntr,

      o_ram_stride => s_ram_stride,
      o_rgb_data_addr_start => s_rgb_data_addr_start,
      o_ready => s_fb_c_ready
    );

 -- crossing from Sys clock domain to HDMI clock
  p_control_cdc: process(i_aclk_video) is
  begin
    if rising_edge(i_aclk_video) then
      if (i_resetn_video = '0') then
        s_bypass_upscaler_cdc <= (others => '0');
        s_sw_enable_cdc <= (others => '0');
        s_aspect_ratio_16_9_cdc <= (others => '0');

        s_sd_hsync_out_cdc <= (others => '0');
        s_sd_vsync_out_cdc <= (others => '0');
        s_sd_video_active_out_cdc <= (others => '0');

        s_sd_red_cdc(c_r0) <= (others => '0');
        s_sd_red_cdc(c_r1) <= (others => '0');
        s_sd_red_cdc(c_r2) <= (others => '0');

        s_sd_green_cdc(c_r0) <= (others => '0');
        s_sd_green_cdc(c_r1) <= (others => '0');
        s_sd_green_cdc(c_r2) <= (others => '0');

        s_sd_blue_cdc(c_r0) <= (others => '0');
        s_sd_blue_cdc(c_r1) <= (others => '0');
        s_sd_blue_cdc(c_r2) <= (others => '0');

      else
        s_bypass_upscaler_cdc <= s_bypass_upscaler_cdc(1 downto 0) & s_bypass_upscaler;
        s_bypass_upscaler_hdmi <= s_bypass_upscaler_cdc(2);
        s_sw_enable_cdc <= s_sw_enable_cdc(1 downto 0) & s_sw_enable_stretched;
        s_sw_enable_hdmi <= s_sw_enable_cdc(2);
        s_aspect_ratio_16_9_cdc <= s_aspect_ratio_16_9_cdc(1 downto 0) & s_aspect_ratio_16_9_stretched;
        s_aspect_ratio_16_9_hdmi <= s_aspect_ratio_16_9_cdc(2); 
        s_sd_vsync_out_cdc <= s_sd_vsync_out_cdc(1 downto 0) & s_sd_vsync_out_stretched;
        s_sd_vsync_out_hdmi <= s_sd_vsync_out_cdc(2);

        s_sd_hsync_out_cdc <= s_sd_hsync_out_cdc(1 downto 0) & s_sd_hsync_out;
        s_sd_video_active_out_cdc <= s_sd_video_active_out_cdc(1 downto 0) & s_sd_video_active_out;

        s_sd_red_cdc(c_r0) <= s_sd_red_out;
        s_sd_red_cdc(c_r1) <= s_sd_red_cdc(c_r0);
        s_sd_red_cdc(c_r2) <= s_sd_red_cdc(c_r1);

        s_sd_green_cdc(c_r0) <= s_sd_green_out;
        s_sd_green_cdc(c_r1) <= s_sd_green_cdc(c_r0);
        s_sd_green_cdc(c_r2) <= s_sd_green_cdc(c_r1);

        s_sd_blue_cdc(c_r0) <= s_sd_blue_out;
        s_sd_blue_cdc(c_r1) <= s_sd_blue_cdc(c_r0);
        s_sd_blue_cdc(c_r2) <= s_sd_blue_cdc(c_r1);
      end if;
    end if;
  end process;

  p_video_output_latch : process(i_aclk_video)
  begin
    if rising_edge(i_aclk_video) then
      if s_bypass_upscaler_hdmi = '1' then 
        -- VGA out
        o_vga_hs <= s_sd_hsync_out_cdc(c_r2);
        o_vga_vs <= s_sd_vsync_out_cdc(c_r2);
        if (s_sd_video_active_out_cdc(c_r2) = '1') then
          o_vga_r <= s_sd_red_cdc(c_r2)(c_color_component_width - 1 downto c_vga_color_depth);
          o_vga_g <= s_sd_green_cdc(c_r2)(c_color_component_width - 1 downto c_vga_color_depth);
          o_vga_b <= s_sd_blue_cdc(c_r2)(c_color_component_width - 1 downto c_vga_color_depth);
        else
          o_vga_r <= (others => '0');
          o_vga_g <= (others => '0');
          o_vga_b <= (others => '0');
        end if;
        -- HDMI out
        o_hdmi_out_data <= s_sd_red_cdc(c_r2) & s_sd_blue_cdc(c_r2) & s_sd_green_cdc(c_r2);
        o_hdmi_out_hsync <= s_sd_hsync_out_cdc(c_r2);
        o_hdmi_out_vsync <= s_sd_vsync_out_cdc(c_r2);
        o_hdmi_out_active_video <= s_sd_video_active_out_cdc(c_r2);
      else
        -- VGA out
        o_vga_hs <= s_tg_hsync_out;
        o_vga_vs <= s_tg_vsync_out;
        if (s_tg_video_active_out = '1') then
          o_vga_r <= s_mem2hdmi_red_out(c_color_component_width - 1 downto c_vga_color_depth);
          o_vga_b <= s_mem2hdmi_blue_out(c_color_component_width - 1 downto c_vga_color_depth);
          o_vga_g <= s_mem2hdmi_green_out(c_color_component_width - 1 downto c_vga_color_depth);
        else
          o_vga_r <= (others => '0');
          o_vga_b <= (others => '0');
          o_vga_g <= (others => '0');
        end if;
        -- HDMI out
        o_hdmi_out_data <= s_mem2hdmi_red_out & s_mem2hdmi_blue_out & s_mem2hdmi_green_out;
        o_hdmi_out_hsync <= s_tg_hsync_out;
        o_hdmi_out_vsync <= s_tg_vsync_out;
        o_hdmi_out_active_video <= s_tg_video_active_out;
      end if;
    end if;
  end process;

  -- This process latches register values upon activation of WR_EN and one of
  -- _EN signals
  p_latching_registers: process(i_aclk_sys)
  begin
    if rising_edge(i_aclk_sys) then
      if (i_resetn_sys = '0') then
        -- Set registers to default values immediately after reset
        s_aspect_ratio_16_9 <= '1';
        s_bypass_upscaler <= '0';
        s_sw_enable <= '0';
        s_upscaler_en <= '1';
      else
        if (s_aspect_ratio_16_9 = '1') then
            s_aspect_ratio_16_9_counter <= 8;
        elsif (s_aspect_ratio_16_9_counter > 0) then
          s_aspect_ratio_16_9_counter <= s_aspect_ratio_16_9_counter - 1;
        end if;

        if (s_sw_enable = '1') then
          s_sw_enable_counter <= 8;
        elsif (s_sw_enable_counter > 0) then
          s_sw_enable_counter <= s_sw_enable_counter - 1;
        end if;

        if (s_sd_vsync_out = '1') then
            s_sd_vsync_out_counter <= 8;
        elsif (s_sd_vsync_out_counter > 0) then
          s_sd_vsync_out_counter <= s_sd_vsync_out_counter - 1;
        end if;

        if s_reg_wr_en = '1' then
          if i_video_control_en = '1' then
            s_aspect_ratio_16_9 <= s_register_data_out(c_control_reg_aspect_ratio_bit);
            s_emu_screen_en <= s_register_data_out(c_control_reg_emu_screen_en_bit);
            s_bypass_upscaler <= s_register_data_out(c_control_reg_bypass_bit);
            s_sw_enable <= s_register_data_out(c_control_reg_sw_enable_bit);
            s_upscaler_en <= s_register_data_out(c_control_reg_upscaler_en_bit);
          end if;
        end if;

        if (s_aspect_ratio_16_9_counter > 0) then
          s_aspect_ratio_16_9_stretched <= '1';
        else
          s_aspect_ratio_16_9_stretched <= '0';
        end if;

        if (s_sw_enable_counter > 0) then
          s_sw_enable_stretched <= '1';
        else
          s_sw_enable_stretched <= '0';
        end if;

        if (s_sd_vsync_out_counter > 0) then
          s_sd_vsync_out_stretched <= '1';
        else
          s_sd_vsync_out_stretched <= '0';
        end if;
      end if;
    end if;
  end process;

  i_timing_gen : timing_generator
    port map (
        i_clk => i_aclk_video,
        i_frame_start => s_sd_vsync_out_hdmi,
        i_aspect_ratio_16_9 => s_aspect_ratio_16_9_hdmi,
        i_enable => s_sw_enable_hdmi,
        o_hsync => s_tg_hsync_out,
        o_vsync => s_tg_vsync_out,
        o_video_active => s_tg_video_active_out
    );

  i_mem2hdmi : mem2hdmi
    generic map(
      g_axi_data_width => g_axi_data_width,
      g_axi_lite_data_width => g_axi_lite_data_width,
      g_axi_addr_width => g_axi_addr_width
    )
    port map (
      i_resetn_sys => i_resetn_sys,
      i_resetn_video => i_resetn_video,
      i_aclk_video => i_aclk_video,
      i_aclk_sys => i_aclk_sys,

      i_aspect_ratio_16_9 => s_aspect_ratio_16_9,
      i_enable_sys => s_sw_enable,
      i_enable_hdmi => s_sw_enable_hdmi,

      -- AXI
      o_axi_mm2s_araddr => o_axi_mm2s_araddr,
      o_axi_mm2s_arburst => o_axi_mm2s_arburst,
      o_axi_mm2s_arcache => o_axi_mm2s_arcache,
      o_axi_mm2s_arlen => o_axi_mm2s_arlen,
      o_axi_mm2s_arprot => o_axi_mm2s_arprot,
      i_axi_mm2s_arready => i_axi_mm2s_arready,
      o_axi_mm2s_arsize => o_axi_mm2s_arsize,
      o_axi_mm2s_arvalid => o_axi_mm2s_arvalid,
      i_axi_mm2s_rdata => i_axi_mm2s_rdata,
      i_axi_mm2s_rlast => i_axi_mm2s_rlast,
      o_axi_mm2s_rready => o_axi_mm2s_rready,
      i_axi_mm2s_rresp => i_axi_mm2s_rresp,
      i_axi_mm2s_rvalid => i_axi_mm2s_rvalid,

      i_hsync => s_tg_hsync_out,
      i_vsync => s_tg_vsync_out,
      i_video_active => s_tg_video_active_out,
      o_red => s_mem2hdmi_red_out,
      o_green => s_mem2hdmi_green_out,
      o_blue => s_mem2hdmi_blue_out,

      i_ram_page => s_ram_page
    );

  i_emu2mem : emu2mem
    generic map (
      g_axi_data_width => g_axi_data_width,
      g_axi_lite_data_width => g_axi_lite_data_width,
      g_axi_addr_width => g_axi_addr_width
    )
    port map (
      i_resetn_sys => i_resetn_sys,
      i_aclk_sys => i_aclk_sys,

      i_aspect_ratio_16_9 => s_aspect_ratio_16_9,

      -- AXI
      o_axi_s2mm_awaddr => o_axi_s2mm_awaddr,
      o_axi_s2mm_awburst => o_axi_s2mm_awburst,
      o_axi_s2mm_awcache => o_axi_s2mm_awcache,
      o_axi_s2mm_awlen => o_axi_s2mm_awlen,
      o_axi_s2mm_awprot => o_axi_s2mm_awprot,
      i_axi_s2mm_awready => i_axi_s2mm_awready,
      o_axi_s2mm_awsize => o_axi_s2mm_awsize,
      o_axi_s2mm_awvalid => o_axi_s2mm_awvalid,
      o_axi_s2mm_wdata => o_axi_s2mm_wdata,
      o_axi_s2mm_wlast => o_axi_s2mm_wlast,
      i_axi_s2mm_wready => i_axi_s2mm_wready,
      i_axi_s2mm_bresp => i_axi_s2mm_bresp,
      o_axi_s2mm_wvalid => o_axi_s2mm_wvalid,
      o_axi_s2mm_wstrb => o_axi_s2mm_wstrb,
      i_axi_s2mm_bvalid => i_axi_s2mm_bvalid,
      o_axi_s2mm_bready => o_axi_s2mm_bready,


      -- Directly from emulator video .. or after upscaler
      i_hsync => s_sd_hsync_out when s_bypass_upscaler else s_upscale_hsync_out,
      i_vsync => s_sd_vsync_out when s_bypass_upscaler else s_upscale_vsync_out,
      i_video_active => s_sd_video_active_out when s_bypass_upscaler else s_upscale_de_out,
      i_margin => s_margin,
      i_red => s_sd_red_out when s_bypass_upscaler else s_upscale_red_out_v,
      i_green => s_sd_green_out when s_bypass_upscaler else s_upscale_green_out_v,
      i_blue => s_sd_blue_out when s_bypass_upscaler else s_upscale_blue_out_v,
      i_ce_emu_video_out => i_ce_emu_video_out when s_bypass_upscaler else i_ce_upscaler_video_out,
      i_emu_h_resolution => s_h_cntr when s_bypass_upscaler else s_h_upscale_cntr,
      i_enable => s_sw_enable and s_emu_screen_en and s_fb_c_ready and s_resolution_locked  when s_bypass_upscaler else
                  s_sw_enable and s_emu_screen_en and s_fb_c_ready and s_upscale_resolution_locked,

      o_ram_page => s_ram_page,

      i_ram_stride => s_ram_stride,
      i_rgb_data_addr_start => s_rgb_data_addr_start
    );

    s_register_data_out <= i_register_data_out;
    s_reg_wr_en <= i_wr_en;
    s_reg_rd_en <= i_rd_en;

    s_upscale_red_out_v <= std_logic_vector(s_upscale_red_out);
    s_upscale_green_out_v <= std_logic_vector(s_upscale_green_out);
    s_upscale_blue_out_v <= std_logic_vector(s_upscale_blue_out);

  i_scaler : bicubic_scaler
    generic map (
      N_DW    => 128,
      N_AW    => 28,
      N_BURST => 256
    )
    port map (
      -- Input video
      i_r => unsigned(i_emu_r),
      i_g => unsigned(i_emu_g),
      i_b => unsigned(i_emu_b),
      i_hs => i_emu_hsync,
      i_vs => i_emu_vsync,
      i_de => i_emu_de,
      i_ce => i_ce_emu_video_out and s_resolution_locked,
      i_clk => i_aclk_sys,

      -- Output video
      o_r => s_upscale_red_out,
      o_g => s_upscale_green_out,
      o_b => s_upscale_blue_out,
      o_hs => s_upscale_hsync_out,
      o_vs => s_upscale_vsync_out,
      o_de => s_upscale_de_out,
      --o_vbl
      --o_brd
      o_ce => i_ce_upscaler_video_out,
      o_clk => i_aclk_sys,
      -- Border colour R G B
      o_border => x"0000FF",

      -- Input video parameters
      iauto => '1',
      -- Detected input image size (pixels / lines)
      i_hdmax =>  s_hdmax_detected,
      i_vdmax =>  s_vdmax_detected,

      -- Output video parameters
      htotal => 738,
      hsstart => 718,
      hsend => 728,
      hdisp => 708,
      hmin => 0,
      hmax => 708,

      vtotal => 749,
      vsstart => 729,
      vsend => 739,
      vdisp => 720,
      vmin => 0,
      vmax => 719,

      vrr => '0',
      --vrrmax  >= 0,
      -- Scaler format. 00=16bpp 565, 01=24bpp 10=32bpp
      format  => "01",

      -- Avalon
      avl_clk => i_aclk_avalon, 
      avl_waitrequest => i_avalon_upscale_waitrequest,
      avl_readdata => i_avalon_upscale_readdata,
      avl_readdatavalid => i_avalon_upscale_readdatavalid,
      avl_burstcount => s_avalon_upscale_burstcount,
      avl_writedata => o_avalon_upscale_writedata,
      avl_address => s_avalon_upscale_address,
      avl_write => o_avalon_upscale_write,
      avl_read => o_avalon_upscale_read,
      avl_byteenable => o_avalon_upscale_byteenable,
      ------------------------------------
      reset_na => i_resetn_sys --and s_resolution_locked
    );

  o_avalon_upscale_burstcount <= "000" & s_avalon_upscale_burstcount;
  o_avalon_upscale_address <= (s_avalon_upscale_address  & "0000") or x"00800000";

end architecture;


