----------------------------------------------------------------------------------
-- Company: Magictale Electronics http://magictale.com
-- Engineer: Dmitry Pakhomenko
-- 
-- Create Date: 27.11.2023 4:47:00 PM
-- Design Name: PWM module
-- Module Name: pwm - RTL
-- Project Name: MSX retro computer emulator on Arty Z7 board
-- Target Devices: Zynq 7020
-- Tool Versions: Vivado 2017.3
-- Description: This module is designed to work as part of audio subsystem
-- to emulate functionality of a beeper and chiptune ICs
-- 
-- Dependencies: no
-- 
-- Revision:
-- Revision 0.01 - Copied across from Speccy2022 project and refactored
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library xil_defaultlib;
use work.types_arty_audio.all;

entity pwm is
  port (
    i_clk : in std_logic;
    i_resetn : in std_logic;
    i_pwm_val : in std_logic_vector(c_pwm_data_width - 1 downto 0);

    o_pwm : out std_logic
  );
end pwm;

architecture rtl of pwm is

  signal s_max_count : unsigned(c_pwm_data_width - 1 downto 0);
  signal s_pwm_counter : unsigned(c_pwm_data_width - 1 downto 0);

begin
  p_state_out : process(i_clk)
  begin
    if rising_edge(i_clk) then
      if (i_resetn = '0') then
        s_max_count <= (others => '0');
        s_pwm_counter <= (others => '0');
        o_pwm <= '0';
      else
        if (s_pwm_counter < s_max_count) then
          o_pwm <= '1';
        elsif (s_pwm_counter /= c_pwm_width) then
          o_pwm <= '0';
        else
          s_max_count <= unsigned(i_pwm_val);
          o_pwm <= '0';
        end if;
        s_pwm_counter <= s_pwm_counter + 1;
      end if;
    end if;
  end process p_state_out;

end architecture rtl;
    