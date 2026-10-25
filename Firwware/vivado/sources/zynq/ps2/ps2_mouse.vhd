----------------------------------------------------------------------------------
-- Company: Magictale Electronics http://magictale.com
-- Engineer: Dmitry Pakhomenko
-- 
-- Create Date: 18.04.2025 5:48:00 PM
-- Design Name: PS2 maouse mapper
-- Module Name: ps2_mouse - RTL
-- Project Name: Retro computer emulator on Arty Z7 board
-- Target Devices: Zynq 7020
-- Tool Versions: Vivado 2017.3
-- Description: PS2 mouse handler for emulator
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


entity ps2_mouse is
    port ( 
      i_resetn_sys : in std_logic;
      i_aclk_emu : in std_logic;
      i_emu_clk_en : in std_logic;

      io_ps_clk : inout std_logic;
      io_ps_dat : inout std_logic;

      -- PS2 emulator interface
      -- [24] - toggles with every press/release
      o_ps2_mouse : out std_logic_vector(24 downto 0)
    );

end ps2_mouse;

architecture rtl of ps2_mouse is

  type t_scancode_fsm is (s_init0, s_init1, s_init2, s_init3, s_movement_data_1, s_movement_data_2, s_movement_data_3, s_error);
  type t_tx_fsm is (s_tx_idle, s_tx_prepare, s_tx_running, s_tx_req_deassert);

  signal s_scancode_fsm : t_scancode_fsm;
  signal s_tx_fsm : t_tx_fsm;
  signal s_skip_bytes : integer range 0 to 7;
  signal s_toggle : std_logic;
  -- Mouse PS/2 FIFO
  signal s_ps2_fifo_din : std_logic_vector(c_ps2_fifo_data_width - 1 downto 0);
  signal s_ps2_fifo_dout : std_logic_vector(c_ps2_fifo_data_width - 1 downto 0);
  signal s_ps2_fifo_wr_en : std_logic := '0';
  signal s_ps2_fifo_empty : std_logic;
  signal s_ps2_fifo_full : std_logic;
  signal s_ps2_fifo_rd_en : std_logic := '0';
  signal s_ps2_fifo_underflow : std_logic;
  signal s_ps2_fifo_overflow : std_logic;
  signal s_fifo_rd_rdy : std_logic := '0'; -- one clock cycle delayed s_ps2_fifo_rd_en

  signal s_ps2_mouse_data_in : std_logic_vector(7 downto 0);
  signal s_ps2_mouse_data_out : std_logic_vector(7 downto 0);
  signal s_ps2_mouse_obf : std_logic;
  signal s_ps2_mouse_ibf : std_logic;
  signal s_mouse_busy : std_logic;
  signal s_cmd_req : std_logic;
  signal s_cmd_pending : std_logic;
  signal s_obf_set : std_logic;
  signal s_ibf_clr : std_logic;

begin

  -- Mouse PS/2 FIFO
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

  i_ps2_mouse : ps2
    port map ( 
      i_resetn_sys => i_resetn_sys,
      i_aclk_sys => i_aclk_emu, 
      io_ps_clk => io_ps_clk,
      io_ps_dat => io_ps_dat,

      o_data => s_ps2_mouse_data_in,
      i_data => s_ps2_mouse_data_out,
      i_ibf_clr => s_ibf_clr,
      i_obf_set => s_obf_set,
      o_ibf => s_ps2_mouse_ibf,
      o_obf => s_ps2_mouse_obf,
      o_busy => s_mouse_busy
    );

  s_ps2_fifo_din <= "00000000" & s_ps2_mouse_data_in;

  p_cmd_to_mouse : process(i_aclk_emu)
  begin
    if rising_edge(i_aclk_emu) then
      if (i_resetn_sys = '0') then
        s_cmd_pending <= '0';
        s_obf_set <= '0';
        s_tx_fsm <= s_tx_idle;
      else
        s_obf_set <= '0';
        case s_tx_fsm is
          when s_tx_idle =>
            if (s_cmd_req = '1') then
              -- Immediately set the flag
              s_cmd_pending <= '1';
              s_tx_fsm <= s_tx_prepare;
             end if;
          when s_tx_prepare =>
            if (s_mouse_busy = '0') then
              -- request trasmission
              s_obf_set <= '1';
              if (s_ps2_mouse_obf = '1') then
                s_tx_fsm <= s_tx_running;
              end if;
            end if;
          when s_tx_running =>
            --s_obf_set <= '0';
            -- wait for end of transmission
            if (s_ps2_mouse_obf = '0') then 
              --s_obf_set <= '0';
              s_cmd_pending <= '0';
              s_tx_fsm <= s_tx_req_deassert;
            end if; 
          when s_tx_req_deassert =>
            -- wait for the cmd request to be deasserted
            if (s_cmd_req = '0') then
              s_tx_fsm <= s_tx_idle;
            end if;
          when others => null;
        end case;
      end if;
    end if;
  end process;

  -- This process reads data from the FIFO
  p_fifo_in_read : process(i_aclk_emu)
    variable rx_byte : std_logic_vector(7 downto 0) := (others => '0');
  begin
    if rising_edge(i_aclk_emu) then
      if (i_resetn_sys = '0') then
        s_ps2_fifo_rd_en <= '0';
        s_ps2_fifo_wr_en <= '0';
        o_ps2_mouse <= (others => '0');
        s_scancode_fsm <= s_init0;
        s_toggle <= '0';
        s_fifo_rd_rdy <= '0';
        s_cmd_req <= '0';
        s_ps2_mouse_data_out <= (others => '0');
        s_ibf_clr <= '0';
      else
        -- handle FIFO write control
        if (s_ps2_mouse_ibf = '1') and (s_ps2_fifo_full = '0') and (i_emu_clk_en = '1') then 
          s_ps2_fifo_wr_en <= '1';
          s_ibf_clr <= '1';
        else
          s_ps2_fifo_wr_en <= '0';
          s_ibf_clr <= '0';
        end if;
        -- handle FIFO read control
        if (s_ps2_fifo_empty = '0') and (i_emu_clk_en = '1') and (s_cmd_pending = '0' and s_cmd_req = '0') then
          s_ps2_fifo_rd_en <= '1';
          s_fifo_rd_rdy <= '0';
        elsif (s_ps2_fifo_rd_en = '1') then
          s_ps2_fifo_rd_en <= '0';
          s_fifo_rd_rdy <= '1';
        end if;
        -- mouse read data handler
        if (s_fifo_rd_rdy = '1') then
          rx_byte := s_ps2_fifo_dout(c_ps2_fifo_lsb_bit + 7 downto c_ps2_fifo_lsb_bit);
          case s_scancode_fsm is
            when s_init0 =>
              if (rx_byte = c_ps2_mouse_stest_ok) then
                s_scancode_fsm <= s_init1;
              end if;
            when s_init1 =>
              if (rx_byte = c_ps2_mouse_id) then
                s_ps2_mouse_data_out <= c_ps2_mouse_reset; 
                s_cmd_req <= '1';
                s_scancode_fsm <= s_init2;
              end if;
            when s_init2 =>
              if (rx_byte = c_ps2_mouse_ack) then
                s_ps2_mouse_data_out <= c_ps2_mouse_enable;
                s_cmd_req <= '1';
                s_scancode_fsm <= s_init3;
              end if;
            when s_init3 =>
              if (rx_byte = c_ps2_mouse_ack) then
                s_scancode_fsm <= s_movement_data_1;
              end if;
            when s_movement_data_1 =>
              -- sanity check - bit 3 must be set 
              if (rx_byte(3) = '1') then
                o_ps2_mouse(7 downto 0) <= rx_byte;
                s_scancode_fsm <= s_movement_data_2;
              else
                s_scancode_fsm <= s_error;
              end if;
            when s_movement_data_2 =>
              o_ps2_mouse(15 downto 8) <= rx_byte;
              s_scancode_fsm <= s_movement_data_3;
            when s_movement_data_3 =>
              o_ps2_mouse(23 downto 16) <= rx_byte;
              o_ps2_mouse(24) <= not s_toggle; -- invert the signal so that we don't miss first byte
              s_toggle <= not s_toggle;
              s_scancode_fsm <= s_movement_data_1;
            when s_error =>
              s_ps2_mouse_data_out <= c_ps2_mouse_reset; 
              s_cmd_req <= '1';
              s_scancode_fsm <= s_init2;
            when others => null;
          end case;
          s_fifo_rd_rdy <= '0';
        end if;
        if (s_cmd_req = '1') and (s_cmd_pending = '0') then
          -- last command to the mouse has been transmitted, 
          -- continue processing the Rx FIFO
          s_cmd_req <= '0';
        end if; 
      end if;
    end if;
  end process;

end architecture;
