----------------------------------------------------------------------------------
-- Company: Magictale Electronics http://magictale.com
-- Engineer: Dmitry Pakhomenko
-- 
-- Create Date: 25/11/2023 2:16:00 PM
-- Design Name: AXI DDR memory interface
-- Module Name: axi_ddr_top - RTL
-- Project Name: Retro computer emulator on Arty Z7 board
-- Target Devices: Zynq 7020
-- Tool Versions: Vivado 2017.3
-- Description: This module allows 8-bit MCU accessing DDRAM via 32-bit AXI bus
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

entity axi_ddr_top is
    generic (
      g_axi_data_width : integer := 32;
      g_axi_lite_data_width : integer := 32;
      g_axi_ddr_data_width : integer := 8;
      g_axi_ddr_addr_width : integer := 24;
      g_axi_addr_width : integer := 32
    );
    port ( 
      i_resetn_sys : in std_logic;
      i_aclk_sys : in std_logic;
      -- AXI interface      
      o_axi_ddr_araddr : out std_logic_vector(g_axi_addr_width - 1 downto 0);
      o_axi_ddr_arburst : out std_logic_vector(1 downto 0);
      o_axi_ddr_arcache : out std_logic_vector(3 downto 0);
      o_axi_ddr_arlen : out std_logic_vector(7 downto 0);
      o_axi_ddr_arprot : out std_logic_vector(2 downto 0);
      i_axi_ddr_arready : in std_logic;
      o_axi_ddr_arsize : out std_logic_vector(2 downto 0);
      o_axi_ddr_arvalid : out std_logic;
      i_axi_ddr_rdata : in std_logic_vector(g_axi_data_width - 1 downto 0);
      i_axi_ddr_rlast : in std_logic;
      o_axi_ddr_rready : out std_logic;
      i_axi_ddr_rresp : in std_logic_vector(1 downto 0);
      i_axi_ddr_rvalid : in std_logic;

      o_axi_ddr_awaddr : out std_logic_vector(g_axi_addr_width - 1 downto 0);
      o_axi_ddr_awburst : out std_logic_vector(1 downto 0);
      o_axi_ddr_awcache : out std_logic_vector(3 downto 0);
      o_axi_ddr_awlen : out std_logic_vector(7 downto 0);
      o_axi_ddr_awprot : out std_logic_vector(2 downto 0);
      i_axi_ddr_awready : in std_logic;
      o_axi_ddr_awsize : out std_logic_vector(2 downto 0);
      o_axi_ddr_awvalid : out std_logic;
      o_axi_ddr_wdata : out std_logic_vector(g_axi_data_width - 1 downto 0);
      o_axi_ddr_wlast : out std_logic;
      i_axi_ddr_wready : in std_logic;
      i_axi_ddr_bresp : in std_logic_vector(1 downto 0);
      o_axi_ddr_wvalid : out std_logic;
      o_axi_ddr_wstrb : out std_logic_vector(3 downto 0);
      i_axi_ddr_bvalid : in std_logic;
      o_axi_ddr_bready : out std_logic;

      i_ddr_address : in std_logic_vector(23 downto 0);
      i_ddr_data : in std_logic_vector(7 downto 0);
      o_ddr_data : out std_logic_vector(7 downto 0);
      i_ddr_mem_wr : in std_logic;
      i_ddr_mem_req : in std_logic;
      o_ddr_mem_busy : out std_logic

    );

end axi_ddr_top;

architecture rtl of axi_ddr_top is

  component axi_ddr
    generic (
      g_axi_ddr_data_width : integer := 8;
      g_axi_ddr_addr_width : integer := 24;
      g_axi_data_width : integer := 32;
      g_axi_addr_width : integer := 32
    );
    port ( 
      i_resetn_sys : in std_logic;
      i_aclk_sys : in std_logic;

      o_axi_ddr_araddr : out std_logic_vector(g_axi_addr_width - 1 downto 0);
      o_axi_ddr_arburst : out std_logic_vector(1 downto 0);
      o_axi_ddr_arcache : out std_logic_vector(3 downto 0);
      o_axi_ddr_arlen : out std_logic_vector(7 downto 0);
      o_axi_ddr_arprot : out std_logic_vector(2 downto 0);
      i_axi_ddr_arready : in std_logic;
      o_axi_ddr_arsize : out std_logic_vector(2 downto 0);
      o_axi_ddr_arvalid : out std_logic;
      i_axi_ddr_rdata : in std_logic_vector(g_axi_data_width - 1 downto 0);
      i_axi_ddr_rlast : in std_logic;
      o_axi_ddr_rready : out std_logic;
      i_axi_ddr_rresp : in std_logic_vector(1 downto 0);
      i_axi_ddr_rvalid : in std_logic;

      o_axi_ddr_awaddr : out std_logic_vector(g_axi_addr_width - 1 downto 0);
      o_axi_ddr_awburst : out std_logic_vector(1 downto 0);
      o_axi_ddr_awcache : out std_logic_vector(3 downto 0);
      o_axi_ddr_awlen : out std_logic_vector(7 downto 0);
      o_axi_ddr_awprot : out std_logic_vector(2 downto 0);
      i_axi_ddr_awready : in std_logic;
      o_axi_ddr_awsize : out std_logic_vector(2 downto 0);
      o_axi_ddr_awvalid : out std_logic;
      o_axi_ddr_wdata : out std_logic_vector(g_axi_data_width - 1 downto 0);
      o_axi_ddr_wlast : out std_logic;
      i_axi_ddr_wready : in std_logic;
      i_axi_ddr_bresp : in std_logic_vector(1 downto 0);
      o_axi_ddr_wvalid : out std_logic;
      o_axi_ddr_wstrb : out std_logic_vector(3 downto 0);
      i_axi_ddr_bvalid : in std_logic;
      o_axi_ddr_bready : out std_logic;

      i_ddr_address : in std_logic_vector(23 downto 0);
      i_ddr_data : in std_logic_vector(7 downto 0);
      o_ddr_data : out std_logic_vector(7 downto 0);
      i_ddr_mem_wr : in std_logic;
      i_ddr_mem_req : in std_logic;
      o_ddr_mem_busy : out std_logic

    );
  end component;


begin

  i_axi_ddr : axi_ddr
    generic map(
      g_axi_ddr_data_width => g_axi_ddr_data_width,
      g_axi_ddr_addr_width => g_axi_ddr_addr_width,
      g_axi_data_width => g_axi_data_width,
      g_axi_addr_width => g_axi_addr_width
    )
    port map (
      i_resetn_sys => i_resetn_sys,
      i_aclk_sys => i_aclk_sys,
      
      o_axi_ddr_araddr => o_axi_ddr_araddr,
      o_axi_ddr_arburst => o_axi_ddr_arburst,
      o_axi_ddr_arcache => o_axi_ddr_arcache,
      o_axi_ddr_arlen => o_axi_ddr_arlen,
      o_axi_ddr_arprot => o_axi_ddr_arprot,
      i_axi_ddr_arready => i_axi_ddr_arready,
      o_axi_ddr_arsize => o_axi_ddr_arsize,
      o_axi_ddr_arvalid => o_axi_ddr_arvalid,
      i_axi_ddr_rdata => i_axi_ddr_rdata,
      i_axi_ddr_rlast => i_axi_ddr_rlast,
      o_axi_ddr_rready => o_axi_ddr_rready,
      i_axi_ddr_rresp => i_axi_ddr_rresp,
      i_axi_ddr_rvalid => i_axi_ddr_rvalid,

      o_axi_ddr_awaddr => o_axi_ddr_awaddr,
      o_axi_ddr_awburst => o_axi_ddr_awburst,
      o_axi_ddr_awcache => o_axi_ddr_awcache,
      o_axi_ddr_awlen => o_axi_ddr_awlen,
      o_axi_ddr_awprot => o_axi_ddr_awprot,
      i_axi_ddr_awready => i_axi_ddr_awready,
      o_axi_ddr_awsize => o_axi_ddr_awsize,
      o_axi_ddr_awvalid => o_axi_ddr_awvalid,
      o_axi_ddr_wdata => o_axi_ddr_wdata,
      o_axi_ddr_wlast => o_axi_ddr_wlast,
      i_axi_ddr_wready => i_axi_ddr_wready,
      i_axi_ddr_bresp => i_axi_ddr_bresp,
      o_axi_ddr_wvalid => o_axi_ddr_wvalid,
      o_axi_ddr_wstrb => o_axi_ddr_wstrb,
      i_axi_ddr_bvalid => i_axi_ddr_bvalid,
      o_axi_ddr_bready => o_axi_ddr_bready,

      i_ddr_address => i_ddr_address,
      i_ddr_data => i_ddr_data,
      o_ddr_data => o_ddr_data,
      i_ddr_mem_wr => i_ddr_mem_wr,
      i_ddr_mem_req => i_ddr_mem_req,
      o_ddr_mem_busy => o_ddr_mem_busy
    );

end architecture;
