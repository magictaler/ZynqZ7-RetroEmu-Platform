----------------------------------------------------------------------------------
-- Company: Magictale Electronics http://magictale.com
-- Engineer: Dmitry Pakhomenko
-- 
-- Create Date: 25/11/2023 4:07:00 PM
-- Design Name: AXI DDR memory interface
-- Module Name: axi_ddr - RTL
-- Project Name: Retro computer emulator on Arty Z7 board
-- Target Devices: Zynq 7020
-- Tool Versions: Vivado 2017.3
-- Description: This module allows 8-bit MCU accessing DDRAM via 32-bit AXI bus
-- 
-- Dependencies: 
-- 
-- Revision:
-- 
-- Revision 0.01 - Copied across from Speccy2022 project and refactored
-- Additional Comments:
-- 
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library xil_defaultlib;
    use work.types_axi_ddr.all;


entity axi_ddr is
    generic (
      g_axi_data_width : integer := 32;
      g_axi_addr_width : integer := 32;
      g_axi_ddr_data_width : integer := 8;
      g_axi_ddr_addr_width : integer := 25
    );
    port ( 
      i_resetn_sys : in std_logic;
      i_aclk_sys : in std_logic;
      -- AXI interface      
      o_axi_ddr_araddr : out std_logic_vector(g_axi_addr_width - 1 downto 0);
      o_axi_ddr_arburst : out std_logic_vector(1 downto 0);
      o_axi_ddr_arcache : out std_logic_vector(3 downto 0);
      o_axi_ddr_arlen : out std_logic_vector(7 downto 0);
      o_axi_ddr_arprot : out std_logic_vector(2 downto 0);
      i_axi_ddr_arready : in std_logic;
      o_axi_ddr_arsize : out std_logic_vector(2 downto 0);
      o_axi_ddr_arvalid : out std_logic;
      i_axi_ddr_rdata : in std_logic_vector(g_axi_data_width - 1 downto 0);
      i_axi_ddr_rlast : in std_logic;
      o_axi_ddr_rready : out std_logic;
      i_axi_ddr_rresp : in std_logic_vector(1 downto 0);
      i_axi_ddr_rvalid : in std_logic;
      
      o_axi_ddr_awaddr : out std_logic_vector(g_axi_addr_width - 1 downto 0);
      o_axi_ddr_awburst : out std_logic_vector(1 downto 0);
      o_axi_ddr_awcache : out std_logic_vector(3 downto 0);
      o_axi_ddr_awlen : out std_logic_vector(7 downto 0);
      o_axi_ddr_awprot : out std_logic_vector(2 downto 0);
      i_axi_ddr_awready : in std_logic;
      o_axi_ddr_awsize : out std_logic_vector(2 downto 0);
      o_axi_ddr_awvalid : out std_logic;
      o_axi_ddr_wdata : out std_logic_vector(g_axi_data_width - 1 downto 0);
      o_axi_ddr_wlast : out std_logic;
      i_axi_ddr_wready : in std_logic;
      i_axi_ddr_bresp : in std_logic_vector(1 downto 0);
      o_axi_ddr_wvalid : out std_logic;
      o_axi_ddr_wstrb : out std_logic_vector(3 downto 0);
      i_axi_ddr_bvalid : in std_logic;
      o_axi_ddr_bready : out std_logic;
      
      i_ddr_address : in std_logic_vector(g_axi_ddr_addr_width - 1 downto 0);
      i_ddr_data : in std_logic_vector(g_axi_ddr_data_width - 1 downto 0);
      o_ddr_data : out std_logic_vector(g_axi_ddr_data_width - 1 downto 0);
      i_ddr_mem_wr : in std_logic;
      i_ddr_mem_req : in std_logic;
      o_ddr_mem_busy : out std_logic
    );

end axi_ddr;

architecture rtl of axi_ddr is

  signal s_state_amba : t_state_amba := t_idle_amba;
  signal s_axi_ddr_arcache : std_logic_vector(3 downto 0) := c_axi_cache;
  signal s_axi_ddr_awcache : std_logic_vector(3 downto 0) := c_axi_cache;
  signal s_rwdata_lsb : integer range 0 to 24;
  signal s_memory_write : std_logic;
  signal s_ddr_mem_req_vec : std_logic_vector(2 downto 0);

begin

  -- This process reads/writes data from/to DDR RAM
  p_amba_fsm : process(i_aclk_sys)
  begin
    if rising_edge(i_aclk_sys) then
      if (i_resetn_sys = '0') then
        s_state_amba <= t_idle_amba;
        s_memory_write <= '0';
        o_axi_ddr_rready <= '0';
        o_axi_ddr_arvalid <= '0';
        -- TODO: add the writing signals
        o_axi_ddr_wstrb <= (others => '0');
      else
        case s_state_amba is
          when t_idle_amba =>
            if (s_ddr_mem_req_vec(2 downto 1) = c_active_high_raising_edge) then
              s_state_amba <= t_set_addr_amba;
              s_memory_write <= i_ddr_mem_wr;
              o_ddr_mem_busy <= '1';
            else
              o_ddr_mem_busy <= '0';
            end if;
          when t_set_addr_amba =>
            if (s_memory_write = '0') then
              -- resetting the two least significant bits as we read in chunks of 32 bits and have to be 32 bits aligned
              o_axi_ddr_araddr <= std_logic_vector(c_axi_ram_start_address + 
                unsigned("00000000" & i_ddr_address(g_axi_ddr_addr_width - 1 downto 2) & "00"));
              o_axi_ddr_arsize <= std_logic_vector(to_unsigned(c_axi_arsize, o_axi_ddr_arsize'length));
              o_axi_ddr_arlen <= std_logic_vector(to_unsigned(c_axi_arlen, o_axi_ddr_arlen'length));
              o_axi_ddr_arburst <= std_logic_vector(to_unsigned(c_axi_arburst, o_axi_ddr_arburst'length));
              o_axi_ddr_arprot <= (others => '0');
              o_axi_ddr_arvalid <= '1';
            else
              -- resetting the two least significant bits as we read in chunks of 32 bits and have to be 32 bits aligned
              o_axi_ddr_awaddr <= std_logic_vector(c_axi_ram_start_address + 
                unsigned("00000000" & i_ddr_address(g_axi_ddr_addr_width - 1 downto 2) & "00"));
              o_axi_ddr_awsize <= std_logic_vector(to_unsigned(c_axi_awsize, o_axi_ddr_awsize'length));
              o_axi_ddr_awlen <= std_logic_vector(to_unsigned(c_axi_awlen, o_axi_ddr_awlen'length));
              o_axi_ddr_awburst <= std_logic_vector(to_unsigned(c_axi_awburst, o_axi_ddr_awburst'length));
              o_axi_ddr_arprot <= (others => '0');
              o_axi_ddr_awvalid <= '1';
            end if;
            s_state_amba <= t_wait_addr_ack_amba;
          when t_wait_addr_ack_amba =>
            if (s_memory_write = '0') then
              if i_axi_ddr_arready = '1' then
                o_axi_ddr_arvalid <= '0';
                o_axi_ddr_rready <= '1';
                s_state_amba <= t_wait_data_start_amba;
              end if;
            else 
              if i_axi_ddr_awready = '1' then
                o_axi_ddr_awvalid <= '0';
                o_axi_ddr_wlast <= '0';
                s_state_amba <= t_wait_data_start_amba;
              end if;
            end if;
          when t_wait_data_start_amba =>
            if (s_memory_write = '0') then
              if i_axi_ddr_rvalid = '1' and i_axi_ddr_rlast = '0' then
                -- Read first portion of data
                o_ddr_data <= i_axi_ddr_rdata(s_rwdata_lsb + 7 downto s_rwdata_lsb);
                s_state_amba <= t_read_amba;
              end if;
            else
              if (i_axi_ddr_wready = '1') then
                o_axi_ddr_wdata(s_rwdata_lsb + 7 downto s_rwdata_lsb) <= i_ddr_data;
                o_axi_ddr_wvalid <= '1';
                o_axi_ddr_wlast <= '1';
                o_axi_ddr_wstrb(to_integer(unsigned(i_ddr_address(1 downto 0)))) <= '1';
                s_state_amba <= t_write_amba;
              end if;
            end if;
          when t_write_amba => 
            if (i_axi_ddr_wready = '1') then
              o_axi_ddr_wdata <= (others => '0');
              o_axi_ddr_wvalid <= '0';
              o_axi_ddr_wlast <= '0';
              o_axi_ddr_wstrb <= (others => '0');
              s_state_amba <= t_write_ack_amba;
            end if;
          when t_write_ack_amba => 
             if (i_axi_ddr_bvalid = '1') then
               if (i_axi_ddr_bresp = "00") then
                 s_state_amba <= t_done_amba;
               else
                 s_state_amba <= t_error_amba; 
               end if;
               o_axi_ddr_bready <= '1';
               o_ddr_mem_busy <= '0';
             end if;
          when t_read_amba =>
            if i_axi_ddr_rvalid = '1' then
              if i_axi_ddr_rlast = '1' then
                -- Valid transmission
                s_state_amba <= t_done_amba;
              end if;
            else
              -- Didn't find rlast pulse
              s_state_amba <= t_error_amba;
            end if;
            o_ddr_mem_busy <= '0';
          when t_error_amba =>
            if (s_memory_write = '0') then
              o_axi_ddr_rready <= '0';
            else
              o_axi_ddr_bready <= '0';
            end if;
            -- We have to ack the transaction regardless
            o_ddr_mem_busy <= '0';
            s_state_amba <= t_idle_amba;
          when t_done_amba =>
            if (s_memory_write = '0') then
              o_axi_ddr_rready <= '0';
            else
              o_axi_ddr_bready <= '0';
            end if;
            o_ddr_mem_busy <= '0';
            s_state_amba <= t_idle_amba;
          when others => null;
        end case;
      end if;
    end if;
  end process;

  p_edge_detection : process(i_aclk_sys)
  begin
    if rising_edge(i_aclk_sys) then
      if (i_resetn_sys = '0') then
        s_ddr_mem_req_vec <= (others => '0');
      else
        s_ddr_mem_req_vec <= s_ddr_mem_req_vec(1 downto 0) & i_ddr_mem_req;
      end if;
    end if;
  end process;

  o_axi_ddr_arcache <= s_axi_ddr_arcache;
  s_rwdata_lsb <= to_integer(unsigned(i_ddr_address(1 downto 0) & "000"));

end architecture;
