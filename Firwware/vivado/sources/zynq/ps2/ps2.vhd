----------------------------------------------------------------------------------
-- Company: Magictale Electronics http://magictale.com
-- Engineer: Dmitry Pakhomenko
-- 
-- Create Date: 23.11.2024 2:29:00 PM
-- Design Name: PS2 interface
-- Module Name: ps2 - RTL
-- Project Name: Retro computer emulator on Arty Z7 board
-- Target Devices: Zynq 7020
-- Tool Versions: Vivado 2017.3
-- Description: PS2 generic interface for connecting a keyboard/mouse
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


entity ps2 is
    port ( 
      i_resetn_sys : in std_logic;
      i_aclk_sys : in std_logic;

      io_ps_clk : inout std_logic;
      io_ps_dat : inout std_logic;

      o_data : out std_logic_vector(7 downto 0);  -- Data in
      i_data : in  std_logic_vector(7 downto 0);  -- Data out
      i_ibf_clr : in std_logic;  -- Ifb flag clear input
      i_obf_set : in std_logic;  -- Obf flag set input
      o_ibf : out std_logic;  -- Received data available
      o_obf : out std_logic;  -- Data ready to sent
      o_busy : out std_logic
    );

end ps2;

architecture rtl of ps2 is

  type t_states is (s_idle, s_write_request, s_start, s_data, s_parity, s_stop);
  type t_debounce_states is (s_stable, s_rise, s_fall, s_wait_stable);

  constant c_debounce_bits : integer := 8;
  constant c_watchdog_bits : integer := 8;

  signal s_state : t_states;
  signal s_debounce_state : t_debounce_states;
  signal s_debounce_cnt : unsigned(c_debounce_bits - 1 downto 0);
  signal s_debounce_cao : std_logic;
  signal s_ps2_clk_syn : std_logic;  -- PS2 clock input syncronized
  signal s_ps2_clk_clean : std_logic;  -- PS2 clock debounced and clean
  signal s_ps2_clk_fall : std_logic;  -- PS2 clock fall edge
  signal s_ps2_clk_rise : std_logic;  -- PS2 clock rise edge
  signal s_ps2_data_syn : std_logic;  -- PS2 data  input syncronized
  signal s_ps2_clk_out : std_logic;  -- PS2 clock output
  signal s_ps2_data_out : std_logic;  -- PS2 clock output
  signal s_writing : std_logic;  -- read / write cycle flag
  signal s_shift_cnt : unsigned(2 downto 0);
  signal s_shift_cao : std_logic;  -- Shift counter carry out
  signal s_shift_reg : std_logic_vector(8 downto 0);
  signal s_shift_in : std_logic;  -- Shift register to right
  signal s_shift_load : std_logic;  -- Shift register parallel load
  signal s_shift_calc_parity : std_logic;  -- Shift register set parity
  signal s_wdt_cnt           : unsigned(c_watchdog_bits - 1 downto 0);
  signal s_wdt_rst           : std_logic;  -- watchdog reset
  signal s_wdt_cao           : std_logic;  -- watchdog carry out
  signal s_shift_parity      : std_logic;  -- Current parity of shift_reg
  signal s_ibf               : std_logic;  -- IBF, In Buffer Full
  signal s_obf               : std_logic;  -- OBF, Out Buffer Full

begin

  -- Sincronize input signals
  syn_ps2 : process (i_aclk_sys, i_resetn_sys)
  begin
    if i_resetn_sys = '0' then     -- asynchronous reset (active low)
      s_ps2_clk_syn <= '0';
      s_ps2_data_syn <= '0';
    elsif i_aclk_sys'event and i_aclk_sys = '1' then  -- rising clock edge
      s_ps2_clk_syn  <= TO_X01(io_ps_clk);
      s_ps2_data_syn <= TO_X01(io_ps_dat);
    end if;
  end process syn_ps2;

  -- clk debounce timer
  debounce_count : process (i_aclk_sys, i_resetn_sys)
  begin
    if i_resetn_sys = '0' then     -- asynchronous reset (active low)
      s_debounce_cnt <= (others => '0');
    elsif i_aclk_sys'event and i_aclk_sys = '1' then  -- rising clock edge
      if (s_ps2_clk_fall or s_ps2_clk_rise or s_debounce_cao) = '1' then
        s_debounce_cnt <= (others => '0');
      else
        s_debounce_cnt <= s_debounce_cnt + 1;
      end if;
    end if;
  end process;
  s_debounce_cao <= s_debounce_cnt(c_debounce_bits - 1);

  -- PS2 clock debounce and edge detector
  debounce_stm : process (i_aclk_sys, i_resetn_sys)
  begin
    if i_resetn_sys = '0' then
      s_debounce_state <= s_stable;
      s_ps2_clk_clean  <= '0';
    elsif i_aclk_sys'event and i_aclk_sys = '1' then
      case s_debounce_state is
        when s_stable =>
          if s_ps2_clk_clean /= s_ps2_clk_syn then
            if s_ps2_clk_syn = '1' then
              s_debounce_state <= s_rise;
            else
              s_debounce_state <= s_fall;
            end if;
          end if;
        when s_wait_stable =>
          if s_debounce_cao = '1' then
            s_debounce_state <= s_stable;
          end if;
        when s_rise => 
          s_debounce_state <= s_wait_stable;
          s_ps2_clk_clean <= '1';
        when s_fall => 
          s_debounce_state <= s_wait_stable;
          s_ps2_clk_clean <= '0';
        when others => null;
      end case;
    end if;
  end process;
  s_ps2_clk_fall <= '1' when s_debounce_state = s_fall else '0';
  s_ps2_clk_rise <= '1' when s_debounce_state = s_rise else '0';

  -- PS2 watchdog
  wdt_proc : process(i_aclk_sys, i_resetn_sys)
  begin
    if i_resetn_sys = '0' then     -- asynchronous reset (active low)
      s_wdt_cnt <= (others => '0');
    elsif i_aclk_sys'event and i_aclk_sys = '1' then  -- rising clock edge
      if (s_wdt_rst or s_wdt_cao) = '1' then
        s_wdt_cnt <= (others => '0');
      elsif s_debounce_cao = '1' then
        s_wdt_cnt <= s_wdt_cnt + 1;
      end if;
    end if;
  end process;
  s_wdt_cao <= s_wdt_cnt(c_watchdog_bits - 1);
  s_wdt_rst <= s_ps2_clk_fall;

  -- Shift register
  shift : process (i_aclk_sys, i_resetn_sys)
  begin
    if i_resetn_sys = '0' then     -- asynchronous reset (active low)
      s_shift_reg <= (others => '0');
    elsif i_aclk_sys'event and i_aclk_sys = '1' then  -- rising clock edge
      if s_shift_load = '1' then
        s_shift_reg(7 downto 0) <= i_data;
        s_shift_reg(8) <= '0';
      elsif s_shift_calc_parity = '1' then
        s_shift_reg(8) <= not s_shift_parity;
      elsif s_shift_in = '1' then
        s_shift_reg(7 downto 0) <= s_shift_reg(8 downto 1);
        s_shift_reg(8) <= s_ps2_data_syn;
      end if;
    end if;
  end process;

  -- Shift counter
  sft_cnt : process(i_aclk_sys, i_resetn_sys)
  begin
    if i_resetn_sys = '0' then     -- asynchronous reset (active low)
      s_shift_cnt <= (others => '0');
    elsif i_aclk_sys'event and i_aclk_sys = '1' then  -- rising clock edge
      if s_state = s_start then
        s_shift_cnt <= (others => '0');
      elsif s_state = s_data and s_ps2_clk_fall = '1' then
        s_shift_cnt <= s_shift_cnt + 1;
      end if;
    end if;
  end process;
  s_shift_cao <= '1' when s_shift_cnt = "111" else '0';

  -- Odd Parity generator
  s_shift_parity <= (s_shift_reg(0) xor
    s_shift_reg(1) xor
    s_shift_reg(2) xor
    s_shift_reg(3) xor
    s_shift_reg(4) xor
    s_shift_reg(5) xor
    s_shift_reg(6) xor
    s_shift_reg(7));

  -- Main State Machine
  stm : process (i_aclk_sys, i_resetn_sys)
  begin
    if i_resetn_sys = '0' then     -- asynchronous reset (active low)
      s_state <= s_idle;
      s_writing <= '0';
    elsif i_aclk_sys'event and i_aclk_sys = '1' then  -- rising clock edge
      case s_state is
        -- Waiting for clk
        when s_idle => 
          if i_obf_set = '1' and s_writing = '0' then
            s_state <= s_write_request;
            s_writing <= '1';
          elsif s_ps2_clk_fall = '1' then
            s_state <= s_start;
          end if;

        -- Write request, clk low
        when s_write_request => 
          if s_wdt_cao = '1' then
            s_state <= s_idle;
          end if;

        -- Clock 1, start bit
        when s_start => 
          if s_wdt_cao = '1' then
            s_state <= s_idle;
          elsif s_ps2_clk_fall = '1' then
            s_state <= s_data;
          end if;

        -- Clocks 2-9, Data bits (LSB first)
        when s_data => 
          if s_wdt_cao = '1' then
            s_state <= s_idle;
          elsif s_ps2_clk_fall = '1' and
            s_shift_cao = '1' then
            s_state <= s_parity;
          end if;

        -- Clock 10, Parity bit
        when s_parity => 
          if s_wdt_cao = '1' then
            s_state <= s_idle;
          elsif s_ps2_clk_fall = '1' then
            s_state <= s_stop;
          end if;

        -- Clock 11, Stop bit
        when s_stop => 
          s_writing <= '0';
          s_state <= s_idle;
        when others => null;
      end case;
    end if;
  end process;

  -- State flags
  flags_proc : process (i_aclk_sys, i_resetn_sys, s_state, s_writing)
  begin  -- process stm_out
    -- Input Buffer write flag
    if i_resetn_sys = '0' then     -- asynchronous reset (active low)
      --obf <= '0';
      s_ibf <= '0';
    elsif i_aclk_sys'event and i_aclk_sys = '1' then  -- rising clock edge
      -- Input Buffer full flag
      if i_ibf_clr = '1' then
        s_ibf <= '0';
      elsif s_writing = '0' then
        if s_state = s_stop then
          if s_shift_reg(8) = not s_shift_parity then
            s_ibf <= '1';
            o_data <= s_shift_reg(7 downto 0);
          end if;
        else --elsif s_state = s_start then
          s_ibf <= '0';
        end if;
      end if;
    end if;
  end process;

  s_obf <= s_writing;

  -- Shift register control
  s_shift_load <= '1' when i_obf_set = '1' else '0';
  s_shift_calc_parity <= '1' when s_state = s_idle and s_writing = '1' else '0';
  s_shift_in <= s_ps2_clk_fall when s_state = s_data or s_state = s_start else '0';

  -- PS2 Registered outputs
  syn_ps2_out : process (i_aclk_sys, i_resetn_sys)
  begin
    if i_resetn_sys = '0' then     -- asynchronous reset (active low)
      s_ps2_data_out <= '1';
      s_ps2_clk_out  <= '1';
    elsif i_aclk_sys'event and i_aclk_sys = '1' then  -- rising clock edge
      -- PS2 Data out
      if s_writing = '1' then
        if s_state = s_idle then
          s_ps2_data_out <= '0';
        elsif s_state = s_data or s_state = s_start then
          s_ps2_data_out <= s_shift_reg(0);
        else
          s_ps2_data_out <= '1';
        end if;
      end if;

      -- PS2 Clk out
      if s_state = s_write_request then
        s_ps2_clk_out <= '0';
      else
        s_ps2_clk_out <= '1';
      end if;
    end if;
  end process;

  o_ibf <= s_ibf;
  o_obf <= s_obf;
  o_busy <= '0' when s_state = s_idle and s_writing = '0' else '1';
  io_ps_clk  <= '0' when s_ps2_clk_out = '0'  else 'Z';
  io_ps_dat <= '0' when s_ps2_data_out = '0' else 'Z';

end architecture;
