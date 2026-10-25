----------------------------------------------------------------------------------
-- Originally designed by SYD as part of Speccy2010 project
-- 
-- Code refactoring by Dmitry Pakomenko, 2024
-- Code cleanup by Dmitry Pakomenko, 2021
-- 
-- Design Name: digital audio mixer module
-- Module Name: arty_audio_mixer - RTL
-- Project Name: Retro computer emulator on Arty Z7 board
-- Target Devices: Zynq 7020
-- Tool Versions: Vivado 2017.3
-- Description: This module is designed to work as part of audio subsystem
-- to emulate functionality of a beeper and chiptune ICs
----------------------------------------------------------------------------------


library ieee;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library xil_defaultlib;
use work.types_arty_audio.all;

entity arty_audio_mixer is
  port (
    i_clk : in std_logic; 
    i_in1_ch_a : in std_logic_vector(c_in_audio_resolution_bits - 1 downto 0); --Input 1, subchannel A
    i_in1_ch_b : in std_logic_vector(c_in_audio_resolution_bits - 1 downto 0); --Input 1, subchannel B
    i_in1_ch_c : in std_logic_vector(c_in_audio_resolution_bits - 1 downto 0); --Input 1, subchannel C
    i_in2_ch_a : in std_logic_vector(c_in_audio_resolution_bits - 1 downto 0); --Input 2, subchannel A
    i_in2_ch_b : in std_logic_vector(c_in_audio_resolution_bits - 1 downto 0); --Input 2, subchannel B
    i_in2_ch_c : in std_logic_vector(c_in_audio_resolution_bits - 1 downto 0); --Input 2, subchannel C
    i_weight_in1_ch_a : in std_logic_vector(c_weight_resolution_bits - 1 downto 0); -- Input 1 - weights
    i_weight_in1_ch_b : in std_logic_vector(c_weight_resolution_bits - 1 downto 0); -- sum should be <= 1
    i_weight_in1_ch_c : in std_logic_vector(c_weight_resolution_bits - 1 downto 0);
    i_weight_in2_ch_a : in std_logic_vector(c_weight_resolution_bits - 1 downto 0); -- Input 2 - weights
    i_weight_in2_ch_b : in std_logic_vector(c_weight_resolution_bits - 1 downto 0); -- sum should be <= 1
    i_weight_in2_ch_c : in std_logic_vector(c_weight_resolution_bits - 1 downto 0);

    i_in3 : in std_logic_vector(c_in_audio_resolution_bits - 1 downto 0);
    i_in4 : in std_logic_vector(c_in_audio_resolution_bits - 1 downto 0);
    i_in5 : in std_logic_vector(c_out_audio_resolution_bits - 1 downto 0);
    i_weight_in3 : in std_logic_vector(c_weight_resolution_bits - 1 downto 0);
    i_weight_in4 : in std_logic_vector(c_weight_resolution_bits - 1 downto 0);
    i_weight_in5 : in std_logic_vector(c_weight_resolution_bits - 1 downto 0);

    i_audio_beeper : in std_logic;
    i_audio_tape : in std_logic;
    i_weight_beeper : in std_logic_vector(c_weight_resolution_bits - 1 downto 0); --beeper
    i_weight_tape : in std_logic_vector(c_weight_resolution_bits - 1 downto 0); --tape

    i_in1_enabled : in std_logic;
    i_in2_enabled : in std_logic;
    i_in3_enabled : in std_logic;
    i_in4_enabled : in std_logic;
    i_in5_enabled : in std_logic;
    o_pwm_val : out std_logic_vector(c_out_audio_resolution_bits - 1 downto 0)
  );
end;

architecture rtl of arty_audio_mixer is

  signal s_in1 : unsigned(c_weight_resolution_bits + c_in_audio_resolution_bits + c_out_audio_resolution_bits - 1 downto 0);
  signal s_in2 : unsigned(c_weight_resolution_bits + c_in_audio_resolution_bits + c_out_audio_resolution_bits - 1 downto 0);
  signal s_in3 : unsigned(c_weight_resolution_bits + c_in_audio_resolution_bits + c_out_audio_resolution_bits - 1 downto 0);
  signal s_in4 : unsigned(c_weight_resolution_bits + c_in_audio_resolution_bits + c_out_audio_resolution_bits - 1 downto 0);
  signal s_in5 : unsigned(c_weight_resolution_bits + c_in_audio_resolution_bits + c_out_audio_resolution_bits - 1 downto 0);
  signal s_in_beeper : unsigned(c_weight_resolution_bits + c_in_audio_resolution_bits + c_out_audio_resolution_bits - 1 downto 0);
  signal s_in_tape : unsigned(c_weight_resolution_bits + c_in_audio_resolution_bits + c_out_audio_resolution_bits - 1 downto 0);

  signal s_tmp_sum : unsigned(c_in_audio_resolution_bits + c_out_audio_resolution_bits - 1 downto 0);
  --signal s_pwm_val : std_logic_vector(c_out_audio_resolution_bits + c_weight_resolution_bits - 1 downto 0);
  signal s_pwm_val : std_logic_vector(39 downto 0) := (others => '0');

  signal s_weight_in1 : unsigned(c_weight_resolution_bits - 1 downto 0);
  signal s_weight_in2 : unsigned(c_weight_resolution_bits - 1 downto 0);
  signal s_weight_in3 : unsigned(c_weight_resolution_bits - 1 downto 0);
  signal s_weight_in4 : unsigned(c_weight_resolution_bits - 1 downto 0);
  signal s_weight_in5 : unsigned(c_weight_resolution_bits - 1 downto 0);
  signal s_weight_beeper : unsigned(c_weight_resolution_bits - 1 downto 0);
  signal s_weight_tape : unsigned(c_weight_resolution_bits - 1 downto 0);

  signal s_weight_sum : unsigned(c_weight_resolution_bits - 1 downto 0);
  signal s_sm_mixer : t_sm_mixer := s_mixer_step1;

begin
  p_audio_mixer : process(i_clk)
  begin
    if i_clk'event and i_clk = '1' then
      case s_sm_mixer is
        when s_mixer_step1 =>
          if i_in1_enabled = '1' then
            s_weight_in1 <= unsigned(i_weight_in1_ch_a) + unsigned(i_weight_in1_ch_b) + unsigned(i_weight_in1_ch_c);
            s_in1 <= (c_out_res_zeroes & unsigned(i_in1_ch_a)) * unsigned(i_weight_in1_ch_a) +
              (c_out_res_zeroes & unsigned(i_in1_ch_b)) * unsigned(i_weight_in1_ch_b) + 
              (c_out_res_zeroes & unsigned(i_in1_ch_c)) * unsigned(i_weight_in1_ch_c);
          else
            s_in1 <= (others => '0');
            s_weight_in1 <= (others => '0');
          end if;

          if i_in2_enabled = '1' then
            s_weight_in2 <= unsigned(i_weight_in2_ch_a) + unsigned(i_weight_in2_ch_b) + unsigned(i_weight_in2_ch_c);
            s_in2 <= (c_out_res_zeroes & unsigned(i_in2_ch_a)) * unsigned(i_weight_in2_ch_a) +
              (c_out_res_zeroes & unsigned(i_in2_ch_b)) * unsigned(i_weight_in2_ch_b) + 
              (c_out_res_zeroes & unsigned(i_in2_ch_c)) * unsigned(i_weight_in2_ch_c);
          else
            s_in2 <= (others => '0');
            s_weight_in2 <= (others => '0');
          end if;
      
          if i_in3_enabled = '1' then
            s_weight_in3 <= unsigned(i_weight_in3);
            s_in3 <= (c_out_res_zeroes & unsigned(i_in3)) * unsigned(i_weight_in3);
          else
            s_in3 <= (others => '0');
            s_weight_in3 <= (others => '0');
          end if;
		
          if i_in4_enabled = '1' then
            s_weight_in4 <= unsigned(i_weight_in4);
            s_in4 <= (c_out_res_zeroes & unsigned(i_in4)) * unsigned(i_weight_in4);
          else
            s_in4 <= (others => '0');
            s_weight_in4 <= (others => '0');
          end if;
		
          if i_in5_enabled = '1' then
            s_weight_in5 <= unsigned(i_weight_in5);
            s_in5 <= (c_in_res_zeroes & unsigned(i_in5)) * unsigned(i_weight_in5);
          else
            s_in5 <= (others => '0');
            s_weight_in5 <= (others => '0');
          end if;
		
          if i_audio_beeper = '1' then
            s_in_beeper <= (c_out_res_zeroes & c_in_res_ones) * unsigned(i_weight_beeper);
          else
            s_in_beeper <= (others => '0');
          end if;
      
          if i_audio_tape = '1' then
            s_in_tape <= (c_out_res_zeroes & c_in_res_ones) * unsigned(i_weight_tape);
          else
            s_in_tape <= (others => '0');
          end if;
          o_pwm_val <= s_pwm_val(c_out_audio_resolution_bits - 1 downto 0);
          s_sm_mixer <= s_mixer_step2;

        when s_mixer_step2 =>
          s_pwm_val <= std_logic_vector(s_tmp_sum(23 downto 8)  *
            unsigned(c_divider_table(to_integer(s_weight_sum(12 downto 8)))));  --assuming input signals were all 8 bit only
          s_sm_mixer <= s_mixer_step1;
        when others => 
          s_sm_mixer <= s_mixer_step1;

      end case;
    end if;
  end process;

  p_audio_adder : process(i_clk)
  begin
    if i_clk'event and i_clk = '1' then

      s_weight_sum <= c_24b_FF + s_weight_in1 + s_weight_in2 + s_weight_in3 + s_weight_in4 + s_weight_in5 + 
        unsigned(i_weight_beeper) + unsigned(i_weight_tape);

      -- 72b vs s_tmp_sum(48)? (used to be 48 vs s_tmp_sum(24))
      s_tmp_sum <= s_in1(c_weight_resolution_bits - 1 downto 0) + 
        s_in2(c_in_audio_resolution_bits + c_out_audio_resolution_bits - 1 downto 0) + 
        s_in3(c_in_audio_resolution_bits + c_out_audio_resolution_bits - 1 downto 0) + 
        s_in4(c_in_audio_resolution_bits + c_out_audio_resolution_bits - 1 downto 0) + 
        s_in5(c_in_audio_resolution_bits + c_out_audio_resolution_bits - 1 downto 0) + 
        s_in_beeper(c_in_audio_resolution_bits + c_out_audio_resolution_bits - 1 downto 0) + 
        s_in_tape(c_in_audio_resolution_bits + c_out_audio_resolution_bits - 1 downto 0);
    end if;
  end process;

--  o_pwm_val <= s_pwm_val(c_out_audio_resolution_bits - 1 downto 0);
   
end architecture rtl;
