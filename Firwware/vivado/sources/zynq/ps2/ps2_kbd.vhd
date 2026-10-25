----------------------------------------------------------------------------------
-- Company: Magictale Electronics http://magictale.com
-- Engineer: Dmitry Pakhomenko
-- 
-- Create Date: 18.03.2025 5:48:00 PM
-- Design Name: PS2 keyboard mapper
-- Module Name: ps2_kbd - RTL
-- Project Name: Retro computer emulator on Arty Z7 board
-- Target Devices: Zynq 7020
-- Tool Versions: Vivado 2017.3
-- Description: PS2 keyboard handler for emulator
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


entity ps2_kbd is
    port ( 
      i_resetn_sys : in std_logic;
      i_aclk_emu : in std_logic;
      i_emu_clk_en : in std_logic;

      io_ps_clk : inout std_logic;
      io_ps_dat : inout std_logic;

      -- PS2 emulator interface
      -- [8] - extended, [9] - pressed, [10] - toggles with every press/release
      o_ps2_key : out std_logic_vector(10 downto 0);

      -- joystick emulated via keyboard
      o_joy_a_emu : out std_logic_vector(5 downto 0)
    );

end ps2_kbd;

architecture rtl of ps2_kbd is

  type t_scancode_fsm is (s_idle, s_second_byte, s_skip, s_extended_break, s_error);

  signal s_scancode_fsm : t_scancode_fsm;
  signal s_skip_bytes : integer range 0 to 7;
  signal s_prev_byte : std_logic_vector(7 downto 0);
  signal s_toggle : std_logic;
  -- Kbd PS/2 FIFO
  signal s_ps2_fifo_din : std_logic_vector(c_ps2_fifo_data_width - 1 downto 0);
  signal s_ps2_fifo_dout : std_logic_vector(c_ps2_fifo_data_width - 1 downto 0);
  signal s_ps2_fifo_wr_en : std_logic := '0';
  signal s_ps2_fifo_empty : std_logic := '0';
  signal s_ps2_fifo_full : std_logic := '0';
  signal s_ps2_fifo_rd_en : std_logic := '0';
  signal s_ps2_fifo_underflow : std_logic := '0';
  signal s_ps2_fifo_overflow : std_logic := '0';
  signal s_fifo_rd_rdy : std_logic := '0'; -- one clock cycle delayed s_ps2_fifo_rd_en

  signal s_ps2_kbd_data_in : std_logic_vector(7 downto 0);
  signal s_ps2_kbd_data_out : std_logic_vector(7 downto 0);
  --signal s_ps2_kbd_ibf : std_logic;
  signal s_ps2_kbd_obf : std_logic;
  signal s_busy : std_logic;

begin

  -- Kbd PS/2 FIFO
  i_ps2_fifo : fifo_1024_16
    port map (
      wr_clk => i_aclk_emu, -- TODO: replace with signle clock FIFO?
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

  i_ps2_kbd : ps2
    port map ( 
      i_resetn_sys => i_resetn_sys,
      i_aclk_sys => i_aclk_emu, 
      io_ps_clk => io_ps_clk,
      io_ps_dat => io_ps_dat,

      o_data => s_ps2_kbd_data_in,
      i_data => s_ps2_kbd_data_out,
      i_ibf_clr => '0',
      i_obf_set => '0',
      o_ibf => s_ps2_fifo_wr_en,
      o_obf => s_ps2_kbd_obf,
      o_busy => s_busy
    );

  s_ps2_fifo_din <= "00000000" & s_ps2_kbd_data_in;

  -- This process reads data from the FIFO
  p_fifo_in_read : process(i_aclk_emu)
    variable rx_byte : std_logic_vector(7 downto 0) := (others => '0');
  begin
    if rising_edge(i_aclk_emu) then
      if (i_resetn_sys = '0') then
        s_ps2_fifo_rd_en <= '0';
        o_ps2_key <= (others => '0');
        s_scancode_fsm <= s_idle;
        s_prev_byte <= (others => '0');
        s_toggle <= '0';
        s_fifo_rd_rdy <= '0';
      else
        if (s_ps2_fifo_empty = '0') and (i_emu_clk_en = '1') then
          s_ps2_fifo_rd_en <= '1';
          s_fifo_rd_rdy <= '0';
        elsif (s_ps2_fifo_rd_en = '1') then
          s_ps2_fifo_rd_en <= '0';
          s_fifo_rd_rdy <= '1';
        end if;
        if s_fifo_rd_rdy = '1' then
          rx_byte := s_ps2_fifo_dout(c_ps2_fifo_lsb_bit + 7 downto c_ps2_fifo_lsb_bit);
          case s_scancode_fsm is
            when s_idle =>
              if (rx_byte /= c_ps2_ext_prefix) and
                 (rx_byte /= c_ps2_pause_prefix_make) and
                 (rx_byte /= c_ps2_prefix_break) then
                -- One byte regular make
                o_ps2_key <= (not s_toggle) & '1' & '0' & rx_byte;
                s_toggle <= not s_toggle;
                -- Joy emulation
                if (rx_byte = c_ps2_numpad_4) then
                  o_joy_a_emu(joy_a_emu_left_bit) <= '1';
                elsif (rx_byte = c_ps2_numpad_6) then
                  o_joy_a_emu(joy_a_emu_right_bit) <= '1';
                elsif (rx_byte = c_ps2_numpad_8) then
                  o_joy_a_emu(joy_a_emu_up_bit) <= '1';
                elsif (rx_byte = c_ps2_numpad_2) then
                  o_joy_a_emu(joy_a_emu_down_bit) <= '1';
                elsif (rx_byte = c_ps2_numpad_5) then
                  o_joy_a_emu(joy_a_emu_trigger_a_bit) <= '1';
                elsif (rx_byte = c_ps2_numpad_0) then
                  o_joy_a_emu(joy_a_emu_trigger_b_bit) <= '1';
                end if;
              else
                s_prev_byte <= rx_byte;
                s_scancode_fsm <= s_second_byte;
              end if;
            when s_second_byte =>
              if (s_prev_byte = c_ps2_ext_prefix) then -- E0
                -- Extended make scancode
                if (rx_byte = c_ps2_prtsc) then -- 12
                  -- printscreen 
                  s_skip_bytes <= 2;
                  s_scancode_fsm <= s_skip;
                elsif (rx_byte = c_ps2_prefix_break) then -- F0
                  -- Extended break scancode
                  -- scancode in next loop
                  s_scancode_fsm <= s_extended_break;
                else
                  -- Regular extended make scancode
                  o_ps2_key <= (not s_toggle) & '1' & '1' & rx_byte;
                  s_toggle <= not s_toggle;
                  s_scancode_fsm <= s_idle;
                end if;
              elsif (s_prev_byte = c_ps2_prefix_break) then -- F0
                -- Regular break
                o_ps2_key <= (not s_toggle) & '0' & '0' & rx_byte;
                s_toggle <= not s_toggle;
                s_scancode_fsm <= s_idle;
                -- Joy emulation
                if (rx_byte = c_ps2_numpad_4) then
                  o_joy_a_emu(joy_a_emu_left_bit) <= '0';
                elsif (rx_byte = c_ps2_numpad_6) then
                  o_joy_a_emu(joy_a_emu_right_bit) <= '0';
                elsif (rx_byte = c_ps2_numpad_8) then
                  o_joy_a_emu(joy_a_emu_up_bit) <= '0';
                elsif (rx_byte = c_ps2_numpad_2) then
                  o_joy_a_emu(joy_a_emu_down_bit) <= '0';
                elsif (rx_byte = c_ps2_numpad_5) then
                  o_joy_a_emu(joy_a_emu_trigger_a_bit) <= '0';
                elsif (rx_byte = c_ps2_numpad_0) then
                  o_joy_a_emu(joy_a_emu_trigger_b_bit) <= '0';
                end if;
              elsif (s_prev_byte = c_ps2_pause_prefix_make) then -- E1
                -- Extended make (pause)
                s_skip_bytes <= 6;
                s_scancode_fsm <= s_skip;
              else 
                -- Regular make but it should be already handled and we should never be here
                s_scancode_fsm <= s_error;
              end if;
            when s_skip =>
              if (s_skip_bytes - 1 = 0) then 
                s_scancode_fsm <= s_idle;
                s_skip_bytes <= 0;
              end if;
              s_skip_bytes <= s_skip_bytes - 1;
            when s_extended_break =>
              if (rx_byte = c_ps2_prtsc_br_3rd_bt) then
                -- Third byte of the printscreen break, skip three trailing bytes
                s_skip_bytes <= 3;
                s_scancode_fsm <= s_skip;
              else
                o_ps2_key <= (not s_toggle) & '0' & '1' & rx_byte;
                s_toggle <= not s_toggle;
                s_scancode_fsm <= s_idle;
              end if;
            when s_error =>
              s_scancode_fsm <= s_idle;
            when others => null;
          end case;
          s_fifo_rd_rdy <= '0';
        end if;
      end if;
    end if;
  end process;

end architecture;
