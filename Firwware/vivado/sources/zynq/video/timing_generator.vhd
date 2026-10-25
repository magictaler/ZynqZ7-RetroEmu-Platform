----------------------------------------------------------------------------------
-- Originally designed by Furkan Cayci in 2018 as part of video timing generator
-- 
-- Code cleanup and extra logic by Dmitry Pakomenko, 2022, 2023
-- 
-- Design Name: timing_generator module
-- Module Name: timing_generator - RTL
-- Project Name: Retro computer emulator on Arty Z7 board
-- Target Devices: Zynq 7020
-- Tool Versions: Vivado 2017.3
-- Description: This module generates video timings
----------------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library xil_defaultlib;
use work.types_arty_video.all;

entity timing_generator is
  port(
    i_clk : in std_logic;
    i_frame_start : in std_logic;
    i_enable : in std_logic;
    i_aspect_ratio_16_9 : in std_logic;
    o_hsync, o_vsync : out std_logic;
    o_video_active : out std_logic
  );
end timing_generator;

architecture rtl of timing_generator is

    -- horizontal and vertical counters
    signal s_hcount : unsigned(c_tg_data_width - 1 downto 0) := (others => '0');
    signal s_vcount : unsigned(c_tg_data_width - 1 downto 0) := (others => '0');
    signal s_timings : video_timing_type := c_emu720x576;
    signal s_running_state : t_gen_state := s_gs_normal;
    signal s_frame_detected : std_logic := '0';
    signal s_aspect_ratio_16_9 : std_logic := '1';

begin
  s_aspect_ratio_16_9 <= i_aspect_ratio_16_9;

  -- p_counters: progress timing counters
  -----------------------------------------
  p_counters : process (i_clk) is
  begin
    if rising_edge(i_clk) then
      if (i_enable = '0') then
        s_hcount <= to_unsigned(s_timings.h_total, s_hcount'length);
        s_vcount <= to_unsigned(s_timings.v_total, s_vcount'length);
        s_running_state <= s_gs_normal;
        s_frame_detected <= '0';
      else
        case s_running_state is
          when s_gs_normal =>
            if (s_hcount = 0) then
              s_hcount <= to_unsigned(s_timings.h_total, s_hcount'length);
              if (s_vcount = 0) then
                s_vcount <= to_unsigned(s_timings.v_total, s_vcount'length);
                s_running_state <= s_gs_frame_sync;
              else
                s_vcount <= s_vcount - 1;
              end if;
            else
              s_hcount <= s_hcount - 1;
            end if;
            -- Latch the i_frame_start if it comes before finishing active frame generation
            if (i_frame_start = '0') and (s_frame_detected = '0') then
              s_frame_detected <= '1';
            end if;
          when s_gs_frame_sync =>
            -- keep counting hcount to generate hsync until we get out of this state
            if (s_hcount = 0) then
              s_hcount <= to_unsigned(s_timings.h_total, s_hcount'length);
            else
              s_hcount <= s_hcount - 1;
            end if;
            -- Synchronise the beginning of the next frame on i_frame_start
            if (i_frame_start = '0') or (s_frame_detected = '1') then
              s_running_state <= s_gs_hsync;
              s_frame_detected <= '0';
            end if;
          when s_gs_hsync =>
            -- Wait until the end of a scanline before switching back to the normal state
            if (s_hcount = 0) then
              s_hcount <= to_unsigned(s_timings.h_total, s_hcount'length);
              s_running_state <= s_gs_normal;
            else
              s_hcount <= s_hcount - 1;
            end if;
          when others =>
            s_running_state <= s_gs_normal;
        end case;
      end if;
    end if;
  end process;

  -- generate video_active, hsync, and vsync signals based on the counters
  p_timing_latch : process (i_clk) is
  begin
    if rising_edge(i_clk) then
      if (s_hcount < s_timings.h_video) and (s_vcount < s_timings.v_video ) and (s_running_state = s_gs_normal) then
        o_video_active <= s_timings.active;
      else 
        o_video_active <= not s_timings.active;
      end if;

      if (s_hcount >= s_timings.h_video + s_timings.h_fp) and (s_hcount < s_timings.h_total - s_timings.h_bp) then
        o_hsync <= s_timings.h_pol;
      else 
        o_hsync <= not s_timings.h_pol;
      end if;

      if (s_vcount >= s_timings.v_video + s_timings.v_fp) and (s_vcount < s_timings.v_total - s_timings.v_bp) then
        o_vsync <= s_timings.v_pol;
      else 
        o_vsync <= not s_timings.v_pol;
      end if;

      if s_aspect_ratio_16_9 = '1' then
        s_timings <= c_hd720p_timing;
      else 
        s_timings <= c_emu720x576;
      end if;
    end if;
  end process;

end rtl;
