----------------------------------------------------------------------------------
-- Company: Magictale Electronics http://magictale.com
-- Engineer: Dmitry Pakhomenko
-- 
-- Create Date: 29.12.2023 10:48:00 AM
-- Design Name: Video resolution detector
-- Module Name: resolution_detector- RTL
-- Project Name: Retro computer emulator on Arty Z7 board
-- Target Devices: Zynq 7020
-- Tool Versions: Vivado 2017.3
-- Description: This module counts the numbers of visible horizontal 
--     and vertical pixels in a frame and latches the values in registers
-- Dependencies: 
-- 
-- Revision:
-- 
-- Revision 0.01 - File created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library xil_defaultlib;
use work.types_arty_video.all;

entity resolution_detector is
  port(
    i_clk_sys : in std_logic;
    i_resetn : in std_logic;
    i_ce_pixel_clock : in std_logic;
    i_hsync : in std_logic; 
    i_vsync : in std_logic;
    i_video_active : in std_logic;

    o_h_cntr : out std_logic_vector(9 downto 0);
    o_v_cntr : out std_logic_vector(9 downto 0);
    o_locked : out std_logic
  );
end resolution_detector;

architecture rtl of resolution_detector is

    constant c_steps_to_lock : integer range 0 to 7 := 3;

    signal s_h_cntr : unsigned(9 downto 0) := (others => '0');
    signal s_v_cntr : unsigned(9 downto 0) := (others => '0');
    signal s_h_steps : integer range 0 to 7 := c_steps_to_lock;
    signal s_v_steps : integer range 0 to 7 := c_steps_to_lock;
    signal s_hsync_in_vec : std_logic_vector(2 downto 0) := (others => '0');
    signal s_vsync_in_vec : std_logic_vector(2 downto 0) := (others => '0');
    signal s_va_in_vec : std_logic_vector(2 downto 0) := (others => '0');

    constant c_ref_clock : integer := c_emu_video_clk * 10; --i_clc_sys frequency in MHz  * 10 for measuring some other frequencies
    signal s_locked_vec : std_logic_vector(2 downto 0) := (others => '0');
    signal s_frames_cntr : unsigned(10 downto 0) := (others => '0');
    signal s_ref_clk_cntr : integer := 0;

begin

  -- p_frames_per_sec: frames per second detector
  -----------------------------------------
  p_frames_per_sec : process (i_clk_sys) is
  begin
    if rising_edge(i_clk_sys) then
      if (i_resetn = '0') then
        s_ref_clk_cntr <= 0;
        s_frames_cntr <= (others => '0');
      else
        if (s_locked_vec(2 downto 1) = c_active_high_raising_edge) then
          s_ref_clk_cntr <= c_ref_clock;
          s_frames_cntr <= (others => '0');
        end if;
        if (s_ref_clk_cntr /= 0) then
          s_ref_clk_cntr <= s_ref_clk_cntr - 1;
          if (i_ce_pixel_clock = '1') then
            if (s_vsync_in_vec(2 downto 1) = c_active_high_raising_edge) then
              s_frames_cntr <= s_frames_cntr + 1;
            end if;
          end if;
        end if;
      end if;
    end if;
  end process;

  -- p_edge_detection: handle hsync and vsync
  -----------------------------------------
  p_edge_detection : process (i_clk_sys) is
  begin
    if rising_edge(i_clk_sys) then
      if (i_resetn = '0') then
        s_hsync_in_vec <= (others => '0');
        s_vsync_in_vec <= (others => '0');
        s_locked_vec <= (others => '0');
        s_va_in_vec <= (others => '0');
      elsif (i_ce_pixel_clock = '1') then
        s_hsync_in_vec <= s_hsync_in_vec(1 downto 0) & i_hsync;
        s_vsync_in_vec <= s_vsync_in_vec(1 downto 0) & i_vsync;
        s_va_in_vec <= s_va_in_vec(1 downto 0) & i_video_active;
        s_locked_vec <= s_locked_vec(1 downto 0) & o_locked;
      end if;
    end if;
  end process;

  -- p_counters: progress resolution counters
  -----------------------------------------
  p_counters : process (i_clk_sys) is
  begin
    if rising_edge(i_clk_sys) then
      if (i_resetn = '0') then
        s_h_cntr <= (others => '0');
        s_v_cntr <= (others => '0');
        s_h_steps <= c_steps_to_lock;
        s_v_steps <= c_steps_to_lock;
        o_locked <= '0';
        o_h_cntr <= (others => '0');
        o_v_cntr <= (others => '0');
      elsif (i_ce_pixel_clock = '1') then
        if (i_video_active = '1') then
          s_h_cntr <= s_h_cntr + 1;
        end if;
        if (s_hsync_in_vec(2 downto 1) = c_active_high_raising_edge) then
          if (s_h_cntr /= 0) then -- ignore blank line at the end of a frame
            if (o_h_cntr = std_logic_vector(s_h_cntr)) then
              if (s_h_steps /= 0) then
                s_h_steps <= s_h_steps - 1;
              end if;
            else
              o_h_cntr <= std_logic_vector(s_h_cntr);
              s_h_steps <= c_steps_to_lock;
            end if;
          end if;
          s_h_cntr <= (others => '0');
        end if;
        if (s_va_in_vec(2 downto 1) = c_active_high_raising_edge) then
          s_v_cntr <= s_v_cntr + 1;
        end if;
        if (s_vsync_in_vec(2 downto 1) = c_active_high_raising_edge) then
          if (o_v_cntr = std_logic_vector(s_v_cntr)) then
            if (s_v_steps /= 0) then
              s_v_steps <= s_v_steps - 1;
            else
              if (s_v_steps = 0) and (s_h_steps = 0) then
                o_locked <= '1';
              else
                o_locked <= '0';
              end if;
            end if;
          else
            o_v_cntr <= std_logic_vector(s_v_cntr);
            s_v_steps <= c_steps_to_lock;
          end if;
          s_v_cntr <= (others => '0');
        end if;
      end if;
    end if;
  end process;

end rtl;
