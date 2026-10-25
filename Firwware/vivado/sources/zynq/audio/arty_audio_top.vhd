----------------------------------------------------------------------------------
-- Company: Magictale Electronics http://magictale.com
-- Engineer: Dmitry Pakhomenko
-- 
-- Create Date: 25.11.2023 5:43:00 PM
-- Design Name: Arty Z7 audio subsystem
-- Module Name: arty_audio_top - RTL
-- Project Name: MSX retro computer emulator on Arty Z7/AX7020 boards
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
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library xil_defaultlib;
use work.types_arty_audio.all;

entity arty_audio_top is
  port (
    i_clk : in std_logic; 
    i_resetn : in std_logic; 
    i_ctrl_mode : in std_logic;

    i_in1_ch_a : in std_logic_vector(c_in_audio_resolution_bits - 1 downto 0);
    i_in1_ch_b : in std_logic_vector(c_in_audio_resolution_bits - 1 downto 0);
    i_in1_ch_c : in std_logic_vector(c_in_audio_resolution_bits - 1 downto 0);

    i_in2_ch_a : in std_logic_vector(c_in_audio_resolution_bits - 1 downto 0);
    i_in2_ch_b : in std_logic_vector(c_in_audio_resolution_bits - 1 downto 0);
    i_in2_ch_c : in std_logic_vector(c_in_audio_resolution_bits - 1 downto 0);

    i_in3 : in std_logic_vector(c_in_audio_resolution_bits - 1 downto 0);
    i_in4 : in std_logic_vector(c_in_audio_resolution_bits - 1 downto 0);
    i_in5 : in std_logic_vector(c_out_audio_resolution_bits - 1 downto 0);

    i_audio_beeper : in std_logic;
    i_audio_tape : in std_logic;

    i_in1_enabled : in std_logic;
    i_in2_enabled : in std_logic;
    i_in3_enabled : in std_logic;
    i_in4_enabled : in std_logic;
    i_in5_enabled : in std_logic;

    o_pwm_out : out std_logic;

    o_bclk : out std_logic;
    o_lrclk : out std_logic;
    o_sdat : out std_logic
  );
end;

architecture rtl of arty_audio_top is

  signal s_pwm_val : std_logic_vector(c_out_audio_resolution_bits - 1 downto 0);
  signal s_mix_mode3 : unsigned(7 downto 0) := x"03";
  signal s_mix_mode1 : unsigned(7 downto 0) := x"01";
  signal s_weight_3ch : t_array_3x24;

  signal s_sampling_counter : integer := 256;
  signal s_counter_dir : std_logic := '1';
  signal s_sine_counter : integer := 0;
  
  signal s_sin_wave : std_logic_vector(c_out_audio_resolution_bits - 1 downto 0);

  component arty_audio_mixer
    port (
      i_clk : in std_logic; 
      i_in1_ch_a : in std_logic_vector(c_in_audio_resolution_bits - 1 downto 0);
      i_in1_ch_b : in std_logic_vector(c_in_audio_resolution_bits - 1 downto 0);
      i_in1_ch_c : in std_logic_vector(c_in_audio_resolution_bits - 1 downto 0);
      i_in2_ch_a : in std_logic_vector(c_in_audio_resolution_bits - 1 downto 0);
      i_in2_ch_b : in std_logic_vector(c_in_audio_resolution_bits - 1 downto 0);
      i_in2_ch_c : in std_logic_vector(c_in_audio_resolution_bits - 1 downto 0);
      i_weight_in1_ch_a : in std_logic_vector(c_weight_resolution_bits - 1 downto 0);
      i_weight_in1_ch_b : in std_logic_vector(c_weight_resolution_bits - 1 downto 0);
      i_weight_in1_ch_c : in std_logic_vector(c_weight_resolution_bits - 1 downto 0);
      i_weight_in2_ch_a : in std_logic_vector(c_weight_resolution_bits - 1 downto 0);
      i_weight_in2_ch_b : in std_logic_vector(c_weight_resolution_bits - 1 downto 0);
      i_weight_in2_ch_c : in std_logic_vector(c_weight_resolution_bits - 1 downto 0);

      i_in3 : in std_logic_vector(c_in_audio_resolution_bits - 1 downto 0);
      i_in4 : in std_logic_vector(c_in_audio_resolution_bits - 1 downto 0);
      i_in5 : in std_logic_vector(c_out_audio_resolution_bits - 1 downto 0);
      i_weight_in3 : in std_logic_vector(c_weight_resolution_bits - 1 downto 0);
      i_weight_in4 : in std_logic_vector(c_weight_resolution_bits - 1 downto 0);
      i_weight_in5 : in std_logic_vector(c_weight_resolution_bits - 1 downto 0);

      i_audio_beeper : in std_logic;
      i_audio_tape : in std_logic;
      i_weight_beeper : in std_logic_vector(c_weight_resolution_bits - 1 downto 0); 
      i_weight_tape : in std_logic_vector(c_weight_resolution_bits - 1 downto 0); 

      i_in1_enabled : in std_logic;
      i_in2_enabled : in std_logic;
      i_in3_enabled : in std_logic;
      i_in4_enabled : in std_logic;
      i_in5_enabled : in std_logic;
      o_pwm_val : out std_logic_vector(c_out_audio_resolution_bits - 1 downto 0)
    );
  end component;

  component pwm
    port ( 
      i_clk : in std_logic;
      i_resetn : in std_logic;
      i_pwm_val : in std_logic_vector(c_pwm_data_width - 1 downto 0);
      o_pwm : out std_logic
    );
  end component;

  component i2s is
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
  end component;

begin

  i_arty_audio_mixer : arty_audio_mixer
    port map (
      i_clk => i_clk,

      i_in1_ch_a => i_in1_ch_a,
      i_in1_ch_b => i_in1_ch_b,
      i_in1_ch_c => i_in1_ch_c,
      i_weight_in1_ch_a => std_logic_vector(s_weight_3ch(0)),
      i_weight_in1_ch_b => std_logic_vector(s_weight_3ch(1)),
      i_weight_in1_ch_c => std_logic_vector(s_weight_3ch(2)),

      i_in2_ch_a => i_in2_ch_a,
      i_in2_ch_b => i_in2_ch_b,
      i_in2_ch_c => i_in2_ch_c,
      i_weight_in2_ch_a => std_logic_vector(s_weight_3ch(0)),
      i_weight_in2_ch_b => std_logic_vector(s_weight_3ch(1)),
      i_weight_in2_ch_c => std_logic_vector(s_weight_3ch(2)),

      i_in3 => i_in3,
      i_in4 => i_in4,
      i_in5 => i_in5,
      i_weight_in3 => std_logic_vector(s_weight_3ch(0)),
      i_weight_in4 => std_logic_vector(s_weight_3ch(0)),
      i_weight_in5 => std_logic_vector(s_weight_3ch(0)),

      i_audio_beeper => i_audio_beeper,
      i_audio_tape => i_audio_tape,
      i_weight_beeper => std_logic_vector(s_weight_3ch(0)),
      i_weight_tape => std_logic_vector(s_weight_3ch(0)),

      i_in1_enabled => i_in1_enabled,
      i_in2_enabled => i_in2_enabled,
      i_in3_enabled => i_in3_enabled,
      i_in4_enabled => i_in4_enabled,
      i_in5_enabled => i_in5_enabled,

      o_pwm_val => s_pwm_val
    );

  i_pwm : pwm
    port map (
      i_clk => i_clk,
      i_resetn => i_resetn,
      i_pwm_val => i_in1_ch_c(14 downto 5), --s_pwm_val(20 downto 9),
      o_pwm => o_pwm_out
    );

  i_i2s : i2s
    port map (
      i_clk => i_clk,
      i_resetn => i_resetn,
      i_ce => '1',

      i_left_chan => s_sin_wave, --s_pwm_val,
      i_right_chan => s_sin_wave, -- s_pwm_val, 

      o_bclk => o_bclk,
      o_lrclk => o_lrclk,
      o_sdat => o_sdat
    );


  process(i_clk)
  begin
    if rising_edge(i_clk) then
      if i_ctrl_mode = '0' then
        s_weight_3ch <= s_weigth_vol_table(to_integer(s_mix_mode3), 0);
      else
        s_weight_3ch <= s_weigth_vol_table(to_integer(s_mix_mode1), 0);
      end if;
   end if;
  end process;

  process(i_clk)
  begin
    if rising_edge(i_clk) then
      if (s_sampling_counter = 0) then
        if (s_counter_dir = '1') then
          s_sine_counter <= s_sine_counter + 1;
          if (s_sine_counter = 127) then 
            s_counter_dir <= not s_counter_dir;
          end if;
        else
          s_sine_counter <= s_sine_counter - 1;
          if (s_sine_counter = 1) then 
            s_counter_dir <= not s_counter_dir;
          end if;
        end if;
        s_sin_wave <= sin_data(s_sine_counter) & "000000000000000000000";
        s_sampling_counter <= 255;
      else
        s_sampling_counter <= s_sampling_counter - 1;
      end if;        
   end if;
  end process;


end architecture rtl;
