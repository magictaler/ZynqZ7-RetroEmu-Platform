----------------------------------------------------------------------------------
-- Company: Magictale Electronics http://magictale.com
-- Engineer: Dmitry Pakhomenko
-- 
-- Create Date: 25.11.2023 11:25:00 AM
-- Design Name: AXI DDR memory interface type definitions, constant definitions
-- Module Name: types_axi_ddr - RTL
-- Project Name: Retro computer emulator on Arty Z7 board
-- Target Devices: Zynq 7020
-- Tool Versions: Vivado 2017.3
-- Description: AXI DDR memory interface types and constants
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

package types_axi_ddr is

  -- AXI (AMBA) specific
  constant c_axi_arsize                   : integer range 0 to 7 := 2; -- burst size. '0' means 1 byte per transfer, '2' means 4 bytes
  constant c_axi_arlen                    : integer range 0 to 7 := 1; -- burst length. '0' means 1 transfer in a burst
  constant c_axi_arburst                  : integer range 0 to 3 := 1; -- burst type. '1' means incrementing
  constant c_axi_ram_start_address        : integer := 99614720; -- default start address of the memory segment (0x5700000 (video frame buffer start address) + 0x800000(max video frame buffer size))
  constant c_axi_awsize                   : integer range 0 to 7 := 2; -- burst size. '0' means 1 byte per transfer, '2' means 4 bytes
  constant c_axi_awlen                    : integer range 0 to 7 := 0; -- burst length. '0' means 1 transfer in a burst
  constant c_axi_awburst                  : integer range 0 to 3 := 1; -- burst type. '1' means incrementing
  constant c_axi_cache                    : std_logic_vector(3 downto 0) := "0011";
 
  -- AXI (AMBA) specific 
  type t_state_amba is (t_idle_amba, t_set_addr_amba, t_wait_addr_ack_amba, t_wait_data_start_amba, t_read_amba, t_write_amba, t_write_ack_amba, t_error_amba, t_done_amba);

  constant c_active_high_raising_edge : std_logic_vector(1 downto 0) := "01";
 
end;-- package types_axi_ddr;

