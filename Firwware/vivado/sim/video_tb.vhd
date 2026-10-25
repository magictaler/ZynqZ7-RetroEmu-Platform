----------------------------------------------------------------------------------
-- Company: Magictale Electronics http://magictale.com
-- Engineer: Dmitry Pakhomenko
-- 
-- Create Date: 26/01/2024 03:00:00 PM
-- Design Name: 
-- Module Name: video_tb - RTL
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
--  use xil_defaultlib.all;

library xil_defaultlib;
  use work.types_arty_video.all;
  use work.types_emulator_top.all;

entity video_tb is
end video_tb;

architecture rtl of video_tb is

  constant c_sys_clock_period : time := 2.9 ns;
  constant c_video_clock_period : time := 11.6 ns;  -- MSX2+ VDP

  constant g_axi_lite_data_width : integer := 32;

  signal s_sys_clk, s_video_clk, s_sys_reset, s_video_reset : std_logic;
  -- MSX VDP
  signal pvideo_r : std_logic_vector(5 downto 0) := (others => '0');
  signal pvideo_g : std_logic_vector(5 downto 0) := (others => '0');
  signal pvideo_b : std_logic_vector(5 downto 0) := (others => '0');
  signal pvideo_de : std_logic := '0';
  signal pvideo_hs_n : std_logic := '0';
  signal pvideo_vs_n : std_logic := '0';
  signal pvideo_cs_n : std_logic := '0';
  signal pvideo_dh_clk : std_logic := '0';
  signal pvideo_dl_clk : std_logic := '0';

  -- axi_s2mm_slave_wr_stub
  signal s_axi_s2mm_awaddr : std_logic_vector(31 downto 0);
  signal s_axi_s2mm_awburst : std_logic_vector(1 downto 0);
  signal s_axi_s2mm_awcache : std_logic_vector(3 downto 0);
  signal s_axi_s2mm_awlen : std_logic_vector(7 downto 0);
  signal s_axi_s2mm_awprot : std_logic_vector(2 downto 0);
  signal s_axi_s2mm_awready : std_logic;
  signal s_axi_s2mm_awsize : std_logic_vector(2 downto 0);
  signal s_axi_s2mm_awvalid : std_logic;
  signal s_axi_s2mm_wdata : std_logic_vector(31 downto 0);
  signal s_axi_s2mm_wlast : std_logic;
  signal s_axi_s2mm_wready : std_logic;
  signal s_axi_s2mm_bresp : std_logic_vector(1 downto 0);
  signal s_axi_s2mm_wvalid : std_logic;
  signal s_axi_s2mm_wstrb : std_logic_vector(3 downto 0);
  signal s_axi_s2mm_bvalid : std_logic;
  signal s_axi_s2mm_bready : std_logic;

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

  component arty_video_top is
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
  end component;


  component VDP is
    port (
        -- VDP CLOCK ... 21.477MHZ
        CLK21M              : in std_logic;
        RESET               : in std_logic;
        REQ                 : in std_logic;
        ACK                 : out std_logic;
        WRT                 : in std_logic;
        ADR                 : in std_logic_vector(15 downto 0);
        DBI                 : out std_logic_vector(7 downto 0);
        DBO                 : in std_logic_vector(7 downto 0);

        INT_N               : out std_logic;

        PRAMOE_N            : out std_logic;
        PRAMWE_N            : out std_logic;
        PRAMADR             : out std_logic_vector(16 downto 0);
        PRAMDBI             : in std_logic_vector(15 downto 0);
        PRAMDBO             : out std_logic_vector(7 downto 0);

        VDPSPEEDMODE        : in std_logic;
        RATIOMODE           : in std_logic_vector(2 downto 0);
        CENTERYJK_R25_N     : in std_logic;

        -- VIDEO OUTPUT
        PVIDEOR             : out std_logic_vector(5 downto 0);
        PVIDEOG             : out std_logic_vector(5 downto 0);
        PVIDEOB             : out std_logic_vector(5 downto 0);
        PVIDEODE            : out std_logic;

        PVIDEOHS_N          : out std_logic;
        PVIDEOVS_N          : out std_logic;
        PVIDEOCS_N          : out std_logic;

        PVIDEODHCLK         : out std_logic;
        PVIDEODLCLK         : out std_logic;

        -- DISPLAY RESOLUTION (0=15KHZ, 1=31KHZ)
        DISPRESO            : in std_logic;

        NTSC_PAL_TYPE       : in std_logic;
        FORCED_V_MODE       : in std_logic;
        LEGACY_VGA          : in std_logic

        -- DEBUG OUTPUT
    --  DEBUG_OUTPUT        : OUT   STD_LOGIC_VECTOR( 15 DOWNTO 0 ) -- 
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

  i_msx_video : VDP
    port map(
        CLK21M => s_video_clk,
        RESET => s_sys_reset,
        REQ => '0',
        ACK => open,
        WRT => '0',
        ADR => (others => '0'),
        DBI => open,
        DBO => (others => '0'),

        INT_N => open,

        PRAMOE_N => open,
        PRAMWE_N => open,
        PRAMADR => open,
        PRAMDBI => (others => '0'),
        PRAMDBO => open,

        VDPSPEEDMODE => '0',
        RATIOMODE => (others => '0'),
        CENTERYJK_R25_N => '0',

        -- VIDEO OUTPUT
        PVIDEOR => pvideo_r,
        PVIDEOG => pvideo_g,
        PVIDEOB => pvideo_b,
        PVIDEODE => pvideo_de,

        PVIDEOHS_N => pvideo_hs_n,
        PVIDEOVS_N => pvideo_vs_n,
        PVIDEOCS_N => pvideo_cs_n,

        PVIDEODHCLK => pvideo_dh_clk,
        PVIDEODLCLK => pvideo_dl_clk,

        -- DISPLAY RESOLUTION (0=15KHZ, 1=31KHZ)
        DISPRESO => '1',

        NTSC_PAL_TYPE => '0',
        FORCED_V_MODE => '1',
        LEGACY_VGA => '1'
    );

  i_axi_s2mm_slave_wr_stub : axi_s2mm_slave_wr_stub
    port map(
      i_resetn_sys => not s_sys_reset,
      i_aclk_sys => s_sys_clk,

      -- AXI
      i_axi_s2mm_awaddr => s_axi_s2mm_awaddr,
      i_axi_s2mm_awburst => s_axi_s2mm_awburst,
      i_axi_s2mm_awcache => s_axi_s2mm_awcache,
      i_axi_s2mm_awlen => s_axi_s2mm_awlen,
      i_axi_s2mm_awprot => s_axi_s2mm_awprot,
      o_axi_s2mm_awready => s_axi_s2mm_awready,
      i_axi_s2mm_awsize => s_axi_s2mm_awsize,
      i_axi_s2mm_awvalid => s_axi_s2mm_awvalid,
      i_axi_s2mm_wdata => s_axi_s2mm_wdata,
      i_axi_s2mm_wlast => s_axi_s2mm_wlast,
      o_axi_s2mm_wready => s_axi_s2mm_wready,
      o_axi_s2mm_bresp => s_axi_s2mm_bresp,
      i_axi_s2mm_wvalid => s_axi_s2mm_wvalid,
      i_axi_s2mm_wstrb => s_axi_s2mm_wstrb,
      o_axi_s2mm_bvalid => s_axi_s2mm_bvalid,
      i_axi_s2mm_bready => s_axi_s2mm_bready
    );

  i_arty_video_top : arty_video_top
    port map ( 
      i_resetn_sys => not s_sys_reset,
      i_resetn_video => not s_video_reset,
      i_aclk_sys => s_sys_clk,
      i_aclk_video => s_video_clk,

      -- AXI interface      
      --o_axi_mm2s_araddr =>
      --o_axi_mm2s_arburst =>
      --o_axi_mm2s_arcache =>
      --o_axi_mm2s_arlen =>
      --o_axi_mm2s_arprot =>
      i_axi_mm2s_arready => '0',
      --o_axi_mm2s_arsize =>
      --o_axi_mm2s_arvalid =>
      i_axi_mm2s_rdata => (others => '0'),
      i_axi_mm2s_rlast => '0',
      --o_axi_mm2s_rready =>
      i_axi_mm2s_rresp => (others => '0'),
      i_axi_mm2s_rvalid => '0',

      o_axi_s2mm_awaddr =>  s_axi_s2mm_awaddr,
      o_axi_s2mm_awburst => s_axi_s2mm_awburst,
      o_axi_s2mm_awcache => s_axi_s2mm_awcache,
      o_axi_s2mm_awlen => s_axi_s2mm_awlen,
      o_axi_s2mm_awprot => s_axi_s2mm_awprot,
      i_axi_s2mm_awready => s_axi_s2mm_awready,
      o_axi_s2mm_awsize => s_axi_s2mm_awsize,
      o_axi_s2mm_awvalid => s_axi_s2mm_awvalid,
      o_axi_s2mm_wdata => s_axi_s2mm_wdata,
      o_axi_s2mm_wlast => s_axi_s2mm_wlast,
      i_axi_s2mm_wready => s_axi_s2mm_wready,
      i_axi_s2mm_bresp => s_axi_s2mm_bresp,
      o_axi_s2mm_wvalid => s_axi_s2mm_wvalid,
      o_axi_s2mm_wstrb => s_axi_s2mm_wstrb,
      i_axi_s2mm_bvalid => s_axi_s2mm_bvalid,
      o_axi_s2mm_bready => s_axi_s2mm_bready,

      -- Registers
      i_wr_en => s_wr_en,
      i_rd_en => '0',
      i_register_data_out => s_register_data_out,
      i_video_control_en => s_video_control_en,
      i_video_control =>  (others => '0'),

      -- Emulator video out - ARTY video in
      i_emu_hsync => not pvideo_hs_n, -- Why inverting twice???
      i_emu_vsync => not pvideo_vs_n, -- Why inverting twice???
      i_emu_de => pvideo_de,
      i_emu_r => pvideo_r & "00",
      i_emu_g => pvideo_g & "00",
      i_emu_b => pvideo_b & "00",

      -- Clock enable signals for ARTY video core
      i_ce_pixel_clock_in => '0',
      i_ce_pixel_clock_scandoubled => '0',
      -- Normally twice as fast as the i_ce_pixel_clock_scandoubled or the emulated video controller clock. 
      -- May be pulled high if the same as i_aclk_sys
      i_ce_emu_video_out => s_ce_21mp,

      -- ARTY VGA video out (clocked by i_aclk_video)
      --o_vga_hs =>
      --o_vga_vs =>
      --o_vga_r =>
      --o_vga_b =>
      --o_vga_g =>

      -- ARTY HDMI video out (clocked by i_aclk_video)
      o_hdmi_out_data => open,
      o_hdmi_out_hsync => open,
      o_hdmi_out_vsync => open,
      o_hdmi_out_active_video => open
    );



end rtl;


