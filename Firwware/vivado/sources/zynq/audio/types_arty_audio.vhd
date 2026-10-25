----------------------------------------------------------------------------------
-- Company: Magictale Electronics http://magictale.com
-- Engineer: Dmitry Pakhomenko
-- 
-- Create Date: 25.11.2023 5:47:00 PM
-- Design Name: audio type definitions, constant definitions
-- Module Name: types_arty_audio - RTL
-- Project Name: Retro computer emulator on Arty Z7/AX7020 boards
-- Target Devices: Zynq 7020
-- Tool Versions: Vivado 2017.3
-- Description: audio types and constants
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

package types_arty_audio is

-- Audio DAC
  constant c_left_jstfd_mode : integer := 1; -- 0 for I2S mode
---PWM
  constant c_pwm_data_width : integer := 10;
  constant c_pwm_width : unsigned(c_pwm_data_width - 1 downto 0) := ( others => '1' );
--arty_audio_mixer  
  constant c_weight_resolution_bits : integer := 24;
  constant c_in_audio_resolution_bits : integer := 16;
  constant c_out_audio_resolution_bits : integer := 16;

  type t_sm_mixer is (s_mixer_step1, s_mixer_step2);
  type t_array_5xu16_8 is array (0 to 31) of unsigned(c_weight_resolution_bits - 1 downto 0);

  constant c_divider_table : t_array_5xu16_8 := (
    x"000000", x"000100", x"000080", x"000055",--00,01,02,03 
    x"000040", x"000033", x"00002a", x"000024",--04,05,06,07 
    x"000020", x"00001c", x"000019", x"000017",--08,09,0a,0b 
    x"000015", x"000013", x"000012", x"000011",--0c,0d,0e,0f 
    x"000010", x"00000f", x"00000e", x"00000d",--10,11,12,13 
    x"00000c", x"00000c", x"00000b", x"00000b",--14,15,16,17 
    x"00000a", x"00000a", x"000009", x"000009",--18,19,1a,1b 
    x"000009", x"000008", x"000008", x"000008" --1c,1d,1e,1f
  );

  constant c_out_res_zeroes : unsigned(c_out_audio_resolution_bits - 1 downto 0) := (others => '0');
  constant c_in_res_zeroes : unsigned(c_in_audio_resolution_bits - 1 downto 0) := (others => '0');
  constant c_24b_FF : unsigned(c_weight_resolution_bits - 1 downto 0) := x"0000FF";
  constant c_in_res_ones : unsigned(c_in_audio_resolution_bits - 1 downto 0) := (others => '1');

--arty_audio_top
  type  t_array_3x24   is array (0 to 2) of unsigned( 23 downto 0);
  type  t_weight_array is array (0 to 3, 0 to 1) of t_array_3x24;

  -- A B C (L)  A B C (R)
  constant s_weigth_vol_table : t_weight_array := (
    ((x"000000",x"000000",x"000000"),(x"000000",x"000000",x"000000")),
    ((x"000092",x"000007",x"000066"),(x"000007",x"000092",x"000066")),
    ((x"000092",x"000066",x"000007"),(x"000007",x"000066",x"000092")),
    ((x"000055",x"000055",x"000055"),(x"000055",x"000055",x"000055")));

  type sin_type is array (0 to 127) of std_logic_vector( 10 downto 0 ); 
  constant sin_data : sin_type := (
    "11111111111", "11001010000", "10101010001", "10010111100",
    "10001010011", "10000000001", "01110111110", "01110000101",
    "01101010101", "01100101001", "01100000011", "01011100000",
    "01011000000", "01010100011", "01010001000", "01001101111",
    "01001011000", "01001000010", "01000101101", "01000011010",
    "01000000111", "00111110110", "00111100101", "00111010101",
    "00111000110", "00110110111", "00110101001", "00110011100",
    "00110001111", "00110000011", "00101110111", "00101101011",
    "00101100000", "00101010110", "00101001011", "00101000001",
    "00100111000", "00100101110", "00100100101", "00100011100",
    "00100010100", "00100001011", "00100000011", "00011111011",
    "00011110100", "00011101100", "00011100101", "00011011110",
    "00011010111", "00011010001", "00011001010", "00011000100",
    "00010111110", "00010111000", "00010110010", "00010101100",
    "00010100111", "00010100001", "00010011100", "00010010111",
    "00010010010", "00010001101", "00010001000", "00010000011",
    "00001111111", "00001111010", "00001110110", "00001110010",
    "00001101110", "00001101010", "00001100110", "00001100010",
    "00001011110", "00001011010", "00001010111", "00001010011",
    "00001010000", "00001001101", "00001001001", "00001000110",
    "00001000011", "00001000000", "00000111101", "00000111011",
    "00000111000", "00000110101", "00000110011", "00000110000",
    "00000101110", "00000101011", "00000101001", "00000100111",
    "00000100101", "00000100010", "00000100000", "00000011110",
    "00000011101", "00000011011", "00000011001", "00000010111",
    "00000010110", "00000010100", "00000010011", "00000010001",
    "00000010000", "00000001110", "00000001101", "00000001100",
    "00000001011", "00000001010", "00000001001", "00000001000",
    "00000000111", "00000000110", "00000000101", "00000000100",
    "00000000011", "00000000011", "00000000010", "00000000010",
    "00000000001", "00000000001", "00000000000", "00000000000",
    "00000000000", "00000000000", "00000000000", "00000000000"
    );

 
end;-- package types_arty_audio;

