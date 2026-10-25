----------------------------------------------------------------------------------
-- Company: Magictale Electronics http://magictale.com
-- Engineer: Dmitry Pakhomenko
-- 
-- Create Date: 26.11.2023 08:17:00 AM
-- Design Name: Arty Z7 specific registers for emulator
-- Module Name: arty_registers - RTL
-- Project Name: Retro computer emulator on Arty Z7 board
-- Target Devices: Zynq 7020
-- Tool Versions: Vivado 2017.3
-- Description: This module contains subset of registers for controlling emulator
--     hardware without specifics of an emulated platform
-- 
-- Dependencies: arty_video
-- 
-- Revision:
-- Revision 0.01 - Copied across from Speccy2022 project and refactored
-- Additional Comments:
-- 
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity registers is
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

      o_rd_en : out std_logic;
      o_wr_en : out std_logic;
      o_register_data_out : out std_logic_vector(g_axi_lite_data_width - 1 downto 0);
      -- Video controller registers
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
      -- Memory mapper registers
--      o_mem_write_test_en : out std_logic;
      -- Emulator specific registers
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

end registers;

architecture rtl of registers is

  -- AXI4LITE signals
  signal s_axi_awaddr : std_logic_vector(g_axi_addr_width - 1 downto 0);
  signal s_axi_awready : std_logic;
  signal s_axi_wready : std_logic;
  signal s_axi_bresp : std_logic_vector(1 downto 0);
  signal s_axi_bvalid : std_logic;
  signal s_axi_araddr : std_logic_vector(g_axi_addr_width - 1 downto 0);
  signal s_axi_arready : std_logic;
  signal s_axi_rdata : std_logic_vector(g_axi_lite_data_width - 1 downto 0);
  signal s_axi_rresp : std_logic_vector(1 downto 0);
  signal s_axi_rvalid : std_logic_vector(2 downto 0);

  -- Example-specific design signals
  -- local parameter for addressing 32 bit / 64 bit g_axi_lite_data_width
  -- c_addr_lsb is used for addressing 32/64 bit registers/memories
  -- c_addr_lsb = 2 for 32 bits (n downto 2)
  -- c_addr_lsb = 3 for 64 bits (n downto 3)
  constant c_addr_lsb  : integer := (g_axi_lite_data_width / 32) + 1;
  constant c_opt_mem_addr_bits : integer := 6;
  ------------------------------------------------
  ---- Signals for user logic register space 
  --------------------------------------------------
--  signal s_border_color_en : std_logic;
--  signal s_framebuf_addr_en : std_logic;
--  signal s_status_en : std_logic;
  signal s_control_en : std_logic;
--  signal s_error_en : std_logic;
--  signal s_irq_en : std_logic;
--  signal s_mem_write_test_en : std_logic;
  signal s_emu_control_en : std_logic;
--  signal s_emu_keyboard_1_en : std_logic;
--  signal s_emu_keyboard_2_en : std_logic;
--  signal s_emu_io_ports_en : std_logic;
--  signal s_emu_tape_fifo_en : std_logic;
--  signal s_emu_bram_en : std_logic;
--  signal s_shadow_emu_bram_en : std_logic;
--  signal s_z80_hl_de_alt_en : std_logic;
--  signal s_z80_bc_af_alt_en : std_logic;
--  signal s_z80_hl_de_en : std_logic;
--  signal s_z80_bc_af_en : std_logic;
--  signal s_z80_ix_iy_en : std_logic;
--  signal s_z80_r_sp_iff_im_en : std_logic;
  signal s_memtest_pass_cnt_en : std_logic;
  signal s_memtest_fail_cnt_en : std_logic;
  signal s_mmc_di_en : std_logic;
--  signal s_mmc_do_en : std_logic;
  signal s_ps2_kbd_do_en : std_logic;
  signal s_joystick_en : std_logic;

  signal s_slv_reg_rden : std_logic;
  signal s_slv_reg_wren : std_logic;
  signal s_reg_data_out : std_logic_vector(g_axi_lite_data_width - 1 downto 0);
  signal s_byte_index : integer;
  signal s_slv_reg_rden_vec : std_logic_vector(2 downto 0);
  signal s_slv_reg_rdrdy : std_logic_vector(1 downto 0);

  signal s_register_data_out : std_logic_vector(g_axi_lite_data_width - 1 downto 0);
  signal s_rd_en : std_logic;
  signal s_wr_en : std_logic;

  -- Standard Video IP registers
  constant c_control_reg             : std_logic_vector (c_opt_mem_addr_bits downto 0) := b"0000000";
--  constant c_status_reg              : std_logic_vector (c_opt_mem_addr_bits downto 0) := b"0000001";
--  constant c_error_reg               : std_logic_vector (c_opt_mem_addr_bits downto 0) := b"0000010";
--  constant c_irq_reg                 : std_logic_vector (c_opt_mem_addr_bits downto 0) := b"0000011";
  constant c_version_reg             : std_logic_vector (c_opt_mem_addr_bits downto 0) := b"0000100";
  -- Core specific registers
  constant c_core_specific_reg_start : std_logic_vector (c_opt_mem_addr_bits downto 0) := b"1000000";
  --constant c_unused_reg         : std_logic_vector (c_opt_mem_addr_bits downto 0) := b"1000000";
--  constant c_framebuf_addr_reg       : std_logic_vector (c_opt_mem_addr_bits downto 0) := b"1000010"; -- Frambuf data start address
--  constant c_border_color_reg        : std_logic_vector (c_opt_mem_addr_bits downto 0) := b"1000100"; -- Emulator border color
  -- Memory mapper test registers
--  constant c_mem_write_test_reg      : std_logic_vector (c_opt_mem_addr_bits downto 0) := b"1000101"; -- Memory write test register
  -- Emulator control register
  constant c_emu_control_reg         : std_logic_vector (c_opt_mem_addr_bits downto 0) := b"1000110"; -- Emulator control register
  -- Emulator Keyboard registers
--  constant c_emu_keyboard_1_reg      : std_logic_vector (c_opt_mem_addr_bits downto 0) := b"1000111"; -- Emulator Keyboard register 1
--  constant c_emu_keyboard_2_reg      : std_logic_vector (c_opt_mem_addr_bits downto 0) := b"1001000"; -- Emulator Keyboard register 2
  -- Emulator IO ports
--  constant c_emu_io_ports_reg        : std_logic_vector (c_opt_mem_addr_bits downto 0) := b"1001001"; -- Emulator IO ports
  -- Emulator TAPE FIFO
--  constant c_emu_tape_fifo_reg       : std_logic_vector (c_opt_mem_addr_bits downto 0) := b"1001010"; -- Emulator TAPE fifo
  -- Accessing BRAM
--  constant c_emu_bram_reg            : std_logic_vector (c_opt_mem_addr_bits downto 0) := b"1001011"; -- A register for accessing Emulator BRAM
--  constant c_shadow_emu_bram_reg     : std_logic_vector (c_opt_mem_addr_bits downto 0) := b"1001100"; -- A register for accessing Shadow Enumator BRAM, for instance, for alternative framebuffer

--  constant c_z80_hl_de_alt_reg       : std_logic_vector (c_opt_mem_addr_bits downto 0) := b"1001101"; -- Access to HL' and DE' Z80 registers
--  constant c_z80_bc_af_alt_reg       : std_logic_vector (c_opt_mem_addr_bits downto 0) := b"1001110"; -- Access to BC' and AF' Z80 registers
--  constant c_z80_hl_de_reg           : std_logic_vector (c_opt_mem_addr_bits downto 0) := b"1001111"; -- Access to HL and DE Z80 registers
--  constant c_z80_bc_af_reg           : std_logic_vector (c_opt_mem_addr_bits downto 0) := b"1010000"; -- Access to BC and AF Z80 registers
--  constant c_z80_ix_iy_reg           : std_logic_vector (c_opt_mem_addr_bits downto 0) := b"1010001"; -- Access to IX and IY Z80 registers
--  constant c_z80_r_sp_iff_im_reg     : std_logic_vector (c_opt_mem_addr_bits downto 0) := b"1010010"; -- Access to R, SP Z80 registers and IFF2, IFF1 and IM bits
  -- Memory tester
  constant c_memtest_pass_cnt_reg    : std_logic_vector (c_opt_mem_addr_bits downto 0) := b"1010011"; -- Memory tester pass counter
  constant c_memtest_fail_cnt_reg    : std_logic_vector (c_opt_mem_addr_bits downto 0) := b"1010100"; -- Memory tester fail counter
  -- SD/MMC card mapping
  constant c_mmc_di_reg              : std_logic_vector (c_opt_mem_addr_bits downto 0) := b"1010101"; -- SD card data in
--  constant c_mmc_do_reg              : std_logic_vector (c_opt_mem_addr_bits downto 0) := b"1010110"; -- SD card data out
  -- P2/2 keyboad mapping 
  constant c_ps2_kbd_do_reg          : std_logic_vector (c_opt_mem_addr_bits downto 0) := b"1010111"; -- emulated PS/2 keyboard data out
  -- Joystick emulation 
  constant c_joystick_reg            : std_logic_vector (c_opt_mem_addr_bits downto 0) := b"1011000"; -- emulated joysticks
 
  constant c_version : std_logic_vector(g_axi_lite_data_width - 1 downto 0) := x"00000010";



  attribute MARK_DEBUG : string;

  --attribute MARK_DEBUG of s_axi_araddr : signal is "true";
  --attribute MARK_DEBUG of s_axi_rdata : signal is "true";
  --attribute MARK_DEBUG of i_mmc_di : signal is "true";
  --attribute MARK_DEBUG of s_slv_reg_rden_vec : signal is "true";

  --attribute MARK_DEBUG of s_slv_reg_wren : signal is "true";
  --attribute MARK_DEBUG of s_slv_reg_rden : signal is "true";
  --attribute MARK_DEBUG of s_rd_en : signal is "true";
  --attribute MARK_DEBUG of s_slv_reg_rdrdy : signal is "true";
  --attribute MARK_DEBUG of s_wr_en  : signal is "true";
  --attribute MARK_DEBUG of o_register_data_out  : signal is "true";
  --attribute MARK_DEBUG of o_mmc_di_en  : signal is "true";


begin

  -- I/O Connections assignments
  o_axi_lite_awready <= s_axi_awready;
  o_axi_lite_wready <= s_axi_wready;
  o_axi_lite_bresp <= s_axi_bresp;
  o_axi_lite_bvalid <= s_axi_bvalid;
  o_axi_lite_arready <= s_axi_arready;
  o_axi_lite_rdata <= s_axi_rdata;
  o_axi_lite_rresp <= s_axi_rresp;
  o_axi_lite_rvalid <= s_axi_rvalid(2);

  o_wr_en <= s_wr_en;
  o_rd_en <= s_rd_en;
  o_register_data_out <= s_register_data_out;

--  o_border_color_en <= s_border_color_en;
--  o_framebuf_addr_en <= s_framebuf_addr_en;
--  o_status_en <= s_status_en;
  o_control_en <= s_control_en;
--  o_error_en <= s_error_en;
--  o_irq_en <= s_irq_en;
--  o_mem_write_test_en <= s_mem_write_test_en;
  o_emu_control_en <= s_emu_control_en;
--  o_emu_keyboard_1_en <= s_emu_keyboard_1_en;
--  o_emu_keyboard_2_en <= s_emu_keyboard_2_en;
--  o_emu_io_ports_en <= s_emu_io_ports_en;
--  o_emu_tape_fifo_en <= s_emu_tape_fifo_en;
--  o_emu_bram_en <= s_emu_bram_en;
--  o_shadow_emu_bram_en <= s_shadow_emu_bram_en;
--  o_z80_hl_de_alt_en <= s_z80_hl_de_alt_en;
--  o_z80_bc_af_alt_en <= s_z80_bc_af_alt_en;
--  o_z80_hl_de_en <= s_z80_hl_de_en;
--  o_z80_bc_af_en <= s_z80_bc_af_en;
--  o_z80_ix_iy_en <= s_z80_ix_iy_en;
--  o_z80_r_sp_iff_im_en <= s_z80_r_sp_iff_im_en;
  o_memtest_pass_cnt_en <= s_memtest_pass_cnt_en;
  o_memtest_fail_cnt_en <= s_memtest_pass_cnt_en;
  o_mmc_di_en <= s_mmc_di_en;
--  o_mmc_do_en <= s_mmc_do_en;
  o_ps2_kbd_do_en <= s_ps2_kbd_do_en;
  o_joystick_en <= s_joystick_en;

  
  -- Implement s_axi_awready generation
  -- s_axi_awready is asserted for one i_aclk_sys clock cycle when both
  -- i_axi_lite_awvalid and i_axi_lite_wvalid are asserted. s_axi_awready is
  -- de-asserted when reset is low.
  p_process1: process (i_aclk_sys)
  begin
    if rising_edge(i_aclk_sys) then 
      if i_resetn_sys = '0' then
        s_axi_awready <= '0';
      else
        if (s_axi_awready = '0' and i_axi_lite_awvalid = '1' and i_axi_lite_wvalid = '1') then
          -- slave is ready to accept write address when
          -- there is a valid write address and write data
          -- on the write address and data bus. This design 
          -- expects no outstanding transactions. 
          s_axi_awready <= '1';
        else
          s_axi_awready <= '0';
        end if;
      end if;
    end if;
  end process;

  -- Implement s_axi_awaddr latching
  -- This process is used to latch the address when both 
  -- i_axi_lite_awvalid and i_axi_lite_wvalid are valid. 
  p_process2: process (i_aclk_sys)
  begin
    if rising_edge(i_aclk_sys) then 
      if i_resetn_sys = '0' then
        s_axi_awaddr <= (others => '0');
      else
        if (s_axi_awready = '0' and i_axi_lite_awvalid = '1' and i_axi_lite_wvalid = '1') then
          -- Write Address latching
          s_axi_awaddr <= i_axi_lite_awaddr;
        end if;
      end if;
    end if;                   
  end process; 

  -- Implement axi_wready generation
  -- axi_wready is asserted for one i_aclk_sys clock cycle when both
  -- i_axi_lite_wvalid and i_axi_lite_awvalid are asserted. s_axi_wready is 
  -- de-asserted when reset is low. 
  p_process3: process (i_aclk_sys)
  begin
    if rising_edge(i_aclk_sys) then 
      if i_resetn_sys = '0' then
        s_axi_wready <= '0';
      else
        if (s_axi_wready = '0' and i_axi_lite_wvalid = '1' and i_axi_lite_awvalid = '1') then
          -- slave is ready to accept write data when 
          -- there is a valid write address and write data
          -- on the write address and data bus. This design 
          -- expects no outstanding transactions.           
          s_axi_wready <= '1';
        else
          s_axi_wready <= '0';
        end if;
      end if;
    end if;
  end process; 

  -- p_process4: Implement write response logic generation
  -- The write response and response valid signals are asserted by the slave
  -- when s_axi_wready, i_axi_lite_wvalid, s_axi_wready and i_axi_lite_awvalid are asserted.
  -- This marks the acceptance of address and indicates the status of
  -- write transaction.
  p_process4: process (i_aclk_sys)
  begin
    if rising_edge(i_aclk_sys) then
      if i_resetn_sys = '0' then
        s_axi_bvalid <= '0';
        s_axi_bresp <= "00";
      else
        if (s_axi_awready = '1' and i_axi_lite_awvalid = '1' and s_axi_wready = '1' and i_axi_lite_wvalid = '1' and s_axi_bvalid = '0') then
          s_axi_bvalid <= '1';
          s_axi_bresp  <= "00";
        elsif (i_axi_lite_bready = '1' and s_axi_bvalid = '1') then   --check if bready is asserted while bvalid is high)
          s_axi_bvalid <= '0';                                        -- (there is a possibility that bready is always asserted high)
        end if;
      end if;
    end if;
  end process;

  -- p_process5: Implement s_axi_arready generation
  -- s_axi_arready is asserted for one i_aclk_sys clock cycle when
  -- i_axi_lite_arvalid is asserted. s_axi_awready is
  -- de-asserted when reset (active low) is asserted.
  -- The read address is also latched when i_axi_arvalid is
  -- asserted. s_axi_araddr is reset to zero on reset assertion.
  p_process5: process (i_aclk_sys)
  begin
    if rising_edge(i_aclk_sys) then
      if i_resetn_sys = '0' then
        s_axi_arready <= '0';
        s_axi_araddr <= (others => '1');
      else
        if (s_axi_arready = '0' and i_axi_lite_arvalid = '1') then
          -- indicates that the slave has accepted the valid read address
          s_axi_arready <= '1';
          -- Read Address latching
          s_axi_araddr  <= i_axi_lite_araddr;
        else
          s_axi_arready <= '0';
        end if;
      end if;
    end if;
  end process;

  -- p_process6: Implement axi_arvalid generation
  -- s_axi_rvalid is asserted for one i_aclk_sys clock cycle when both
  -- i_axi_lite_arvalid and s_axi_arready are asserted. The slave registers
  -- data are available on the s_axi_rdata bus at this instance. The
  -- assertion of s_axi_rvalid marks the validity of read data on the
  -- bus and s_axi_rresp indicates the status of read transaction. s_axi_rvalid
  -- is deasserted on reset (active low). s_axi_rresp and s_axi_rdata are
  -- cleared to zero on reset (active low).
  --------------------------------------
  p_process6: process (i_aclk_sys)
  begin
    if rising_edge(i_aclk_sys) then
      if i_resetn_sys = '0' then
        s_axi_rvalid <= "000";
        s_axi_rresp  <= "00";
      else
        if (s_axi_arready = '1' and i_axi_lite_arvalid = '1' and s_axi_rvalid(2) = '0') then
          s_axi_rvalid <= "001";
        end if;
        if (s_axi_rvalid(0) = '1') then
          s_axi_rvalid <= "010";
        elsif (s_axi_rvalid(1) = '1') then
          -- Valid read data is available at the read data bus
          s_axi_rvalid <= "100";
          s_axi_rresp  <= "00"; -- 'OKAY' response
        elsif (s_axi_rvalid(2) = '1' and i_axi_lite_rready = '1') then
          -- Read data is accepted by the master
          s_axi_rvalid <= "000";
        end if;
      end if;
    end if;
  end process;

  s_slv_reg_wren <= s_axi_wready and i_axi_lite_wvalid and s_axi_awready and i_axi_lite_awvalid;
  s_slv_reg_rden <= s_axi_arready and i_axi_lite_arvalid and (not s_axi_rvalid(2)) ;
  s_rd_en <= s_slv_reg_rdrdy(0);
  -- p_process7: Implement memory mapped register enable
  -- Slave register write enable is asserted when valid address and data are available
  -- Slave register read enable is asserted when valid address is available
  p_process7: process (i_aclk_sys)
  variable v_loc_addr : std_logic_vector(c_opt_mem_addr_bits downto 0); 
  begin
    if rising_edge(i_aclk_sys) then 
      if i_resetn_sys = '0' then
--        s_border_color_en <= '0';
--        s_framebuf_addr_en <= '0';
--        s_status_en <= '0';
        s_control_en <= '0';
--        s_error_en <= '0';
--        s_irq_en <= '0';
--        s_mem_write_test_en <= '0';
        s_emu_control_en <= '0';
--        s_emu_keyboard_1_en <= '0';
--        s_emu_keyboard_2_en <= '0';
--        s_emu_io_ports_en <= '0';
--        s_emu_tape_fifo_en <= '0';
--        s_emu_bram_en <= '0';
--        s_shadow_emu_bram_en <= '0'; 

--        s_z80_hl_de_alt_en <= '0'; 
--        s_z80_bc_af_alt_en <= '0'; 
--        s_z80_hl_de_en <= '0'; 
--        s_z80_bc_af_en <= '0'; 
--        s_z80_ix_iy_en <= '0'; 
--        s_z80_r_sp_iff_im_en <= '0'; 
        s_memtest_pass_cnt_en <= '0';
        s_memtest_fail_cnt_en <= '0';
        s_mmc_di_en <= '0';
--        s_mmc_do_en <= '0';
        s_ps2_kbd_do_en <= '0';
        s_joystick_en <= '0';

      else
        if s_slv_reg_wren = '1' then
          v_loc_addr := s_axi_awaddr(c_addr_lsb + c_opt_mem_addr_bits downto c_addr_lsb);
        elsif s_slv_reg_rden = '1' then
          v_loc_addr := s_axi_araddr(c_addr_lsb + c_opt_mem_addr_bits downto c_addr_lsb);
        end if;

        if (s_slv_reg_wren = '1') or (s_slv_reg_rden = '1') then
          case v_loc_addr is
--            when c_border_color_reg =>
--              s_border_color_en <= '1';
--            when c_framebuf_addr_reg =>
--              s_framebuf_addr_en <= '1';
--            when c_status_reg =>
--              s_status_en <= '1';
            when c_control_reg =>
              s_control_en <= '1';
--            when c_error_reg =>
--              s_error_en <= '1';
--            when c_irq_reg =>
--              s_irq_en <= '1';
--            when c_mem_write_test_reg =>
--              s_mem_write_test_en <= '1';
            when c_emu_control_reg =>
              s_emu_control_en <= '1';
--            when c_emu_keyboard_1_reg =>
--              s_emu_keyboard_1_en <= '1';
--            when c_emu_keyboard_2_reg =>
--              s_emu_keyboard_2_en <= '1';
--            when c_emu_io_ports_reg =>
--              s_emu_io_ports_en <= '1';
--            when c_emu_tape_fifo_reg =>
--              s_emu_tape_fifo_en <= '1';
--            when c_emu_bram_reg =>
--              s_emu_bram_en <= '1';
--            when c_shadow_emu_bram_reg =>
--              s_shadow_emu_bram_en <= '1';
--            when c_z80_hl_de_alt_reg =>
--              s_z80_hl_de_alt_en <= '1'; 
--            when c_z80_bc_af_alt_reg =>
--              s_z80_bc_af_alt_en <= '1'; 
--            when c_z80_hl_de_reg =>
--              s_z80_hl_de_en <= '1'; 
--            when c_z80_bc_af_reg =>
--              s_z80_bc_af_en <= '1'; 
--            when c_z80_ix_iy_reg =>
--              s_z80_ix_iy_en <= '1'; 
--            when c_z80_r_sp_iff_im_reg =>
--              s_z80_r_sp_iff_im_en <= '1'; 
            when c_memtest_pass_cnt_reg =>
              s_memtest_pass_cnt_en <= '1'; 
           when c_memtest_fail_cnt_reg =>
              s_memtest_fail_cnt_en <= '1'; 
            when c_mmc_di_reg =>
              s_mmc_di_en <= '1'; 
--            when c_mmc_do_reg =>
--              s_mmc_do_en <= '1'; 
            when c_ps2_kbd_do_reg =>
              s_ps2_kbd_do_en <= '1';
            when c_joystick_reg =>
              s_joystick_en <= '1';

            when others =>
--              s_border_color_en <= '0';
--              s_framebuf_addr_en <= '0';
--              s_status_en <= '0';
              s_control_en <= '0';
--              s_error_en <= '0';
--              s_irq_en <= '0';
--              s_mem_write_test_en <= '0';
              s_emu_control_en <= '0';
--              s_emu_keyboard_1_en <= '0';
--              s_emu_keyboard_2_en <= '0';
--              s_emu_io_ports_en <= '0';
--              s_emu_tape_fifo_en <= '0';
--              s_emu_bram_en <= '0';
--              s_shadow_emu_bram_en <= '0';

--              s_z80_hl_de_alt_en <= '0'; 
--              s_z80_bc_af_alt_en <= '0'; 
--              s_z80_hl_de_en <= '0'; 
--              s_z80_bc_af_en <= '0'; 
--              s_z80_ix_iy_en <= '0'; 
--              s_z80_r_sp_iff_im_en <= '0'; 
              s_memtest_pass_cnt_en <= '0';
              s_memtest_fail_cnt_en <= '0';
              s_mmc_di_en <= '0';
--              s_mmc_do_en <= '0';
             s_ps2_kbd_do_en <= '0';
              s_joystick_en <= '0';
          end case;
        else
--          s_border_color_en <= '0';
--          s_framebuf_addr_en <= '0';
--          s_status_en <= '0';
          s_control_en <= '0';
--          s_error_en <= '0';
--          s_irq_en <= '0';
--          s_mem_write_test_en <= '0';
          s_emu_control_en <= '0';
--          s_emu_keyboard_1_en <= '0';
--          s_emu_keyboard_2_en <= '0';
--          s_emu_io_ports_en <= '0';
--          s_emu_tape_fifo_en <= '0';
--          s_emu_bram_en <= '0';
--          s_shadow_emu_bram_en <= '0';

--          s_z80_hl_de_alt_en <= '0'; 
--          s_z80_bc_af_alt_en <= '0'; 
--          s_z80_hl_de_en <= '0'; 
--          s_z80_bc_af_en <= '0'; 
--          s_z80_ix_iy_en <= '0'; 
--          s_z80_r_sp_iff_im_en <= '0'; 
          s_memtest_pass_cnt_en <= '0';
          s_memtest_fail_cnt_en <= '0';
          s_mmc_di_en <= '0';
--          s_mmc_do_en <= '0';
          s_ps2_kbd_do_en <= '0';
          s_joystick_en <= '0';
        end if;
      end if;
    end if;                   
  end process; 

  -- p_process8: Delay s_slv_reg_rden by one clock cycle
  p_process8: process(i_aclk_sys) is
  begin
    if rising_edge(i_aclk_sys) then
      if (i_resetn_sys = '0') then
        s_wr_en <= '0';
        s_slv_reg_rdrdy <= "00";
        s_slv_reg_rden_vec <= (others => '0');
      else
        s_wr_en <= s_slv_reg_wren;

        s_slv_reg_rden_vec <= s_slv_reg_rden_vec(1 downto 0) & s_slv_reg_rden;

        if s_slv_reg_rden = '1' then
          s_slv_reg_rdrdy <= "01";
        elsif s_slv_reg_rdrdy(0) = '1' then
          s_slv_reg_rdrdy <= "10";
        else
          s_slv_reg_rdrdy <= "00";
        end if;
      end if;
    end if;
  end process;

  -- p_process9: Register write data
  p_process9: process(i_aclk_sys) is
  begin
    if (rising_edge (i_aclk_sys)) then
      if (i_axi_lite_wvalid = '1' and i_axi_lite_awvalid = '1') then
          loop_1: for s_byte_index in 0 to (g_axi_lite_data_width/ 8 - 1) loop
            if ( i_axi_lite_wstrb(s_byte_index) = '1' ) then
              -- Respective byte enables are asserted as per write strobes
              s_register_data_out(s_byte_index * 8 + 7 downto s_byte_index * 8) <= i_axi_lite_wdata(s_byte_index * 8 + 7 downto s_byte_index * 8);
            end if;
          end loop;
        end if;
    end if;
  end process;

  -- p_process10: Register read data
  p_process10: process(i_aclk_sys) is
  variable v_loc_addr : std_logic_vector(c_opt_mem_addr_bits downto 0);
  begin
    if (rising_edge (i_aclk_sys)) then
      if (i_resetn_sys = '0') then
        s_axi_rdata  <= (others => '0');
      else
        if (s_slv_reg_rden_vec(2 downto 1) = "01") then
          -- When there is a valid read address (i_axi_arvalid) with
          -- acceptance of read address by the slave (s_axi_arready),
          -- output the read data
          -- Read address mux
          v_loc_addr := s_axi_araddr(c_addr_lsb + c_opt_mem_addr_bits downto c_addr_lsb);
            case v_loc_addr is
--              when c_border_color_reg =>
--                s_axi_rdata <= i_border_color;
--              when c_framebuf_addr_reg =>
--                s_axi_rdata <= i_framebuf_addr;
--              when c_status_reg =>
--                s_axi_rdata <= i_status;
              when c_control_reg =>
                s_axi_rdata <= i_control;
--              when c_error_reg =>
--                s_axi_rdata <= i_error;
--              when c_irq_reg =>
--                s_axi_rdata <= i_irq;
              when c_version_reg =>
                s_axi_rdata <= c_version;
              when c_emu_control_reg =>
                s_axi_rdata <= i_emu_control;
--              when c_emu_io_ports_reg =>
--                s_axi_rdata <= i_emu_io_ports;
--              when c_emu_tape_fifo_reg =>
--                s_axi_rdata <= i_emu_tape_fifo;
--              when c_emu_bram_reg =>
--                s_axi_rdata <= i_emu_bram;
--              when c_shadow_emu_bram_reg =>
--                s_axi_rdata <= i_shadow_emu_bram;
--              when c_z80_hl_de_alt_reg =>
--                s_axi_rdata <= i_z80_hl_de_alt; 
--              when c_z80_bc_af_alt_reg =>
--                s_axi_rdata <= i_z80_bc_af_alt; 
--              when c_z80_hl_de_reg =>
--                s_axi_rdata <= i_z80_hl_de; 
--              when c_z80_bc_af_reg =>
--                s_axi_rdata <= i_z80_bc_af; 
--              when c_z80_ix_iy_reg =>
--                s_axi_rdata <= i_z80_ix_iy; 
--              when c_z80_r_sp_iff_im_reg =>
--                s_axi_rdata <= i_z80_r_sp_iff_im; 
              when c_memtest_pass_cnt_reg =>
                s_axi_rdata <= i_memtest_pass_cnt; 
              when c_memtest_fail_cnt_reg =>
                s_axi_rdata <= i_memtest_fail_cnt; 
              when c_mmc_di_reg =>
                s_axi_rdata <= i_mmc_di; 
--              when c_mmc_do_reg =>
--                s_axi_rdata <= i_mmc_do; 
              when c_ps2_kbd_do_reg =>
                s_axi_rdata <= i_ps2_kbd_do;
              when c_joystick_reg =>
                s_axi_rdata <= i_joystick;

              when others => 
                s_axi_rdata <= (others => '0');
          end case;
        end if;
      end if;
    end if;
  end process;

end architecture;
