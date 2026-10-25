----------------------------------------------------------------------------------
-- Company: Magictale Electronics http://magictale.com
-- Engineer: Dmitry Pakhomenko
-- 
-- Create Date: 30.12.2023 9:23:00 AM
-- Design Name: Frame buffer params calculation module
-- Module Name: framebuf_calc- RTL
-- Project Name: Retro computer emulator on Arty Z7 board
-- Target Devices: Zynq 7020
-- Tool Versions: Vivado 2017.3
-- Description: This module calculates start address for first emulator scanline and RAM stride
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

entity framebuf_calc is
  generic (
     g_axi_addr_width : integer := 32
  );
  port(
    i_clk_sys : in std_logic;
    i_resetn : in std_logic;
    i_locked : in std_logic;
    i_aspect_ratio_16_9 : in std_logic;
    i_emu_h_resolution : in std_logic_vector(9 downto 0);
    i_emu_v_resolution : in std_logic_vector(9 downto 0);
    o_ram_stride : out std_logic_vector(11 downto 0);
    o_rgb_data_addr_start : out std_logic_vector(g_axi_addr_width - 1 downto 0);
    o_ready : out std_logic
  );
end framebuf_calc;

architecture rtl of framebuf_calc is

    signal s_locked_vec : std_logic_vector(2 downto 0) := (others => '0');

begin

  -- p_edge_detection: handle i_locked
  -----------------------------------------
  p_edge_detection : process (i_clk_sys) is
  begin
    if rising_edge(i_clk_sys) then
      if (i_resetn = '0') then
        s_locked_vec <= (others => '0');
      else
        s_locked_vec <= s_locked_vec(1 downto 0) & i_locked;
      end if;
    end if;
  end process;

  -- p_calc: offsets calculations
  -----------------------------------------
  p_calc : process (i_clk_sys) is
  begin
    if rising_edge(i_clk_sys) then
      if (i_resetn = '0') then
        o_ready <= '0';
        o_rgb_data_addr_start <= (others => '0');
        o_ram_stride <= (others => '0');
      elsif (s_locked_vec(2 downto 1) = c_active_high_raising_edge) then
        if (i_aspect_ratio_16_9 = '1') then
          o_ram_stride <= std_logic_vector(to_unsigned((c_hd720p_timing.h_video - 
            to_integer(unsigned(i_emu_h_resolution))) * c_axi_rgb_data_width_bytes, o_ram_stride'length));

          o_rgb_data_addr_start <= std_logic_vector(to_unsigned(
            c_axi_ram_rgb_data_rdaddress +
            (c_hd720p_timing.h_video - to_integer(unsigned(i_emu_h_resolution))) * c_axi_rgb_data_half_width + 
            (c_hd720p_timing.v_video - to_integer(unsigned(i_emu_v_resolution))) * c_hd720p_timing.h_video * c_axi_rgb_data_half_width, 
            o_rgb_data_addr_start'length));
        else
          o_ram_stride <= std_logic_vector(to_unsigned((c_emu720x576.h_video - 
            to_integer(unsigned(i_emu_h_resolution))) * c_axi_rgb_data_width_bytes, o_ram_stride'length));

          o_rgb_data_addr_start <= std_logic_vector(to_unsigned(
            c_axi_ram_rgb_data_rdaddress + 
            (c_emu720x576.h_video - to_integer(unsigned(i_emu_h_resolution))) * c_axi_rgb_data_half_width +  
            (c_emu720x576.v_video - to_integer(unsigned(i_emu_v_resolution))) * c_emu720x576.h_video * c_axi_rgb_data_half_width, 
            o_rgb_data_addr_start'length));
        end if;
        o_ready <= '1';
      elsif (s_locked_vec(2 downto 1) = c_active_high_falling_edge) then
        o_ready <= '0'; 
      end if;
    end if;
  end process;
end rtl;
