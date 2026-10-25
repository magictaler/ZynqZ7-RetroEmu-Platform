----------------------------------------------------------------------------------
-- MSX2+ port to Arty-Z7
-- 
-- Company: Magictale Electronics http://magictale.com
-- Engineer: Dmitry Pakhomenko
-- 
-- Create Date: 21.02.2024 21:53:00 PM
-- Design Name: MSX2+ Board
-- Module Name: emsx_top - RTL
-- Project Name: MSX2+ retro computer emulator on Arty Z7/AX7020 boards
-- Target Devices: Zynq 7020
-- Tool Versions: Vivado 2017.3
-- Description: This is a top level of the MSX2+ emulator
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created on 21.02.2024
-- Additional Comments:
-- 
----------------------------------------------------------------------------------

library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

library xil_defaultlib;
    use work.types_arty_video.all;
    use work.types_arty_audio.all;
    use work.types_zx_main_top.all;
    use work.types_emulator_top.all;

entity emsx_top is
    generic (
      g_axi_lite_data_width : integer := 32;
      g_rst_seq : unsigned(4 downto 0) := "00000";
      g_sd_via_ps : integer := 0;
      g_ext_sdram : integer := 1
    );
    port ( 
      i_resetn_sys : in std_logic;
      i_aclk_sys : in std_logic; -- 85.90908 MHz
      i_aclk_emu : in std_logic; -- 21.4815 MHz
      i_aclk_mem : in std_logic; -- 85.90908 MHz
      i_p_cold_reset : in std_logic; -- TODO: connect it to the upper level

      -- DDRAM interface
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
      io_mem_dq : inout std_logic_vector(15 downto 0);

      o_mem_dat_en : out std_logic;

      -- Registers
      i_wr_en : in std_logic;    
      i_rd_en : in std_logic;    
      i_register_data_out : in std_logic_vector(c_register_width - 1 downto 0);
      i_emu_control_en : in std_logic;
      o_emu_control : out std_logic_vector(g_axi_lite_data_width - 1 downto 0);
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

      -- Chip enable @ 21.48 MHz for MSX2+
      o_ce_21mp : out std_logic;
      o_ce_42mp : out std_logic;

      -- PS/2 keyboard ports
      -- [8] - extended, [9] - pressed, [10] - toggles with every press/release
      i_ps2_key : in std_logic_vector(10 downto 0);
      o_p_caps : out std_logic;

      -- Joystick ports (Port_A, Port_B)
      i_p_joy_a : in std_logic_vector(5 downto 0);
      o_p_str_a : out std_logic;
      i_p_joy_b : in std_logic_vector(5 downto 0);
      o_p_str_b : out std_logic;

      --cmtin           : in    std_logic; -- EAR 

      -- DIP switch, Lamp ports
      i_p_dip : in std_logic_vector(7 downto 0);     -- 0=On,    1=Off (default on shipment)
      o_p_led : out std_logic_vector(7 downto 0);    -- 0=Off,   1=On  (green)
      o_p_led_pwr : out std_logic; -- 0=Off,   1=On  (red)
      i_p_r800 : in std_logic;

      i_rtc_setup : in std_logic;
      i_rtc_time : in std_logic_vector(64 downto 0);

      -- Audio
      o_p_audio_psg : out std_logic_vector(9 downto 0);
      o_p_audio_opll : out std_logic_vector(13 downto 0);
      o_p_audio_pcm : out std_logic_vector(15 downto 0);
      o_p_audio_trpcm : out std_logic_vector(7 downto 0);

      i_mmc_miso : in std_logic;
      o_mmc_cs : out std_logic;
      o_mmc_mosi : out std_logic;
      o_mmc_clk : out std_logic;

      o_led0_red : out std_logic; -- MMC active LED
      o_led1_red : out std_logic; -- BIOS loaded LED

      o_cpucen : out std_logic

    );

end emsx_top;

architecture rtl of emsx_top is

  -- Registers
  constant c_control_reg_cpu_reset_bit              : integer range 0 to 31 := 3;
  constant c_joy1_lsb_bit                           : integer range 0 to 31 := 0;
  constant c_joy1_msb_bit                           : integer range 0 to 31 := 5;
  constant c_joy2_lsb_bit                           : integer range 0 to 31 := 8;
  constant c_joy2_msb_bit                           : integer range 0 to 31 := 13;

  signal s_cpu_reset_reg : std_logic;

  -- MSX2+
  signal s_ce_42mp : std_logic; -- 42.95454
  signal s_ce_21mp : std_logic; -- 21.47727

  -- Clock, Reset control signals
  signal s_cpucen : std_logic;
  signal s_cpucen_n : std_logic;
  signal s_ff_clksel : std_logic;
  signal s_ff_clksel5m_n : std_logic;
  signal s_hybridclk_n : std_logic;
  signal s_hstartcount : unsigned(2 downto 0);
  signal s_htoutcount : unsigned(2 downto 0);
  signal s_logo_rst_cnt : unsigned(4 downto 0) := (others => '0');
  signal s_logo_timeout : std_logic_vector(1 downto 0);
  signal s_first_boot_n : std_logic := '0';
  signal s_reset : std_logic;
  signal s_rst_en : std_logic := '0';
  signal s_free_counter : unsigned(15 downto 0) := (others => '0');
  signal s_hard_rst_cnt : unsigned(3 downto 0) := (others => '0');
  signal s_hold_rst_en : std_logic := '0';
  signal s_rst_seq : unsigned(4 downto 0) := g_rst_seq;
  signal s_rst_ena : std_logic := '0';

  -- Switched I/O ports
  signal s_swio_req : std_logic;
  signal s_swio_dbi : std_logic_vector(7 downto 0);
  signal s_io40_n : std_logic_vector(7 downto 0);
  signal s_io41_id212_n : std_logic_vector(7 downto 0);   -- here to reduce LEs
  signal s_io42_id212 : std_logic_vector(7 downto 0);
  signal s_io43_id212 : std_logic_vector(7 downto 0);
  alias s_rst_key_lock : std_logic is s_io43_id212(5);
  signal s_io44_id212 : std_logic_vector(7 downto 0);
  alias s_green_leds : std_logic_vector(7 downto 0) is s_io44_id212;
  signal s_custom_speed : unsigned(3 downto 0);
  signal s_t_mega_sd : std_logic;
  signal s_t_pana_redir : std_logic;                     -- here to reduce LEs
  signal s_vdp_speed_mode : std_logic;
  signal s_v9938_n : std_logic;
  signal s_mapper_req : std_logic;                       -- here to reduce LEs
  signal s_mapper_ack : std_logic;
  signal s_mega_sd_req : std_logic;                      -- here to reduce LEs
  signal s_megasd_ack : std_logic;
  signal s_io41_id008_n : std_logic;
  signal s_swio_kmap : std_logic;
  signal s_cmt_scro : std_logic;
  signal s_swio_cmt : std_logic;
  signal s_lights_mode : std_logic;
  signal s_red_sta : std_logic;
  signal s_last_rst_sta : std_logic;                     -- here to reduce LEs
  signal s_rst_req_sta : std_logic;                      -- here to reduce LEs
  signal s_blink_en : std_logic;
  signal s_pseudo_stereo : std_logic;
  signal s_extclk3m : std_logic;
  signal s_right_inverse : std_logic;
  signal s_vram_slot_ids : std_logic_vector(7 downto 0);
  signal s_vram_page : std_logic_vector(7 downto 0);
  signal s_def_kmap : std_logic;                         -- here to reduce LEs
  signal s_ff_dip_req : std_logic_vector(7 downto 0);
  signal s_ff_dip_ack : std_logic_vector(7 downto 0);    -- here to reduce LEs
  signal s_lev_ctrl : std_logic_vector(2 downto 0);
  signal s_green_lv_en : std_logic;
  signal s_swio_reset_n : std_logic;
  signal s_warm_reset : std_logic;
  signal s_warm_msx_logo : std_logic;                    -- here to reduce LEs
  signal s_zemmix_neo : std_logic;
  signal s_jis2_en : std_logic;
  signal s_port_f4_mode : std_logic;
  signal s_ratio_mode : std_logic_vector(2 downto 0);
  signal s_center_yjk_r25_n : std_logic;
  signal s_legacy_sel : std_logic;
  signal s_slot0_req : std_logic;                        -- here to reduce LEs
  signal s_slot0_mode : std_logic;

  -- CPU clock enablers to use
  signal s_true_cen : std_logic;
  signal s_true_cen_n : std_logic;

  -- Clock divider
  signal s_clkdiv3 : unsigned(1 downto 0);
  signal s_ff_mem_seq : std_logic_vector(1 downto 0) := (others => '0');
  signal s_paus_flash : std_logic;

  -- Turbo CPU clock enablers
  signal s_cpucen_5m : std_logic;
  signal s_cpucen_5m_n : std_logic;
  signal s_cpucen_10m : std_logic;
  signal s_cpucen_10m_n : std_logic;

  -- Operation mode
  signal s_ff_clk21m_cnt : unsigned(20 downto 0); -- free run counter
  signal s_display_mode : std_logic_vector(1 downto 0);
  signal s_slot1_mode : std_logic;
  signal s_slot2_mode : std_logic_vector(1 downto 0);
  signal s_kmap : std_logic; -- '0': Japanese-106    '1': Non-Japanese (English-101, French, ..)
  signal s_flash_cnt : unsigned(3 downto 0); -- flash counter
  signal s_green_lv : std_logic_vector(6 downto 0); -- green level
  signal s_green_lv_cnt : unsigned(3 downto 0); -- green level counter
  signal s_ff_rst_seq : unsigned(1 downto 0);
  signal s_faded_red : std_logic;
  signal s_faded_green : std_logic;
  signal s_key_mode : std_logic; -- Kana key board layout: 1=JIS layout
  alias s_mmc_mode : std_logic is s_megasd_ack; -- '0': disable SD/MMC  '1': enable SD/MMC
  signal s_w_key_mode : std_logic; -- Kana key board layout: 1=JIS layout
  alias s_full_ram : std_logic is s_mapper_ack; -- '0': 2048 kB RAM     '1': 4096 kB RAM
  signal s_slot2mode : std_logic_vector(1 downto 0);

  -- ESE-RAM signals
  signal s_erm_req : std_logic;
  signal s_erm_ram : std_logic;
  signal s_erm_wrt : std_logic;
  signal s_erm_adr : std_logic_vector(19 downto 0);

  -- MSX cartridge slot control signals
  signal s_bus_dir : std_logic;
  signal s_i_slt_rfsh_n : std_logic;
  signal s_i_slt_merq_n : std_logic;
  signal s_i_slt_iorq_n : std_logic;
  signal s_x_slt_rd_n : std_logic;
  signal s_x_slt_wr_n : std_logic;
  signal s_i_slt_adr : std_logic_vector(15 downto 0);
  signal s_i_slt_dat : std_logic_vector(7 downto 0);
  signal s_dlydbi : std_logic_vector(7 downto 0);
  signal s_cpu_m1_n : std_logic;
  signal s_cpu_rfsh_n : std_logic;
  signal s_cpu_di : std_logic_vector(7 downto 0);
  signal s_cpu_do : std_logic_vector(7 downto 0);
  signal s_cpu_reset_n : std_logic;

  -- Internal bus signals (common)
  signal s_req : std_logic;
  signal s_ack : std_logic;
  signal s_iack : std_logic;
  signal s_mem : std_logic;
  signal s_wrt : std_logic;
  signal s_adr : std_logic_vector(15 downto 0);
  signal s_dbi : std_logic_vector(7 downto 0);
  signal s_dbo : std_logic_vector(7 downto 0);

  -- Primary, Expansion slot signals
  signal s_exp_dbi : std_logic_vector(7 downto 0);
  signal s_exp_slot0 : std_logic_vector(7 downto 0);
  signal s_exp_slot3 : std_logic_vector(7 downto 0);
  signal s_pri_slt_num : std_logic_vector(1 downto 0);
  signal s_exp_slt_num0 : std_logic_vector(1 downto 0);
  signal s_exp_slt_num3 : std_logic_vector(1 downto 0);

  -- Slot decode signals
  signal s_i_slt_bot : std_logic;
  signal s_i_slt_map : std_logic;
  signal s_j_slt_mem : std_logic;
  signal s_i_slt_scc1 : std_logic;
  signal s_j_slt_scc1 : std_logic;
  signal s_i_slt_scc2 : std_logic;
  signal s_j_slt_scc2 : std_logic;
  signal s_i_slt_erm : std_logic;

  -- Mapper RAM signals
  signal s_map_req : std_logic;
  signal s_map_dbi : std_logic_vector(7 downto 0);
  signal s_map_ram : std_logic;
  signal s_map_wrt : std_logic;
  signal s_map_adr : std_logic_vector(21 downto 0);

  -- Kanji signals
  signal s_kan_req : std_logic;
  signal s_kan_dbi : std_logic_vector(7 downto 0);
  signal s_kan_rom : std_logic;
  signal s_kan_adr : std_logic_vector(17 downto 0);

  -- PPI(8255) signals
  signal s_ppi_req : std_logic;
  signal s_ppi_dbi : std_logic_vector(7 downto 0);
  signal s_ppi_port_a : std_logic_vector(7 downto 0);
  signal s_ppi_port_b : std_logic_vector(7 downto 0);
  signal s_ppi_port_c : std_logic_vector(7 downto 0);

  signal s_w_page_dec : std_logic_vector(3 downto 0);
  signal s_w_prislt_dec : std_logic_vector(3 downto 0);
  signal s_w_expslt0_dec : std_logic_vector(3 downto 0);
  signal s_w_expslt3_dec : std_logic_vector(3 downto 0);

  -- 1 bit sound port signal
  alias s_key_click : std_logic is s_ppi_port_c(7);

  -- turboR PCM device
  signal s_tr_pcm_req : std_logic;
  signal s_tr_pcm_dbi : std_logic_vector(7 downto 0);

  -- System timer (S1990)
  signal s_systim_req : std_logic;
  signal s_systim_dbi : std_logic_vector(7 downto 0);

  -- RTC signals
  signal s_rtc_req : std_logic;
  signal s_rtc_ack : std_logic;
  signal s_rtc_dbi : std_logic_vector(7 downto 0);

  -- Port F4 device
  signal s_port_f4_req : std_logic;
  signal s_port_f4_bit7 : std_logic; -- 1=hard reset, 0=soft reset

  -- PS/2 signals
  signal s_paus : std_logic;
  signal s_scro : std_logic;
  signal s_reso : std_logic;
  signal s_reso_v : std_logic;
  signal s_fkeys : std_logic_vector(7 downto 0);
  -- Joysticks
  signal p_joy_a : std_logic_vector(5 downto 0);
  signal p_str_a : std_logic;
  signal p_joy_b : std_logic_vector(5 downto 0);
  signal p_str_b : std_logic;

  -- Sound output, Toggle keys
  signal s_v_fkeys : std_logic_vector(7 downto 0);

  -- DRAM arbiter
  signal s_w_wrt_req : std_logic;

  -- IPL-ROM signals
  signal s_rom_dbi : std_logic_vector(7 downto 0);
  signal s_ff_ldbios_n : std_logic;

  -- PSG signals
  signal s_psg_req : std_logic;
  signal s_psg_dbi : std_logic_vector(7 downto 0);
  signal s_psg_amp : std_logic_vector(9 downto 0);

  -- RTC lfsr counter
  signal s_rtcbase_cnt : std_logic_vector(21 downto 0);
  signal s_rtcbase_d0 : std_logic;
  signal s_w_10hz : std_logic := '1';

  -- SCC signals
  signal s_scc1_req : std_logic;
  signal s_scc1_ack : std_logic;
  signal s_scc1_dbi : std_logic_vector(7 downto 0);
  signal s_scc1_ram : std_logic;
  signal s_scc1_wrt : std_logic;
  signal s_scc1_adr : std_logic_vector(20 downto 0);
  signal s_scc1_amp_l : std_logic_vector(14 downto 0);

  signal s_p_audio_pcm_tmp : signed(15 downto 0);
  signal s_psg_amp_tmp : std_logic_vector(9 downto 0);
  signal s_key_click_tmp : std_logic_vector(5 downto 0);
  signal s_p_audio_psg_tmp : unsigned(9 downto 0);

  signal s_p_audio_pcm_tmp1 : signed(15 downto 0);
  signal s_p_audio_pcm_tmp2 : unsigned(15 downto 0);

  signal s_scc2_req : std_logic;
  signal s_scc2_ack : std_logic;
  signal s_scc2_dbi : std_logic_vector(7 downto 0);
  signal s_scc2_ram : std_logic;
  signal s_scc2_wrt : std_logic;
  signal s_scc2_adr : std_logic_vector(20 downto 0);
  signal s_scc2_amp_l : std_logic_vector(14 downto 0);

  signal s_scc1_type : std_logic_vector(1 downto 0);

  -- External memory signals
  signal s_ram_req : std_logic;
  signal s_ram_ack : std_logic;
  signal s_ram_dbi : std_logic_vector(7 downto 0);
  signal s_clr_adr : unsigned(17 downto 0);
  signal s_cpu_adr : std_logic_vector(22 downto 0);

  -- Experimental section for timing improvement 
  signal v_counter7 : unsigned(c_ddr_data_width - 1 downto 0) := x"00";
  signal s_emu_ce_cntr : unsigned(c_ddr_data_width - 1 downto 0) := x"00";

  -- MSX VDP
  signal s_pvideo_r : std_logic_vector(5 downto 0);
  signal s_pvideo_g : std_logic_vector(5 downto 0);
  signal s_pvideo_b : std_logic_vector(5 downto 0);
  signal s_pvideo_de : std_logic;
  signal s_pvideo_hs_n : std_logic;
  signal s_pvideo_vs_n : std_logic;
  signal s_pvideo_cs_n : std_logic;
  signal s_pvideo_dh_clk : std_logic;
  signal s_pvideo_dl_clk : std_logic;

  signal s_pramwe_n : std_logic;
  signal s_vdp_adr : std_logic_vector(16 downto 0);
  signal s_vrm_dbi : std_logic_vector(15 downto 0);
  signal s_vrm_dbo : std_logic_vector(7 downto 0);

  -- Opll signals
  signal s_opll_req : std_logic;
  signal s_opll_ack : std_logic;
  signal s_opll_en_wait : std_logic;

  -- VDP signals
  signal s_vdp_req : std_logic;
  signal s_vdp_dbi : std_logic_vector(7 downto 0);
  signal s_p_vdp_int_n : std_logic;
  signal s_ntsc_pal_type : std_logic;
  signal s_forced_v_mode : std_logic;
  signal s_legacy_vga : std_logic;
  signal s_mem_dbi : std_logic_vector(15 downto 0);

  -- SD-RAM control signals
  signal s_sdr_sta : std_logic_vector(2 downto 0);
  signal s_sdr_cmd : std_logic_vector(2 downto 0);
  signal s_sdr_adr : std_logic_vector( 12 downto 0 );
  signal s_ff_sdr_seq : std_logic_vector(2 downto 0);
  signal s_sd_paus : std_logic := '0';

  constant c_sdr_cmd_pr : std_logic_vector(2 downto 0) := "010"; -- precharge all
  constant c_sdr_cmd_re : std_logic_vector(2 downto 0) := "001"; -- refresh
  constant c_sdr_cmd_ms : std_logic_vector(2 downto 0) := "000"; -- mode regiser set
  constant c_sdr_cmd_xx : std_logic_vector(2 downto 0) := "111"; -- no operation
  constant c_sdr_cmd_ac : std_logic_vector(2 downto 0) := "011"; -- activate
  constant c_sdr_cmd_rd : std_logic_vector(2 downto 0) := "101"; -- read
  constant c_sdr_cmd_wr : std_logic_vector(2 downto 0) := "100"; -- write

  -- MSX cartridge slot ports
  signal s_p_slt_rst_n : std_logic; -- pCpuRst_n returns here
  signal s_p_slt_iorq_n : std_logic;
  signal s_p_slt_rd_n : std_logic;
  signal s_p_slt_wr_n : std_logic;
  signal s_p_slt_adr : std_logic_vector(15 downto 0);

  signal s_p_slt_rfsh_n : std_logic;
  signal s_p_slt_wait_n : std_logic;
  signal s_p_slt_int_n : std_logic;
  signal s_p_slt_merq_n : std_logic;

  -- BIOS-ROM decode signals
  signal s_rom_req : std_logic;
  signal s_rom_main : std_logic;
  signal s_rom_opll : std_logic;
  signal s_rom_extd : std_logic;
  signal s_rom_kanj : std_logic;

  signal s_rom_xbas : std_logic;
  signal s_rom_free : std_logic;

  -- SD/MMC signals
  signal s_mmc_en : std_logic;
  signal s_mmc_act : std_logic;
  signal s_mmc_dbi : std_logic_vector(7 downto 0);
  signal s_mmc_led_en : std_logic;

  -- SD/MMC slot ports
  signal s_mmc_sck : std_logic;
  signal s_mmc_cs : std_logic;
  signal s_mmc_mosi : std_logic;
  signal s_mmc_miso : std_logic;

  -- Interface to redirect dataflow to an SD/MMC card controlled by PS side
  -- like it is in case of Xilinx Zynq/Ultrascale SOC
  signal s_mmc_ps_di : std_logic_vector(8 downto 0); -- MSB includes mmc_cs
  signal s_mmc_ps_di_latched : std_logic_vector(8 downto 0);
  signal s_mmc_ps_do : std_logic_vector(7 downto 0);
  signal s_mmc_ps_di_stb : std_logic;
  signal s_mmc_ps_di_pending : std_logic;
  signal s_mmc_ps_do_pending : std_logic;
  signal s_mmc_ps_busy : std_logic;
  signal s_map_ps_di_stb_cdc : std_logic_vector(2 downto 0) := (others => '0');

  signal s_p_cpu_wait_n : std_logic;

  type t_8bx3_vec is array (2 downto 0) of std_logic_vector(7 downto 0);
  type t_23bx3_vec is array (2 downto 0) of std_logic_vector(23 downto 0);

  signal s_dbo_cdc : t_8bx3_vec := ((others => '0'), (others => '0'), (others => '0'));
  signal s_cpu_addr_cdc : t_23bx3_vec := ((others => '0'), (others => '0'), (others => '0'));
  signal s_w_wrt_req_cdc : std_logic_vector(2 downto 0) := (others => '0');
  signal s_ram_req_cdc : std_logic_vector(2 downto 0) := (others => '0');
  signal s_vdp_pulse : std_logic;
  signal s_vdp_ack : std_logic;

  signal s_vdp_req_filt : std_logic;

  -- SDRAM
  signal s_mem_dat_out : std_logic_vector(7 downto 0);
  signal s_mem_dat_in : std_logic_vector(15 downto 0);

  -- SDRAM Memory test
  signal s_pass_count : std_logic_vector (31 downto 0);
  signal s_fail_count : std_logic_vector (31 downto 0);
  signal s_written : std_logic_vector (15 downto 0);
  signal s_read : std_logic_vector (15 downto 0);
  signal s_check_in_progress : std_logic;
  signal s_dram_ready : std_logic;

begin

  g_generate_sdram_tester_mapper : if g_ext_sdram = 0 generate

  i_tester : tester
    port map( 
      clk => i_aclk_sys,
      rst_n => i_resetn_sys,

      sz => "01", -- 32MB
      chip => "00",

      passcount => s_pass_count,
      failcount => s_fail_count,

      written => s_written,
      read => s_read,

      o_check_in_progress => s_check_in_progress,
      o_dram_ready => s_dram_ready,

      DRAM_CLK => open,
      DRAM_DQ => io_mem_dq,
      DRAM_ADDR => o_mem_adr,
      DRAM_LDQM => o_mem_ldq,
      DRAM_UDQM => o_mem_udq,
      DRAM_WE_N => o_mem_we_n,
      DRAM_CAS_N => o_mem_cas_n,
      DRAM_RAS_N => o_mem_ras_n,
      DRAM_CS_N => o_mem_cs_n,
      DRAM_BA_0 => o_mem_ba0,
      DRAM_BA_1 => o_mem_ba1
    );
 
    process (i_resetn_sys, i_aclk_sys)
    begin
      if rising_edge(i_aclk_sys) then
        if (i_resetn_sys = '0') then

        else
          if i_rd_en = '1' then
             o_memtest_pass_cnt <= s_pass_count;
             o_memtest_fail_cnt <= s_fail_count;
           end if;
        end if;
      end if;
    end process;

  end generate g_generate_sdram_tester_mapper;

  g_generate_sdram_emu_mapper : if g_ext_sdram = 1 generate

    process (o_mem_dat_en, io_mem_dq)
    begin
      if (o_mem_dat_en = '1') then 
        io_mem_dq <= s_mem_dat_out & s_mem_dat_out;
      else
        io_mem_dq <= (others => 'Z');
      end if;
      s_mem_dat_in <= io_mem_dq;
    end process;

    o_mem_cke <= '1';
    o_mem_cs_n <= '0';
    o_mem_ras_n <= s_sdr_cmd(2);
    o_mem_cas_n <= s_sdr_cmd(1);
    o_mem_we_n <= s_sdr_cmd(0);

    o_mem_udq <= s_sdr_adr(12);
    o_mem_ldq <= s_sdr_adr(11);
    o_mem_ba1 <= '0';
    o_mem_ba0 <= '0';

    o_mem_adr <= s_sdr_adr;

  end generate g_generate_sdram_emu_mapper;

  ----------------------------------------------------------------
  -- Clock generator (21.48MHz > 3.58MHz)
  -- pCpuClk should be independent from reset
  ----------------------------------------------------------------

  -- CPUCLK Enabler : 3.58MHz = 21.48MHz / 6
  process (i_resetn_sys, i_aclk_emu)
  variable v_div : std_logic := '0';
  begin
    if (rising_edge(i_aclk_emu) )then
      if (i_resetn_sys = '0' )then
        s_cpucen <= '0';
        s_cpucen_n  <= '0';
        v_div := '0';
      else
        s_cpucen <= v_div and s_clkdiv3(1);
        s_cpucen_n <= not v_div and s_clkdiv3(1);
        if (s_clkdiv3(1) = '1') then
          v_div := not v_div;
        end if;
      end if;
    end if;
  end process;

  -- Turbo CPUCLK Enabler : 5.39MHz = 21.48MHz / 4
  process (i_resetn_sys, i_aclk_emu)
  variable v_div : unsigned(1 downto 0);
  begin
    if (rising_edge(i_aclk_emu)) then
      if (i_resetn_sys = '0')then
        s_cpucen_5m <= '0';
        s_cpucen_5m_n <= '0';
        v_div := "01";
      else
        s_cpucen_5m <= v_div(1) and v_div(0);
        s_cpucen_5m_n <= not v_div(1) and v_div(0);
        v_div := v_div + 1;
      end if;
    end if;
  end process;

  -- Turbo CPUCLK Enabler : 10.79MHz = 21.48MHz / 2
  process (i_resetn_sys, i_aclk_emu)
  begin
    if (rising_edge(i_aclk_emu)) then
      if (i_resetn_sys = '0') then
        s_cpucen_10m <= '1';
        s_cpucen_10m_n <= '0';
      else
        s_cpucen_10m <= not s_cpucen_10m;
        s_cpucen_10m_n <= not s_cpucen_10m_n;
      end if;
    end if;
  end process;

  -- Prescaler : 21.48MHz / 6
  process (i_resetn_sys, i_aclk_emu)
  begin
    if (rising_edge(i_aclk_emu)) then
      if (i_resetn_sys = '0') then
        s_clkdiv3 <= "10";
      else
        if (s_clkdiv3 = "00") then
          s_clkdiv3 <= "10";
        else
          s_clkdiv3 <= s_clkdiv3 - 1;
        end if;
      end if;
    end if;
  end process;

  -- hybrid clock start counter
  process (i_resetn_sys, i_aclk_emu)
  begin
    if (rising_edge(i_aclk_emu)) then
      if (i_resetn_sys = '0') then
        s_hstartcount <= (others => '0');
      else
        if (s_ff_clk21m_cnt(16 downto 0) = "00000000000000000") then
          if (s_mmc_en = '0') then
            s_hstartcount <= "111"; -- begin after 48ms
          elsif (s_hstartcount /= "000") then
            s_hstartcount <= s_hstartcount - 1;
          end if;
        end if;
      end if;
    end if;
  end process;

  -- hybrid clock timeout counter
  process (i_resetn_sys, i_aclk_emu)
  begin
    if (rising_edge(i_aclk_emu)) then
       if (i_resetn_sys = '0') then
         s_htoutcount <=  (others => '0');
       else
         if (s_hstartcount = "000" or s_htoutcount /= "000") then
           if (s_mmc_en = '1') then
             s_htoutcount <= "111"; -- timeout after 96ms
           elsif (s_ff_clk21m_cnt(17 downto 0) = "000000000000000000") then
             s_htoutcount <=  s_htoutcount - 1;
           end if;
         end if;
       end if;
     end if;
  end process;

  -- hybrid clock enabler
  process (i_resetn_sys, i_aclk_emu)
  begin
    if (rising_edge(i_aclk_emu)) then
      if (i_resetn_sys = '0') then
        s_hybridclk_n <=  '1';
      else
        if (s_htoutcount = "000") then
          s_hybridclk_n <= '1';
        else
          s_hybridclk_n <= not s_t_mega_sd;
        end if;
      end if;
    end if;
  end process;

  -- logo speed limiter
  process (i_aclk_emu)
  begin
    if rising_edge(i_aclk_emu) then
      if (s_ff_ldbios_n = '0') then
        if (s_last_rst_sta = s_port_f4_mode) then
          s_logo_rst_cnt <= "11111"; -- 3100ms
        end if;
      else
        if (s_w_10hz = '1' and s_sd_paus = '0' and s_logo_rst_cnt /= "00000") then
          s_logo_rst_cnt <= s_logo_rst_cnt - 1;
        end if;
      end if;
    end if;
  end process;

  process (i_aclk_sys) -- Wrapped into process to remove timing warnings, DmitryP
  begin
    if (i_aclk_sys'event and i_aclk_sys = '0') then
      if (s_logo_rst_cnt = "11111") then
        s_logo_timeout <= "00"; -- 3100ms
      elsif (s_logo_rst_cnt = "10010") then
        s_logo_timeout <= "01"; -- 1800ms
      elsif (s_logo_rst_cnt = "00000") then
        s_logo_timeout <= "10"; -- 0ms
      end if;
    end if;
  end process;

  -- virtual DIP-SW assignment (1/2)
  process (i_aclk_mem)
  begin
    if (i_aclk_mem'event and i_aclk_mem = '0') then
      if (s_first_boot_n /= '1' or s_rst_en = '1') then
        if (s_true_cen = '0' and s_p_slt_wait_n = '0') then
          if (s_ff_ldbios_n = '0' or s_logo_timeout = "00") then -- ultra-fast bootstrap technology
            s_ff_clksel5m_n <= '1';
            s_ff_clksel <= '1';
          elsif (s_logo_timeout = "10") then
            if (s_io42_id212(0) = '0') then
              s_ff_clksel5m_n <= s_io41_id008_n and s_hybridclk_n;
              s_ff_clksel <= s_io42_id212(0) and s_hybridclk_n;
            else
              s_ff_clksel5m_n <= s_io41_id008_n;
              s_ff_clksel <= s_io42_id212(0);
            end if;
          else
            s_ff_clksel5m_n <= '1';
            s_ff_clksel <= '0';
          end if;
        end if;
      end if;
    end if;
  end process;

  -- virtual DIP-SW assignment (2/2)
  process (i_aclk_emu)
  begin
    if (rising_edge(i_aclk_emu)) then
      if (s_sd_paus = '0' and (s_first_boot_n /= '1' or s_rst_en = '1')) then
        if (s_w_10hz = '1') then
          s_cmt_scro <= s_swio_cmt;
          s_display_mode(1) <= s_io42_id212(1);
          s_display_mode(0) <= s_io42_id212(2);
          s_slot1_mode <= s_io42_id212(3);
          s_slot2_mode(1) <= s_io42_id212(4);
          s_slot2_mode(0) <= s_io42_id212(5);
        end if;
      end if;
    end if;
  end process;
	 
  -- keyboard layout assignment
  s_kmap <= s_swio_kmap when rising_edge(i_aclk_emu);

  -- cpu clock assignment
  s_true_cen <= s_cpucen_10m when (s_ff_clksel = '1' and i_resetn_sys /= '0') else -- 10.74 MHz
    s_cpucen_5m when (s_ff_clksel5m_n = '0' and i_resetn_sys /= '0') else --  5.37 MHz
    s_cpucen; --  3.58 MHz

  s_true_cen_n <= s_cpucen_10m_n when (s_ff_clksel = '1' and i_resetn_sys /= '0') else -- 10.74 MHz
    s_cpucen_5m_n when (s_ff_clksel5m_n = '0' and i_resetn_sys /= '0') else --  5.37 MHz
    s_cpucen_n; --  3.58 MHz

  ----------------------------------------------------------------
  -- Reset control
  -- "s_rst_seq" should be cleared when power-on reset
  ----------------------------------------------------------------
  s_p_slt_rst_n <= i_resetn_sys;

  process (i_aclk_mem)
  begin
    if (i_aclk_mem'event and i_aclk_mem = '1') then
      s_ff_mem_seq <= s_ff_mem_seq(0) & (not s_ff_mem_seq(1));
    end if;
  end process;

  process (i_aclk_mem)
  begin
    if (i_aclk_mem'event and i_aclk_mem = '1') then
      if (s_ff_mem_seq = "00") then
        s_free_counter <= s_free_counter + 1;
      end if;
    end if;
  end process;

  -- hard reset timer
  process (s_p_slt_rst_n, i_aclk_emu, s_hard_rst_cnt)
  begin
    if (s_rst_key_lock = '0') then
      if (s_p_slt_rst_n /= '0') then
        s_hold_rst_en <= '0';
        if (s_hard_rst_cnt /= "0011" or s_hard_rst_cnt /= "0010") then
          s_hard_rst_cnt <= "0000";
        end if;
      elsif (i_aclk_emu'event and i_aclk_emu = '1') then
        if (s_hold_rst_en = '0') then
          if i_p_cold_reset = '1' then
            s_hard_rst_cnt <= "0011";
          else
            s_hard_rst_cnt <= "1110"; -- 1500ms hold reset
          end if;
          s_hold_rst_en <= '1';
        elsif (s_w_10hz = '1' and s_hard_rst_cnt /= "0001") then
          s_hard_rst_cnt <= s_hard_rst_cnt - 1;
        end if;
      end if;
    end if;
  end process;

  process (i_aclk_mem)
  begin
    if rising_edge(i_aclk_mem) then
      -- Control reset via register
      if (s_cpu_reset_reg = '1') then
        s_rst_seq <= (others => '0');      
      else
        if (s_hard_rst_cnt = "0011") then -- 200ms from "0001"
          if (s_w_10hz = '1' and s_rst_seq /= "00000") then
            s_rst_seq <= (others => '0');
          end if;
        else
          if (s_ff_mem_seq = "00" and s_free_counter = X"FFFF" and s_rst_seq /= "11111") then
            s_rst_seq <= s_rst_seq + 1; -- 3ms (= 65536 / 21.48MHz)
          end if;
        end if;
      end if;
    end if;
  end process;

  process (i_aclk_emu)
  begin
    if rising_edge(i_aclk_emu) then
      s_reset <= '0';
      if (s_p_slt_rst_n = '0' and s_rst_key_lock = '0' and s_hard_rst_cnt /= "0001") then
        s_reset <= '1';
      elsif (s_swio_reset_n = '0' or s_hard_rst_cnt = "0011" or s_hard_rst_cnt = "0010" or s_rst_seq /= "11111") then
        s_reset <= '1';
      end if;
    end if;
  end process;

  process (i_resetn_sys, i_aclk_sys)
  begin
    if rising_edge(i_aclk_sys) then
      if (i_resetn_sys = '0') then
        s_cpu_reset_reg <= '0';
        p_joy_a <= (others => '0');
        p_joy_b <= (others => '0');
      else
        if i_wr_en = '1' then
          if i_emu_control_en = '1' then
            s_cpu_reset_reg <= i_register_data_out(c_control_reg_cpu_reset_bit);
          end if;
          if i_joystick_en = '1' then
            p_joy_a <= i_register_data_out(c_joy1_msb_bit downto c_joy1_lsb_bit);
            p_joy_b <= i_register_data_out(c_joy2_msb_bit downto c_joy2_lsb_bit);
          end if;
        end if;
      end if;
    end if;
  end process;

  ----------------------------------------------------------------
  -- Operation mode
  ----------------------------------------------------------------

  -- free run counter
  process (i_resetn_sys, i_aclk_emu)
  begin
    if (rising_edge(i_aclk_emu)) then
      if (i_resetn_sys = '0') then
        s_ff_clk21m_cnt <= (others => '0');
      else
        s_ff_clk21m_cnt <= s_ff_clk21m_cnt + 1;
      end if;
    end if;
  end process;

  -- RTC lfsr counter => range 0 to 2147726 => 100ms
  -- http://outputlogic.com/?page_id=275
  s_rtcbase_d0 <= (s_rtcbase_cnt(21) xnor s_rtcbase_cnt(20));
  s_w_10hz <= '1' when (s_rtcbase_cnt = "0010001111000001111010") else '0';

  process (i_aclk_emu)
  begin
    if (i_aclk_emu'event and i_aclk_emu = '1') then
      if (s_w_10hz = '1') then
        s_rtcbase_cnt <= (others => '0');
      else
        s_rtcbase_cnt <= (s_rtcbase_cnt( 20 downto 0 ) & s_rtcbase_d0);
      end if;
    end if;
  end process;

  -- flash counter
  process (i_aclk_emu)
  begin
    if (i_aclk_emu'event and i_aclk_emu = '1') then
      if (s_sd_paus = '0') then
        if (s_ff_clksel5m_n = '1') then
          s_flash_cnt <= "0000";
        else
          s_flash_cnt <= "0100";
        end if;
      elsif (s_w_10hz = '1') then
        if (s_flash_cnt = "0000") then
          s_flash_cnt <= "1011"; -- 1200ms
        else
          s_flash_cnt <= s_flash_cnt - 1;
        end if;
      end if;
    end if;
  end process;

  -- green level counter
  process (i_resetn_sys, i_aclk_emu)
  begin
    if (rising_edge(i_aclk_emu)) then
      if (i_resetn_sys = '0') then
        s_green_lv_cnt <= "0000";
      else
        if (s_green_lv_en = '1') then
          s_green_lv_cnt <= "1111";
        elsif (s_w_10hz = '1' and s_green_lv_cnt /= "0000") then
          s_green_lv_cnt <= s_green_lv_cnt - 1; -- 1600ms
        end if;
      end if;
    end if;
  end process;

  -- green level assignment
  process (i_resetn_sys, i_aclk_emu)
  begin
    if (rising_edge(i_aclk_emu)) then
      if (i_resetn_sys = '0') then
        s_green_lv <= (others => '0');
      else
        case s_lev_ctrl is
          when "111" => s_green_lv <= "1111111";
          when "110" => s_green_lv <= "0111111";
          when "101" => s_green_lv <= "0011111";
          when "100" => s_green_lv <= "0001111";
          when "011" => s_green_lv <= "0000111";
          when "010" => s_green_lv <= "0000011";
          when "001" => s_green_lv <= "0000001";
          when others => s_green_lv <= "0000000";
        end case;
      end if;
    end if;
  end process;

  -- reset enable wait counter
  --
  --  s_ff_rst_seq(0)   X___X~~~X~~~X___X___X ...
  --  s_ff_rst_seq(1)   X___X___X~~~X~~~X___X ...
  --
  process (i_resetn_sys, i_aclk_emu)
  begin
    if (rising_edge(i_aclk_emu)) then
      if (i_resetn_sys = '0') then
        s_ff_rst_seq <= "00";
      else
        if (s_w_10hz = '1') then
          s_ff_rst_seq <= s_ff_rst_seq(0) & (not s_ff_rst_seq(1));
        else
          --  hold
        end if;
      end if;
    end if;
  end process;

  -- power LED
  process (i_resetn_sys, i_aclk_emu, s_zemmix_neo)
  begin
    if (rising_edge(i_aclk_emu)) then
      if (i_resetn_sys = '0') then
        o_p_led_pwr <= i_aclk_emu or s_zemmix_neo; -- lights test holding the hard reset
      else
        if (s_sd_paus = '1') then
          if (s_paus_flash = '1' and s_zemmix_neo = '0') then
            o_p_led_pwr <= s_faded_red; -- Pause        is Flash + Faded Red
          else
            o_p_led_pwr <= '0';
          end if;
        -- Lights On/Off toggle
        elsif (s_red_sta = '1' and s_paus = '0' and s_green_lv_cnt = "0000") then
--        elsif (ff_clksel5m_n = '0') then -- test for tMegaSD
            if (s_zemmix_neo = '1') then
              o_p_led_pwr <= '1'; -- On
            else
              o_p_led_pwr <= s_faded_red; -- 5.37MHz On   is Faded Red only
            end if;
        else
--        o_p_led_pwr <= s_logo_timeout(0); -- test of logo speed limiter
          o_p_led_pwr <= '0'; -- Off / Blink
        end if;
      end if;
    end if;
  end process;

  -- reset enabler
  process (i_resetn_sys, i_aclk_emu)
  begin
    if (rising_edge(i_aclk_emu)) then
      if (i_resetn_sys = '0') then
        s_rst_ena <= '0';
      else
        if (s_ff_rst_seq = "11" and s_warm_reset /= '1') then
          s_rst_ena <= '1'; -- RstEna change to 1 after 200ms from power on
          s_first_boot_n <= '1';
        else
          --  hold
        end if;
      end if;
    end if;
  end process;

  -- DIP SW latch
  s_ff_dip_req <= not i_p_dip when rising_edge(i_aclk_emu);

  -- LEDs luminance
  process (i_aclk_emu)
  begin
    if (i_aclk_emu'event and i_aclk_emu = '1') then
      if (s_zemmix_neo = '0') then
        s_faded_green <= s_ff_clk21m_cnt(12);
        s_faded_red <= s_ff_clk21m_cnt(0);
      else
        s_faded_green <= '1';
        s_faded_red <= '1';
      end if;
    end if;
  end process;

  -- Kana keyboard layout: 1=JIS layout
  s_w_key_mode <= '1';

  -- Pause Flash (800ms On + 400ms Off = 1200ms per cycle)
  s_paus_flash <= '0' when (s_flash_cnt(3 downto 2) = "00") else '1';

  -- Blink assignment
  s_mmc_led_en <= ((s_ff_clk21m_cnt(20) or (not s_ff_clk21m_cnt(19))) and s_faded_green)
      when (s_blink_en = '1' and s_mmc_en = '1' )else
           (s_mmc_mode and s_faded_green)
           when (s_blink_en = '0' and s_lights_mode = '0') else
           (s_green_leds(7) and s_faded_green)
           when (s_lights_mode = '1') else '0';

  -- LEDs assignment
  o_p_led <= "000" & -- Pause Flash for Zemmix Neo
    (s_paus_flash and s_faded_green) &
    "0000" when (s_sd_paus = '1' and s_zemmix_neo = '1') else

    -- Lights On/Off toggle (active when 'SdPaus' is not used)
    "00000000" when (s_paus = '1') else

    s_green_leds(0) &  -- LightsMode + Blink for Zemmix Neo
    s_green_leds(1) &
    s_green_leds(2) &
    s_green_leds(3) &
    s_green_leds(4) &
    s_green_leds(5) &
    s_green_leds(6) &
    s_mmc_led_en when (s_lights_mode = '1' and s_zemmix_neo = '1') else

    s_mmc_led_en &  -- Blink + LightsMode for 1chipMSX
    (s_green_leds(6) and s_faded_green) &
    (s_green_leds(5) and s_faded_green) &
    (s_green_leds(4) and s_faded_green) &
    (s_green_leds(3) and s_faded_green) &
    (s_green_leds(2) and s_faded_green) &
    (s_green_leds(1) and s_faded_green) &
    (s_green_leds(0) and s_faded_green) when (s_lights_mode = '1') else

    s_green_lv(0) &  -- Volume + High-Speed Level + Blink for Zemmix Neo
    s_green_lv(1) &
    s_green_lv(2) &
    s_green_lv(3) &
    s_green_lv(4) &
    s_green_lv(5) &
    s_green_lv(6) &
    s_mmc_led_en when (s_green_lv_cnt /= "0000" and s_zemmix_neo = '1') else

    s_mmc_led_en &  -- Blink + Volume + High-Speed Level for 1chipMSX
    (s_green_lv(6) and s_free_counter(1)) &
    (s_green_lv(5) and s_free_counter(1)) &
    (s_green_lv(4) and s_free_counter(1)) &
    (s_green_lv(3) and s_free_counter(1)) &
    (s_green_lv(2) and s_free_counter(1)) &
    (s_green_lv(1) and s_free_counter(1)) &
    (s_green_lv(0) and s_free_counter(1)) when (s_green_lv_cnt /= "0000") else

    -- lights test holding the hard reset
    (others => s_free_counter(0)) when (s_p_slt_rst_n = '0' and s_rst_key_lock = '0') else

    s_io42_id212(0) &  -- Virtual DIP-SW (Auto) + Blink for Zemmix Neo
    s_display_mode(1) &
    s_display_mode(0) &
    s_slot1_mode &
    s_slot2_mode(1) &
    s_slot2_mode(0) &
    s_full_ram &
    s_mmc_led_en when (s_zemmix_neo = '1' )else

    s_mmc_led_en &  -- Blink + Virtual DIP-SW (Auto) for 1chipMSX
    (s_full_ram and s_faded_green) &
    (s_slot2_mode(0) and s_faded_green) &
    (s_slot2_mode(1) and s_faded_green) &
    (s_slot1_mode and s_faded_green) &
    (s_display_mode(0) and s_faded_green) &
    (s_display_mode(1) and s_faded_green) &
    (s_io42_id212(0) and s_faded_green);

  ----------------------------------------------------------------
  -- MSX cartridge slot control
  ----------------------------------------------------------------
  s_p_slt_rfsh_n <= s_cpu_rfsh_n;
  s_p_slt_int_n <= s_p_vdp_int_n;

  s_cpu_di <= s_dbi when (s_p_slt_iorq_n = '0' and s_bus_dir = '1') else
    s_dbi when (s_p_slt_merq_n = '0' and s_pri_slt_num = "00") else
    s_dbi when (s_p_slt_merq_n = '0' and s_pri_slt_num = "11") else
    s_dbi when (s_p_slt_merq_n = '0' and s_pri_slt_num = "01" and s_scc1_type /= "00") else
    s_dbi when (s_p_slt_merq_n = '0' and s_pri_slt_num = "10" and s_slot2mode /= "00") else
    (others => '1');

  ----------------------------------------------------------------
  -- Z80 CPU wait control
  ----------------------------------------------------------------
  process (i_aclk_emu, s_true_cen, s_reset)
  variable v_i_cpu_m1_n : std_logic; -- slack 1.759ns
  variable v_j_slt_merq_n : std_logic;
  variable v_j_slt_iorq_n : std_logic;
  variable v_count : unsigned(3 downto 0); -- slack 0.822ns
  begin
    if (rising_edge(i_aclk_emu) and s_true_cen = '1') then
      if (s_reset = '1') then
        v_i_cpu_m1_n := '1';
        v_j_slt_iorq_n := '1';
        v_j_slt_merq_n := '1';
        v_count := "0000";
        s_p_slt_wait_n <= '1';
      else
        if (s_p_slt_merq_n = '0' and v_j_slt_merq_n = '1') then
          if (s_ff_clksel = '1') then
            v_count := s_custom_speed; -- 8 MHz until 4 MHz
          elsif (s_ff_clksel5m_n = '0' and (s_i_slt_scc1 = '1' or s_i_slt_scc2 = '1')) then
            v_count := "0001";
          end if;
        elsif (s_p_slt_iorq_n = '0' and v_j_slt_iorq_n = '1') then -- wait for external bus
          if (s_ff_clksel = '1') then
            v_count := "0011";
          elsif (s_ff_clksel5m_n = '0') then
            v_count := "0110";
          end if;
        elsif (v_count /= "0000") then -- countdown timer
          v_count := v_count - 1;
        end if;

        if (s_cpu_m1_n = '0' and v_i_cpu_m1_n = '1') then
          s_p_slt_wait_n <= '0';
        elsif (v_count /= "0000") then
          s_p_slt_wait_n <= '0';
        elsif ((s_ff_clksel = '1' or s_ff_clksel5m_n = '0') and s_opll_req = '1' and s_opll_ack = '0') then
          s_p_slt_wait_n <= '0';
        elsif (s_erm_req = '1' and s_adr(15 downto 13) = "010" and s_mmc_act = '1') then
          s_p_slt_wait_n <= '0';
--      elsif (SdPaus = '1') then -- dismissed dangerous function
--        s_p_slt_wait_n <= '0';
        elsif (i_ddr_mem_busy = '1') and (g_ext_sdram = 0) then
          s_p_slt_wait_n <= '0';
        elsif (s_mmc_ps_busy = '1') and (g_sd_via_ps = 1) then -- this is only for using SD-CARD via MIO pins
          s_p_slt_wait_n <= '0';
        else
          s_p_slt_wait_n <= '1';
        end if;

        v_i_cpu_m1_n := s_cpu_m1_n;
        v_j_slt_iorq_n := s_p_slt_iorq_n;
        v_j_slt_merq_n := s_p_slt_merq_n;
      end if;
    end if;
  end process;

  ----------------------------------------------------------------
  -- On chip internal bus control
  ----------------------------------------------------------------
  process (i_aclk_emu, s_reset)
  variable v_exp_dec : std_logic;
  begin
    if (rising_edge(i_aclk_emu)) then
      if (s_reset = '1') then
        s_i_slt_rfsh_n <= '1';
        s_i_slt_merq_n <= '1';
        s_i_slt_iorq_n <= '1';
        s_x_slt_rd_n <= '1';
        s_x_slt_wr_n <= '1';
        s_i_slt_adr <= (others => '1');
        s_i_slt_dat <= (others => '1');

        s_iack <= '0';

        s_dlydbi <= (others => '1');
        v_exp_dec := '0';
      else
        -- MSX slot signals
        s_i_slt_rfsh_n <= s_p_slt_rfsh_n;
        s_i_slt_merq_n <= s_p_slt_merq_n;
        s_i_slt_iorq_n <= s_p_slt_iorq_n;
        s_x_slt_rd_n <= s_p_slt_rd_n;
        s_x_slt_wr_n <= s_p_slt_wr_n;
        s_i_slt_adr <= s_p_slt_adr;
        s_i_slt_dat <= s_cpu_do;

        if (s_i_slt_merq_n  = '1' and s_i_slt_iorq_n = '1') then
          s_iack <= '0';
        elsif (ack = '1') then
          s_iack <= '1';
        end if;

        -- input assignments for internal devices
        if (s_mem = '1' and v_exp_dec = '1') then
          s_dlydbi <= s_exp_dbi;
        elsif (s_mem = '1' and s_i_slt_bot = '1') then -- IPL-ROM
          s_dlydbi <= s_rom_dbi;
        elsif (s_mem = '1' and s_i_slt_erm = '1' and s_mmc_en = '1') then -- MegaSD
          if g_sd_via_ps = 0 then
            s_dlydbi <= s_mmc_dbi;
          else
            s_dlydbi <= s_mmc_ps_do;
          end if;
        elsif (s_mem = '0' and s_adr(7 downto 2) = "100110") then -- VDP (V9938/V9958)
          s_dlydbi <= s_vdp_dbi;
        elsif (s_mem = '0' and s_adr(7 downto 2) = "101000") then -- PSG (AY-3-8910)
          s_dlydbi <= s_psg_dbi;
        elsif (s_mem = '0' and s_adr(7 downto 2) = "101010") then -- PPI (8255)
          s_dlydbi <= s_ppi_dbi;
        elsif (s_mem = '0' and s_adr(7 downto 2) = "110110" and s_jis2_en = '1') then -- Kanji-data (JIS1+JIS2)
          s_dlydbi <= s_kan_dbi;
        elsif (s_mem = '0' and s_adr(7 downto 1) = "1101100") then -- Kanji-data (JIS1 only)
          s_dlydbi <= s_kan_dbi;
        elsif (s_mem = '0' and s_adr(7 downto 2) = "111111" and s_full_ram = '0') then -- Memory-mapper 2048 kB
          s_dlydbi <= '1' & s_map_dbi(6 downto 0);
        elsif (s_mem = '0' and s_adr(7 downto 2) = "111111") then -- Memory-mapper 4096 kB
          s_dlydbi <= s_map_dbi;
        elsif (s_mem = '0' and s_adr(7 downto 1) = "1011010") then -- RTC (RP-5C01)
          s_dlydbi <= s_rtc_dbi;
        elsif (s_mem = '0' and s_adr(7 downto 1) = "1110011") then -- System timer (S1990)
          s_dlydbi <= s_systim_dbi;
        elsif (s_mem = '0' and s_adr(7 downto 1) = "1010010") then -- turboR PCM device
          s_dlydbi <= s_tr_pcm_dbi;
        elsif (s_mem = '0' and s_adr(7 downto 4) = "0100" and s_io40_n /= "11111111") then -- Switched I/O ports
          s_dlydbi <= s_swio_dbi;
        elsif (s_mem = '0' and s_adr(7 downto 0) = "10100111" and s_port_f4_mode = '1') then -- Pause R800 (read only)
          s_dlydbi <= (others => '0');
        elsif (s_mem = '0' and s_adr(7 downto 0) = "11110100" and s_port_f4_mode = '1') then -- Port F4 normal (Z80 mode)
          s_dlydbi <= s_port_f4_bit7 & "0000000";
        elsif (s_mem = '0' and s_adr(7 downto 0) = "11110100") then -- Port F4 inverted
          s_dlydbi <= s_port_f4_bit7 & "1111111";
        else
          s_dlydbi <= (others => '1');
        end if;

        if (s_adr = X"FFFF") then
          v_exp_dec := '1';
        else
          v_exp_dec := '0';
        end if;
      end if;
    end if;
  end process;

  ----------------------------------------------------------------
  process (i_aclk_emu, s_reset)
  begin
    if (rising_edge(i_aclk_emu)) then
      if (s_reset = '1') then
        s_j_slt_scc1 <= '0';
        s_j_slt_scc2 <= '0';
        s_j_slt_mem <= '0';
        s_wrt <= '0';
      else
        if (s_mem = '1' and s_i_slt_scc1 = '1') then
          s_j_slt_scc1 <= '1';
        else
          s_j_slt_scc1 <= '0';
        end if;
        if (s_mem = '1' and s_i_slt_scc2 = '1') then
          s_j_slt_scc2 <= '1';
        else
          s_j_slt_scc2 <= '0';
        end if;
        if (s_mem = '1' and s_i_slt_erm = '1') then
          if (s_mmc_en = '1' and s_adr(15 downto 13) = "010") then
            s_j_slt_mem <= '0';
          elsif (s_mmc_mode = '1' or s_ff_ldbios_n = '0') then -- enable SD/MMC drive
            s_j_slt_mem <= '1';
          else -- disable SD/MMC drive
            s_j_slt_mem <= '0';
          end if;
        elsif (s_mem = '1' and (s_i_slt_map = '1' or s_rom_main = '1' or s_rom_opll = '1' or s_rom_extd = '1' or s_rom_xbas = '1' or s_rom_free = '1')) then
          s_j_slt_mem <= '1';
        else
          s_j_slt_mem <= '0';
        end if;
        if (s_req = '0') then
          s_wrt <= not s_p_slt_wr_n; -- 1=write, 0=read
        end if;
      end if;
    end if;
  end process;

  -- access request, CPU > Components
  s_req <= '1' when (((s_i_slt_merq_n = '0') or (s_i_slt_iorq_n = '0')) and
    ((s_x_slt_rd_n = '0') or (s_x_slt_wr_n = '0')) and s_iack = '0') else '0';

  s_mem <= s_i_slt_iorq_n; -- 1=memory area, 0=i/o area
  s_dbo <= s_i_slt_dat; -- CPU data (CPU > device)
  s_adr <= s_i_slt_adr; -- CPU address (CPU > device)

  -- access acknowledge, Components > CPU
  s_ack <= s_ram_ack when (s_ram_req = '1') else -- ErmAck, MapAck, KanAck
    s_scc1_ack when (s_mem = '1' and s_i_slt_scc1 = '1') else -- Scc1Ack
    s_scc2_ack when (s_mem = '1' and s_i_slt_scc2 = '1') else -- Scc2Ack
    s_opll_ack when (s_opll_req = '1') else -- OpllAck
    s_req; -- PsgAck, PpiAck, MapAck, VdpAck, RtcAck, ...

  s_dbi <= s_scc1_dbi when (s_j_slt_scc1 = '1') else
    s_scc2_dbi when (s_j_slt_scc2 = '1') else
    s_ram_dbi  when (s_j_slt_mem  = '1') else
    s_dlydbi;

  ----------------------------------------------------------------
  -- port F4
  ----------------------------------------------------------------
  process (i_aclk_emu, i_p_cold_reset)
  begin
    if (rising_edge(i_aclk_emu)) then
      if (i_p_cold_reset = '1') then
        s_port_f4_bit7 <= '0';
      else
        if (s_port_f4_req = '1' and s_wrt = '1') then
          s_port_f4_bit7 <= s_dbo(7);
        end if;
      end if;
    end if;
  end process;

  ----------------------------------------------------------------
  -- PPI(8255) / primary-slot, keyboard, 1 bit sound port
  ----------------------------------------------------------------
  process (i_aclk_emu, s_reset)
  begin
    if (i_aclk_emu'event and i_aclk_emu = '1') then
      if (s_reset = '1') then
        s_ppi_port_a <= "11111111"; -- primary slot : page 0 => boot-rom, page 1/2 => ese-mmc, page 3 => mapper
        s_ppi_port_c <= (others => '0');
        s_ff_ldbios_n <= '0'; -- OCM-BIOS is ready to be loaded
      else
        -- I/O port access on A8-ABh ... PPI(8255) access
        if (s_ppi_req = '1') then
          if (s_wrt = '1' and s_adr(1 downto 0) = "00") then
            s_ppi_port_a <= s_dbo;
            s_ff_ldbios_n <= '1'; -- OCM-BIOS is done!
          elsif (s_wrt = '1' and s_adr(1 downto 0) = "10") then
            s_ppi_port_c <= s_dbo;
          elsif (s_wrt = '1' and s_adr(1 downto 0) = "11" and s_dbo(7) = '0') then
            case s_dbo(3 downto 1) is
              when "000" => s_ppi_port_c(0) <= s_dbo(0); -- key_matrix Y(0)
              when "001" => s_ppi_port_c(1) <= s_dbo(0); -- key_matrix Y(1)
              when "010" => s_ppi_port_c(2) <= s_dbo(0); -- key_matrix Y(2)
              when "011" => s_ppi_port_c(3) <= s_dbo(0); -- key_matrix Y(3)
              when "100" => s_ppi_port_c(4) <= s_dbo(0); -- cassete motor on (0=On,1=Off)
              when "101" => s_ppi_port_c(5) <= s_dbo(0); -- cassete audio out
              when "110" => s_ppi_port_c(6) <= s_dbo(0); -- CAPS lamp (0=On,1=Off)
              when others => s_ppi_port_c(7) <= s_dbo(0); -- 1 bit sound port
            end case;
          end if;
        end if;
      end if;
    end if;
  end process;

  o_p_caps <= not s_ppi_port_c(6);

  -- I/O port access on A8-ABh ... PPI(8255) register read
  s_ppi_dbi <= s_ppi_port_a when s_adr(1 downto 0) = "00" else
    s_ppi_port_b when s_adr(1 downto 0) = "01" else
    s_ppi_port_c when s_adr(1 downto 0) = "10" else
    (others => '1');

  ----------------------------------------------------------------
  -- Expansion slot
  ----------------------------------------------------------------

  -- slot #0
  process (i_aclk_emu, s_reset)
  begin
    if ( rising_edge(i_aclk_emu)) then
      if (s_reset = '1') then
        s_exp_slot0 <= (others => '0');
      else
        -- Memory mapped I/O port access on FFFFh ... expansion slot register (master mode)
        if (s_req = '1' and s_i_slt_merq_n = '0' and s_wrt = '1' and s_adr = X"FFFF") then
          if (s_ppi_port_a(7 downto 6) = "00") then
            if (s_slot0_mode = '1') then
              s_exp_slot0 <= s_dbo;
            else
              s_exp_slot0 <= (others => '0');
            end if;
          end if;
        end if;
      end if;
    end if;
  end process;

  -- slot #3
  process (i_aclk_emu, s_reset)
  begin
    if (rising_edge(i_aclk_emu)) then
      if (s_reset = '1') then
        s_exp_slot3 <= "00101011"; -- primary slot : page 0 => ipl-rom, page 1/2 => megasd, page 3 => mapper
      else
        -- Memory mapped I/O port access on FFFFh ... expansion slot register (master mode)
        if (s_req = '1' and s_i_slt_merq_n = '0' and s_wrt = '1' and s_adr = X"FFFF") then
          if (s_ppi_port_a(7 downto 6) = "11") then
            s_exp_slot3 <= s_dbo;
          end if;
        end if;
      end if;
    end if;
  end process;

  -- primary slot number (master mode)
  with s_adr(15 downto 14) select s_pri_slt_num <=
    s_ppi_port_a(1 downto 0) when "00",
    s_ppi_port_a(3 downto 2) when "01",
    s_ppi_port_a(5 downto 4) when "10",
    s_ppi_port_a(7 downto 6) when others;

  -- expansion slot number : slot 0 (master mode)
  with s_adr(15 downto 14) select s_exp_slt_num0 <=
    s_exp_slot0(1 downto 0) when "00",
    s_exp_slot0(3 downto 2) when "01",
    s_exp_slot0(5 downto 4) when "10",
    s_exp_slot0(7 downto 6) when others;

  -- expansion slot number : slot 3 (master mode)
  with s_adr(15 downto 14) select s_exp_slt_num3 <=
    s_exp_slot3(1 downto 0) when "00",
    s_exp_slot3(3 downto 2) when "01",
    s_exp_slot3(5 downto 4) when "10",
    s_exp_slot3(7 downto 6) when others;

  -- expansion slot register read
  with s_ppi_port_a(7 downto 6) select s_exp_dbi <=
    not s_exp_slot0 when "00",
    not s_exp_slot3 when "11",
    (others => '1') when others;

  ----------------------------------------------------------------
  --  Slot/Page Decode
  ----------------------------------------------------------------
  with (s_adr(15 downto 14)) select s_w_page_dec <=
    "0001" when "00",
    "0010" when "01",
    "0100" when "10",
    "1000" when "11",
    "XXXX" when others;

  with (s_pri_slt_num) select s_w_prislt_dec <=
    "0001" when "00",
    "0010" when "01",
    "0100" when "10",
    "1000" when "11",
    "XXXX" when others;

  with (s_exp_slt_num0) select s_w_expslt0_dec <=
    "0001" when "00",
    "0010" when "01",
    "0100" when "10",
    "1000" when "11",
    "XXXX" when others;

  with (s_exp_slt_num3) select s_w_expslt3_dec <=
    "0001" when "00",
    "0010" when "01",
    "0100" when "10",
    "1000" when "11",
    "XXXX" when others;

  ----------------------------------------------------------------
  --  Address Decode for CPU
  ----------------------------------------------------------------
  -- Slot0-X
  s_rom_main <= s_mem when ((s_w_prislt_dec(0) and (s_w_expslt0_dec(0) or (not s_slot0_mode)) and (s_w_page_dec(0) or s_w_page_dec(1))) = '1') else '0'; -- 0-0 (0000-7FFFh)    32 kB  MSX2P   .ROM / MSXTR   .ROM
  s_rom_opll <= s_mem when ((s_w_prislt_dec(0) and s_w_expslt0_dec(2) and s_slot0_mode and s_w_page_dec(1)) = '1') else '0'; -- 0-2 (4000-7FFFh)    16 kB  MSX2PMUS.ROM / MSXTRMUS.ROM
  s_rom_free <= s_mem when ((s_w_prislt_dec(0) and s_w_expslt0_dec(3) and s_slot0_mode and s_w_page_dec(1)) = '1') else '0'; -- 0-3 (4000-7FFFh)    16 kB  FREE16KB.ROM / MSXTROPT.ROM
  -- Slot1
  s_i_slt_scc1 <= s_mem when ((s_w_prislt_dec(1) and (s_w_page_dec(1) or s_w_page_dec(2))) = '1' and s_scc1_type /= "00") else '0';
  -- Slot2
  s_i_slt_scc2 <= s_mem when ((s_w_prislt_dec(2) and (s_w_page_dec(1) or s_w_page_dec(2))) = '1' and s_slot2_mode /= "00") else '0';
  -- Slot3-X
  s_i_slt_map <= s_mem when ((s_w_prislt_dec(3) and s_w_expslt3_dec(0)) = '1' and s_adr /= X"FFFF") else '0'; -- 3-0 (0000-FFFFh)  4096 kB  Internal Mapper
  s_rom_extd <= s_mem when ((s_w_prislt_dec(3) and s_w_expslt3_dec(1) and (s_w_page_dec(0) or s_w_page_dec(1) or s_w_page_dec(2))) = '1') else '0'; -- 3-1 (0000-BFFFh)    48 kB  (MSX2PEXT.ROM or MSXTREXT.ROM) + MSXKANJI.ROM
  s_i_slt_erm <= s_mem when ((s_w_prislt_dec(3) and s_w_expslt3_dec(2) and (s_w_page_dec(1) or s_w_page_dec(2))) = '1') else '0'; -- 3-2 (4000-BFFFh)   128 kB  (MEGASDHC.ROM + FILL64KB.ROM) or NEXTOR16.ROM
  s_rom_xbas <= s_mem when ((s_w_prislt_dec(3) and s_w_expslt3_dec(3) and s_w_page_dec(1) and s_ff_ldbios_n) = '1') else '0'; -- 3-3 (4000-7FFFh)    16 kB  XBASIC2 .ROM / XBASIC21.ROM
  s_i_slt_bot <= s_mem when ((s_w_prislt_dec(3) and s_w_expslt3_dec(3) and (s_w_page_dec(0) or s_w_page_dec(3)) and (not s_ff_ldbios_n)) = '1') else '0'; -- 3-3 (0000-FFFFh)     1 kB  IPL-ROM (pre-boot state)
  -- I/O
  s_rom_kanj <=  not s_mem when (s_adr(7 downto 2) = "110110") else '0';

    -- RamX / RamY access request
  s_ram_req <= s_scc1_ram or s_scc2_ram or s_erm_ram or s_map_ram or s_rom_req or s_kan_rom;

  -- access request to component
  s_vdp_req <= s_req when (s_mem = '0' and s_adr(7 downto 2) = "100110") else '0'; -- I/O:98-9Bh   / VDP (V9938/V9958)
  s_psg_req <= s_req when (s_mem = '0' and s_adr(7 downto 2) = "101000") else '0'; -- I/O:A0-A3h   / PSG (AY-3-8910)
  s_ppi_req <= s_req when (s_mem = '0' and s_adr(7 downto 2) = "101010") else '0'; -- I/O:A8-ABh   / PPI (8255)
  s_opll_req <= s_req when (s_mem = '0' and s_adr(7 downto 1) = "0111110" and s_slot0_mode = '1') else '0'; -- I/O:7C-7Dh   / OPLL (YM2413)
  s_kan_req <= s_req when (s_mem = '0' and s_adr(7 downto 2) = "110110") else '0'; -- I/O:D8-DBh   / Kanji-data
  s_rom_req <= s_req when ((s_rom_main or s_rom_opll or s_rom_extd or s_rom_xbas or s_rom_free) = '1') else '0';
  s_map_req <= s_req when (s_mem = '0' and s_adr(7 downto 2) = "111111") else -- I/O:FC-FFh   / Memory-mapper
    s_req when (s_i_slt_map = '1') else '0'; -- MEM:         / Memory-mapper
  s_scc1_req <= s_req when (s_i_slt_scc1 = '1') else '0'; -- MEM:         / ESE-SCC1
  s_scc2_req <= s_req when (s_i_slt_scc2 = '1') else '0'; -- MEM:         / ESE-SCC2
  s_erm_req <= s_req when (s_i_slt_erm = '1') else '0'; -- MEM:         / ESE-RAM, MegaSD
  s_rtc_req <= s_req when (s_mem = '0' and s_adr(7 downto 1) = "1011010") else '0'; -- I/O:B4-B5h   / RTC (RP-5C01)
  s_systim_req <= s_req when (s_mem = '0' and s_adr(7 downto 1) = "1110011") else '0'; -- I/O:E6-E7h   / System timer (S1990)
  s_swio_req <= s_req when (s_mem = '0' and s_adr(7 downto 4) = "0100") else '0'; -- I/O:40-4Fh   / Switched I/O ports
  s_port_f4_req <= s_req when (s_mem = '0' and s_adr(7 downto 0) = "11110100") else '0'; -- I/O:F4h      / Port F4 device
  s_tr_pcm_req <= s_req when (s_mem = '0' and s_adr(7 downto 1) = "1010010") else '0'; -- I/O:A4h-A5h  / turboR PCM device
  --  s_pcm_req <=  s_req when (s_mem = '0' and s_adr(7 downto 1) = "1110100") else '0';  -- I/O:E8-E9h   / Test PCM

  s_bus_dir <= '1' when (s_p_slt_adr(7 downto 2) = "100110") else  -- I/O:98-9Bh / VDP (V9938/V9958)
    '1' when (s_p_slt_adr(7 downto 2) = "101000") else -- I/O:A0-A3h / PSG (AY-3-8910)
    '1' when (s_p_slt_adr(7 downto 2) = "101010") else -- I/O:A8-ABh / PPI (8255)
    '1' when (s_p_slt_adr(7 downto 2) = "110110" and s_jis2_en = '1') else -- I/O:D8-DBh / Kanji-data (JIS1+JIS2)
    '1' when (s_p_slt_adr(7 downto 1) = "1101100") else -- I/O:D8-D9h / Kanji-data (JIS1 only)
    '1' when (s_p_slt_adr(7 downto 2) = "111111") else -- I/O:FC-FFh / Memory-mapper
    '1' when (s_p_slt_adr(7 downto 1) = "1011010") else -- I/O:B4-B5h / RTC (RP-5C01)
    '1' when (s_p_slt_adr(7 downto 1) = "1110011") else -- I/O:E6-E7h / System timer (S1990)
    '1' when (s_p_slt_adr(7 downto 4) = "0100" and s_io40_n /= "11111111") else -- I/O:40-4Fh / Switched I/O ports
    '1' when (s_p_slt_adr(7 downto 0) = "10100111" and s_port_f4_mode = '1') else -- I/O:A7h    / Pause R800 (read only)
    '1' when (s_p_slt_adr(7 downto 0) = "11110100") else -- I/O:F4h    / Port F4 device
    '1' when (s_p_slt_adr(7 downto 1) = "1010010") else -- I/O:A4-A5h / turboR PCM device
    -- '1' when (s_p_slt_adr(7 downto 1) = "1110100") else -- I/O:E8-E9h / Test PCM
    '0';

  ----------------------------------------------------------------
  -- Video output
  ----------------------------------------------------------------
----s_v9938_n <= '0'; -- '0' is V9938 MSX2 VDP
  s_v9938_n <= '1'; -- '1' is V9958 MSX2+/tR VDP

--  process (clk21m)
--  begin
--    if( rising_edge(clk21m) )then
--      pDac_VR   <= VideoR;
--      pDac_VG   <= VideoG;
--      pDac_VB   <= VideoB;
--      Reso_v    <= pScandoubler;       -- 15kHz/31kHz
--      legacy_vga <= '1';
--      pVideoHS  <= not VideoHS_n;
--      pVideoVS  <= not VideoVS_n;
--    end if;
--  end process;

  ----------------------------------------------------------------
  -- Sound output
  ----------------------------------------------------------------

  -- | b7  | b6   | b5   | b4   | b3  | b2  | b1  | b0  |
  -- | SHI | --   | PgUp | PgDn | F9  | F10 | F11 | F12 |
  process (i_aclk_emu, s_reset)
  begin
    if (i_aclk_emu'event and i_aclk_emu = '1') then
      if (s_reset = '1') then
        s_v_fkeys <= (others => '0'); -- Sync to oFkeys
      else
        if (s_first_boot_n /= '1' or s_rst_ena = '1') then
          s_v_fkeys <= s_fkeys;
        end if;
      end if;
    end if;
  end process;

  s_psg_amp_tmp <= "0" & s_psg_amp(9 downto 1);
  s_key_click_tmp <= s_key_click & "00000";
  s_p_audio_psg_tmp <= unsigned(s_psg_amp_tmp) + unsigned(s_key_click_tmp);
  o_p_audio_psg <= std_logic_vector(s_p_audio_psg_tmp);

  s_p_audio_pcm_tmp <= signed(s_scc1_amp_l(14) & s_scc1_amp_l) + signed(s_scc2_amp_l(14) & s_scc2_amp_l);
  -- Revisit this conditional case:
  o_p_audio_pcm <= "0000000000000000" when (s_scc1_amp_l(14) = '1' or s_scc2_amp_l(14) = '1') else std_logic_vector(s_p_audio_pcm_tmp);

  ----------------------------------------------------------------
  -- External memory access
  ----------------------------------------------------------------
  -- Slot map / SD-RAM memory map
  --
  -- Slot 0-0 : MainROM               620000-627FFF (  32 kB)
  -- Slot 3-3 : XBASIC                628000-62BFFF (  16 kB)
  -- Slot 0-2 : FM-BIOS               62C000-62FFFF (  16 kB)
  -- Slot 0-3 : rom_free(OPT)         63C000-63FFFF (  16 kB)
  -- Slot 1   : (EXTERNAL-SLOT)
  --            / ESE-SCC1            500000-5FFFFF (1024 kB) <= shared w/ the 2nd half of ESE-SCC2
  -- Slot 2   : (EXTERNAL-SLOT)
  --            / ESE-SCC2            400000-5FFFFF (2048 kB)
  -- Slot 3-0 : Mapper                000000-3FFFFF (4096 kB)
  -- Slot 3-1 : ExtROM + KanjiROM     630000-63BFFF (  48 kB)
  -- Slot 3-2 : MegaSDHC / NEXTOR     600000-61FFFF ( 128 kB)
  --            EseRAM                600000-67FFFF (BIOS: 512 kB)
  -- Slot 3-3 : IPL-ROM               (blockRAM: 1 kB, see IPLROM.VHD) <= shared w/ XBASIC
  -- VRAM     : VRAM                  700000-7FFFFF (1024 kB)
  -- I/O      : Kanji-data            640000-67FFFF ( 256 kB)

  process (i_resetn_sys, i_aclk_sys)  -- Wrapped into process to remove timing warnings, DmitryP
  begin
    if rising_edge(i_aclk_sys) then
      if (i_resetn_sys = '0') then

      else
        if (s_i_slt_map  = '1' and s_full_ram = '1') then
          s_cpu_adr(22 downto 20) <= "0" & s_map_adr(21 downto 20); -- 0xxxxx => 4096 kB RAM
        elsif (s_i_slt_map  = '1') then
          s_cpu_adr(22 downto 20) <= "00" & s_map_adr(20); -- 0xxxxx => 2048 kB RAM
        elsif (s_i_slt_scc2 = '1') then
          s_cpu_adr(22 downto 20) <= "10" & s_scc2_adr(20); -- 4xxxxx => 2048 kB ESE-SCC2
        elsif (s_i_slt_scc1 = '1') then
          s_cpu_adr(22 downto 20) <= "101"; -- 5xxxxx => 1024 kB ESE-SCC1
        else
          s_cpu_adr(22 downto 20) <= "110"; -- 6xxxxx => 1024 kB ESE-RAM
        end if;
        --    "111"; -- 7xxxxx => 1024 kB Video RAM

        if (s_i_slt_map = '1') then
          s_cpu_adr(19 downto 0) <= s_map_adr(19 downto  0); -- 000000-3FFFFF (4096 kB)  Slot3-0
        elsif (s_i_slt_scc2 = '1') then
          s_cpu_adr(19 downto 0) <= s_scc2_adr(19 downto 0);  -- 400000-5FFFFF (2048 kB)  Slot2
        elsif (s_i_slt_scc1 = '1') then
          s_cpu_adr(19 downto 0) <= s_scc1_adr(19 downto 0); -- 500000-5FFFFF (1024 kB)  Slot1
        elsif (s_i_slt_erm  = '1') then
          s_cpu_adr(19 downto 0) <= "0" & s_erm_adr(18 downto 0);  -- 600000-67FFFF ( 512 kB)  Slot3-2
        elsif (s_rom_main = '1') then
          s_cpu_adr(19 downto 0) <= "00100" & s_adr(14 downto 0);  -- 620000-627FFF (  32 kB)  Slot0-0
        elsif (s_rom_xbas = '1') then
          s_cpu_adr(19 downto 0) <= "001010" & s_adr(13 downto 0);  -- 628000-62BFFF (  16 kB)  Slot3-3
        elsif (s_rom_opll = '1') then
          s_cpu_adr(19 downto 0) <= "001011" & s_adr(13 downto  0);  -- 62C000-62FFFF (  16 kB)  Slot0-2
        elsif (s_rom_extd = '1') then
          s_cpu_adr(19 downto 0) <= "0011" & s_adr(15 downto 0);  -- 630000-63BFFF (  48 kB)  Slot3-1
        elsif (s_rom_free = '1') then
          s_cpu_adr(19 downto 0) <= "001111" & s_adr(13 downto  0);  -- 63C000-63FFFF (  16 kB)  Slot0-3
        elsif (s_rom_kanj = '1') then
          s_cpu_adr(19 downto 0) <= "01" & s_kan_adr(17 downto 0); -- 640000-67FFFF ( 256 kB)  Kanji-data (JIS1+JIS2)
        end if;
        --(others => '0'); -- TODO: is it correct replacement for 'else null'? DmitryP

      end if;
    end if;
  end process;

  s_w_wrt_req <= (s_ram_req and ((s_scc1_wrt and s_i_slt_scc1) or (s_scc2_wrt and s_i_slt_scc2) 
      or (s_erm_wrt and s_i_slt_erm) or (s_map_wrt and s_i_slt_map)));


  g_generate_emsx : if g_ext_sdram = 1 generate

    ----------------------------------------------------------------
    -- SD-RAM access
    ----------------------------------------------------------------
    --   SdrSta = "000" => idle
    --   SdrSta = "001" => precharge all
    --   SdrSta = "010" => refresh
    --   SdrSta = "011" => mode register set
    --   SdrSta = "100" => read cpu
    --   SdrSta = "101" => write cpu
    --   SdrSta = "110" => read vdp
    --   SdrSta = "111" => write vdp
    ----------------------------------------------------------------

  process (i_aclk_mem)
  begin
    if (i_aclk_mem'event and i_aclk_mem = '1') then
      if (s_ff_sdr_seq = "111") then
        if (s_rst_seq(4 downto 2) = "000") then
          s_sdr_sta <= "000"; -- idle
        elsif (s_rst_seq(4 downto 2) = "001") then
          case s_rst_seq(1 downto 0) is
            when "00" => s_sdr_sta <= "000"; -- idle
            when "01" => s_sdr_sta <= "001"; -- precharge all
            when "10" => s_sdr_sta <= "010"; -- refresh (more than 8 cycles)
            when others => s_sdr_sta <= "011"; -- mode register set
          end case;
        elsif (s_rst_seq(4 downto 3) /= "11" )then
          s_sdr_sta <= "101"; -- Write (Initialize memory content)
        elsif (s_i_slt_rfsh_n = '0' and s_pvideo_dl_clk = '1') then
          s_sdr_sta <= "010"; -- refresh
        elsif (s_sd_paus = '1' and s_pvideo_dl_clk = '1' ) then
          s_sdr_sta <= "010"; -- refresh
        else
          --  Normal memory access mode
          s_sdr_sta(2) <= '1'; -- read/write cpu/vdp
        end if;
      elsif (s_ff_sdr_seq = "001" and s_sdr_sta(2) = '1' and s_rst_seq(4 downto 3) = "11" )then
        s_sdr_sta(1) <= s_pvideo_dl_clk; -- 0:cpu, 1:vdp
        if (s_pvideo_dl_clk = '0') then
          s_sdr_sta(0) <= s_w_wrt_req; -- for cpu
        else
          s_sdr_sta(0) <= not s_pramwe_n; -- for vdp
        end if;
        end if;
      end if;
  end process;

  process (i_aclk_mem)
  begin
    if (i_aclk_mem'event and i_aclk_mem = '1') then
      case s_ff_sdr_seq is
        when "000" =>
          if (s_sdr_sta(2) = '1') then -- CPU/VDP read/write
            s_sdr_cmd <= c_sdr_cmd_ac;
          elsif (s_sdr_sta(1 downto 0) = "00") then -- idle
            s_sdr_cmd <= c_sdr_cmd_xx;
          elsif (s_sdr_sta(1 downto 0) = "01") then -- precharge all
            s_sdr_cmd <= c_sdr_cmd_pr;
          elsif (s_sdr_sta(1 downto 0) = "10") then -- refresh
            s_sdr_cmd <= c_sdr_cmd_re;
          else -- mode register set
            s_sdr_cmd <= c_sdr_cmd_ms;
        end if;
        when "001" =>
          s_sdr_cmd <= c_sdr_cmd_xx;
        when "010" =>
          if (s_sdr_sta(2) = '1') then
            if (s_sdr_sta(0) = '0') then
              s_sdr_cmd <= c_sdr_cmd_rd; -- "100"(cpu read) / "110"(vdp read)
            else
              s_sdr_cmd <= c_sdr_cmd_wr; -- "101"(cpu write) / "111"(vdp write)
            end if;
          end if;
        when "011" =>
          s_sdr_cmd <= c_sdr_cmd_xx;
        when others =>
          null;
        end case;
      end if;
  end process;

  process (i_aclk_mem)
  begin
    if (i_aclk_mem'event and i_aclk_mem = '1') then
      case s_ff_sdr_seq is
        when "000" =>
          if (s_sdr_sta(2) = '0') then
            --  single  CL=2 WT=0(seq) BL=1
            s_sdr_adr <= "00010" & "0" & "010" & "0" & "000";
          else
            if (s_rst_seq(4 downto 3) /= "11") then
              s_sdr_adr <= std_logic_vector(s_clr_adr(12 downto 0)); -- clear memory (VRAM, MainRAM)
            elsif (s_pvideo_dl_clk = '0') then
              s_sdr_adr <= s_cpu_adr(13 downto 1); -- cpu read/write
            else
              s_sdr_adr <= s_vdp_adr(12 downto 0); -- vdp read/write
            end if;
          end if;
        when "010" =>
          s_sdr_adr(10 downto 9) <= "10"; -- A10=1 => enable auto precharge
          if (s_sdr_sta(2) = '1') then
            if (s_sdr_sta(0) = '0') then
              s_sdr_adr(12) <= '0';
              s_sdr_adr(11) <= '0';
            else
              if (s_rst_seq(4 downto 3) /= "11") then
                s_sdr_adr(12) <= '0';
                s_sdr_adr(11) <= '0';
              elsif (s_pvideo_dl_clk = '0') then
                s_sdr_adr(12) <= not s_cpu_adr(0);
                s_sdr_adr(11) <= s_cpu_adr(0);
              else
                s_sdr_adr(12) <= not s_vdp_adr(16);
                s_sdr_adr(11) <= s_vdp_adr(16);
              end if;
            end if;
          end if;
          if (s_rst_seq(4 downto 2) = "010") then
            s_sdr_adr(8 downto 0) <= "111" & "000" & std_logic_vector(s_clr_adr(15 downto 13)); -- clear VRAM (128 kB)        => start adr 700000h
          elsif (s_rst_seq(4 downto 2) = "011") then
            s_sdr_adr(8 downto 0) <= "110" & "000" & std_logic_vector(s_clr_adr(15 downto 13)); -- clear ERAM (128 kB)        => start adr 600000h
          elsif (s_rst_seq(4 downto 2) = "100") then
            s_sdr_adr(8 downto 0) <= "000" & "000" & std_logic_vector(s_clr_adr(15 downto 13)); -- clear MainRAM (128 kB)     => start adr 000000h
          elsif (s_rst_seq(4 downto 1) = "1010") then
            s_sdr_adr(8 downto 0) <= "100" & "000" & std_logic_vector(s_clr_adr(15 downto 13)); -- clear ESE-SCC2             => start adr 400000h
          elsif (s_rst_seq(4 downto 1) = "1011") then
            s_sdr_adr(8 downto 0) <= "101" & "000" & std_logic_vector(s_clr_adr(15 downto 13)); -- clear ESE-SCC1             => start adr 500000h
          elsif (s_pvideo_dl_clk = '0') then
            s_sdr_adr(8 downto 0) <= s_cpu_adr(22 downto 14);
          elsif (s_vdp_adr(15) = '0') then
            s_sdr_adr(8 downto 0) <= "11" & "1" & s_vram_page(3 downto 0) & s_vdp_adr(14 downto 13);
          else
            s_sdr_adr(8 downto 0) <= "11" & "1" & s_vram_page(7 downto 4) & s_vdp_adr(14 downto 13);
          end if;
        when others =>
          null;
      end case;
    end if;
  end process;

  process (s_ff_sdr_seq, s_sdr_sta, s_rst_seq, s_pvideo_dl_clk, s_dbo, s_vrm_dbo)
  begin
    o_mem_dat_en <= '0';
    s_mem_dat_out <= (others => '1');
    if (s_ff_sdr_seq = "010" and s_sdr_sta(2) = '1' and s_sdr_sta(0) = '1') then
      if (s_rst_seq(4 downto 3) /= "11") then
        o_mem_dat_en <= '1';
      elsif (s_pvideo_dl_clk = '0') then
        o_mem_dat_en <= '1';
        s_mem_dat_out <= s_dbo; -- "101"(cpu write)
      else
        o_mem_dat_en <= '1';
        s_mem_dat_out <= s_vrm_dbo; -- "111"(vdp write)
      end if;
    end if;
  end process;

  -- Clear address for DRAM initialization
  process (i_aclk_mem)
  begin
    if (i_aclk_mem'event and i_aclk_mem = '1') then
      if (s_ff_sdr_seq = "010") then
        if (s_rst_seq(4 downto 3) /= "11") then
          s_clr_adr <= (others => '0');
        else
          s_clr_adr <= s_clr_adr + 1;
        end if;
      end if;
    end if;
  end process;

  process (i_aclk_mem)
  begin
    if (i_aclk_mem'event and i_aclk_mem = '1') then
      if (s_ff_sdr_seq = "101") then
        s_mem_dbi <= s_mem_dat_in(15 downto 0);
      end if;
    end if;
  end process;

  -- Data read latch for CPU
  process (i_aclk_mem)
  begin
    if (i_aclk_mem'event and i_aclk_mem = '1') then
      if (s_ff_sdr_seq = "110") then
        if (s_sdr_sta = "100") then -- read cpu
          if (s_cpu_adr(0) = '0') then
            s_ram_dbi <= s_mem_dbi(7 downto 0);
          else
            s_ram_dbi <= s_mem_dbi(15 downto 8);
          end if;
        end if;
      end if;
    end if;
  end process;

  -- Data read latch for VDP
  process (i_aclk_mem)
  begin
    if (i_aclk_mem'event and i_aclk_mem = '1') then
      if (s_ff_sdr_seq = "110") then
        if (s_sdr_sta = "110") then -- read vdp
          -- FIXME: uncomment to switch over from BRAM
          -- VRAM is in BRAM when commented out
          s_vrm_dbi <= s_mem_dbi(15 downto 0);
        end if;
      end if;
    end if;
  end process;

  -- SDRAM controller state
  process(i_aclk_mem)
  begin
    if (i_aclk_mem'event and i_aclk_mem = '1') then
      case s_ff_sdr_seq is
        when "000" =>
          if (s_pvideo_dh_clk = '1' or s_rst_seq(4 downto 3) /= "11") then
            s_ff_sdr_seq <= "001";
          end if;
        when "111" =>
          if (s_pvideo_dh_clk = '0' or s_rst_seq(4 downto 3) /= "11") then
            s_ff_sdr_seq <= "000";
          end if;
        when others =>
          s_ff_sdr_seq <= std_logic_vector(unsigned(s_ff_sdr_seq) + 1);
      end case;
    end if;
  end process;

  process (i_aclk_emu, s_reset)
  begin
     if (i_aclk_emu'event and i_aclk_emu = '1') then
       if (s_reset = '1') then
         s_ram_ack <= '0';
       else
         if (s_ram_req = '0') then
           s_ram_ack <= '0';
         elsif (s_pvideo_dl_clk = '0' and s_pvideo_dh_clk = '1') then
           s_ram_ack <= '1';
         end if;
         if (s_pvideo_dl_clk = '0') then
           s_vram_page <= s_vram_slot_ids;
         end if;
       end if;
     end if;
  end process;

  -- Disable accessing DDRAM when using SDRAM
  o_ddr_address <= (others => '0');
  o_ddr_data <= (others => '0');
  o_ddr_mem_wr <= '0';
  o_ddr_mem_req <= '0';

  end generate g_generate_emsx;

  --s_cpu_reset_n <= ((s_p_slt_rst_n or s_rst_key_lock) and s_swio_reset_n);
  s_cpu_reset_n <= not s_reset;

  s_p_cpu_wait_n <= s_p_slt_wait_n;

  ----------------------------------------------------------------
  -- Connect components
  ----------------------------------------------------------------
  U01 : T80pa
    port map (
    RESET_n => s_cpu_reset_n,
    R800_mode => i_p_r800,
    CLK => i_aclk_emu,
    CEN_p => s_true_cen,
    CEN_n => s_true_cen_n,
    WAIT_n => s_p_cpu_wait_n,
    INT_n => s_p_slt_int_n,
    NMI_n => '1',
    BUSRQ_n => '1',
    M1_n => s_cpu_m1_n,
    MREQ_n => s_p_slt_merq_n,
    IORQ_n => s_p_slt_iorq_n,
    RD_n => s_p_slt_rd_n,
    WR_n => s_p_slt_wr_n,
    RFSH_n => s_cpu_rfsh_n,
    HALT_n => open,
    BUSAK_n => open,
    A => s_p_slt_adr,
    DI => s_cpu_di,
    DO => s_cpu_do
  );

  U02 : iplrom
    port map (
      clk => i_aclk_emu,
      adr => s_adr, 
      dbi => s_rom_dbi
   );

  U03 : megasd
    port map (
      clk21m => i_aclk_emu, 
      reset => s_reset, 
      clkena => s_cpucen, 
      req => s_erm_req,
      ack => open, 
      wrt => s_wrt, 
      adr => s_adr, 
      dbi => open, 
      dbo => s_dbo,
      ramreq => s_erm_ram, 
      ramwrt => s_erm_wrt, 
      ramadr => s_erm_adr, 
      ramdbi => s_ram_dbi, 
      ramdbo => open,
      mmcdbi => s_mmc_dbi, 
      mmcena => s_mmc_en,
      mmcact => s_mmc_act, 
      mmc_ck => s_mmc_sck, 
      mmc_cs => s_mmc_cs, 
      mmc_di => s_mmc_mosi, 
      mmc_do => s_mmc_miso,
      mmc_ps_di => s_mmc_ps_di,
      mmc_ps_di_stb => s_mmc_ps_di_stb,
      epc_ck => open, 
      epc_cs => open, 
      epc_oe => open, 
      epc_di => open, 
      epc_do => '0'
  );

  U05 : mapper
    port map (
      clk21m => i_aclk_emu, 
      reset  => s_reset, 
      clkena => s_cpucen, 
      req => s_map_req,
      ack => open, 
      mem => s_mem, 
      wrt => s_wrt, 
      adr => s_adr, 
      dbi => s_map_dbi, 
      dbo => s_dbo,
      ramreq => s_map_ram, 
      ramwrt => s_map_wrt, 
      ramadr => s_map_adr, 
      ramdbi => s_ram_dbi, 
      ramdbo => open
  );

  U06 : eseps2
    port map (
      clk21m => i_aclk_emu, 
      reset => s_reset, 
      clkena => s_cpucen, 
      Kmap => s_kmap, 
      Paus => s_paus, 
      Scro => s_scro, 
      Reso => s_reso, 
      Fkeys => s_fkeys,
      ps2_key => i_ps2_key, 
      PpiPortC => s_ppi_port_c, 
      pKeyX => s_ppi_port_b
  );

  U07 : rtc
    port map (
      clk21m => i_aclk_emu, 
      reset => s_reset, 
      setup => i_rtc_setup, 
      rt => i_rtc_time, 
      clkena => s_w_10hz, 
      req => s_rtc_req, 
      ack => open, 
      wrt => s_wrt, 
      adr => s_adr, 
      dbi => s_rtc_dbi, 
      dbo => s_dbo
  );

  U08 : kanji
    port map (
      clk21m => i_aclk_emu,
      reset  => s_reset, 
      clkena => s_cpucen, 
      req    => s_kan_req, 
      ack    => open, 
      wrt    => s_wrt, 
      adr    => s_adr, 
      dbi    => s_kan_dbi, 
      dbo    => s_dbo,
      ramreq => s_kan_rom, 
      ramadr => s_kan_adr, 
      ramdbi => s_ram_dbi, 
      ramdbo => open
   );

  -- V9958 MSX2+/tR VDP
  U20 : vdp
    port map (
        CLK21M => i_aclk_emu,
        RESET => s_reset,
        REQ => s_vdp_pulse, --s_vdp_req, 
        ACK => s_vdp_ack,
        WRT => s_wrt,
        ADR => s_adr,
        DBI => s_vdp_dbi,
        DBO => s_dbo,

        INT_N => s_p_vdp_int_n,

        PRAMOE_N => open,
        PRAMWE_N => s_pramwe_n,
        PRAMADR => s_vdp_adr,
        PRAMDBI => s_vrm_dbi,
        PRAMDBO => s_vrm_dbo,

        VDPSPEEDMODE => s_vdp_speed_mode,
        RATIOMODE => s_ratio_mode,
        CENTERYJK_R25_N => s_center_yjk_r25_n,

        -- VIDEO OUTPUT
        PVIDEOR => s_pvideo_r,
        PVIDEOG => s_pvideo_g,
        PVIDEOB => s_pvideo_b,
        PVIDEODE => s_pvideo_de,

        PVIDEOHS_N => s_pvideo_hs_n,
        PVIDEOVS_N => s_pvideo_vs_n,
        PVIDEOCS_N => s_pvideo_cs_n, -- TODO: not connected?

        PVIDEODHCLK => s_pvideo_dh_clk,
        PVIDEODLCLK => s_pvideo_dl_clk,

        -- DISPLAY RESOLUTION (0=15KHZ, 1=31KHZ)
        DISPRESO => '1', --s_reso_v,

        NTSC_PAL_TYPE => '0', --s_ntsc_pal_type,
        FORCED_V_MODE => '1', --s_forced_v_mode,
        LEGACY_VGA => '1' --s_legacy_vga
    );

    U30 : psg
      port map (
        clk21m => i_aclk_emu, 
        reset => s_reset, 
        clkena => s_cpucen, 
        req => s_psg_req, 
        ack => open, 
        wrt => s_wrt, 
        adr => s_adr, 
        dbi => s_psg_dbi, 
        dbo => s_dbo,
        joya => i_p_joy_a, --p_joy_a,
        stra => o_p_str_a, 
        joyb => i_p_joy_b, -- p_joy_b
        strb => o_p_str_b, 
        kana => open, 
        cmtin => '0', --cmtin,
        keymode => s_w_key_mode, 
        wave => s_psg_amp
    );

  U31_1 : megaram
    port map (
      clk21m => i_aclk_emu,
      reset => s_reset, 
      clkena => s_cpucen, 
      req => s_scc1_req,
      ack => s_scc1_ack, 
      wrt => s_wrt, 
      adr => s_adr, 
      dbi => s_scc1_dbi, 
      dbo => s_dbo,
      ramreq => s_scc1_ram, 
      ramwrt => s_scc1_wrt, 
      ramadr => s_scc1_adr, 
      ramdbi => s_ram_dbi, 
      ramdbo => open, 
      mapsel => s_scc1_type, 
      wavl => s_scc1_amp_l, 
      wavr => open
  );

  s_scc1_type <= "00" when (s_slot1_mode = '0') else "10";

  U31_2 : megaram
    port map (
      clk21m => i_aclk_emu,
      reset => s_reset,
      clkena => s_cpucen,
      req => s_scc2_req,
      ack => s_scc2_ack,
      wrt => s_wrt,
      adr => s_adr,
      dbi => s_scc2_dbi,
      dbo => s_dbo,
      ramreq => s_scc2_ram,
      ramwrt => s_scc2_wrt,
      ramadr => s_scc2_adr,
      ramdbi => s_ram_dbi,
      ramdbo => open,
      mapsel => s_slot2_mode,
      wavl => s_scc2_amp_l,
      wavr => open
  );

  U32 : eseopll
    port map (
      clk21m => i_aclk_emu,
      reset => s_reset,
      clkena => s_cpucen,
      enawait => s_opll_en_wait,
      req => s_opll_req,
      ack => s_opll_ack,
      wrt => s_wrt,
      adr => s_adr,
      dbo => s_dbo,
      wav => o_p_audio_opll
  );

  s_opll_en_wait <= '1' when (s_ff_clksel = '1' or s_ff_clksel5m_n = '0') else '0';

  U34: system_timer
    port map (
      clk21m => i_aclk_emu,
      reset => s_reset,
      req => s_systim_req,
      ack => open,
      adr => s_adr,
      dbi => s_systim_dbi,
      dbo => s_dbo
  );

  U40 : tr_pcm
    port map (
      clk21m => i_aclk_emu,
      reset => s_reset,
      req => s_tr_pcm_req,
      ack => open,
      wrt => s_wrt,
      adr => s_adr(0),
      dbi => s_tr_pcm_dbi,
      dbo => s_dbo,
      wave_in => (others => '0'),
      wave_out => o_p_audio_trpcm
  );

  U35: switched_io_ports
    port map (
      clk21m => i_aclk_emu,
      reset => s_reset,
      req => s_swio_req,
      ack => open,
      wrt => s_wrt,
      adr => s_adr,
      dbi => s_swio_dbi,
      dbo => s_dbo,

      io40_n => s_io40_n,
      io41_id212_n => s_io41_id212_n, -- here to reduce LEs
      io42_id212 => s_io42_id212,
      io43_id212 => s_io43_id212,
      io44_id212 => s_io44_id212,
      OpllVol => open,
      SccVol => open,
      PsgVol => open,
      MstrVol => open,
      CustomSpeed => std_logic_vector(s_custom_speed),
      tMegaSD => s_t_mega_sd,
      tPanaRedir => s_t_pana_redir,   -- here to reduce LEs
      VdpSpeedMode => s_vdp_speed_mode,
      V9938_n => s_v9938_n,
      Mapper_req => s_mapper_req,   -- here to reduce LEs
      Mapper_ack => s_mapper_ack,
      MegaSD_req => s_mega_sd_req,   -- here to reduce LEs
      MegaSD_ack => s_megasd_ack,
      io41_id008_n => s_io41_id008_n,
      swioKmap => s_swio_kmap,
      CmtScro => s_cmt_scro,
      swioCmt => s_swio_cmt,
      LightsMode => s_lights_mode,
      Red_sta => s_red_sta,
      LastRst_sta => s_last_rst_sta,  -- here to reduce LEs
      RstReq_sta => s_rst_req_sta,   -- here to reduce LEs
      Blink_ena => s_blink_en,
      pseudoStereo => s_pseudo_stereo,
      extclk3m => s_extclk3m,
      ntsc_pal_type => s_ntsc_pal_type,
      forced_v_mode => s_forced_v_mode,
      right_inverse => s_right_inverse,
      vram_slot_ids => s_vram_slot_ids,
      DefKmap => s_def_kmap,      -- here to reduce LEs

      ff_dip_req => s_ff_dip_req,
      ff_dip_ack => s_ff_dip_ack,   -- here to reduce LEs

      SdPaus => s_sd_paus,
      Scro => '0',
      ff_Scro => '0',
      Reso => '0',
      ff_Reso => '0',
      FKeys => s_fkeys,
      vFKeys => s_v_fkeys,
      LevCtrl => s_lev_ctrl,
      GreenLvEna => s_green_lv_en,

      swioRESET_n => s_swio_reset_n,
      warmRESET => s_warm_reset,
      WarmMSXlogo => s_warm_msx_logo,   -- here to reduce LEs

      ZemmixNeo => s_zemmix_neo,

      JIS2_ena => s_jis2_en,
      portF4_mode => s_port_f4_mode,
      ff_ldbios_n => s_ff_ldbios_n,

      RatioMode => s_ratio_mode,
      centerYJK_R25_n => s_center_yjk_r25_n,
      legacy_sel => s_legacy_sel,
      Slot0_req => s_slot0_req,     -- here to reduce LEs
      Slot0Mode => s_slot0_mode
  );

  o_emu_hsync <= not s_pvideo_hs_n; -- TODO: or inverted???
  o_emu_vsync <= not s_pvideo_vs_n; -- TODO: or inverted???
  o_emu_de <= s_pvideo_de;
  o_emu_r <= s_pvideo_r & "00";
  o_emu_g <= s_pvideo_g & "00";
  o_emu_b <= s_pvideo_b & "00";

  s_vdp_pulse <= s_vdp_req when s_vdp_ack = '0' and s_vdp_req_filt = '0' else '0';

  -- Generates 42MHz, 21MHz
  p_emu_clk_en_generator : process(i_aclk_sys)
  variable v_div_counter7 : unsigned(15 downto 0) := x"0000";
  variable v_mul_counter7 : unsigned(7 downto 0) := x"00";
  variable v_freq_div : integer;
  begin
    if rising_edge(i_aclk_sys) then
      -- count 10 times faster so it makes the frequency 859.0908 MHz
      v_div_counter7 := v_div_counter7 + 10;
      -- now divider makes it 859.0908 MHz / 25 = 34.363 Mhz which is good enough for the upscaler
      v_freq_div := 25;
      if v_div_counter7 >= v_freq_div then
        v_div_counter7 := v_div_counter7 - v_freq_div;
        v_mul_counter7 := v_mul_counter7 + 1;
        s_ce_42mp <= '1';
      else
        s_ce_42mp <= '0';
      end if;
      s_emu_ce_cntr <= s_emu_ce_cntr + 1;
      s_ce_21mp <= s_emu_ce_cntr(1) and (not s_emu_ce_cntr(0));
    end if;
  end process;

  -- MSX2+
  o_ce_21mp <= s_ce_21mp;
  o_ce_42mp <= s_ce_42mp;

  g_generate_emsx_ddram : if g_ext_sdram = 0 generate
    o_ddr_address <= s_cpu_addr_cdc(2);
    s_ram_dbi <= i_ddr_data;
    s_ram_ack <= '0' when (i_ddr_mem_busy = '0' and s_ram_req = '1') or (i_ddr_mem_busy = '1') else '1';
    o_ddr_data <= s_dbo_cdc(2);
    o_ddr_mem_wr <= s_w_wrt_req_cdc(2);
    o_ddr_mem_req <= s_ram_req_cdc(2);
  end generate g_generate_emsx_ddram;

  s_mmc_miso <= i_mmc_miso;
  o_mmc_cs <= s_mmc_cs;
  o_mmc_mosi <= s_mmc_mosi;
  o_mmc_clk <= s_mmc_sck;

  o_led0_red <= s_mmc_led_en;
  o_led1_red <= s_ff_ldbios_n;


  process (i_resetn_sys, i_aclk_emu)
  begin
    if rising_edge(i_aclk_emu) then
      if (i_resetn_sys = '0') then
        s_vdp_req_filt <= '0';
      else
        if (s_vdp_req = '1') then
          s_vdp_req_filt <= '1';
        else
          s_vdp_req_filt <= '0';
        end if;
      end if;
    end if;
  end process;

  process (i_resetn_sys, i_aclk_sys)
  begin
    if rising_edge(i_aclk_sys) then
      if (i_resetn_sys = '0') then
        s_dbo_cdc <= (others => (others => '0'));
        s_cpu_addr_cdc <= (others => (others => '0'));
        s_w_wrt_req_cdc <= (others => '0');
        s_ram_req_cdc <= (others => '0');
      else
        s_dbo_cdc <= s_dbo_cdc(1 downto 0) & s_dbo;
        s_cpu_addr_cdc <= s_cpu_addr_cdc(1 downto 0) & ('0' & s_cpu_adr);
        s_w_wrt_req_cdc <= s_w_wrt_req_cdc(1 downto 0) & s_w_wrt_req;
        s_ram_req_cdc <= s_ram_req_cdc(1 downto 0) & s_ram_req;
      end if;
    end if;
  end process;

  process (i_aclk_sys, s_cpu_reset_n)
  begin
    if rising_edge(i_aclk_sys) then
      if (s_cpu_reset_n = '0') then
        s_map_ps_di_stb_cdc <= (others => '0');
        s_mmc_ps_di_pending <= '0';
        s_mmc_ps_do_pending <= '0';
        s_mmc_ps_di_latched <= (others => '1');
      else
        s_map_ps_di_stb_cdc <= s_map_ps_di_stb_cdc(1 downto 0) & s_mmc_ps_di_stb;
        if s_map_ps_di_stb_cdc(2 downto 1) = c_active_high_raising_edge then
          s_mmc_ps_di_pending <= '1';
          s_mmc_ps_do_pending <= '1';
          s_mmc_ps_di_latched <= s_mmc_ps_di;
        end if;

        if (i_mmc_di_en = '1') then
          if (i_wr_en = '1') then
            -- PS is writing the MMC_DO register
            if (s_mmc_ps_do_pending = '1') then 
              s_mmc_ps_do_pending <= '0';
              s_mmc_ps_do <= i_register_data_out(7 downto 0);  
            end if;
          else
            -- PS is reading the MMC_DI register, allow to read value only once, bit 8 indicates pending data
            if (s_mmc_ps_di_pending = '1') then 
              o_mmc_di <= x"0000" & "0000001" & s_mmc_ps_di_latched;
              s_mmc_ps_di_pending <= '0';
            else
              o_mmc_di <= (others => '0');
            end if;
          end if;
        end if;
      end if;
    end if;
  end process;

  s_mmc_ps_busy <= '1' when s_mmc_ps_di_stb = '1' or s_mmc_ps_di_pending = '1' or s_mmc_ps_do_pending = '1' else '0';

  -- For PS/2 emulation
  o_cpucen <= s_cpucen;


end architecture;
