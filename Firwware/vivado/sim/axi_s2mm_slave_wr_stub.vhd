----------------------------------------------------------------------------------
-- Company: Magictale Electronics http://magictale.com
-- Engineer: Dmitry Pakhomenko
-- 
-- Create Date: 25.11.2023 9:25:00 PM
-- Design Name: AXI writing stream stub
-- Module Name: scandoubler2mem - RTL
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
-- Additional Comments:
-- 
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library xil_defaultlib;
use work.types_arty_video.all;

entity axi_s2mm_slave_wr_stub is
    generic (
      g_axi_data_width : integer := 32;
      g_axi_lite_data_width : integer := 32;
      g_axi_addr_width : integer := 32
    );
    port(
      i_resetn_sys : in std_logic;
      i_aclk_sys : in std_logic;

      -- AXI
      i_axi_s2mm_awaddr : in std_logic_vector(g_axi_addr_width - 1 downto 0);
      i_axi_s2mm_awburst : in std_logic_vector(1 downto 0);
      i_axi_s2mm_awcache : in std_logic_vector(3 downto 0);
      i_axi_s2mm_awlen : in std_logic_vector(7 downto 0);
      i_axi_s2mm_awprot : in std_logic_vector(2 downto 0);
      o_axi_s2mm_awready : out std_logic;
      i_axi_s2mm_awsize : in std_logic_vector(2 downto 0);
      i_axi_s2mm_awvalid : in std_logic;
      i_axi_s2mm_wdata : in std_logic_vector(g_axi_data_width - 1 downto 0);
      i_axi_s2mm_wlast : in std_logic;
      o_axi_s2mm_wready : out std_logic;
      o_axi_s2mm_bresp : out std_logic_vector(1 downto 0);
      i_axi_s2mm_wvalid : in std_logic;
      i_axi_s2mm_wstrb : in std_logic_vector(3 downto 0);
      o_axi_s2mm_bvalid : out std_logic;
      i_axi_s2mm_bready : in std_logic
  );
end axi_s2mm_slave_wr_stub;

architecture rtl of axi_s2mm_slave_wr_stub is

  type t_state_amba is (t_idle_amba, t_wait_data_valid_amba, t_write_amba, 
    t_sync_handle_amba, t_write_amba_last, t_write_ack_amba, t_error_amba, t_done_amba);

  -- AMBA specific (DMA)
  signal s_state_amba : t_state_amba := t_idle_amba;

begin

  -- p_amba_slave_stub_fsm: AMBA FSM to write into RAM
  -----------------------------------------
  p_amba_slave_stub_fsm : process(i_aclk_sys)
  begin
    if rising_edge(i_aclk_sys) then
      if (i_resetn_sys = '0') then
        s_state_amba <= t_idle_amba;
        o_axi_s2mm_awready <= '0';
        o_axi_s2mm_bvalid <= '0';
        o_axi_s2mm_bresp <= "00";
        o_axi_s2mm_wready <= '0';
      else
        case s_state_amba is
          when t_idle_amba =>
            o_axi_s2mm_bvalid <= '0';
            if (i_axi_s2mm_awvalid = '1') then
              o_axi_s2mm_awready <= '1';
              o_axi_s2mm_wready <= '1';
              s_state_amba <= t_wait_data_valid_amba;
            end if;
          when t_wait_data_valid_amba =>
            if (i_axi_s2mm_wvalid = '1') then
              if (i_axi_s2mm_wlast = '1') then
                s_state_amba <= t_write_amba_last;
              else
                s_state_amba <= t_write_amba;
              end if;
            end if;
          when t_write_amba =>
            if (i_axi_s2mm_wlast = '1') then
              s_state_amba <= t_write_amba_last;
            end if;
          when t_write_amba_last => 
            if (i_axi_s2mm_wlast = '0') and (i_axi_s2mm_wvalid = '0') then
              o_axi_s2mm_bvalid <= '1';
              o_axi_s2mm_bresp <= "00";
              s_state_amba <= t_write_ack_amba;
            end if;
          when t_write_ack_amba => 
            if (i_axi_s2mm_bready = '1') then
              o_axi_s2mm_bvalid <= '0';
              o_axi_s2mm_awready <= '0';
              o_axi_s2mm_wready <= '0';
              s_state_amba <= t_idle_amba;
            end if;
          when others => null;
        end case;
      end if;
    end if;
  end process;

end rtl;

