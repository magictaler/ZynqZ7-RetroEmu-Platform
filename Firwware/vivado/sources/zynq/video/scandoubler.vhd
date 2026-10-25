----------------------------------------------------------------------------------
-- Company: Magictale Electronics http://magictale.com
-- Engineer: Dmitry Pakhomenko
-- 
-- Create Date: 25.11.2023 7:19:00 PM
-- Design Name: scandoubler
-- Module Name: scandoubler - RTL
-- Project Name: Retro computer emulator on Arty Z7 board
-- Target Devices: Zynq 7020
-- Tool Versions: Vivado 2017.3
-- Description: This module takes video output from a retro video controller
--   and doubles the number of scanlines, the pixel clock becomes 4 times faster
-- Dependencies: bram_720_24, make sure that the dimention is big enough to accomodate 
--   two scanlines from a retro system (before scandoubling)
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
use work.types_arty_video.all;

entity scandoubler is
  port(
    i_clk_sys : in std_logic;
    i_ce_pixel_clock_in : in std_logic;
    i_ce_pixel_clock_scandoubled : in std_logic;
    i_enable : in std_logic;
    -- Original video from a retrosystem with low pixel clock (~7MHz)
    i_hsync, i_vsync : in std_logic;
    i_hblank, i_vblank : in std_logic;
    i_r, i_g, i_b : in std_logic_vector(c_color_component_width - 1 downto 0);
    -- Scandoubled video with four time faster (say, 28MHz) pixel clock
    o_hsync, o_vsync : out std_logic;
    o_video_active : out std_logic;
    o_margin : out std_logic;
    o_r, o_g, o_b : out std_logic_vector(c_color_component_width - 1 downto 0)
  );
end scandoubler;

architecture rtl of scandoubler is

  signal s_sm_vid_out_state : t_sm_vid_out_state := s_vo_idle;
  signal s_sm_hsync_gen_state : t_sm_hsync_gen_state := s_hs_repeater;
  signal s_wea : std_logic_vector(0 downto 0);
  signal s_addra : unsigned(c_sd_gen_counter_width - 1 downto 0) := (others => '0');
  signal s_addrb : unsigned(c_sd_gen_counter_width - 1 downto 0) := (others => '0');
  signal s_dina : std_logic_vector(c_color_component_width * 3 - 1 downto 0);
  signal s_doutb : std_logic_vector(c_color_component_width * 3 - 1 downto 0);
  signal s_video_active_in : std_logic;
  signal s_hsync_in_counter : unsigned(c_sd_gen_counter_width - 1 downto 0);
  signal s_hsync_in_latched_counter : unsigned(c_sd_gen_counter_width - 1 downto 0);
  signal s_hsync_out_counter : unsigned(c_sd_gen_counter_width - 1 downto 0);
  signal s_scanlinea_num : std_logic := '0';
  signal s_scanlineb_num : unsigned(1 downto 0) := (others => '0');
  signal s_hsync_period_counter : unsigned(c_sd_gen_counter_width - 1 downto 0) := (others => '0');
  signal s_hsync_period : unsigned(c_sd_gen_counter_width - 1 downto 0) := (others => '0');
  signal s_hsync_duration : unsigned(5 downto 0) := (others => '0');
  signal s_hsync2active : unsigned(c_sd_gen_counter_width - 1 downto 0) := (others => '0');
  signal s_active_duration : unsigned(c_sd_gen_counter_width - 1 downto 0) := (others => '0');
  signal s_hsync_in_vec : std_logic_vector(2 downto 0) := (others => '0');
  signal s_vsync_in_vec : std_logic_vector(2 downto 0) := (others => '0');
  signal s_active_vec : std_logic_vector(2 downto 0) := (others => '0');
  signal s_vblank_in_vec : std_logic_vector(2 downto 0) := (others => '0');
  signal s_hsync_in : std_logic;
  signal s_vblank_in : std_logic;
  signal s_hsync_out : std_logic := not c_emu720x576.h_pol;
  signal s_vsync_out : std_logic := not c_emu720x576.v_pol;
  signal s_vsync_out_counter : unsigned(c_sd_gen_counter_width - 1 downto 0);
  signal s_hsync_out_vec : std_logic_vector(2 downto 0) := (others => '0');
  signal s_hsync_p_gen_counter : unsigned(c_sd_gen_counter_width - 1 downto 0) := (others => '0');
  signal s_hsync_w_gen_counter : unsigned(5 downto 0) := (others => '0');
  signal s_hsync2active_counter : unsigned(c_sd_gen_counter_width - 1 downto 0) := (others => '0');
  signal s_video_active_out : std_logic := '0';
  signal s_video_active_gen_counter : unsigned(c_sd_gen_counter_width - 1 downto 0) := (others => '0');
  signal s_hcounter : unsigned(c_sd_gen_counter_width - 1 downto 0) := (others => '0');
  signal s_h_margin_area : std_logic := '0';
  signal s_v_margin_area : std_logic := '0';
  signal s_active_duration_stable : std_logic := '0';
  signal s_params_in_sync : std_logic := '0';
  signal s_hmargin : unsigned(c_sd_gen_counter_width - 1 downto 0) := (others => '0');


  component bram_720_24
    port (
      clka : in std_logic;
      wea : in std_logic_vector(0 downto 0);
      addra : in std_logic_vector(c_sd_gen_counter_width - 1 downto 0);
      dina : in std_logic_vector(c_color_component_width * 3 - 1 downto 0);
      clkb : in std_logic;
      addrb : in std_logic_vector(c_sd_gen_counter_width - 1 downto 0);
      doutb : out std_logic_vector(c_color_component_width * 3 - 1 downto 0)
    );
  end component;

begin

  i_bram_720_24 : bram_720_24
    port map (
      clka => i_clk_sys,
      wea => s_wea,
      addra => std_logic_vector(s_addra),
      dina => s_dina,

      clkb => i_clk_sys,
      addrb => std_logic_vector(s_addrb),
      doutb => s_doutb
    );

  s_video_active_in <= not (i_hblank or i_vblank);
  s_wea <= "1" when i_ce_pixel_clock_in = '1' and s_video_active_in = '1' else "0";
  s_dina <= i_r & i_g & i_b;
  s_hsync_in <= i_hsync;
  s_vblank_in <= i_vblank;
  o_hsync <= s_hsync_out;
  o_vsync <= s_vsync_out;
  o_video_active <= s_video_active_out;
  o_r <= s_doutb(c_color_component_width * 3 - 1 downto c_color_component_width * 2) when s_h_margin_area = '0' and s_v_margin_area = '0' else c_zero_intensity;
  o_g <= s_doutb(c_color_component_width * 2 - 1 downto c_color_component_width) when s_h_margin_area = '0' and s_v_margin_area = '0' else c_zero_intensity;
  o_b <= s_doutb(c_color_component_width - 1 downto 0) when s_h_margin_area = '0' and s_v_margin_area = '0' else c_zero_intensity;
  o_margin <= '1' when s_h_margin_area = '1' or s_v_margin_area = '1' else '0';

  -- p_vid_in: measuring the parameters
  -- of the video signal from the emulated 
  -- video controller
  ----------------------------------------
  p_vid_in : process(i_clk_sys)
  begin
    if rising_edge(i_clk_sys) then
      if (i_enable = '0') then 
        s_addra <= (others => '0');
        s_scanlinea_num <= '0';
        s_hsync_period_counter <= (others => '0');
        s_hsync_period <= (others => '0');
        s_hsync_duration <= (others => '0');
        s_hsync2active <= (others => '0');
        s_active_duration <= (others => '0');
        s_hsync_in_vec <= (others => '0');
        s_vsync_in_vec <= (others => '0');
        s_active_vec <= (others => '0');
        s_vblank_in_vec <= (others => '0');
        s_hmargin <= (others => '0');
        s_active_duration_stable <= '0';
      else
        if (i_ce_pixel_clock_in = '1') then
          s_hsync_in_vec <= s_hsync_in_vec(1 downto 0) & s_hsync_in;
          s_vsync_in_vec <= s_vsync_in_vec(1 downto 0) & i_vsync;
          s_active_vec <= s_active_vec(1 downto 0) & s_video_active_in;
          s_vblank_in_vec <= s_vblank_in_vec(1 downto 0) & s_vblank_in;
          if (s_hsync_in_vec(2 downto 1) = "01") then
            s_hsync_period <= s_hsync_period_counter;
            s_hsync_period_counter <= (others => '0');
            if (s_vblank_in = '1') then
              if (s_hsync_in_counter /= 0) then
                s_hsync_in_latched_counter <= s_hsync_in_counter;
              end if;
              s_hsync_in_counter <= (others => '0');
            else
              s_hsync_in_counter <= s_hsync_in_counter + 1;
            end if;
          else
            s_hsync_period_counter <= s_hsync_period_counter + 1;
          end if;
          if (s_active_vec(2 downto 1) = "01") then
            -- ignore the first counted value at the beginning of a new frame
            if (s_hsync_in_counter /= 0) then
              s_hsync2active <= s_hsync_period_counter;
            end if;
          elsif (s_active_vec(2 downto 1) = "10") then
            s_scanlinea_num <= not s_scanlinea_num;
            -- filtering out small values to counteract the ULA glitch at the end of frame
            if (c_active_duration_threshold < (s_hsync_period_counter - s_hsync2active)) then
              if (s_active_duration = (s_hsync_period_counter - s_hsync2active)) then
                s_active_duration_stable <= '1';
              else
                s_active_duration_stable <= '0';
              end if;
              s_active_duration <= s_hsync_period_counter - s_hsync2active; 
              s_hmargin <= shift_right(c_half_hvideo - s_hsync_period_counter + s_hsync2active, 1);
            end if;
          end if;
          if (s_hsync_in_vec(2 downto 1) = "10") then
            s_hsync_duration <= s_hsync_period_counter(5 downto 0);
          end if;
          if (i_vsync = '1') then
            -- Always start new frame from the first page in BRAM
            s_scanlinea_num <= '0';
          end if;
          if (s_video_active_in = '0') then
            if (s_scanlinea_num = '0') then
              s_addra <= (others => '0');
            else
              s_addra <= to_unsigned(c_slow_scanline_length, s_addra'length);
            end if;
          else
            s_addra <= s_addra + 1;
          end if;
        end if;
      end if;
    end if;
  end process;

  -- p_params_in_sync_gen: generator of s_params_in_sync
  ----------------------------------------
  p_params_in_sync_gen : process(i_clk_sys)
  begin
    if rising_edge(i_clk_sys) then
      if (i_enable = '0') then 
        s_params_in_sync <= '0';
      else
        if (i_ce_pixel_clock_scandoubled = '1') then
          if (i_vsync = '1') then
            if (s_active_duration_stable = '1') then
              s_params_in_sync <= '1';
            end if;
          end if;
        end if;
      end if;
    end if;
  end process;

  -- p_hsync_gen: generator of out hsync
  -- with double frequency
  ----------------------------------------
  p_hsync_gen : process(i_clk_sys)
  begin
    if rising_edge(i_clk_sys) then
      if (i_enable = '0') then 
        s_sm_hsync_gen_state <= s_hs_repeater;
        s_hsync_out <= '1';
        s_hsync_out_vec <= (others => '0');
        s_hsync_p_gen_counter <= (others => '0');
        s_hsync_w_gen_counter <= (others => '0');
      else
        if (i_ce_pixel_clock_scandoubled = '1') then
          case s_sm_hsync_gen_state is 
            when s_hs_repeater =>
              if (s_hsync_in = '1') then
                s_hsync_out <= c_emu720x576.h_pol;
                s_hsync_p_gen_counter <= s_hsync_period;
                s_hsync_w_gen_counter <= s_hsync_duration;
                s_sm_hsync_gen_state <= s_hs_gen_start;
              end if;
            when s_hs_gen_start =>
              -- s_hsync_w_gen_counter should be obviously less than s_hsync_p_gen_counter
              if (s_hsync_w_gen_counter = 0) then
                s_hsync_out <= not c_emu720x576.h_pol;
              else
                s_hsync_w_gen_counter <= s_hsync_w_gen_counter - 1;
              end if;
              if (s_hsync_p_gen_counter = 0) then
                s_hsync_out <= c_emu720x576.h_pol;
                s_hsync_w_gen_counter <= s_hsync_duration;
                s_sm_hsync_gen_state <= s_hs_gen_end;
              else
                s_hsync_p_gen_counter <= s_hsync_p_gen_counter - 1;
              end if;
            when s_hs_gen_end =>
              if (s_hsync_w_gen_counter = 0) then
                s_hsync_out <= not c_emu720x576.h_pol;
                s_sm_hsync_gen_state <= s_hs_repeater;
              else
                s_hsync_w_gen_counter <= s_hsync_w_gen_counter - 1;
              end if;
            when others =>
              s_sm_hsync_gen_state <= s_hs_repeater;
          end case;
          s_hsync_out_vec <= s_hsync_out_vec(1 downto 0) & s_hsync_out;
        end if;
      end if;
    end if;
  end process;

  -- p_vid_out: reading the stored scanline
  -- twice and play it at double
  -- frequency
  ----------------------------------------
  p_vid_out : process(i_clk_sys)
  begin
    if rising_edge(i_clk_sys) then
      if (i_enable = '0') or (s_params_in_sync = '0') then 
        s_sm_vid_out_state <= s_vo_idle;
        s_addrb <= (others => '0');
        s_scanlineb_num <= (others => '0');
        s_hsync2active_counter <= (others => '0');
        s_video_active_out <= not c_emu720x576.active;
        s_vsync_out <= not c_emu720x576.v_pol;
        s_video_active_gen_counter <= (others => '0');
        s_hcounter <= (others => '0');
        s_h_margin_area <= '0';
        s_v_margin_area <= '0';
      else
        if (i_ce_pixel_clock_scandoubled = '1') then
          if (s_hcounter = s_hsync_period) then
            s_hcounter <= (others => '0');
          else
            s_hcounter <= s_hcounter + 1;
          end if;
          case s_sm_vid_out_state is
            when s_vo_idle =>
              if (s_hsync_out = c_emu720x576.h_pol) and (s_video_active_in = '1') then
                s_sm_vid_out_state <= s_vo_hsync_out_sync;
                s_video_active_out <= not c_emu720x576.active;
                s_hsync2active_counter <= s_hsync2active + 1;
                s_hsync_out_counter <= to_unsigned(c_emu720x576.v_video - 1, s_hsync_out_counter'length);
                s_scanlineb_num <= (others => '0');
                s_v_margin_area <= '0';
              end if;
            when s_vo_hsync_out_sync =>
              if (s_hsync_out = not c_emu720x576.h_pol) then
                s_sm_vid_out_state <= s_vo_start_delay;  -- syncronise with hsync out 
              end if;  
            when s_vo_start_delay =>
              if (s_vsync_in_vec(2 downto 1) = "01") then
                s_sm_vid_out_state <= s_vo_idle; -- synchronise with the beginning of a frame
              else
                if (s_hsync2active_counter = 0) then
                  if (s_scanlineb_num > 1) then
                    s_addrb <= to_unsigned(c_slow_scanline_length, s_addra'length);
                  else
                    s_addrb <= (others => '0');
                  end if;
                  s_video_active_gen_counter <= to_unsigned(c_half_hvideo - 1, s_video_active_gen_counter'length);
                  s_video_active_out <= c_emu720x576.active;
                  if (s_video_active_out = not c_emu720x576.active) then
                    s_hcounter <= (others => '0');
                  end if;
                  s_sm_vid_out_state <= s_vo_scanline; 
                else
                  s_hsync2active_counter <= s_hsync2active_counter - 1;
                end if;
              end if;
            when s_vo_scanline =>
              if (s_video_active_gen_counter = 0) then 
                -- end of scanline
                s_video_active_out <= not c_emu720x576.active;
                if (s_hsync_out_counter = 0) then
                  s_vsync_out_counter <= to_unsigned(c_emu720x576.v_fp, s_vsync_out_counter'length);
                  s_sm_vid_out_state <= s_vo_vsync_fp;
                else
                  s_sm_vid_out_state <= s_vo_hsync_out_sync;
                  s_hsync2active_counter <= s_hsync2active + 4;
                  s_scanlineb_num <= s_scanlineb_num + 1;
                  s_hsync_out_counter <= s_hsync_out_counter - 1;
                end if;
              else
                -- scanline is active
                s_video_active_gen_counter <= s_video_active_gen_counter - 1;
                if ((s_video_active_gen_counter > s_hmargin) and (s_video_active_gen_counter < (s_hmargin + s_active_duration))) then
                  s_h_margin_area <= '0';
                  s_addrb <= s_addrb + 1;
                else
                  s_h_margin_area <= '1';
                end if;
                if (s_hsync_out_counter = c_emu720x576.v_video - s_hsync_in_latched_counter - s_hsync_in_latched_counter) then
                  s_v_margin_area <= '1';
                end if;
              end if;
            when s_vo_vsync_fp =>
              -- vsync front porch generation
              if (s_vsync_out_counter = 0) then
                s_vsync_out_counter <= to_unsigned(c_emu720x576.v_sync, s_vsync_out_counter'length);
                s_vsync_out <= c_emu720x576.v_pol;
                s_sm_vid_out_state <= s_vo_vsync;
              else
                s_vsync_out_counter <= s_vsync_out_counter - 1;
              end if;
            when s_vo_vsync =>
              -- vsync generation
              if (s_vsync_out_counter = 0) then
                s_vsync_out <= not c_emu720x576.v_pol;
                s_sm_vid_out_state <= s_vo_idle;
              else
                s_vsync_out_counter <= s_vsync_out_counter - 1;
              end if;
            when others =>
              s_sm_vid_out_state <= s_vo_idle;
          end case;
        end if;
      end if;
    end if;
  end process;

end rtl;

