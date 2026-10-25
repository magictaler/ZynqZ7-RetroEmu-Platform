----------------------------------------------------------------------------------
-- Company: Magictale Electronics http://magictale.com
-- Engineer: Dmitry Pakhomenko
-- 
-- Create Date: 24.08.2024 9:25:00 AM
-- Design Name: PS2 keyboard emulator type definitions, constant definitions
-- Module Name: types_ps2_kbd_emu - RTL
-- Project Name: Retro computer emulator on Arty Z7 board
-- Target Devices: Zynq 7020
-- Tool Versions: Vivado 2017.3
-- Description: PS2 keyboards emulator types and constants
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

package types_ps2_kbd_emu is

  constant c_active_high_raising_edge : std_logic_vector(1 downto 0) := "01";
  constant c_active_high_falling_edge : std_logic_vector(1 downto 0) := "10";

  constant c_ps2_fifo_data_width : integer range 0 to 16 := 16;
  constant c_ps2_fifo_msb_bit    : integer range 0 to 31 := 10;
  constant c_ps2_fifo_lsb_bit    : integer range 0 to 31 := 0;

  constant joy_a_emu_down_bit : integer range 0 to 6 := 0;
  constant joy_a_emu_up_bit : integer range 0 to 6 := 1;
  constant joy_a_emu_right_bit : integer range 0 to 6 := 2;
  constant joy_a_emu_left_bit : integer range 0 to 6 := 3;
  constant joy_a_emu_trigger_a_bit : integer range 0 to 6 := 4;
  constant joy_a_emu_trigger_b_bit : integer range 0 to 6 := 5;

  constant c_ps2_ext_prefix : std_logic_vector(7 downto 0) := x"E0";
  constant c_ps2_pause_prefix_make : std_logic_vector(7 downto 0) := x"E1";
  constant c_ps2_prefix_break : std_logic_vector(7 downto 0) := x"F0";
  constant c_ps2_prtsc: std_logic_vector(7 downto 0) := x"12";
  constant c_ps2_prtsc_br_3rd_bt: std_logic_vector(7 downto 0) := x"7C";

  constant c_ps2_numpad_4 : std_logic_vector(7 downto 0) := x"6B"; -- left
  constant c_ps2_numpad_6 : std_logic_vector(7 downto 0) := x"74"; -- right
  constant c_ps2_numpad_8 : std_logic_vector(7 downto 0) := x"75"; -- up
  constant c_ps2_numpad_2 : std_logic_vector(7 downto 0) := x"72"; -- down
  constant c_ps2_numpad_5 : std_logic_vector(7 downto 0) := x"73"; -- trigger a
  constant c_ps2_numpad_0 : std_logic_vector(7 downto 0) := x"70"; -- trigger b

  constant c_ps2_mouse_ack : std_logic_vector(7 downto 0) := x"FA";
  constant c_ps2_mouse_id : std_logic_vector(7 downto 0) := x"00";
  constant c_ps2_mouse_stest_ok : std_logic_vector(7 downto 0) := x"AA";
  constant c_ps2_mouse_reset : std_logic_vector(7 downto 0) := x"FF";
  constant c_ps2_mouse_enable : std_logic_vector(7 downto 0) := x"F4";

  component fifo_1024_16
    port ( 
      wr_clk : in std_logic;
      rd_clk : in std_logic;
      rst : in std_logic;
      din : in std_logic_vector(c_ps2_fifo_data_width - 1 downto 0);
      wr_en : in std_logic;
      rd_en : in std_logic;
      dout : out std_logic_vector(c_ps2_fifo_data_width - 1 downto 0);
      full : out std_logic;
      overflow : out std_logic;
      empty : out std_logic;
      underflow : out std_logic
    );
  end component;

  component ps2 is
    port ( 
      i_resetn_sys : in std_logic;
      i_aclk_sys : in std_logic;
      io_ps_clk : inout std_logic;
      io_ps_dat : inout std_logic;
      o_data : out std_logic_vector(7 downto 0);
      i_data : in  std_logic_vector(7 downto 0);
      i_ibf_clr : in  std_logic;
      i_obf_set : in  std_logic;
      o_ibf : out std_logic;
      o_obf : out std_logic;
      o_busy : out std_logic
    );
  end component;

end;-- package types_ps2_kbd_demo;

