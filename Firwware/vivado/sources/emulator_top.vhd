----------------------------------------------------------------------------------
-- A generic emulation framework for ARTY Z7 platform
-- Inspired by MiSTER project
--  
-- Company: Magictale Electronics http://magictale.com
-- Engineer: Dmitry Pakhomenko
--
-- Design Name: Emulator wrapper for Arty Z7/AX7020
--
----------------------------------------------------------------------------------

library IEEE;
    use IEEE.std_logic_1164.ALL;
    use ieee.numeric_std.all;
library UNISIM;
    use UNISIM.VCOMPONENTS.ALL;

library xil_defaultlib;
    use work.types_arty_video.all;
    use work.types_arty_audio.all;
    use work.types_emulator_top.all;

entity emulator_top is
  generic (
    g_mem_test : integer := 0
  );
  port (
    DDR_addr : inout std_logic_vector (c_ddr_addr_width - 1 downto 0);
    DDR_ba : inout std_logic_vector (2 downto 0);
    DDR_cas_n : inout std_logic;
    DDR_ck_n : inout std_logic;
    DDR_ck_p : inout std_logic;
    DDR_cke : inout std_logic;
    DDR_cs_n : inout std_logic;
    DDR_dm : inout std_logic_vector (3 downto 0);
    DDR_dq : inout std_logic_vector (c_ddr_dq_data_width - 1 downto 0);
    DDR_dqs_n : inout std_logic_vector (3 downto 0);
    DDR_dqs_p : inout std_logic_vector (3 downto 0);
    DDR_odt : inout std_logic;
    DDR_ras_n : inout std_logic;
    DDR_reset_n : inout std_logic;
    DDR_we_n : inout std_logic;

    --low latency SDRAM interface
    SDRAM_CLK : out std_logic;
    SDRAM_CS : out std_logic;
    SDRAM_RAS : out std_logic;
    SDRAM_CAS : out std_logic;
    SDRAM_WE : out std_logic;
    SDRAM_BA : out std_logic_vector(1 downto 0);
    SDRAM_A : out std_logic_vector(12 downto 0);
    SDRAM_DQ : inout std_logic_vector(15 downto 0);

    FIXED_IO_ddr_vrn : inout std_logic;
    FIXED_IO_ddr_vrp : inout std_logic;
    FIXED_IO_mio : inout std_logic_vector (c_fixed_mio_width - 1 downto 0);
    FIXED_IO_ps_clk : inout std_logic;
    FIXED_IO_ps_porb : inout std_logic;
    FIXED_IO_ps_srstb : inout std_logic;
    HDMI_DDC_scl_io : inout std_logic;
    HDMI_DDC_sda_io : inout std_logic;
    HDMI_HPD_tri_i : in std_logic_vector (0 downto 0);
    TMDS_clk_n : out std_logic;
    TMDS_clk_p : out std_logic;
    TMDS_data_n : out std_logic_vector (2 downto 0);
    TMDS_data_p : out std_logic_vector (2 downto 0);
    MMC_MISO: in std_logic;
    MMC_MOSI : out std_logic;
    MMC_CS : out std_logic;
    MMC_CLK : out std_logic;
    LED0_RED : out std_logic;
    LED1_RED : out std_logic;

    DAC_DATA : out std_logic;
    DAC_BCLK : out std_logic;
    DAC_LRCLK : out std_logic;
    MOUSE_CLK : inout std_logic;
    MOUSE_DAT : inout std_logic;
    KBD_CLK : inout std_logic;
    KBD_DAT : inout std_logic;
    I2C_SCL : inout STD_LOGIC;
    I2C_SDA : inout STD_LOGIC
  );
end emulator_top;

architecture STRUCTURE of emulator_top is

  signal HDMI_DDC_scl_i : std_logic;
  signal HDMI_DDC_scl_o : std_logic;
  signal HDMI_DDC_scl_t : std_logic;
  signal HDMI_DDC_sda_i : std_logic;
  signal HDMI_DDC_sda_o : std_logic;
  signal HDMI_DDC_sda_t : std_logic;
  
  signal s_clk_sys : std_logic;
  signal s_clk_video : std_logic; 
  signal s_clk_emu : std_logic; 
  signal s_clk_avalon : std_logic; 
  signal s_resetn_sys : std_logic;
  signal s_resetn_video : std_logic;

  signal s_vdma_axi_mm2s_araddr : std_logic_vector (c_axi_addr_width - 1 downto 0);
  signal s_vdma_axi_mm2s_arburst : std_logic_vector (1 downto 0);
  signal s_vdma_axi_mm2s_arcache : std_logic_vector (3 downto 0);
  signal s_vdma_axi_mm2s_arlen : std_logic_vector (7 downto 0);
  signal s_vdma_axi_mm2s_arprot : std_logic_vector (2 downto 0);
  signal s_vdma_axi_mm2s_arready : std_logic;
  signal s_vdma_axi_mm2s_arsize : std_logic_vector (2 downto 0);
  signal s_vdma_axi_mm2s_arvalid : std_logic;
  signal s_vdma_axi_mm2s_rdata : std_logic_vector (c_mms_data_width - 1 downto 0);
  signal s_vdma_axi_mm2s_rlast : std_logic;
  signal s_vdma_axi_mm2s_rready  : std_logic;
  signal s_vdma_axi_mm2s_rresp : std_logic_vector (1 downto 0);
  signal s_vdma_axi_mm2s_rvalid  : std_logic;

  signal s_vdma_axi_s2mm_awaddr : std_logic_vector(c_axi_addr_width - 1 downto 0);
  signal s_vdma_axi_s2mm_awburst : std_logic_vector(1 downto 0);
  signal s_vdma_axi_s2mm_awcache : std_logic_vector(3 downto 0);
  signal s_vdma_axi_s2mm_awlen : std_logic_vector(7 downto 0);
  signal s_vdma_axi_s2mm_awprot : std_logic_vector(2 downto 0);
  signal s_vdma_axi_s2mm_awready : std_logic;
  signal s_vdma_axi_s2mm_awsize : std_logic_vector(2 downto 0);
  signal s_vdma_axi_s2mm_awvalid : std_logic;
  signal s_vdma_axi_s2mm_wdata : std_logic_vector(c_smm_data_width - 1 downto 0);
  signal s_vdma_axi_s2mm_wlast : std_logic;
  signal s_vdma_axi_s2mm_wready : std_logic;
  signal s_vdma_axi_s2mm_bresp : std_logic_vector(1 downto 0);
  signal s_vdma_axi_s2mm_wvalid : std_logic;
  signal s_vdma_axi_s2mm_wstrb : std_logic_vector(3 downto 0);
  signal s_vdma_axi_s2mm_bvalid : std_logic;
  signal s_vdma_axi_s2mm_bready : std_logic;

  signal s_rgb_out_data : std_logic_vector (23 downto 0);
  signal s_rgb_out_hsync : std_logic;
  signal s_rgb_out_vsync : std_logic;
  signal s_rgb_out_active_video : std_logic;

  signal s_emu_hsync : std_logic;
  signal s_emu_vsync : std_logic;
  signal s_emu_de : std_logic;
  signal s_emu_r : std_logic_vector(c_color_component_width - 1 downto 0);
  signal s_emu_g : std_logic_vector(c_color_component_width - 1 downto 0);
  signal s_emu_b : std_logic_vector(c_color_component_width - 1 downto 0);

  signal s_avalon_upscale_address : std_logic_vector(31 downto 0);
  signal s_avalon_upscale_burstcount : std_logic_vector(10 downto 0);
  signal s_avalon_upscale_byteenable : std_logic_vector(15 downto 0);
  signal s_avalon_upscale_read : std_logic;
  signal s_avalon_upscale_readdata : std_logic_vector(127 downto 0);
  signal s_avalon_upscale_readdatavalid : std_logic;
  signal s_avalon_upscale_waitrequest : std_logic;
  signal s_avalon_upscale_write : std_logic;
  signal s_avalon_upscale_writedata : std_logic_vector(127 downto 0);

  signal s_vdma_axi_lite_araddr : std_logic_vector (c_axi_addr_width - 1 downto 0);
  signal s_vdma_axi_lite_arready : std_logic;
  signal s_vdma_axi_lite_arvalid : std_logic;
  signal s_vdma_axi_lite_awaddr : std_logic_vector (c_axi_addr_width - 1 downto 0);
  signal s_vdma_axi_lite_awready : std_logic;
  signal s_vdma_axi_lite_awvalid : std_logic;
  signal s_vdma_axi_lite_bready : std_logic;
  signal s_vdma_axi_lite_bresp : std_logic_vector (1 downto 0);
  signal s_vdma_axi_lite_bvalid : std_logic;
  signal s_vdma_axi_lite_rdata : std_logic_vector (c_axi_lite_data_width - 1 downto 0);
  signal s_vdma_axi_lite_rready : std_logic;
  signal s_vdma_axi_lite_rresp : std_logic_vector (1 downto 0);
  signal s_vdma_axi_lite_rvalid : std_logic;
  signal s_vdma_axi_lite_wdata : std_logic_vector (c_axi_lite_data_width - 1 downto 0);
  signal s_vdma_axi_lite_wready : std_logic;
  signal s_vdma_axi_lite_wvalid : std_logic;
  signal s_vdma_axi_lite_arprot : std_logic_vector (2 downto 0);
  signal s_vdma_axi_lite_awprot : std_logic_vector (2 downto 0);
  signal s_vdma_axi_lite_wstrb : std_logic_vector (3 downto 0);

  signal s_axi_ddr_araddr : std_logic_vector (c_axi_addr_width - 1 downto 0);
  signal s_axi_ddr_arburst : std_logic_vector (1 downto 0);
  signal s_axi_ddr_arcache : std_logic_vector (3 downto 0);
  signal s_axi_ddr_arlen : std_logic_vector (7 downto 0);
  signal s_axi_ddr_arprot : std_logic_vector (2 downto 0);
  signal s_axi_ddr_arready : std_logic;
  signal s_axi_ddr_arsize : std_logic_vector (2 downto 0);
  signal s_axi_ddr_arvalid : std_logic;
  signal s_axi_ddr_rdata : std_logic_vector (c_smm_data_width - 1 downto 0);
  signal s_axi_ddr_rlast : std_logic;
  signal s_axi_ddr_rready  : std_logic;
  signal s_axi_ddr_rresp : std_logic_vector (1 downto 0);
  signal s_axi_ddr_rvalid  : std_logic;
 
  signal s_axi_ddr_awaddr : std_logic_vector (c_axi_addr_width - 1 downto 0);
  signal s_axi_ddr_awburst : std_logic_vector (1 downto 0);
  signal s_axi_ddr_awcache : std_logic_vector (3 downto 0);
  signal s_axi_ddr_awlen : std_logic_vector (7 downto 0);
  signal s_axi_ddr_awprot : std_logic_vector (2 downto 0);
  signal s_axi_ddr_awready : std_logic;
  signal s_axi_ddr_awsize : std_logic_vector (2 downto 0);
  signal s_axi_ddr_awvalid : std_logic;
  signal s_axi_ddr_wdata : std_logic_vector (c_smm_data_width - 1 downto 0);
  signal s_axi_ddr_wlast : std_logic;
  signal s_axi_ddr_wready : std_logic;
  signal s_axi_ddr_bresp : std_logic_vector (1 downto 0);
  signal s_axi_ddr_wvalid : std_logic;
  signal s_axi_ddr_wstrb : std_logic_vector (3 downto 0);
  signal s_axi_ddr_bvalid : std_logic;
  signal s_axi_ddr_bready : std_logic;

  signal s_ddr_address : std_logic_vector (c_ddr_addr_width - 1 downto 0);
  signal s_ddr_data_in : std_logic_vector (c_ddr_data_width - 1 downto 0);
  signal s_ddr_data_out : std_logic_vector (c_ddr_data_width - 1 downto 0);
  signal s_ddr_mem_wr : std_logic;
  signal s_ddr_mem_req : std_logic;
  signal s_ddr_mem_busy : std_logic;

  signal s_mem_cke : std_logic;
  signal s_mem_cs_n : std_logic;
  signal s_mem_ras_n : std_logic;
  signal s_mem_cas_n : std_logic;
  signal s_mem_we_n : std_logic;
  signal s_mem_udq : std_logic;
  signal s_mem_ldq : std_logic;
  signal s_mem_ba : std_logic_vector(1 downto 0);
  signal s_mem_adr : std_logic_vector(12 downto 0);
  signal s_sdr_dat : std_logic_vector(15 downto 0);
  signal s_mem_dat_en : std_logic;

  signal s_register_data_out : std_logic_vector (c_register_width - 1 downto 0);
  signal s_wr_en : std_logic;    
  signal s_rd_en : std_logic;    
  signal s_video_control_en : std_logic;
  signal s_video_control : std_logic_vector (c_register_width - 1 downto 0);
  signal s_emu_control_en : std_logic;
  signal s_emu_control : std_logic_vector (c_register_width - 1 downto 0);
  signal s_memtest_pass_cnt_en : std_logic;
  signal s_memtest_pass_cnt : std_logic_vector (c_register_width - 1 downto 0);
  signal s_memtest_fail_cnt_en : std_logic;
  signal s_memtest_fail_cnt : std_logic_vector (c_register_width - 1 downto 0);
  signal s_mmc_di_en : std_logic;
  signal s_mmc_di : std_logic_vector(c_register_width - 1 downto 0);
  signal s_ps2_kbd_do_en : std_logic;
  signal s_ps2_kbd_do : std_logic_vector(c_register_width - 1 downto 0);
  signal s_joystick_en : std_logic;
  signal s_joystick : std_logic_vector(c_register_width - 1 downto 0);

  signal s_ps2_mouse_data_in : std_logic_vector(7 downto 0);
  signal s_ps2_mouse_data_out : std_logic_vector(7 downto 0);
  signal s_ps2_kbd_data_in : std_logic_vector(7 downto 0);
  signal s_ps2_kbd_data_out : std_logic_vector(7 downto 0);
  signal s_ps2_kbd_ibf : std_logic;
  signal s_ps2_kbd_obf : std_logic;
  signal s_ps2_mouse_ibf : std_logic;
  signal s_ps2_mouse_obf : std_logic;

  signal s_ce_7mp : std_logic;
  signal s_ce_14mp : std_logic;
  signal s_ce_28mp : std_logic;

  signal s_ce_21mp : std_logic;
  signal s_ce_42mp : std_logic;

  signal s_p_audio_psg : std_logic_vector(9 downto 0);
  signal s_p_audio_opll : std_logic_vector(13 downto 0);
  signal s_p_audio_pcm : std_logic_vector(15 downto 0);
  signal s_p_audio_trpcm : std_logic_vector(7 downto 0);
  signal s_audio_l_flt : std_logic_vector(c_out_audio_resolution_bits - 1 downto 0) := (others => '0');
  signal s_audio_r_flt : std_logic_vector(c_out_audio_resolution_bits - 1 downto 0) := (others => '0');
  signal s_i2s_ce : std_logic;

  signal s_vga_hs : std_logic;
  signal s_vga_vs : std_logic;
  signal s_vga_r : std_logic_vector (c_vga_color_depth - 1 downto 0);
  signal s_vga_g : std_logic_vector (c_vga_color_depth - 1 downto 0);
  signal s_vga_b : std_logic_vector (c_vga_color_depth - 1 downto 0);

  signal s_mmc_mosi : std_logic;
  signal s_mmc_miso : std_logic;
  signal s_mmc_cs : std_logic;
  signal s_mmc_clk : std_logic;

  signal s_led0_red : std_logic;
  signal s_led1_red : std_logic;

  signal s_ps2_key : std_logic_vector(10 downto 0);
  signal s_joy_a_emu : std_logic_vector(5 downto 0);
  signal s_joy_b : std_logic_vector(5 downto 0);
  signal s_joy_a_stb : std_logic;
  signal s_joy_b_stb : std_logic;

  signal s_cpucen : std_logic;
  signal s_ps2_mouse : std_logic_vector(24 downto 0);

  signal s_dac_data : std_logic;
  signal s_dac_bclk : std_logic;
  signal s_dac_lrclk : std_logic;

  signal s_emu_hat_iic_scl_i : std_logic;
  signal s_emu_hat_iic_scl_o : std_logic;
  signal s_emu_hat_iic_scl_t : std_logic;
  signal s_emu_hat_iic_sda_i : std_logic;
  signal s_emu_hat_iic_sda_o : std_logic;
  signal s_emu_hat_iic_sda_t : std_logic;


begin

  HDMI_DDC_scl_iobuf: component IOBUF
    port map (
      I => HDMI_DDC_scl_o,
      IO => HDMI_DDC_scl_io,
      O => HDMI_DDC_scl_i,
      T => HDMI_DDC_scl_t
    );

  HDMI_DDC_sda_iobuf: component IOBUF
    port map (
      I => HDMI_DDC_sda_o,
      IO => HDMI_DDC_sda_io,
      O => HDMI_DDC_sda_i,
      T => HDMI_DDC_sda_t
    );

  DAC_DATA_obuf: component OBUF
    generic map (
      DRIVE => c_obuf_drive_strenth,
      IOSTANDARD => c_obuf_iostandard,
      SLEW => c_obuf_slew)
    port map (
      I => s_dac_data,
      O => DAC_DATA
    );

  DAC_BCLK_obuf: component OBUF
    generic map (
      DRIVE => c_obuf_drive_strenth,
      IOSTANDARD => c_obuf_iostandard,
      SLEW => c_obuf_slew)
    port map (
      I => s_dac_bclk,
      O => DAC_BCLK
    );

  DAC_LRCLK_obuf: component OBUF
    generic map (
      DRIVE => c_obuf_drive_strenth,
      IOSTANDARD => c_obuf_iostandard,
      SLEW => c_obuf_slew)
    port map (
      I => s_dac_lrclk,
      O => DAC_LRCLK
    );


  mmc_cs_i: component OBUF
    generic map (
      DRIVE => c_obuf_drive_strenth,
      IOSTANDARD => c_obuf_iostandard,
      SLEW => c_obuf_slew)
     port map (
       I => s_mmc_cs, 
       O => MMC_CS
     );

  mmc_mosi_i: component OBUF
    generic map (
      DRIVE => c_obuf_drive_strenth,
      IOSTANDARD => c_obuf_iostandard,
      SLEW => c_obuf_slew)
     port map (
       I => s_mmc_mosi, 
       O => MMC_MOSI
     );

  mmc_clk_i: component OBUF
    generic map (
      DRIVE => c_obuf_drive_strenth,
      IOSTANDARD => c_obuf_iostandard,
      SLEW => c_obuf_slew)
     port map (
       I => s_mmc_clk, 
       O => MMC_CLK
     );

  mmc_miso_i: component IBUF
    generic map (
      IOSTANDARD => c_obuf_iostandard)
     port map (
       O => s_mmc_miso,
       I => MMC_MISO
     );


  led0_red_i: component IBUF
    generic map (
      IOSTANDARD => c_obuf_iostandard)
     port map (
       I => s_led0_red,
       O => LED0_RED
     );

  led1_red_i: component IBUF
    generic map (
      IOSTANDARD => c_obuf_iostandard)
     port map (
       I => s_led1_red,
       O => LED1_RED
     );


  emulator_bd_i: component emulator
    port map (
      DDR_addr(c_ddr_dq_addr_width - 1 downto 0) => DDR_addr(c_ddr_dq_addr_width - 1 downto 0),
      DDR_ba(2 downto 0) => DDR_ba(2 downto 0),
      DDR_cas_n => DDR_cas_n,
      DDR_ck_n => DDR_ck_n,
      DDR_ck_p => DDR_ck_p,
      DDR_cke => DDR_cke,
      DDR_cs_n => DDR_cs_n,
      DDR_dm(3 downto 0) => DDR_dm(3 downto 0),
      DDR_dq(c_ddr_dq_data_width - 1 downto 0) => DDR_dq(c_ddr_dq_data_width - 1 downto 0),
      DDR_dqs_n(3 downto 0) => DDR_dqs_n(3 downto 0),
      DDR_dqs_p(3 downto 0) => DDR_dqs_p(3 downto 0),
      DDR_odt => DDR_odt,
      DDR_ras_n => DDR_ras_n,
      DDR_reset_n => DDR_reset_n,
      DDR_we_n => DDR_we_n,

      FIXED_IO_ddr_vrn => FIXED_IO_ddr_vrn,
      FIXED_IO_ddr_vrp => FIXED_IO_ddr_vrp,
      FIXED_IO_mio(c_fixed_mio_width - 1 downto 0) => FIXED_IO_mio(c_fixed_mio_width - 1 downto 0),
      FIXED_IO_ps_clk => FIXED_IO_ps_clk,
      FIXED_IO_ps_porb => FIXED_IO_ps_porb,
      FIXED_IO_ps_srstb => FIXED_IO_ps_srstb,

      HDMI_DDC_scl_i => HDMI_DDC_scl_i,
      HDMI_DDC_scl_o => HDMI_DDC_scl_o,
      HDMI_DDC_scl_t => HDMI_DDC_scl_t,
      HDMI_DDC_sda_i => HDMI_DDC_sda_i,
      HDMI_DDC_sda_o => HDMI_DDC_sda_o,
      HDMI_DDC_sda_t => HDMI_DDC_sda_t,
      HDMI_HPD_tri_i(0) => HDMI_HPD_tri_i(0),

      S_CLK_SYS => s_clk_sys,
      S_CLK_VIDEO => s_clk_video,
      S_CLK_EMU => s_clk_emu,
      S_CLK_AVALON => s_clk_avalon,
      S_RESETN_SYS => s_resetn_sys,
      S_RESETN_VIDEO => s_resetn_video,

      S_AVALON_UPSCALE_address => s_avalon_upscale_address,
      S_AVALON_UPSCALE_burstcount => s_avalon_upscale_burstcount,
      S_AVALON_UPSCALE_byteenable => s_avalon_upscale_byteenable,
      S_AVALON_UPSCALE_read => s_avalon_upscale_read,
      S_AVALON_UPSCALE_readdata => s_avalon_upscale_readdata,
      S_AVALON_UPSCALE_readdatavalid => s_avalon_upscale_readdatavalid,
      S_AVALON_UPSCALE_waitrequest => s_avalon_upscale_waitrequest,
      S_AVALON_UPSCALE_write => s_avalon_upscale_write,
      S_AVALON_UPSCALE_writedata => s_avalon_upscale_writedata,

      S_VDMA_AXI_MM2S_araddr => s_vdma_axi_mm2s_araddr,
      S_VDMA_AXI_MM2S_arburst => s_vdma_axi_mm2s_arburst,
      S_VDMA_AXI_MM2S_arcache => s_vdma_axi_mm2s_arcache,
      S_VDMA_AXI_MM2S_arlen => s_vdma_axi_mm2s_arlen,
      S_VDMA_AXI_MM2S_arprot => s_vdma_axi_mm2s_arprot,
      S_VDMA_AXI_MM2S_arready => s_vdma_axi_mm2s_arready,
      S_VDMA_AXI_MM2S_arsize => s_vdma_axi_mm2s_arsize,
      S_VDMA_AXI_MM2S_arvalid => s_vdma_axi_mm2s_arvalid,
      S_VDMA_AXI_MM2S_rdata => s_vdma_axi_mm2s_rdata,
      S_VDMA_AXI_MM2S_rlast => s_vdma_axi_mm2s_rlast,
      S_VDMA_AXI_MM2S_rready => s_vdma_axi_mm2s_rready,
      S_VDMA_AXI_MM2S_rresp => s_vdma_axi_mm2s_rresp,
      S_VDMA_AXI_MM2S_rvalid => s_vdma_axi_mm2s_rvalid,

      S_VDMA_AXI_S2MM_awaddr => s_vdma_axi_s2mm_awaddr,
      S_VDMA_AXI_S2MM_awburst => s_vdma_axi_s2mm_awburst,
      S_VDMA_AXI_S2MM_awcache => s_vdma_axi_s2mm_awcache,
      S_VDMA_AXI_S2MM_awlen => s_vdma_axi_s2mm_awlen,
      S_VDMA_AXI_S2MM_awprot => s_vdma_axi_s2mm_awprot,
      S_VDMA_AXI_S2MM_awready => s_vdma_axi_s2mm_awready,
      S_VDMA_AXI_S2MM_awsize => s_vdma_axi_s2mm_awsize,
      S_VDMA_AXI_S2MM_awvalid => s_vdma_axi_s2mm_awvalid,
      S_VDMA_AXI_S2MM_wdata => s_vdma_axi_s2mm_wdata,
      S_VDMA_AXI_S2MM_wlast => s_vdma_axi_s2mm_wlast,
      S_VDMA_AXI_S2MM_wready => s_vdma_axi_s2mm_wready,
      S_VDMA_AXI_S2MM_bresp => s_vdma_axi_s2mm_bresp,
      S_VDMA_AXI_S2MM_wvalid => s_vdma_axi_s2mm_wvalid,
      S_VDMA_AXI_S2MM_wstrb => s_vdma_axi_s2mm_wstrb,
      S_VDMA_AXI_S2MM_bvalid => s_vdma_axi_s2mm_bvalid,
      S_VDMA_AXI_S2MM_bready => s_vdma_axi_s2mm_bready,

      S_RGB_OUT_data => s_rgb_out_data,
      S_RGB_OUT_hsync => s_rgb_out_hsync,
      S_RGB_OUT_vsync => s_rgb_out_vsync,
      S_RGB_OUT_active_video => s_rgb_out_active_video,

      S_VDMA_AXI_LITE_araddr => s_vdma_axi_lite_araddr,
      S_VDMA_AXI_LITE_arready(0) => s_vdma_axi_lite_arready,
      S_VDMA_AXI_LITE_arvalid(0) => s_vdma_axi_lite_arvalid,
      S_VDMA_AXI_LITE_awaddr => s_vdma_axi_lite_awaddr,
      S_VDMA_AXI_LITE_awready(0) => s_vdma_axi_lite_awready,
      S_VDMA_AXI_LITE_awvalid(0) => s_vdma_axi_lite_awvalid,
      S_VDMA_AXI_LITE_bready(0) => s_vdma_axi_lite_bready,
      S_VDMA_AXI_LITE_bresp => s_vdma_axi_lite_bresp,
      S_VDMA_AXI_LITE_bvalid(0) => s_vdma_axi_lite_bvalid,
      S_VDMA_AXI_LITE_rdata => s_vdma_axi_lite_rdata,
      S_VDMA_AXI_LITE_rready(0) => s_vdma_axi_lite_rready,
      S_VDMA_AXI_LITE_rresp => s_vdma_axi_lite_rresp,
      S_VDMA_AXI_LITE_rvalid(0) => s_vdma_axi_lite_rvalid,
      S_VDMA_AXI_LITE_wdata => s_vdma_axi_lite_wdata,
      S_VDMA_AXI_LITE_wready(0) => s_vdma_axi_lite_wready,
      S_VDMA_AXI_LITE_wvalid(0) => s_vdma_axi_lite_wvalid,
      S_VDMA_AXI_LITE_arprot => s_vdma_axi_lite_arprot,
      S_VDMA_AXI_LITE_awprot => s_vdma_axi_lite_awprot,
      S_VDMA_AXI_LITE_wstrb => s_vdma_axi_lite_wstrb,
      
      S_ZX_ADDR_DATA_BUS_AXI_araddr => s_axi_ddr_araddr,
      S_ZX_ADDR_DATA_BUS_AXI_arburst => s_axi_ddr_arburst,
      S_ZX_ADDR_DATA_BUS_AXI_arcache => s_axi_ddr_arcache,
      S_ZX_ADDR_DATA_BUS_AXI_arlen => s_axi_ddr_arlen,
      S_ZX_ADDR_DATA_BUS_AXI_arprot => s_axi_ddr_arprot,
      S_ZX_ADDR_DATA_BUS_AXI_arready => s_axi_ddr_arready,
      S_ZX_ADDR_DATA_BUS_AXI_arsize => s_axi_ddr_arsize,
      S_ZX_ADDR_DATA_BUS_AXI_arvalid => s_axi_ddr_arvalid,
      S_ZX_ADDR_DATA_BUS_AXI_rdata => s_axi_ddr_rdata,
      S_ZX_ADDR_DATA_BUS_AXI_rlast => s_axi_ddr_rlast,
      S_ZX_ADDR_DATA_BUS_AXI_rready => s_axi_ddr_rready,
      S_ZX_ADDR_DATA_BUS_AXI_rresp => s_axi_ddr_rresp,
      S_ZX_ADDR_DATA_BUS_AXI_rvalid => s_axi_ddr_rvalid,

      S_ZX_ADDR_DATA_BUS_AXI_awaddr => s_axi_ddr_awaddr,
      S_ZX_ADDR_DATA_BUS_AXI_awburst => s_axi_ddr_awburst,
      S_ZX_ADDR_DATA_BUS_AXI_awcache => s_axi_ddr_awcache,
      S_ZX_ADDR_DATA_BUS_AXI_awlen => s_axi_ddr_awlen,
      S_ZX_ADDR_DATA_BUS_AXI_awprot => s_axi_ddr_awprot,
      S_ZX_ADDR_DATA_BUS_AXI_awready => s_axi_ddr_awready,
      S_ZX_ADDR_DATA_BUS_AXI_awsize => s_axi_ddr_awsize,
      S_ZX_ADDR_DATA_BUS_AXI_awvalid => s_axi_ddr_awvalid,
      S_ZX_ADDR_DATA_BUS_AXI_wdata => s_axi_ddr_wdata,
      S_ZX_ADDR_DATA_BUS_AXI_wlast => s_axi_ddr_wlast,
      S_ZX_ADDR_DATA_BUS_AXI_wready => s_axi_ddr_wready,
      S_ZX_ADDR_DATA_BUS_AXI_bresp => s_axi_ddr_bresp,
      S_ZX_ADDR_DATA_BUS_AXI_wvalid => s_axi_ddr_wvalid,
      S_ZX_ADDR_DATA_BUS_AXI_wstrb => s_axi_ddr_wstrb,
      S_ZX_ADDR_DATA_BUS_AXI_bvalid => s_axi_ddr_bvalid,
      S_ZX_ADDR_DATA_BUS_AXI_bready => s_axi_ddr_bready,

      TMDS_clk_n => TMDS_clk_n,
      TMDS_clk_p => TMDS_clk_p,
      TMDS_data_n(2 downto 0) => TMDS_data_n(2 downto 0),
      TMDS_data_p(2 downto 0) => TMDS_data_p(2 downto 0),

      S_IIC_PS_0_scl_i => s_emu_hat_iic_scl_i,
      S_IIC_PS_0_scl_o => s_emu_hat_iic_scl_o,
      S_IIC_PS_0_scl_t => s_emu_hat_iic_scl_t,
      S_IIC_PS_0_sda_i => s_emu_hat_iic_sda_i,
      S_IIC_PS_0_sda_o => s_emu_hat_iic_sda_o,
      S_IIC_PS_0_sda_t => s_emu_hat_iic_sda_t

    );

  arty_video_top_i : component arty_video_top
    generic map(
      g_axi_data_width => c_smm_data_width,
      g_axi_lite_data_width => c_axi_lite_data_width,
      g_axi_addr_width => c_axi_addr_width
    )
    port map(
      i_resetn_sys => s_resetn_sys,
      i_resetn_video => s_resetn_video,
      i_aclk_sys => s_clk_sys,
      i_aclk_video => s_clk_video, 
      i_aclk_avalon => s_clk_avalon,
      --i_p_cold_reset

      o_axi_mm2s_araddr => s_vdma_axi_mm2s_araddr,
      o_axi_mm2s_arburst => s_vdma_axi_mm2s_arburst,
      o_axi_mm2s_arcache => s_vdma_axi_mm2s_arcache,
      o_axi_mm2s_arlen => s_vdma_axi_mm2s_arlen,
      o_axi_mm2s_arprot => s_vdma_axi_mm2s_arprot,
      i_axi_mm2s_arready => s_vdma_axi_mm2s_arready,
      o_axi_mm2s_arsize => s_vdma_axi_mm2s_arsize,
      o_axi_mm2s_arvalid => s_vdma_axi_mm2s_arvalid,
      i_axi_mm2s_rdata => s_vdma_axi_mm2s_rdata,
      i_axi_mm2s_rlast => s_vdma_axi_mm2s_rlast,
      o_axi_mm2s_rready => s_vdma_axi_mm2s_rready,
      i_axi_mm2s_rresp => s_vdma_axi_mm2s_rresp,
      i_axi_mm2s_rvalid => s_vdma_axi_mm2s_rvalid,

      o_axi_s2mm_awaddr => s_vdma_axi_s2mm_awaddr,
      o_axi_s2mm_awburst => s_vdma_axi_s2mm_awburst,
      o_axi_s2mm_awcache => s_vdma_axi_s2mm_awcache,
      o_axi_s2mm_awlen => s_vdma_axi_s2mm_awlen,
      o_axi_s2mm_awprot => s_vdma_axi_s2mm_awprot,
      i_axi_s2mm_awready => s_vdma_axi_s2mm_awready,
      o_axi_s2mm_awsize => s_vdma_axi_s2mm_awsize,
      o_axi_s2mm_awvalid => s_vdma_axi_s2mm_awvalid,
      o_axi_s2mm_wdata => s_vdma_axi_s2mm_wdata,
      o_axi_s2mm_wlast => s_vdma_axi_s2mm_wlast,
      i_axi_s2mm_wready => s_vdma_axi_s2mm_wready,
      i_axi_s2mm_bresp => s_vdma_axi_s2mm_bresp,
      o_axi_s2mm_wvalid => s_vdma_axi_s2mm_wvalid,
      o_axi_s2mm_wstrb => s_vdma_axi_s2mm_wstrb,
      i_axi_s2mm_bvalid => s_vdma_axi_s2mm_bvalid,
      o_axi_s2mm_bready => s_vdma_axi_s2mm_bready,

      o_avalon_upscale_address => s_avalon_upscale_address,
      o_avalon_upscale_burstcount => s_avalon_upscale_burstcount,
      o_avalon_upscale_byteenable => s_avalon_upscale_byteenable,
      o_avalon_upscale_read => s_avalon_upscale_read,
      i_avalon_upscale_readdata => s_avalon_upscale_readdata,
      i_avalon_upscale_readdatavalid => s_avalon_upscale_readdatavalid,
      i_avalon_upscale_waitrequest => s_avalon_upscale_waitrequest,
      o_avalon_upscale_write => s_avalon_upscale_write,
      o_avalon_upscale_writedata => s_avalon_upscale_writedata,

      i_wr_en => s_wr_en,
      i_rd_en => s_rd_en,
      i_register_data_out => s_register_data_out,
      i_video_control_en => s_video_control_en,
      i_video_control => s_video_control,

      i_emu_hsync => s_emu_hsync,
      i_emu_vsync => s_emu_vsync,
      i_emu_de => s_emu_de,
      i_emu_r => s_emu_r,
      i_emu_g => s_emu_g,
      i_emu_b => s_emu_b,

      i_ce_pixel_clock_in => s_ce_7mp,
      i_ce_pixel_clock_scandoubled => s_ce_14mp,
      i_ce_emu_video_out => s_ce_21mp,
      i_ce_upscaler_video_out => s_ce_42mp,

      -- to VGA PMOD
      o_vga_hs => s_vga_hs,
      o_vga_vs => s_vga_vs,
      o_vga_r => s_vga_r,
      o_vga_b => s_vga_b,
      o_vga_g => s_vga_g,

      -- to HDMI
      o_hdmi_out_data => s_rgb_out_data,
      o_hdmi_out_hsync => s_rgb_out_hsync,
      o_hdmi_out_vsync => s_rgb_out_vsync,
      o_hdmi_out_active_video => s_rgb_out_active_video
    );

  registers_top_i : component registers_top
    generic map(
      g_axi_lite_data_width => c_axi_lite_data_width,
      g_axi_addr_width => c_axi_addr_width
    )
    port map(
      i_resetn_sys => s_resetn_sys,
      i_aclk_sys => s_clk_sys,

      i_axi_lite_araddr => s_vdma_axi_lite_araddr,
      o_axi_lite_arready => s_vdma_axi_lite_arready,
      i_axi_lite_arvalid => s_vdma_axi_lite_arvalid,
      i_axi_lite_awaddr => s_vdma_axi_lite_awaddr,
      o_axi_lite_awready => s_vdma_axi_lite_awready,
      i_axi_lite_awvalid => s_vdma_axi_lite_awvalid,
      i_axi_lite_bready => s_vdma_axi_lite_bready,
      o_axi_lite_bresp => s_vdma_axi_lite_bresp,
      o_axi_lite_bvalid => s_vdma_axi_lite_bvalid,
      o_axi_lite_rdata => s_vdma_axi_lite_rdata,
      i_axi_lite_rready => s_vdma_axi_lite_rready,
      o_axi_lite_rresp => s_vdma_axi_lite_rresp,
      o_axi_lite_rvalid => s_vdma_axi_lite_rvalid,
      i_axi_lite_wdata => s_vdma_axi_lite_wdata,
      o_axi_lite_wready => s_vdma_axi_lite_wready,
      i_axi_lite_wvalid => s_vdma_axi_lite_wvalid,
      i_axi_lite_arprot => s_vdma_axi_lite_arprot,
      i_axi_lite_awprot => s_vdma_axi_lite_awprot,
      i_axi_lite_wstrb => s_vdma_axi_lite_wstrb,

      o_wr_en => s_wr_en,
      o_rd_en => s_rd_en,
      o_register_data_out => s_register_data_out,
      o_video_control_en => s_video_control_en,
      i_video_control => s_video_control,
      o_emu_control_en => s_emu_control_en,
      i_emu_control => s_emu_control,
      o_memtest_pass_cnt_en => s_memtest_pass_cnt_en,
      i_memtest_pass_cnt => s_memtest_pass_cnt,
      o_memtest_fail_cnt_en => s_memtest_fail_cnt_en,
      i_memtest_fail_cnt => s_memtest_fail_cnt,

      o_mmc_di_en => s_mmc_di_en,
      i_mmc_di => s_mmc_di,
      o_ps2_kbd_do_en => s_ps2_kbd_do_en,
      i_ps2_kbd_do => s_ps2_kbd_do,
      o_joystick_en => s_joystick_en,
      i_joystick => s_joystick
    );


  axi_ddr_top_i : component axi_ddr_top
    generic map(
      g_axi_data_width => c_smm_data_width,
      g_axi_lite_data_width => c_axi_lite_data_width,
      g_axi_addr_width => c_axi_addr_width,
      g_axi_ddr_data_width => c_ddr_data_width,
      g_axi_ddr_addr_width => c_ddr_addr_width
    )
    port map(
      i_resetn_sys => s_resetn_sys,
      i_aclk_sys => s_clk_sys,
 
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
      o_ddr_data => s_ddr_data_out,
      i_ddr_mem_wr => s_ddr_mem_wr,
      i_ddr_mem_req => s_ddr_mem_req,
      o_ddr_mem_busy => s_ddr_mem_busy
    );

g_generate_emu : if g_mem_test = 0 generate
  
  emsx_top_i : component emsx_top
    generic map(
      g_axi_lite_data_width => c_axi_lite_data_width
    )
    port map(
      i_resetn_sys => s_resetn_sys,
      i_aclk_sys => s_clk_sys,
      i_aclk_emu => s_clk_emu,
      i_aclk_mem => s_clk_sys,
      --i_p_cold_reset

      o_ddr_address => s_ddr_address,
      i_ddr_data => s_ddr_data_out,
      o_ddr_data => s_ddr_data_in,
      o_ddr_mem_wr => s_ddr_mem_wr,
      o_ddr_mem_req => s_ddr_mem_req,
      i_ddr_mem_busy => s_ddr_mem_busy,

      -- SDRAM interface
      o_mem_cke => s_mem_cke,
      o_mem_cs_n => s_mem_cs_n,
      o_mem_ras_n => s_mem_ras_n,
      o_mem_cas_n => s_mem_cas_n,
      o_mem_we_n => s_mem_we_n,
      o_mem_udq => s_mem_udq,
      o_mem_ldq => s_mem_ldq,
      o_mem_ba1 => s_mem_ba(1),
      o_mem_ba0 => s_mem_ba(0),
      o_mem_adr => s_mem_adr,
      io_mem_dq => SDRAM_DQ,
      o_mem_dat_en => s_mem_dat_en,

      i_wr_en => s_wr_en,
      i_rd_en => s_rd_en,
      i_register_data_out => s_register_data_out,      
      i_emu_control_en => s_emu_control_en,
      o_emu_control => s_emu_control,
      i_mmc_di_en => s_mmc_di_en,
      o_mmc_di => s_mmc_di,
      i_memtest_pass_cnt_en => s_memtest_pass_cnt_en,
      o_memtest_pass_cnt => s_memtest_pass_cnt,
      i_memtest_fail_cnt_en => s_memtest_fail_cnt_en,
      o_memtest_fail_cnt => s_memtest_fail_cnt,
      i_joystick_en => s_joystick_en,
      o_joystick => s_joystick,

      o_emu_hsync => s_emu_hsync,
      o_emu_vsync => s_emu_vsync,
      o_emu_de => s_emu_de,
      o_emu_r => s_emu_r,
      o_emu_g => s_emu_g,
      o_emu_b => s_emu_b,

      o_ce_21mp => s_ce_21mp,
      o_ce_42mp => s_ce_42mp,

      -- PS/2 keyboard ports
      i_ps2_key => s_ps2_key,
      --o_p_caps => 

      i_p_joy_a => s_joy_a_emu,
      o_p_str_a => s_joy_a_stb,
      i_p_joy_b => s_joy_b,
      o_p_str_b => s_joy_b_stb,

      -- DIP switch, Lamp ports
      i_p_dip => "00000000",
      --o_p_led => 
      --o_p_led_pwr => 
      --i_p_r800 => 

      --i_rtc_setup => 
      --i_rtc_time => 

      o_p_audio_psg => s_p_audio_psg,
      o_p_audio_opll => s_p_audio_opll,
      o_p_audio_pcm => s_p_audio_pcm,
      o_p_audio_trpcm => s_p_audio_trpcm,
      --o_p_beeper => s_p_beeper,

      i_mmc_miso => s_mmc_miso,
      o_mmc_cs => s_mmc_cs,
      o_mmc_mosi => s_mmc_mosi,
      o_mmc_clk => s_mmc_clk,

      o_led0_red => s_led0_red,
      o_led1_red => s_led1_red,

      o_cpucen => s_cpucen

    );   

  mist_adapter_i: component mist_adapter
    port map(
      AUDIO_CLK => s_clk_emu,
      AUDIO_RES => not s_resetn_sys,

      AUDIO_OPLL => s_p_audio_opll,
      AUDIO_PSG => s_p_audio_psg,
      AUDIO_PCM => s_p_audio_pcm,
      AUDIO_TRPCM => s_p_audio_trpcm,

      AUDIO_L => open,
      AUDIO_R => open,
      AUDIO_S => open,
      AUDIO_MIX => open,

      I2S_CE => s_i2s_ce, 
      AUDIO_L_FLT => s_audio_l_flt,
      AUDIO_R_FLT => s_audio_r_flt
    );


end generate g_generate_emu;
 
g_generate_memtest : if g_mem_test = 1 generate

  memtest_top_i : component memtest_top
    generic map(
      g_axi_lite_data_width => c_axi_lite_data_width
    )
    port map(
      i_resetn_sys => s_resetn_sys,
      i_aclk_sys => s_clk_sys,
      i_aclk_emu => s_clk_emu,
      --i_p_cold_reset

      o_ddr_address => s_ddr_address,
      i_ddr_data => s_ddr_data_out,
      o_ddr_data => s_ddr_data_in,
      o_ddr_mem_wr => s_ddr_mem_wr,
      o_ddr_mem_req => s_ddr_mem_req,
      i_ddr_mem_busy => s_ddr_mem_busy,

      -- SDRAM interface
      o_mem_clk => open, --(clock already connected through ODDR2 primitive)
      o_mem_cke => s_mem_cke,
      o_mem_cs_n => s_mem_cs_n,
      o_mem_ras_n => s_mem_ras_n,
      o_mem_cas_n => s_mem_cas_n,
      o_mem_we_n => s_mem_we_n,
      o_mem_udq => s_mem_udq,
      o_mem_ldq => s_mem_ldq,
      o_mem_ba1 => s_mem_ba(1),
      o_mem_ba0 => s_mem_ba(0),
      o_mem_adr => s_mem_adr,
      io_mem_dq => SDRAM_DQ,

      i_wr_en => s_wr_en,
      i_rd_en => s_rd_en,
      i_register_data_out => s_register_data_out,      
      i_emu_control_en => s_emu_control_en,
      o_emu_control => s_emu_control,
      i_memtest_pass_cnt_en => s_memtest_pass_cnt_en,
      o_memtest_pass_cnt => s_memtest_pass_cnt,
      i_memtest_fail_cnt_en => s_memtest_fail_cnt_en,
      o_memtest_fail_cnt => s_memtest_fail_cnt,

      o_emu_hsync => s_emu_hsync,
      o_emu_vsync => s_emu_vsync,
      o_emu_de => s_emu_de,
      o_emu_r => s_emu_r,
      o_emu_g => s_emu_g,
      o_emu_b => s_emu_b,

      o_ce_21mp => s_ce_21mp,

      -- DIP switch, Lamp ports
      i_p_dip => "00000000",

      i_mmc_miso => s_mmc_miso,
      o_mmc_cs => s_mmc_cs,
      o_mmc_mosi => s_mmc_mosi,
      o_mmc_clk => s_mmc_clk,

      o_led0_red => s_led0_red,
      o_led1_red => s_led1_red

    );   

end generate g_generate_memtest;

    -- Put OBUFs in between ? (no need, they are automatically put anyway)
    SDRAM_CS <= s_mem_cs_n;
    SDRAM_RAS <= s_mem_ras_n;
    SDRAM_CAS <= s_mem_cas_n;
    SDRAM_WE <= s_mem_we_n;
    SDRAM_BA <= s_mem_ba;
    SDRAM_A <= s_mem_adr;
    --s_mem_cke not used is this hardware design
    --s_mem_udq not used in this hardware design
    --s_mem_ldq not used in this hardware design

    sdram_clk_i: component ODDR
    generic map (
      DDR_CLK_EDGE => "SAME_EDGE", -- "OPPOSITE_EDGE" or "SAME_EDGE"
      INIT => '0', -- Initial value for Q port ('1' or '0')
      SRTYPE => "SYNC") -- Reset Type ("ASYNC" or "SYNC")
    port map (
      Q => SDRAM_CLK, -- 1-bit DDR output
      C => s_clk_sys, -- 1-bit clock input
      CE => '1', -- 1-bit clock enable input
      D1 => '0', -- 1-bit data input (positive edge) 
      D2 => '1', -- 1-bit data input (negative edge)
      R => not s_resetn_sys, -- 1-bit reset input
      S => '0' -- 1-bit set input
    );

    ps2_kbd_emu_i : component ps2_kbd_emu
    generic map (
      g_axi_lite_data_width => c_axi_lite_data_width
    )
    port map ( 
      i_resetn_sys => s_resetn_sys,
      i_aclk_sys => s_clk_sys,
      i_aclk_emu => s_clk_emu,
      i_emu_clk_en => s_cpucen,
      -- Register interface      
      i_ps2_kbd_do_en => s_ps2_kbd_do_en,
      o_ps2_kbd_do => s_ps2_kbd_do,
      i_reg_wr_en => s_wr_en,
      i_reg_rd_en => s_rd_en, 
      i_register_data_out => s_register_data_out,
      -- PS2 interface
      o_ps2_key => open --s_ps2_key -- Emulation of PS/2 keyboard via USB stack
    );
 
    ps2_kbd_i : component ps2_kbd
    port map ( 
      i_resetn_sys => s_resetn_sys,
      i_aclk_emu => s_clk_emu,
      i_emu_clk_en => s_cpucen,

      io_ps_clk => KBD_CLK,
      io_ps_dat => KBD_DAT,

      -- PS2 emulator interface
      o_ps2_key => s_ps2_key,

      -- Joystick emulated through PS/2 keyboard
      o_joy_a_emu => s_joy_a_emu
    );

    ps2_mouse_i : component ps2_mouse
    port map ( 
      i_resetn_sys => s_resetn_sys,
      i_aclk_emu => s_clk_emu,
      i_emu_clk_en => s_cpucen,

      io_ps_clk => MOUSE_CLK,
      io_ps_dat => MOUSE_DAT,

      -- PS2 emulator interface
      o_ps2_mouse => s_ps2_mouse
    );

    ps2_mouse_msx_i : component ps2mouse
    port map (
      clk => s_clk_emu, -- check this
      reset => s_resetn_sys,
      strobe => s_joy_b_stb,
      data => s_joy_b,
      ps2_mouse => s_ps2_mouse
    );

    i_i2s : i2s
    port map (
      i_clk => s_clk_emu,
      i_resetn => s_resetn_sys,
      i_ce => s_i2s_ce,

      i_left_chan => s_audio_l_flt,
      i_right_chan => s_audio_r_flt, 

      o_bclk => s_dac_bclk,
      o_lrclk => s_dac_lrclk,
      o_sdat => s_dac_data
    );

-- Temporary
s_ps2_kbd_data_out <= (others => '0');

-- Temporary
s_ps2_mouse_data_out <= (others => '0');

    iic_scl_iobuf: component IOBUF
    port map (
      I => s_emu_hat_iic_scl_o,
      IO => I2C_SCL,
      O => s_emu_hat_iic_scl_i,
      T => s_emu_hat_iic_scl_t
    );

    iic_sda_iobuf: component IOBUF
    port map (
      I => s_emu_hat_iic_sda_o,
      IO => I2C_SDA,
      O => s_emu_hat_iic_sda_i,
      T => s_emu_hat_iic_sda_t
    );

end STRUCTURE;
