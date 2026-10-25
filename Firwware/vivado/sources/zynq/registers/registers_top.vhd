----------------------------------------------------------------------------------
-- Company: Magictale Electronics http://magictale.com
-- Engineer: Dmitry Pakhomenko
-- 
-- Create Date: 09.12.2023 1:56:00 PM
-- Design Name: Top wrapper for Arty emulator registers
-- Module Name: registers_top - RTL
-- Project Name: Retro computer emulator on Arty Z7 board
-- Target Devices: Zynq 7020
-- Tool Versions: Vivado 2017.3
-- Description: This module contains subset of registers for controlling emulator
--     hardware without specifics of an emulated platform
-- 
-- Dependencies: registers.vhd
-- 
-- Revision:
-- Revision 0.01 - File created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library xil_defaultlib;
  use work.types_emulator_top.all;

entity registers_top is
    generic (
      g_axi_lite_data_width : integer := 32;
      g_axi_addr_width : integer := 32
    );
    port ( 
      i_resetn_sys : in std_logic;
      i_aclk_sys : in std_logic;

      -- AXI Lite interface
      i_axi_lite_araddr : in std_logic_vector (g_axi_addr_width - 1 downto 0);
      o_axi_lite_arready : out std_logic;
      i_axi_lite_arvalid : in std_logic;
      i_axi_lite_awaddr : in std_logic_vector (g_axi_addr_width - 1 downto 0);
      o_axi_lite_awready : out std_logic;
      i_axi_lite_awvalid : in std_logic;
      i_axi_lite_bready : in std_logic;
      o_axi_lite_bresp : out std_logic_vector (1 downto 0);
      o_axi_lite_bvalid : out std_logic;
      o_axi_lite_rdata : out std_logic_vector (g_axi_lite_data_width - 1 downto 0);
      i_axi_lite_rready : in std_logic;
      o_axi_lite_rresp : out std_logic_vector (1 downto 0);
      o_axi_lite_rvalid : out std_logic;
      i_axi_lite_wdata : in std_logic_vector (g_axi_lite_data_width - 1 downto 0);
      o_axi_lite_wready : out std_logic;
      i_axi_lite_wvalid : in std_logic;
      i_axi_lite_arprot : in std_logic_vector (2 downto 0);
      i_axi_lite_awprot : in std_logic_vector (2 downto 0);
      i_axi_lite_wstrb : in std_logic_vector ((g_axi_lite_data_width / 8 ) - 1 downto 0);

      o_wr_en : out std_logic;
      o_rd_en : out std_logic;
      o_register_data_out : out std_logic_vector(g_axi_lite_data_width - 1 downto 0);
      o_mem_write_test_en : out std_logic;
      o_video_control_en : out std_logic;
      i_video_control : in std_logic_vector(g_axi_lite_data_width - 1 downto 0);
      o_emu_control_en : out std_logic;
      i_emu_control : in std_logic_vector(g_axi_lite_data_width - 1 downto 0);
--      o_emu_keyboard_1_en : out std_logic;
--      o_emu_keyboard_2_en : out std_logic;
--      o_emu_io_ports_en : out std_logic;
--      i_emu_io_ports : in std_logic_vector(g_axi_lite_data_width - 1 downto 0);
--      o_emu_tape_fifo_en : out std_logic;
--      i_emu_tape_fifo : in std_logic_vector(g_axi_lite_data_width - 1 downto 0);
--      o_emu_bram_en : out std_logic;
--      i_emu_bram : in std_logic_vector(g_axi_lite_data_width - 1 downto 0);
--      o_shadow_emu_bram_en : out std_logic;
--      i_shadow_emu_bram : in std_logic_vector(g_axi_lite_data_width - 1 downto 0);
--      o_border_color_en : out std_logic;
--      i_border_color : in std_logic_vector(g_axi_lite_data_width - 1 downto 0);

      -- Z80 registers
--      o_z80_hl_de_alt_en : out std_logic;
--      i_z80_hl_de_alt : in std_logic_vector(g_axi_lite_data_width - 1 downto 0);
--      o_z80_bc_af_alt_en : out std_logic;
--      i_z80_bc_af_alt : in std_logic_vector(g_axi_lite_data_width - 1 downto 0);
--      o_z80_hl_de_en : out std_logic;
--      i_z80_hl_de : in std_logic_vector(g_axi_lite_data_width - 1 downto 0);
--      o_z80_bc_af_en : out std_logic;
--      i_z80_bc_af : in std_logic_vector(g_axi_lite_data_width - 1 downto 0);
--      o_z80_ix_iy_en : out std_logic;
--      i_z80_ix_iy : in std_logic_vector(g_axi_lite_data_width - 1 downto 0);
--      o_z80_r_sp_iff_im_en : out std_logic;
--      i_z80_r_sp_iff_im : in std_logic_vector(g_axi_lite_data_width - 1 downto 0);

      o_memtest_pass_cnt_en : out std_logic;
      i_memtest_pass_cnt : in std_logic_vector(g_axi_lite_data_width - 1 downto 0);
      o_memtest_fail_cnt_en : out std_logic;
      i_memtest_fail_cnt : in std_logic_vector(g_axi_lite_data_width - 1 downto 0);

      o_mmc_di_en : out std_logic;
      i_mmc_di : in std_logic_vector(g_axi_lite_data_width - 1 downto 0);
--      o_mmc_do_en : out std_logic;
--      i_mmc_do : in std_logic_vector(g_axi_lite_data_width - 1 downto 0);
      o_ps2_kbd_do_en : out std_logic;
      i_ps2_kbd_do : in std_logic_vector(g_axi_lite_data_width - 1 downto 0);
      o_joystick_en : out std_logic;
      i_joystick : in std_logic_vector(g_axi_lite_data_width - 1 downto 0)
    );

end registers_top;

architecture rtl of registers_top is

  signal s_reg_rd_en : std_logic;
  signal s_reg_wr_en : std_logic;
  signal s_register_data_out : std_logic_vector(g_axi_lite_data_width - 1 downto 0);

--  signal s_border_color : std_logic_vector(g_axi_lite_data_width - 1 downto 0);
--  signal s_border_color_en : std_logic;
--  signal s_framebuf_addr : std_logic_vector(g_axi_lite_data_width - 1 downto 0);
--  signal s_framebuf_addr_en : std_logic;
--  signal s_status : std_logic_vector(g_axi_lite_data_width - 1 downto 0);
--  signal s_status_en : std_logic;
  signal s_control : std_logic_vector(g_axi_lite_data_width - 1 downto 0);
  signal s_control_en : std_logic;
--  signal s_error : std_logic_vector(g_axi_lite_data_width - 1 downto 0);
--  signal s_error_en : std_logic;
--  signal s_irq : std_logic_vector(g_axi_lite_data_width - 1 downto 0);
--  signal s_irq_en : std_logic;

  component registers
    generic (
      g_axi_lite_data_width : integer := 32;
      g_axi_addr_width : integer := 32
    );
    port ( 
      i_resetn_sys : in std_logic;
      i_aclk_sys : in std_logic;

      i_axi_lite_araddr : in std_logic_vector (g_axi_addr_width - 1 downto 0);
      o_axi_lite_arready : out std_logic;
      i_axi_lite_arvalid : in std_logic;
      i_axi_lite_awaddr : in std_logic_vector (g_axi_addr_width - 1 downto 0);
      o_axi_lite_awready : out std_logic;
      i_axi_lite_awvalid : in std_logic;
      i_axi_lite_bready : in std_logic;
      o_axi_lite_bresp : out std_logic_vector (1 downto 0);
      o_axi_lite_bvalid : out std_logic;
      o_axi_lite_rdata : out std_logic_vector (g_axi_lite_data_width - 1 downto 0);
      i_axi_lite_rready : in std_logic;
      o_axi_lite_rresp : out std_logic_vector (1 downto 0);
      o_axi_lite_rvalid : out std_logic;
      i_axi_lite_wdata : in std_logic_vector (g_axi_lite_data_width - 1 downto 0);
      o_axi_lite_wready : out std_logic;
      i_axi_lite_wvalid : in std_logic;
      i_axi_lite_arprot : in std_logic_vector (2 downto 0);
      i_axi_lite_awprot : in std_logic_vector (2 downto 0);
      i_axi_lite_wstrb : in std_logic_vector ((g_axi_lite_data_width / 8 ) - 1 downto 0);

      o_rd_en : out std_logic;
      o_wr_en : out std_logic;
      o_register_data_out : out std_logic_vector(g_axi_lite_data_width - 1 downto 0);
      
      --i_border_size : in std_logic_vector(g_axi_lite_data_width - 1 downto 0);
      --o_border_size_en : out std_logic;
--      i_border_color : in std_logic_vector(g_axi_lite_data_width - 1 downto 0);
--      o_border_color_en : out std_logic;
--      i_framebuf_addr : in std_logic_vector(g_axi_lite_data_width - 1 downto 0);
--      o_framebuf_addr_en : out std_logic;
--      i_status : in std_logic_vector(g_axi_lite_data_width - 1 downto 0);
--      o_status_en : out std_logic;
      i_control : in std_logic_vector(g_axi_lite_data_width - 1 downto 0);
      o_control_en : out std_logic;
--      i_error : in std_logic_vector(g_axi_lite_data_width - 1 downto 0);
--      o_error_en : out std_logic;
--      i_irq : in std_logic_vector(g_axi_lite_data_width - 1 downto 0);
--      o_irq_en : out std_logic;

--      o_mem_write_test_en : out std_logic;
      o_emu_control_en : out std_logic;
      i_emu_control : in std_logic_vector(g_axi_lite_data_width - 1 downto 0);
--      o_emu_keyboard_1_en : out std_logic;
--      o_emu_keyboard_2_en : out std_logic;
--      o_emu_io_ports_en  : out std_logic;
--      i_emu_io_ports : in std_logic_vector(g_axi_lite_data_width - 1 downto 0);
--      o_emu_tape_fifo_en : out std_logic;
--      i_emu_tape_fifo : in std_logic_vector(g_axi_lite_data_width - 1 downto 0);
--      o_emu_bram_en : out std_logic;
--      i_emu_bram : in std_logic_vector(g_axi_lite_data_width - 1 downto 0);
--      o_shadow_emu_bram_en : out std_logic;
--      i_shadow_emu_bram : in std_logic_vector(g_axi_lite_data_width - 1 downto 0);

      -- Z80 registers
--      o_z80_hl_de_alt_en : out std_logic;
--      i_z80_hl_de_alt : in std_logic_vector(g_axi_lite_data_width - 1 downto 0);
--      o_z80_bc_af_alt_en : out std_logic;
--      i_z80_bc_af_alt : in std_logic_vector(g_axi_lite_data_width - 1 downto 0);
--      o_z80_hl_de_en : out std_logic;
--      i_z80_hl_de : in std_logic_vector(g_axi_lite_data_width - 1 downto 0);
--      o_z80_bc_af_en : out std_logic;
--      i_z80_bc_af : in std_logic_vector(g_axi_lite_data_width - 1 downto 0);
--      o_z80_ix_iy_en : out std_logic;
--      i_z80_ix_iy : in std_logic_vector(g_axi_lite_data_width - 1 downto 0);
--      o_z80_r_sp_iff_im_en : out std_logic;
--      i_z80_r_sp_iff_im : in std_logic_vector(g_axi_lite_data_width - 1 downto 0);

      o_memtest_pass_cnt_en : out std_logic;
      i_memtest_pass_cnt : in std_logic_vector(g_axi_lite_data_width - 1 downto 0);
      o_memtest_fail_cnt_en : out std_logic;
      i_memtest_fail_cnt : in std_logic_vector(g_axi_lite_data_width - 1 downto 0);

      o_mmc_di_en : out std_logic;
      i_mmc_di : in std_logic_vector(g_axi_lite_data_width - 1 downto 0);
--      o_mmc_do_en : out std_logic;
--      i_mmc_do : in std_logic_vector(g_axi_lite_data_width - 1 downto 0);
      o_ps2_kbd_do_en : out std_logic;
      i_ps2_kbd_do : in std_logic_vector(g_axi_lite_data_width - 1 downto 0);
      o_joystick_en : out std_logic;
      i_joystick : in std_logic_vector(g_axi_lite_data_width - 1 downto 0)

    );
  end component;

begin

  i_registers : registers
    port map (
      i_resetn_sys => i_resetn_sys,
      i_aclk_sys => i_aclk_sys,
      i_axi_lite_araddr => i_axi_lite_araddr,
      o_axi_lite_arready => o_axi_lite_arready,
      i_axi_lite_arvalid => i_axi_lite_arvalid,
      i_axi_lite_awaddr => i_axi_lite_awaddr,
      o_axi_lite_awready => o_axi_lite_awready,
      i_axi_lite_awvalid => i_axi_lite_awvalid,
      i_axi_lite_bready => i_axi_lite_bready,
      o_axi_lite_bresp => o_axi_lite_bresp,
      o_axi_lite_bvalid => o_axi_lite_bvalid,
      o_axi_lite_rdata => o_axi_lite_rdata,
      i_axi_lite_rready => i_axi_lite_rready,
      o_axi_lite_rresp => o_axi_lite_rresp,
      o_axi_lite_rvalid => o_axi_lite_rvalid,
      i_axi_lite_wdata => i_axi_lite_wdata,
      o_axi_lite_wready => o_axi_lite_wready,
      i_axi_lite_wvalid => i_axi_lite_wvalid,
      i_axi_lite_arprot => i_axi_lite_arprot,
      i_axi_lite_awprot => i_axi_lite_awprot,
      i_axi_lite_wstrb => i_axi_lite_wstrb,

      o_rd_en => s_reg_rd_en,
      o_wr_en => s_reg_wr_en,
      o_register_data_out => s_register_data_out,
--      i_border_color => s_border_color,
--      o_border_color_en => s_border_color_en,
--      i_framebuf_addr => s_framebuf_addr,
--      o_framebuf_addr_en => s_framebuf_addr_en,
--      i_status => s_status,
--      o_status_en => s_status_en,
      i_control => s_control,
      o_control_en => s_control_en,
--      i_error => s_error,
--      o_error_en => s_error_en,
--      i_irq => s_irq,
--      o_irq_en => s_irq_en,

--      o_mem_write_test_en => o_mem_write_test_en,
      o_emu_control_en => o_emu_control_en,
      i_emu_control => i_emu_control,
--      o_emu_keyboard_1_en => o_emu_keyboard_1_en,
--      o_emu_keyboard_2_en => o_emu_keyboard_2_en,
--      o_emu_io_ports_en => o_emu_io_ports_en,
--      i_emu_io_ports => i_emu_io_ports,
--      o_emu_tape_fifo_en => o_emu_tape_fifo_en,
--      i_emu_tape_fifo  => i_emu_tape_fifo,
--      o_emu_bram_en => o_emu_bram_en,
--      i_emu_bram => i_emu_bram,
--      o_shadow_emu_bram_en => o_shadow_emu_bram_en,
--      i_shadow_emu_bram => i_shadow_emu_bram,

      -- Z80 registers
--      o_z80_hl_de_alt_en => o_z80_hl_de_alt_en,
--      i_z80_hl_de_alt => i_z80_hl_de_alt,
--      o_z80_bc_af_alt_en => o_z80_bc_af_alt_en,
--      i_z80_bc_af_alt => i_z80_bc_af_alt,
--      o_z80_hl_de_en => o_z80_hl_de_en,
--      i_z80_hl_de => i_z80_hl_de,
--      o_z80_bc_af_en => o_z80_bc_af_en,
--      i_z80_bc_af => i_z80_bc_af,
--      o_z80_ix_iy_en => o_z80_ix_iy_en,
--      i_z80_ix_iy => i_z80_ix_iy,
--      o_z80_r_sp_iff_im_en => o_z80_r_sp_iff_im_en,
--      i_z80_r_sp_iff_im => i_z80_r_sp_iff_im,

      o_memtest_pass_cnt_en => o_memtest_pass_cnt_en,
      i_memtest_pass_cnt => i_memtest_pass_cnt,
      o_memtest_fail_cnt_en => o_memtest_fail_cnt_en,
      i_memtest_fail_cnt => i_memtest_fail_cnt,

      o_mmc_di_en => o_mmc_di_en,
      i_mmc_di => i_mmc_di,
--      o_mmc_do_en => o_mmc_do_en,
--      i_mmc_do => i_mmc_do,
      o_ps2_kbd_do_en => o_ps2_kbd_do_en,
      i_ps2_kbd_do => i_ps2_kbd_do,
      o_joystick_en => o_joystick_en,
      i_joystick => i_joystick
    );
  
    o_register_data_out <= s_register_data_out;
    o_wr_en <= s_reg_wr_en;
    o_rd_en <= s_reg_rd_en;

    o_video_control_en <= s_control_en;
    s_control <= i_video_control;

end architecture;
