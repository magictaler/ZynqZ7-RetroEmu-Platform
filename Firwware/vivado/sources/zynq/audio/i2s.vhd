----------------------------------------------------------------------------------
-- Company: Magictale Electronics http://magictale.com
-- Engineer: Dmitry Pakhomenko
-- 
-- Create Date: 17.11.2024 10:18:00 PM
-- Design Name: i2s module
-- Module Name: i2s - RTL
-- Project Name: MSX retro computer emulator on Arty Z7/AX7020 boards
-- Target Devices: Zynq 7020
-- Tool Versions: Vivado 2017.3
-- Description: This module is designed to work as part of audio subsystem
-- to interface with stereo audio DAC via i2s
-- 
-- Dependencies: no
-- 
-- Revision:
-- Revision 0.01 - initial minimalistic implementation
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library xil_defaultlib;
use work.types_arty_audio.all;

entity i2s is
  port (
    i_clk : in std_logic;
    i_resetn : in std_logic;
    i_ce : in std_logic;

    i_left_chan : in std_logic_vector(c_out_audio_resolution_bits - 1 downto 0);
    i_right_chan : in std_logic_vector(c_out_audio_resolution_bits - 1 downto 0);

    o_bclk : out std_logic;
    o_lrclk : out std_logic;
    o_sdat : out std_logic
  );
end i2s;

architecture rtl of i2s is

  signal s_bt_count : integer range 1 to 32 := 1;
  signal s_bclk : std_logic;
  signal s_lrclk : std_logic;
  signal s_sdat : std_logic;
  signal s_left_chan : std_logic_vector(c_out_audio_resolution_bits - 1 downto 0);
  signal s_right_chan : std_logic_vector(c_out_audio_resolution_bits - 1 downto 0);

  signal s_counter_dir : std_logic := '1';
  signal s_sine_counter : integer := 0;
  signal s_sin_wave : std_logic_vector(c_out_audio_resolution_bits - 1 downto 0);
  signal s_sin_wave_tmp : integer;
  signal s_wave_sign : std_logic := '0';

begin
  p_state_out : process(i_clk)
  begin
    if rising_edge(i_clk) then
      if (i_resetn = '0') then
        s_bt_count <= 1;
        s_bclk <= '1';
        s_lrclk <= '1';
        s_sdat <= '1';
      else
        if (i_ce = '1') then
          s_bclk <= not s_bclk;
          if (s_bclk = '1') then
            if (s_bt_count = c_out_audio_resolution_bits) then 
              s_bt_count <= 1;
              s_lrclk <= not s_lrclk;
              if (s_lrclk = '1') then
                s_left_chan <= i_left_chan; --s_sin_wave;
                s_right_chan <= i_right_chan; --s_sin_wave;
              end if;
            else
              s_bt_count <= s_bt_count + 1;
            end if;
            if (s_lrclk = '1') then
              s_sdat <= s_right_chan(c_out_audio_resolution_bits - s_bt_count);
            else
              s_sdat <= s_left_chan(c_out_audio_resolution_bits - s_bt_count);
            end if;
          end if;
        end if;
      end if;
    end if;
  end process p_state_out;

  process(i_clk)
  begin
    if rising_edge(i_clk) then
      if (i_resetn = '0') then
        s_sine_counter <=  127;
        s_counter_dir <= '0';
        s_wave_sign <= '1';
      else
        if (i_ce = '1') and (s_bclk = '1') and (s_bt_count = c_out_audio_resolution_bits) and ((s_lrclk = '1')) then
          if (s_counter_dir = '1') then
            s_sine_counter <= s_sine_counter + 1;
            if (s_sine_counter = 126) then 
              s_counter_dir <= not s_counter_dir;
            end if;
          else
            s_sine_counter <= s_sine_counter - 1;
            if (s_sine_counter = 1) then 
              s_counter_dir <= not s_counter_dir;
              s_wave_sign <= not s_wave_sign;
            end if;
          end if;
          if (s_wave_sign = '0') then
            s_sin_wave_tmp <= to_integer(unsigned(sin_data(s_sine_counter))) - 2047;
          else
            s_sin_wave_tmp <= 2047 - to_integer(unsigned(sin_data(s_sine_counter)));
          end if;
        end if;        
     end if;
   end if;
  end process;

  s_sin_wave <= std_logic_vector(to_signed(s_sin_wave_tmp, s_sin_wave'length));

  o_bclk <= s_bclk;
  o_lrclk <= s_lrclk;
  o_sdat <= s_sdat;

end architecture rtl;
    
