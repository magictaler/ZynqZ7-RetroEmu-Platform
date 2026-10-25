----------------------------------------------------------------------------------
-- SDRAM memory test for Arty-Z7
-- 
-- Company: Magictale Electronics http://magictale.com
-- Engineer: Dmitry Pakhomenko
-- 
-- Create Date: 14.06.2024 20:09:00 PM
-- Design Name: SDRAM memory test
-- Module Name: memtest_top - RTL
-- Project Name: SDRAM memory test for Arty Z7/AX7020 boards
-- Target Devices: Zynq 7020
-- Tool Versions: Vivado 2017.3
-- Description: This is a top level of the SDRAM memory test
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created on 14.06.2024
-- Additional Comments:
-- 
----------------------------------------------------------------------------------

library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

library xil_defaultlib;
    use work.types_arty_video.all;
    use work.types_arty_audio.all;
    use work.types_emulator_top.all;

entity memtest_top is
    generic (
      g_axi_lite_data_width : integer := 32;
      g_rst_seq : unsigned(4 downto 0) := "00000"
    );
    port ( 
      i_resetn_sys : in std_logic;
      i_aclk_sys : in std_logic; -- 85.90908 MHz
      i_aclk_emu : in std_logic; -- 21.4815 MHz
      --i_p_cold_reset : in std_logic; -- TODO: connect it to the upper level

      -- DDRAM interface
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

      -- Registers
      i_wr_en : in std_logic;    
      i_rd_en : in std_logic;    
      i_register_data_out : in std_logic_vector(c_register_width - 1 downto 0);
      i_emu_control_en : in std_logic;
      o_emu_control : out std_logic_vector(g_axi_lite_data_width - 1 downto 0);
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

      -- Chip enable @ 21.48 MHz for MSX2+
      o_ce_21mp : out std_logic;

      -- PS/2 keyboard ports
      --i_ps2_key : in std_logic_vector(10 downto 0); -- TODO: connect this
      o_p_caps : out std_logic;

      -- DIP switch, Lamp ports
      i_p_dip : in std_logic_vector(7 downto 0);     -- 0=On,    1=Off (default on shipment)
      o_p_led : out std_logic_vector(7 downto 0);    -- 0=Off,   1=On  (green)
      o_p_led_pwr : out std_logic; -- 0=Off,   1=On  (red)
      --i_p_r800 : in std_logic;

      --i_rtc_setup : in std_logic;
      --i_rtc_time : in std_logic_vector(64 downto 0);

      o_p_audio_psg : out std_logic_vector(9 downto 0);
      o_p_audio_opll : out std_logic_vector(13 downto 0);
      o_p_audio_pcm : out std_logic_vector(15 downto 0);
      o_p_audio_trpcm : out std_logic_vector(7 downto 0);

      i_mmc_miso : in std_logic;
      o_mmc_cs : out std_logic;
      o_mmc_mosi : out std_logic;
      o_mmc_clk : out std_logic;

      o_led0_red : out std_logic;
      o_led1_red : out std_logic
    );

end memtest_top;

architecture rtl of memtest_top is

signal s_pass_count : std_logic_vector (31 downto 0);
signal s_fail_count : std_logic_vector (31 downto 0);

signal s_written : std_logic_vector (15 downto 0);
signal s_read : std_logic_vector (15 downto 0);
signal s_check_in_progress : std_logic;
signal s_dram_ready : std_logic;

begin
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

      DRAM_CLK => o_mem_clk,
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

end architecture;
