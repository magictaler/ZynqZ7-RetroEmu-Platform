----------------------------------------------------------------------------------
-- Company: Magictale Electronics http://magictale.com
-- Engineer: Dmitry Pakhomenko
-- 
-- Create Date: 29.03.2024 1:36:00 PM
-- Design Name: AXI reading stream stub
-- Module Name: axi_s2mm_slave_rd_stub - RTL
-- Project Name: Retro computer emulator on Arty Z7 board
-- Target Devices: Zynq 7020
-- Tool Versions: Vivado 2017.3
-- Description: This module emulates streaming AXI interface in reading mode
-- Dependencies: 
-- 
-- Revision:
-- 
-- Revision 0.01 - Initial implementation
-- Additional Comments:
-- 
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library xil_defaultlib;
use work.types_arty_video.all;

entity axi_s2mm_slave_rd_stub is
    generic (
      g_axi_data_width : integer := 32;
      g_axi_lite_data_width : integer := 32;
      g_axi_addr_width : integer := 32
    );
    port(
      i_resetn_sys : in std_logic;
      i_aclk_sys : in std_logic;

      -- AXI
      i_axi_s2mm_araddr : in std_logic_vector (g_axi_addr_width - 1 downto 0);
      i_axi_s2mm_arburst : in std_logic_vector (1 downto 0);
      i_axi_s2mm_arcache : in std_logic_vector (3 downto 0);
      i_axi_s2mm_arlen : in std_logic_vector (7 downto 0);
      i_axi_s2mm_arprot : in std_logic_vector (2 downto 0);
      o_axi_s2mm_arready : out std_logic;
      i_axi_s2mm_arsize : in std_logic_vector (2 downto 0);
      i_axi_s2mm_arvalid : in std_logic;
      o_axi_s2mm_rdata : out std_logic_vector (g_axi_data_width - 1 downto 0);
      o_axi_s2mm_rlast : out std_logic;
      i_axi_s2mm_rready : in std_logic;
      o_axi_s2mm_rresp : out std_logic_vector (1 downto 0);
      o_axi_s2mm_rvalid : out std_logic
  );
end axi_s2mm_slave_rd_stub;

architecture rtl of axi_s2mm_slave_rd_stub is

  type t_state_amba is (t_idle_amba, t_wait_rready_amba, t_read_amba, 
    t_read_amba_last, t_error_amba, t_done_amba);

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
        o_axi_s2mm_arready <= '0';
        o_axi_s2mm_rlast <= '0';
        o_axi_s2mm_rresp <= "00";
        o_axi_s2mm_rvalid <= '0';
        o_axi_s2mm_rdata <= (others => '0');
      else
        case s_state_amba is
          when t_idle_amba =>
            if (i_axi_s2mm_arvalid = '1') then
              o_axi_s2mm_arready <= '1';
              s_state_amba <= t_wait_rready_amba;
            end if;
          when t_wait_rready_amba =>
            if (i_axi_s2mm_rready = '1') then
              s_state_amba <= t_read_amba;
            end if;
          when t_read_amba =>
            if (i_axi_s2mm_rready = '1') then
              o_axi_s2mm_rvalid <= '1';
              o_axi_s2mm_rdata <= (others => '1');
              s_state_amba <= t_read_amba_last;
            end if;
          when t_read_amba_last => 
            if (i_axi_s2mm_rready = '1') then
              o_axi_s2mm_rlast <= '1';
              s_state_amba <= t_done_amba;
            end if;
          when t_done_amba => 
            o_axi_s2mm_rvalid <= '0';
            o_axi_s2mm_rlast <= '0';
            o_axi_s2mm_rdata <= (others => '0');
            o_axi_s2mm_arready <= '0';
            s_state_amba <= t_idle_amba;
          when others => null;
        end case;
      end if;
    end if;
  end process;

end rtl;

