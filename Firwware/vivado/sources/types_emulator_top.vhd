----------------------------------------------------------------------------------
-- Company: Magictale Electronics http://magictale.com
-- Engineer: Dmitry Pakhomenko
-- 
-- Create Date: 24.11.2023 8:27:00 PM
-- Design Name: Emulator top type definitions, constant definitions
-- Module Name: types_emulator_top - RTL
-- Project Name: Generic retro computer emulator on Arty Z7/AX7020 boards
-- Target Devices: Zynq 7020
-- Tool Versions: Vivado 2017.3
-- Description: top types and constants for all modules
-- 
-- Dependencies: 
-- 
-- Revision:
-- 
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

library xil_defaultlib;
  use work.types_arty_video.all;
  use work.types_arty_audio.all;

package types_emulator_top is

  constant c_mms_data_width : integer := 64;
  constant c_smm_data_width : integer := 32;
  constant c_axi_addr_width : integer := 32;
  constant c_ddr_dq_data_width : integer := 32;
  constant c_ddr_dq_addr_width : integer := 15;
  constant c_ddr_addr_width : integer := 24;
  constant c_ddr_data_width : integer := 8;
  constant c_axi_lite_data_width : integer := 32;
  constant c_obuf_drive_strenth : integer := 12;
  constant c_obuf_iostandard : string := "DEFAULT";
  constant c_obuf_slew : string := "SLOW";
  constant c_vga_color_depth : integer := 4; -- VGA PMOD module is only 12bit in color resolution
  constant c_register_width : integer := 32;
  constant c_fixed_mio_width : integer := 54;

  component emulator
    port (
      HDMI_HPD_tri_i : in std_logic_vector (0 downto 0);
      DDR_cas_n : inout std_logic;
      DDR_cke : inout std_logic;
      DDR_ck_n : inout std_logic;
      DDR_ck_p : inout std_logic;
      DDR_cs_n : inout std_logic;
      DDR_reset_n : inout std_logic;
      DDR_odt : inout std_logic;
      DDR_ras_n : inout std_logic;
      DDR_we_n : inout std_logic;
      DDR_ba : inout std_logic_vector (2 downto 0);
      DDR_addr : inout std_logic_vector (c_ddr_dq_addr_width - 1 downto 0);
      DDR_dm : inout std_logic_vector (3 downto 0);
      DDR_dq : inout std_logic_vector (c_ddr_dq_data_width - 1 downto 0);
      DDR_dqs_n : inout std_logic_vector (3 downto 0);
      DDR_dqs_p : inout std_logic_vector (3 downto 0);

      FIXED_IO_mio : inout std_logic_vector (c_fixed_mio_width - 1 downto 0);
      FIXED_IO_ddr_vrn : inout std_logic;
      FIXED_IO_ddr_vrp : inout std_logic;
      FIXED_IO_ps_srstb : inout std_logic;
      FIXED_IO_ps_clk : inout std_logic;
      FIXED_IO_ps_porb : inout std_logic;
      HDMI_DDC_sda_i : in std_logic;
      HDMI_DDC_sda_o : out std_logic;
      HDMI_DDC_sda_t : out std_logic;
      HDMI_DDC_scl_i : in std_logic;
      HDMI_DDC_scl_o : out std_logic;
      HDMI_DDC_scl_t : out std_logic;
      TMDS_clk_p : out std_logic;
      TMDS_clk_n : out std_logic;
      TMDS_data_p : out std_logic_vector (2 downto 0);
      TMDS_data_n : out std_logic_vector (2 downto 0);
      S_CLK_SYS : out std_logic;
      S_CLK_VIDEO : out std_logic;
      S_CLK_EMU : out std_logic;
      S_CLK_AVALON : out std_logic;
      S_RESETN_SYS : out std_logic;
      S_RESETN_VIDEO : out std_logic;

      S_VDMA_AXI_MM2S_araddr : in std_logic_vector (c_axi_addr_width - 1 downto 0);
      S_VDMA_AXI_MM2S_arburst : in std_logic_vector (1 downto 0);
      S_VDMA_AXI_MM2S_arcache : in std_logic_vector (3 downto 0);
      S_VDMA_AXI_MM2S_arlen : in std_logic_vector (7 downto 0);
      S_VDMA_AXI_MM2S_arprot : in std_logic_vector (2 downto 0);
      S_VDMA_AXI_MM2S_arready : out std_logic;
      S_VDMA_AXI_MM2S_arsize : in std_logic_vector (2 downto 0);
      S_VDMA_AXI_MM2S_arvalid : in std_logic;
      S_VDMA_AXI_MM2S_rdata : out std_logic_vector (c_mms_data_width - 1 downto 0);
      S_VDMA_AXI_MM2S_rlast : out std_logic;
      S_VDMA_AXI_MM2S_rready : in std_logic;
      S_VDMA_AXI_MM2S_rresp : out std_logic_vector (1 downto 0);
      S_VDMA_AXI_MM2S_rvalid : out std_logic;

      S_VDMA_AXI_S2MM_awaddr : in std_logic_vector(c_axi_addr_width - 1 downto 0);
      S_VDMA_AXI_S2MM_awburst : in std_logic_vector(1 downto 0);
      S_VDMA_AXI_S2MM_awcache : in std_logic_vector(3 downto 0);
      S_VDMA_AXI_S2MM_awlen : in std_logic_vector(7 downto 0);
      S_VDMA_AXI_S2MM_awprot : in std_logic_vector(2 downto 0);
      S_VDMA_AXI_S2MM_awready : out std_logic;
      S_VDMA_AXI_S2MM_awsize : in std_logic_vector(2 downto 0);
      S_VDMA_AXI_S2MM_awvalid : in std_logic;
      S_VDMA_AXI_S2MM_wdata : in std_logic_vector(c_smm_data_width - 1 downto 0);
      S_VDMA_AXI_S2MM_wlast : in std_logic;
      S_VDMA_AXI_S2MM_wready : out std_logic;
      S_VDMA_AXI_S2MM_bresp : out std_logic_vector(1 downto 0);
      S_VDMA_AXI_S2MM_wvalid : in std_logic;
      S_VDMA_AXI_S2MM_wstrb : in std_logic_vector(3 downto 0);
      S_VDMA_AXI_S2MM_bvalid : out std_logic;
      S_VDMA_AXI_S2MM_bready : in std_logic;

      S_RGB_OUT_data : in std_logic_vector (23 downto 0);
      S_RGB_OUT_hsync : in std_logic;
      S_RGB_OUT_vsync : in std_logic;
      S_RGB_OUT_active_video : in std_logic;

      S_AVALON_UPSCALE_address : in std_logic_vector(31 downto 0);
      S_AVALON_UPSCALE_burstcount : in std_logic_vector(10 downto 0);
      S_AVALON_UPSCALE_byteenable : in std_logic_vector(15 downto 0);
      S_AVALON_UPSCALE_read : in std_logic;
      S_AVALON_UPSCALE_readdata : out std_logic_vector(127 downto 0);
      S_AVALON_UPSCALE_readdatavalid : out std_logic;
      S_AVALON_UPSCALE_waitrequest : out std_logic;
      S_AVALON_UPSCALE_write : in std_logic;
      S_AVALON_UPSCALE_writedata : in std_logic_vector(127 downto 0);
    
      S_VDMA_AXI_LITE_araddr : out std_logic_vector (c_axi_addr_width - 1 downto 0);
      S_VDMA_AXI_LITE_arready : in std_logic_vector(0 downto 0);
      S_VDMA_AXI_LITE_arvalid : out std_logic_vector (0 downto 0);
      S_VDMA_AXI_LITE_awaddr : out std_logic_vector (c_axi_addr_width - 1 downto 0);
      S_VDMA_AXI_LITE_awready : in std_logic_vector (0 downto 0);
      S_VDMA_AXI_LITE_awvalid : out std_logic_vector (0 downto 0);
      S_VDMA_AXI_LITE_bready : out std_logic_vector (0 downto 0);
      S_VDMA_AXI_LITE_bresp : in std_logic_vector (1 downto 0);
      S_VDMA_AXI_LITE_bvalid : in std_logic_vector (0 downto 0);
      S_VDMA_AXI_LITE_rdata : in std_logic_vector (c_axi_lite_data_width - 1 downto 0);
      S_VDMA_AXI_LITE_rready : out std_logic_vector (0 downto 0);
      S_VDMA_AXI_LITE_rresp : in std_logic_vector (1 downto 0);
      S_VDMA_AXI_LITE_rvalid : in std_logic_vector (0 downto 0);
      S_VDMA_AXI_LITE_wdata : out std_logic_vector (c_axi_lite_data_width - 1 downto 0);
      S_VDMA_AXI_LITE_wready : in std_logic_vector (0 downto 0);
      S_VDMA_AXI_LITE_wvalid : out std_logic_vector (0 downto 0);
      S_VDMA_AXI_LITE_arprot : out std_logic_vector (2 downto 0);
      S_VDMA_AXI_LITE_awprot : out std_logic_vector (2 downto 0);
      S_VDMA_AXI_LITE_wstrb : out std_logic_vector (3 downto 0);

      S_ZX_ADDR_DATA_BUS_AXI_araddr : in std_logic_vector (c_axi_addr_width - 1 downto 0);
      S_ZX_ADDR_DATA_BUS_AXI_arburst : in std_logic_vector (1 downto 0);
      S_ZX_ADDR_DATA_BUS_AXI_arcache : in std_logic_vector (3 downto 0);
      S_ZX_ADDR_DATA_BUS_AXI_arlen : in std_logic_vector (7 downto 0);
      S_ZX_ADDR_DATA_BUS_AXI_arprot : in std_logic_vector (2 downto 0);
      S_ZX_ADDR_DATA_BUS_AXI_arready : out std_logic;
      S_ZX_ADDR_DATA_BUS_AXI_arsize : in std_logic_vector (2 downto 0);
      S_ZX_ADDR_DATA_BUS_AXI_arvalid : in std_logic;
      S_ZX_ADDR_DATA_BUS_AXI_rdata : out std_logic_vector (c_smm_data_width - 1 downto 0);
      S_ZX_ADDR_DATA_BUS_AXI_rlast : out std_logic;
      S_ZX_ADDR_DATA_BUS_AXI_rready : in std_logic;
      S_ZX_ADDR_DATA_BUS_AXI_rresp : out std_logic_vector (1 downto 0);
      S_ZX_ADDR_DATA_BUS_AXI_rvalid : out std_logic;

      S_ZX_ADDR_DATA_BUS_AXI_awaddr : in std_logic_vector(c_axi_addr_width - 1 downto 0);
      S_ZX_ADDR_DATA_BUS_AXI_awburst : in std_logic_vector(1 downto 0);
      S_ZX_ADDR_DATA_BUS_AXI_awcache : in std_logic_vector(3 downto 0);
      S_ZX_ADDR_DATA_BUS_AXI_awlen : in std_logic_vector(7 downto 0);
      S_ZX_ADDR_DATA_BUS_AXI_awprot : in std_logic_vector(2 downto 0);
      S_ZX_ADDR_DATA_BUS_AXI_awready : out std_logic;
      S_ZX_ADDR_DATA_BUS_AXI_awsize : in std_logic_vector(2 downto 0);
      S_ZX_ADDR_DATA_BUS_AXI_awvalid : in std_logic;
      S_ZX_ADDR_DATA_BUS_AXI_wdata : in std_logic_vector(c_smm_data_width - 1 downto 0);
      S_ZX_ADDR_DATA_BUS_AXI_wlast : in std_logic;
      S_ZX_ADDR_DATA_BUS_AXI_wready : out std_logic;
      S_ZX_ADDR_DATA_BUS_AXI_bresp : out std_logic_vector(1 downto 0);
      S_ZX_ADDR_DATA_BUS_AXI_wvalid : in std_logic;
      S_ZX_ADDR_DATA_BUS_AXI_wstrb : in std_logic_vector(3 downto 0);
      S_ZX_ADDR_DATA_BUS_AXI_bvalid : out std_logic;
      S_ZX_ADDR_DATA_BUS_AXI_bready : in std_logic;

      S_IIC_PS_0_scl_i : in std_logic;
      S_IIC_PS_0_scl_o : out std_logic;
      S_IIC_PS_0_scl_t : out std_logic;
      S_IIC_PS_0_sda_i : in std_logic;
      S_IIC_PS_0_sda_o : out std_logic;
      S_IIC_PS_0_sda_t : out std_logic

    );
  end component;

  component arty_video_top
    generic (
      g_axi_data_width : integer;
      g_axi_lite_data_width : integer;
      g_axi_addr_width : integer
    );
    port ( 
      i_resetn_sys : in std_logic;
      i_resetn_video : in std_logic;
      i_aclk_sys : in std_logic;
      i_aclk_video : in std_logic;
      i_aclk_avalon : in std_logic;

      o_axi_mm2s_araddr : out std_logic_vector (c_axi_addr_width - 1 downto 0);
      o_axi_mm2s_arburst : out std_logic_vector (1 downto 0);
      o_axi_mm2s_arcache : out std_logic_vector (3 downto 0);
      o_axi_mm2s_arlen : out std_logic_vector (7 downto 0);
      o_axi_mm2s_arprot : out std_logic_vector (2 downto 0);
      i_axi_mm2s_arready : in std_logic;
      o_axi_mm2s_arsize : out std_logic_vector (2 downto 0);
      o_axi_mm2s_arvalid : out std_logic;
      i_axi_mm2s_rdata : in std_logic_vector (c_mms_data_width - 1 downto 0);
      i_axi_mm2s_rlast : in std_logic;
      o_axi_mm2s_rready : out std_logic;
      i_axi_mm2s_rresp : in std_logic_vector (1 downto 0);
      i_axi_mm2s_rvalid : in std_logic;

      o_axi_s2mm_awaddr : out std_logic_vector(c_axi_addr_width - 1 downto 0);
      o_axi_s2mm_awburst : out std_logic_vector(1 downto 0);
      o_axi_s2mm_awcache : out std_logic_vector(3 downto 0);
      o_axi_s2mm_awlen : out std_logic_vector(7 downto 0);
      o_axi_s2mm_awprot : out std_logic_vector(2 downto 0);
      i_axi_s2mm_awready : in std_logic;
      o_axi_s2mm_awsize : out std_logic_vector(2 downto 0);
      o_axi_s2mm_awvalid : out std_logic;
      o_axi_s2mm_wdata : out std_logic_vector(c_smm_data_width - 1 downto 0);
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

      i_wr_en : in std_logic;    
      i_rd_en : in std_logic;    
      i_register_data_out : in std_logic_vector(c_register_width - 1 downto 0);
      i_video_control_en : in std_logic;
      i_video_control : in std_logic_vector(c_register_width - 1 downto 0);

      i_emu_hsync : in std_logic;
      i_emu_vsync : in std_logic;
      i_emu_de : in std_logic;
      i_emu_r : in std_logic_vector(c_color_component_width - 1 downto 0);
      i_emu_g : in std_logic_vector(c_color_component_width - 1 downto 0);
      i_emu_b : in std_logic_vector(c_color_component_width - 1 downto 0);

      i_ce_pixel_clock_in : in std_logic;
      i_ce_pixel_clock_scandoubled : in std_logic;
      i_ce_emu_video_out : in std_logic;
      i_ce_upscaler_video_out : in std_logic; 

      -- VGA out
      o_vga_hs : out std_logic;
      o_vga_vs : out std_logic;
      o_vga_r : out std_logic_vector (c_vga_color_depth - 1 downto 0);
      o_vga_b : out std_logic_vector (c_vga_color_depth - 1 downto 0);
      o_vga_g : out std_logic_vector (c_vga_color_depth - 1 downto 0);

      -- HDMI out
      o_hdmi_out_data : out std_logic_vector (23 downto 0);
      o_hdmi_out_hsync : out std_logic;
      o_hdmi_out_vsync : out std_logic;
      o_hdmi_out_active_video : out std_logic
    );
  end component;

  component registers_top is
    generic (
      g_axi_lite_data_width : integer;
      g_axi_addr_width : integer
    );
    port ( 
      i_resetn_sys : in std_logic;
      i_aclk_sys : in std_logic;

      i_axi_lite_araddr : in std_logic_vector (c_axi_addr_width - 1 downto 0);
      o_axi_lite_arready : out std_logic;
      i_axi_lite_arvalid : in std_logic;
      i_axi_lite_awaddr : in std_logic_vector (c_axi_addr_width - 1 downto 0);
      o_axi_lite_awready : out std_logic;
      i_axi_lite_awvalid : in std_logic;
      i_axi_lite_bready : in std_logic;
      o_axi_lite_bresp : out std_logic_vector (1 downto 0);
      o_axi_lite_bvalid : out std_logic;
      o_axi_lite_rdata : out std_logic_vector (c_axi_lite_data_width - 1 downto 0);
      i_axi_lite_rready : in std_logic;
      o_axi_lite_rresp : out std_logic_vector (1 downto 0);
      o_axi_lite_rvalid : out std_logic;
      i_axi_lite_wdata : in std_logic_vector (c_axi_lite_data_width - 1 downto 0);
      o_axi_lite_wready : out std_logic;
      i_axi_lite_wvalid : in std_logic;
      i_axi_lite_arprot : in std_logic_vector (2 downto 0);
      i_axi_lite_awprot : in std_logic_vector (2 downto 0);
      i_axi_lite_wstrb : in std_logic_vector (3 downto 0);

      o_wr_en : out std_logic;    
      o_rd_en : out std_logic;    
      o_register_data_out : out std_logic_vector(c_register_width - 1 downto 0);
      o_mem_write_test_en : out std_logic;
      o_video_control_en : out std_logic;
      i_video_control : in std_logic_vector(c_register_width - 1 downto 0);
      o_emu_control_en : out std_logic;
      i_emu_control : in std_logic_vector(c_register_width - 1 downto 0);
      o_memtest_pass_cnt_en : out std_logic;
      i_memtest_pass_cnt : in std_logic_vector(g_axi_lite_data_width - 1 downto 0);
      o_memtest_fail_cnt_en : out std_logic;
      i_memtest_fail_cnt : in std_logic_vector(g_axi_lite_data_width - 1 downto 0);

      o_mmc_di_en : out std_logic;
      i_mmc_di : in std_logic_vector(g_axi_lite_data_width - 1 downto 0);
      o_ps2_kbd_do_en : out std_logic;
      i_ps2_kbd_do : in std_logic_vector(g_axi_lite_data_width - 1 downto 0);
      o_joystick_en : out std_logic;
      i_joystick : in std_logic_vector(g_axi_lite_data_width - 1 downto 0)
    );
  end component;

  component axi_ddr_top
    generic (
      g_axi_data_width : integer;
      g_axi_lite_data_width : integer;
      g_axi_addr_width : integer;
      g_axi_ddr_data_width : integer;
      g_axi_ddr_addr_width : integer
    );
    port ( 
      i_resetn_sys : in std_logic;
      i_aclk_sys : in std_logic;

      o_axi_ddr_araddr : out std_logic_vector (c_axi_addr_width - 1 downto 0);
      o_axi_ddr_arburst : out std_logic_vector (1 downto 0);
      o_axi_ddr_arcache : out std_logic_vector (3 downto 0);
      o_axi_ddr_arlen : out std_logic_vector (7 downto 0);
      o_axi_ddr_arprot : out std_logic_vector (2 downto 0);
      i_axi_ddr_arready : in std_logic;
      o_axi_ddr_arsize : out std_logic_vector (2 downto 0);
      o_axi_ddr_arvalid : out std_logic;
      i_axi_ddr_rdata : in std_logic_vector (c_smm_data_width - 1 downto 0);
      i_axi_ddr_rlast : in std_logic;
      o_axi_ddr_rready : out std_logic;
      i_axi_ddr_rresp : in std_logic_vector (1 downto 0);
      i_axi_ddr_rvalid : in std_logic;

      o_axi_ddr_awaddr : out std_logic_vector(c_axi_addr_width - 1 downto 0);
      o_axi_ddr_awburst : out std_logic_vector(1 downto 0);
      o_axi_ddr_awcache : out std_logic_vector(3 downto 0);
      o_axi_ddr_awlen : out std_logic_vector(7 downto 0);
      o_axi_ddr_awprot : out std_logic_vector(2 downto 0);
      i_axi_ddr_awready : in std_logic;
      o_axi_ddr_awsize : out std_logic_vector(2 downto 0);
      o_axi_ddr_awvalid : out std_logic;
      o_axi_ddr_wdata : out std_logic_vector(c_smm_data_width - 1 downto 0);
      o_axi_ddr_wlast : out std_logic;
      i_axi_ddr_wready : in std_logic;
      i_axi_ddr_bresp : in std_logic_vector(1 downto 0);
      o_axi_ddr_wvalid : out std_logic;
      o_axi_ddr_wstrb : out std_logic_vector(3 downto 0);
      i_axi_ddr_bvalid : in std_logic;
      o_axi_ddr_bready : out std_logic;

      i_ddr_address : in std_logic_vector(c_ddr_addr_width - 1 downto 0);
      i_ddr_data : in std_logic_vector(c_ddr_data_width - 1 downto 0);
      o_ddr_data : out std_logic_vector(c_ddr_data_width - 1 downto 0);
      i_ddr_mem_wr : in std_logic;
      i_ddr_mem_req : in std_logic;
      o_ddr_mem_busy : out std_logic
    );
  end component;

  component emsx_top
    generic (
      g_axi_lite_data_width : integer
    );
    port ( 
      i_resetn_sys : in std_logic;
      i_aclk_sys : in std_logic;
      i_aclk_emu : in std_logic;
      i_aclk_mem : in std_logic;

      o_ddr_address : out std_logic_vector(c_ddr_addr_width - 1 downto 0);
      i_ddr_data : in std_logic_vector(c_ddr_data_width - 1 downto 0);
      o_ddr_data : out std_logic_vector(c_ddr_data_width - 1 downto 0);
      o_ddr_mem_wr : out std_logic;
      o_ddr_mem_req : out std_logic;
      i_ddr_mem_busy : in std_logic;

      -- SDRAM interface
      o_mem_cke : out std_logic; -- SDRAM Clock enable
      o_mem_cs_n : out std_logic; -- SDRAM Chip select
      o_mem_ras_n : out std_logic; -- SDRAM Row/RAS
      o_mem_cas_n : out std_logic; -- SDRAM /CAS
      o_mem_we_n : out std_logic; -- SDRAM /WE
      o_mem_udq : out std_logic; -- SDRAM UDQM
      o_mem_ldq : out std_logic; -- SDRAM LDQM
      o_mem_ba1 : out std_logic; -- SDRAM Bank select address 1
      o_mem_ba0 : out std_logic; -- SDRAM Bank select address 0
      o_mem_adr : out std_logic_vector(12 downto 0); -- SDRAM Address
      --i_mem_dat_in : in std_logic_vector(15 downto 0); -- SDRAM Data
      --o_mem_dat_out : out std_logic_vector(7 downto 0); -- SDRAM Data
      io_mem_dq : inout std_logic_vector(15 downto 0);
      o_mem_dat_en : out std_logic;

      i_wr_en : in std_logic;
      i_rd_en : in std_logic;
      i_register_data_out : in std_logic_vector(c_register_width - 1 downto 0);
      i_emu_control_en : in std_logic;
      o_emu_control : out std_logic_vector(c_register_width - 1 downto 0);
      i_mmc_di_en : in std_logic;
      o_mmc_di : out std_logic_vector(g_axi_lite_data_width - 1 downto 0);
      i_memtest_pass_cnt_en : in std_logic;
      o_memtest_pass_cnt : out std_logic_vector(g_axi_lite_data_width - 1 downto 0);
      i_memtest_fail_cnt_en : in std_logic;
      o_memtest_fail_cnt : out std_logic_vector(g_axi_lite_data_width - 1 downto 0);
      i_joystick_en : in std_logic;
      o_joystick : out std_logic_vector(g_axi_lite_data_width - 1 downto 0);

      -- Emulator video out
      o_emu_hsync : out std_logic;
      o_emu_vsync : out std_logic;
      o_emu_de : out std_logic;
      o_emu_r : out std_logic_vector(c_color_component_width - 1 downto 0);
      o_emu_g : out std_logic_vector(c_color_component_width - 1 downto 0);
      o_emu_b : out std_logic_vector(c_color_component_width - 1 downto 0);

      -- MSX2+
      o_ce_21mp : out std_logic;
      o_ce_42mp : out std_logic;

      -- PS/2 keyboard ports
      i_ps2_key : in std_logic_vector(10 downto 0);
      --o_p_caps : out std_logic;

      i_p_joy_a : in std_logic_vector(5 downto 0);
      o_p_str_a : out std_logic;
      i_p_joy_b : in std_logic_vector(5 downto 0);
      o_p_str_b : out std_logic;

      -- DIP switch, Lamp ports
      i_p_dip : in std_logic_vector(7 downto 0);     -- 0=On,    1=Off (default on shipment)
      --o_p_led : out std_logic_vector(7 downto 0);     -- 0=Off,   1=On  (green)
      --o_p_led_pwr : out std_logic; -- 0=Off,   1=On  (red)
      --i_p_r800 : in std_logic;

      --i_rtc_setup : in std_logic;
      --i_rtc_time : in std_logic_vector(64 downto 0);

      o_p_audio_psg : out std_logic_vector(9 downto 0);
      o_p_audio_opll : out std_logic_vector(13 downto 0);
      o_p_audio_pcm : out std_logic_vector(15 downto 0);
      o_p_audio_trpcm : out std_logic_vector(7 downto 0);
      --o_p_beeper : out std_logic;

      i_mmc_miso : in std_logic;
      o_mmc_cs : out std_logic;
      o_mmc_mosi : out std_logic;
      o_mmc_clk : out std_logic;

      o_led0_red : out std_logic;
      o_led1_red : out std_logic;

      o_cpucen : out std_logic
    );
  end component;

  component memtest_top
    generic (
      g_axi_lite_data_width : integer
    );
    port ( 
      i_resetn_sys : in std_logic;
      i_aclk_sys : in std_logic;
      i_aclk_emu : in std_logic;

      o_ddr_address : out std_logic_vector(c_ddr_addr_width - 1 downto 0);
      i_ddr_data : in std_logic_vector(c_ddr_data_width - 1 downto 0);
      o_ddr_data : out std_logic_vector(c_ddr_data_width - 1 downto 0);
      o_ddr_mem_wr : out std_logic;
      o_ddr_mem_req : out std_logic;
      i_ddr_mem_busy : in std_logic;

      -- SDRAM interface
      o_mem_clk : out std_logic; -- SDRAM Clock
      o_mem_cke : out std_logic; -- SDRAM Clock enable
      o_mem_cs_n : out std_logic; -- SDRAM Chip select
      o_mem_ras_n : out std_logic; -- SDRAM Row/RAS
      o_mem_cas_n : out std_logic; -- SDRAM /CAS
      o_mem_we_n : out std_logic; -- SDRAM /WE
      o_mem_udq : out std_logic; -- SDRAM UDQM
      o_mem_ldq : out std_logic; -- SDRAM LDQM
      o_mem_ba1 : out std_logic; -- SDRAM Bank select address 1
      o_mem_ba0 : out std_logic; -- SDRAM Bank select address 0
      o_mem_adr : out std_logic_vector(12 downto 0); -- SDRAM Address
      io_mem_dq : inout std_logic_vector(15 downto 0);

      i_wr_en : in std_logic;
      i_rd_en : in std_logic;
      i_register_data_out : in std_logic_vector(c_register_width - 1 downto 0);
      i_emu_control_en : in std_logic;
      o_emu_control : out std_logic_vector(c_register_width - 1 downto 0);
      i_memtest_pass_cnt_en : in std_logic;
      o_memtest_pass_cnt : out std_logic_vector(g_axi_lite_data_width - 1 downto 0);
      i_memtest_fail_cnt_en : in std_logic;
      o_memtest_fail_cnt : out std_logic_vector(g_axi_lite_data_width - 1 downto 0);

      -- Emulator video out
      o_emu_hsync : out std_logic;
      o_emu_vsync : out std_logic;
      o_emu_de : out std_logic;
      o_emu_r : out std_logic_vector(c_color_component_width - 1 downto 0);
      o_emu_g : out std_logic_vector(c_color_component_width - 1 downto 0);
      o_emu_b : out std_logic_vector(c_color_component_width - 1 downto 0);

      -- MSX2+
      o_ce_21mp : out std_logic;

      -- DIP switch, Lamp ports
      i_p_dip : in std_logic_vector(7 downto 0);     -- 0=On,    1=Off (default on shipment)

      i_mmc_miso : in std_logic;
      o_mmc_cs : out std_logic;
      o_mmc_mosi : out std_logic;
      o_mmc_clk : out std_logic;

      o_led0_red : out std_logic;
      o_led1_red : out std_logic
     
    );
  end component;

  component tester
    port ( 
      clk : in std_logic;
      rst_n : in std_logic;

      sz : in std_logic_vector(1 downto 0);
      chip : in std_logic_vector(1 downto 0);

      passcount : out std_logic_vector(31 downto 0);
      failcount : out std_logic_vector(31 downto 0);

      written : out std_logic_vector(15 downto 0);
      read : out std_logic_vector(15 downto 0);

      o_check_in_progress : out std_logic;
      o_dram_ready : out std_logic;

      DRAM_CLK : out std_logic;
      DRAM_DQ : inout std_logic_vector(15 downto 0);
      DRAM_ADDR : out std_logic_vector(12 downto 0);
      DRAM_LDQM,DRAM_UDQM : out std_logic;
      DRAM_WE_N : out std_logic;
      DRAM_CAS_N : out std_logic;
      DRAM_RAS_N : out std_logic;
      DRAM_CS_N : out std_logic;
      DRAM_BA_0 : out std_logic;
      DRAM_BA_1 : out std_logic
    );
  end component;

  component ps2_kbd_emu
    generic (
      g_axi_lite_data_width : integer := 32
    );
    port ( 
      i_resetn_sys : in std_logic;
      i_aclk_sys : in std_logic;
      i_aclk_emu : in std_logic;
      i_emu_clk_en : in std_logic;
      -- Register interface      
      i_ps2_kbd_do_en : in std_logic;
      o_ps2_kbd_do : out std_logic_vector(g_axi_lite_data_width - 1 downto 0);
      i_reg_wr_en : in std_logic;
      i_reg_rd_en : in std_logic;
      i_register_data_out : in std_logic_vector(g_axi_lite_data_width - 1 downto 0);
      -- PS2 interface
      o_ps2_key : out std_logic_vector(10 downto 0)
    );
  end component;

  component ps2_kbd is
    port ( 
      i_resetn_sys : in std_logic;
      i_aclk_emu : in std_logic;
      i_emu_clk_en : in std_logic;

      io_ps_clk : inout std_logic;
      io_ps_dat : inout std_logic;

      -- PS2 emulator interface
      o_ps2_key : out std_logic_vector(10 downto 0);

      -- joysticks emulated via keyboard
      o_joy_a_emu : out std_logic_vector(5 downto 0)
    );

  end component;

  component ps2_mouse
    port ( 
      i_resetn_sys : in std_logic;
      i_aclk_emu : in std_logic;
      i_emu_clk_en : in std_logic;

      io_ps_clk : inout std_logic;
      io_ps_dat : inout std_logic;

      -- PS2 emulator interface
      o_ps2_mouse : out std_logic_vector(24 downto 0)
    );
  end component;

  component ps2mouse
    port (
      clk : in std_logic;
      reset : in std_logic;
      strobe : in std_logic;
      data : out std_logic_vector(5 downto 0);
      ps2_mouse : in std_logic_vector(24 downto 0)
  );
  end component;

  component arty_audio_top
    port (
      i_clk : in std_logic; 
      i_resetn : in std_logic; 
      i_ctrl_mode : in std_logic;

      i_in1_ch_a : in std_logic_vector(c_in_audio_resolution_bits - 1 downto 0);
      i_in1_ch_b : in std_logic_vector(c_in_audio_resolution_bits - 1 downto 0);
      i_in1_ch_c : in std_logic_vector(c_in_audio_resolution_bits - 1 downto 0);

      i_in2_ch_a : in std_logic_vector(c_in_audio_resolution_bits - 1 downto 0);
      i_in2_ch_b : in std_logic_vector(c_in_audio_resolution_bits - 1 downto 0);
      i_in2_ch_c : in std_logic_vector(c_in_audio_resolution_bits - 1 downto 0);

      i_in3 : in std_logic_vector(c_in_audio_resolution_bits - 1 downto 0);
      i_in4 : in std_logic_vector(c_in_audio_resolution_bits - 1 downto 0);
      i_in5 : in std_logic_vector(c_out_audio_resolution_bits - 1 downto 0);

      i_audio_beeper : in std_logic;
      i_audio_tape : in std_logic;

      i_in1_enabled : in std_logic;
      i_in2_enabled : in std_logic;
      i_in3_enabled : in std_logic;
      i_in4_enabled : in std_logic;
      i_in5_enabled : in std_logic;

      o_pwm_out : out std_logic;

      o_bclk : out std_logic;
      o_lrclk : out std_logic;
      o_sdat : out std_logic
    );
  end component;

  component mist_adapter
    port (
        AUDIO_CLK : in std_logic;
        AUDIO_RES : in std_logic;

        AUDIO_OPLL : in std_logic_vector(13 downto 0);
        AUDIO_PSG : in std_logic_vector(9 downto 0);
        AUDIO_PCM : in std_logic_vector(15 downto 0);
        AUDIO_TRPCM : in std_logic_vector(7 downto 0);

        AUDIO_L : out std_logic_vector(15 downto 0);
        AUDIO_R : out std_logic_vector(15 downto 0);
        AUDIO_S : out std_logic;
        AUDIO_MIX : out std_logic_vector(1 downto 0);

        I2S_CE : out std_logic;
        AUDIO_L_FLT : out std_logic_vector(15 downto 0);
        AUDIO_R_FLT : out std_logic_vector(15 downto 0)
    );
  end component;

  component i2s is
    port (
      i_clk : in std_logic;
      i_resetn : in std_logic;
      i_ce : in std_logic;

      i_left_chan : in std_logic_vector(c_out_audio_resolution_bits - 1 downto 0);
      i_right_chan : in std_logic_vector(c_out_audio_resolution_bits - 1 downto 0);

      o_bclk : out std_logic;
      o_lrclk : out std_logic;
      o_sdat : out std_logic
    );
  end component;
 
end;-- package types_emulator_top;

