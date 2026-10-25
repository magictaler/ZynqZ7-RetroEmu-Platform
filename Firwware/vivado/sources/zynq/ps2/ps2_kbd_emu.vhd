----------------------------------------------------------------------------------
-- Company: Magictale Electronics http://magictale.com
-- Engineer: Dmitry Pakhomenko
-- 
-- Create Date: 24.08.2024 9:25:00 AM
-- Design Name: PS2 keyboard emulator
-- Module Name: ps2_kbd_emu - RTL
-- Project Name: Retro computer emulator on Arty Z7 board
-- Target Devices: Zynq 7020
-- Tool Versions: Vivado 2017.3
-- Description: PS2 keyboard emulator for mapping virtual P2S port with 
--              something else like HID driver from USB stack
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

library xil_defaultlib;
    use work.types_ps2_kbd_emu.all;


entity ps2_kbd_emu is
    generic (
      g_axi_lite_data_width : integer := 32
    );
    port ( 
      i_resetn_sys : in std_logic;
      i_aclk_sys : in std_logic;
      i_aclk_emu : in std_logic;
      i_emu_clk_en : in std_logic;
      -- Register interface      
      i_ps2_kbd_do_en : in std_logic;
      o_ps2_kbd_do : out std_logic_vector(g_axi_lite_data_width - 1 downto 0);
      i_reg_wr_en : in std_logic;
      i_reg_rd_en : in std_logic;
      i_register_data_out : in std_logic_vector(g_axi_lite_data_width - 1 downto 0);
      -- PS2 interface
      o_ps2_key : out std_logic_vector(10 downto 0)
    );

end ps2_kbd_emu;

architecture rtl of ps2_kbd_emu is

  -- Kbd PS/2 FIFO
  signal s_ps2_fifo_din : std_logic_vector(c_ps2_fifo_data_width - 1 downto 0);
  signal s_ps2_fifo_dout : std_logic_vector(c_ps2_fifo_data_width - 1 downto 0);
  signal s_ps2_fifo_wr_en : std_logic := '0';
  signal s_ps2_fifo_empty : std_logic := '0';
  signal s_ps2_fifo_full : std_logic := '0';
  signal s_ps2_fifo_rd_en : std_logic := '0';
  signal s_ps2_fifo_underflow : std_logic := '0';
  signal s_ps2_fifo_overflow : std_logic := '0';

begin

  -- Kbd PS/2 FIFO
  i_ps2_fifo : fifo_1024_16
    port map (
      wr_clk => i_aclk_sys,
      rd_clk => i_aclk_emu,
      rst => not i_resetn_sys,
      din => s_ps2_fifo_din,
      wr_en => s_ps2_fifo_wr_en,
      rd_en => s_ps2_fifo_rd_en,
      dout => s_ps2_fifo_dout,
      full => s_ps2_fifo_full,
      overflow => s_ps2_fifo_overflow,
      empty => s_ps2_fifo_empty,
      underflow => s_ps2_fifo_underflow
    );

  -- This process reads data from the register and puts into the FIFO
  p_reg_read : process(i_aclk_sys)
  begin
    if rising_edge(i_aclk_sys) then
      if (i_resetn_sys = '0') then
        s_ps2_fifo_wr_en <= '0';
      else
        s_ps2_fifo_wr_en <= '0';
        if (i_reg_wr_en = '1') then
          if (i_ps2_kbd_do_en = '1') then
            if (s_ps2_fifo_full = '0') then
              s_ps2_fifo_din <= "00000" & i_register_data_out(c_ps2_fifo_msb_bit downto c_ps2_fifo_lsb_bit);
              s_ps2_fifo_wr_en <= '1';
            else
              -- data is dropped if no room in the FIFO
            end if;
          end if;
        end if;
      end if;
    end if;
  end process;

  -- This process reads data from the FIFO
  p_fifo_read : process(i_aclk_emu)
  begin
    if rising_edge(i_aclk_emu) then
      if (i_resetn_sys = '0') then
        s_ps2_fifo_rd_en <= '0';
        o_ps2_key <= (others => '0');
      else
          if (s_ps2_fifo_empty = '0') and (i_emu_clk_en = '1') then
            s_ps2_fifo_rd_en <= '1';
          else
            o_ps2_key <= s_ps2_fifo_dout(c_ps2_fifo_msb_bit downto c_ps2_fifo_lsb_bit);
            s_ps2_fifo_rd_en <= '0';
          end if;
      end if;
    end if;
  end process;

end architecture;
