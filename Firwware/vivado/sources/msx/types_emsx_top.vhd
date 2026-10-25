----------------------------------------------------------------------------------
-- Company: Magictale Electronics http://magictale.com
-- Engineer: Dmitry Pakhomenko
-- 
-- Create Date: 06.07.2023 8:45:00 AM
-- Design Name: zx main type definitions, constant definitions
-- Module Name: types_zx_main_top - RTL
-- Project Name: ZX Spectrum retro computer emulator on Arty Z7 board
-- Target Devices: Zynq 7020
-- Tool Versions: Vivado 2017.3
-- Description: zx main types and constants
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

package types_zx_main_top is

  constant c_speaker_bit : integer range 0 to 7 := 4;
  constant c_weight_audio_beeper : std_logic_vector(23 downto 0) := x"000055";
  constant c_weight_audio_tape : std_logic_vector(23 downto 0) := x"000020";
  -- Registers
  constant c_control_reg_cpu_reset_bit              : integer range 0 to 31 := 3;

  constant c_32b_msbit            : integer range 0 to 31 := 31;
  constant c_16b_msbit            : integer range 0 to 15 := 15;
  constant c_16b_lsbit            : integer range 0 to 15 := 0;
  constant c_8b_msbit             : integer range 0 to 7 := 7;
  constant c_8b_lsbit             : integer range 0 to 7 := 0;

  component T80pa
    generic(
      Mode      : integer := 0; -- 0 => Z80, 1 => Fast Z80, 2 => 8080, 3 => GB
      R800_MULU : integer := 1  -- 0 => no MULU, 1=> R800 MULU
      );
    port(
      RESET_n     : in  std_logic;
      R800_mode   : in  std_logic := '0';
      CLK         : in  std_logic;
      CEN_p       : in  std_logic := '1';
      CEN_n       : in  std_logic := '1';
      WAIT_n      : in  std_logic := '1';
      INT_n       : in  std_logic := '1';
      NMI_n       : in  std_logic := '1';
      BUSRQ_n     : in  std_logic := '1';
      M1_n        : out std_logic;
      MREQ_n      : out std_logic;
      IORQ_n      : out std_logic;
      RD_n        : out std_logic;
      WR_n        : out std_logic;
      RFSH_n      : out std_logic;
      HALT_n      : out std_logic;
      BUSAK_n     : out std_logic;
      OUT0        : in  std_logic := '0';  -- 0 => OUT(C),0, 1 => OUT(C),255
      A           : out std_logic_vector(15 downto 0);
      DI          : in  std_logic_vector(7 downto 0);
      DO          : out std_logic_vector(7 downto 0);
      REG         : out std_logic_vector(211 downto 0); -- IFF2, IFF1, IM, IY, HL', DE', BC', IX, HL, DE, BC, PC, SP, R, I, F', A', F, A
      DIRSet      : in  std_logic := '0';
      DIR         : in  std_logic_vector(211 downto 0) := (others => '0') -- IFF2, IFF1, IM, IY, HL', DE', BC', IX, HL, DE, BC, PC, SP, R, I, F', A', F, A
      );
  end component;

  component ram
    port (
      adr : in  std_logic_vector(7 downto 0);
      clk : in  std_logic;
      we : in  std_logic;
      dbo : in  std_logic_vector(7 downto 0);
      dbi : out std_logic_vector(7 downto 0)
    );
  end component;

  component iplrom
    port (
      clk : in std_logic;
      adr : in std_logic_vector(15 downto 0);
      dbi : out std_logic_vector(7 downto 0)
    );
  end component;

  component megasd
    port (
      clk21m : in std_logic;
      reset : in std_logic;
      clkena : in std_logic;
      req : in std_logic;
      ack : out std_logic;
      wrt : in std_logic;
      adr : in std_logic_vector(15 downto 0);
      dbi : out std_logic_vector(7 downto 0);
      dbo : in std_logic_vector(7 downto 0);

      ramreq : out std_logic;
      ramwrt : out std_logic;
      ramadr : out std_logic_vector(19 downto 0);
      ramdbi : in std_logic_vector(7 downto 0);
      ramdbo : out std_logic_vector(7 downto 0);

      mmcdbi : out std_logic_vector(7 downto 0);
      mmcena : out std_logic;
      mmcact : out std_logic;

      mmc_ck : out std_logic;
      mmc_cs : out std_logic;
      mmc_di : out std_logic;
      mmc_do : in std_logic;

      -- Interface to redirect dataflow to an SD/MMC card controlled by PS like it is in case of Xilinx Zynq/Ultrascale SOC
      mmc_ps_di : out std_logic_vector(8 downto 0);
      mmc_ps_di_stb : out std_logic;

      epc_ck : out std_logic;
      epc_cs : out std_logic;
      epc_oe : out std_logic;
      epc_di : out std_logic;
      epc_do : in std_logic
    );
  end component;

  component mapper
    port(
      clk21m : in std_logic;
      reset : in std_logic;
      clkena : in std_logic;
      req : in std_logic;
      ack : out std_logic;
      mem : in std_logic;
      wrt : in std_logic;
      adr : in std_logic_vector(15 downto 0);
      dbi : out std_logic_vector(7 downto 0);
      dbo : in std_logic_vector(7 downto 0);

      ramreq : out std_logic;
      ramwrt : out std_logic;
      ramadr : out std_logic_vector(21 downto 0);
      ramdbi : in std_logic_vector(7 downto 0);
      ramdbo : out std_logic_vector(7 downto 0)
    );
  end component;

  component eseps2
    port (
      clk21m : in std_logic;
      reset : in std_logic;
      clkena : in std_logic;

      Kmap : in std_logic;

      Paus : inout std_logic;
      Scro : inout std_logic;
      Reso : inout std_logic;

      Fkeys : out std_logic_vector(7 downto 0);

      ps2_key : in  std_logic_vector(10 downto 0);

      PpiPortC : in  std_logic_vector(7 downto 0);
      pKeyX : out std_logic_vector(7 downto 0)
      );
  end component;

  component keymap
    port (
      adr : in std_logic_vector(10 downto 0);
      clk : in std_logic;
      dbi : out std_logic_vector(7 downto 0)
    );
  end component;

  component rtc
    port(
      clk21m : in std_logic;
      reset : in std_logic;

      setup : in std_logic;
      rt : in std_logic_vector(64 downto 0);

      clkena : in std_logic;          -- 10Hz
      req : in std_logic;
      ack : out std_logic;
      wrt : in std_logic;
      adr : in std_logic_vector( 15 downto 0 );
      dbi : out std_logic_vector(  7 downto 0 );
      dbo : in std_logic_vector(  7 downto 0 )
   );
  end component;

  component kanji
    port(
      clk21m : in std_logic;
      reset : in std_logic;
      clkena : in std_logic;
      req : in std_logic;
      ack : out std_logic;
      wrt : in std_logic;
      adr : in std_logic_vector(15 downto 0);
      dbi : out std_logic_vector(7 downto 0);
      dbo : in std_logic_vector(7 downto 0);
      ramreq : out std_logic;
      ramadr : out std_logic_vector(17 downto  0);
      ramdbi : in std_logic_vector(7 downto  0);
      ramdbo : out std_logic_vector(7 downto  0)
    );
  end component;

  component vdp
    port (
      -- VDP CLOCK ... 21.477MHZ
      CLK21M : in std_logic;
      RESET : in std_logic;
      REQ : in std_logic;
      ACK : out std_logic;
      WRT : in std_logic;
      ADR : in std_logic_vector(15 downto 0);
      DBI : out std_logic_vector(7 downto 0);
      DBO : in std_logic_vector(7 downto 0);

      INT_N : out std_logic;

      PRAMOE_N : out std_logic;
      PRAMWE_N : out std_logic;
      PRAMADR : out std_logic_vector(16 downto 0);
      PRAMDBI : in std_logic_vector(15 downto 0);
      PRAMDBO : out std_logic_vector(7 downto 0);

      VDPSPEEDMODE : in std_logic;
      RATIOMODE : in std_logic_vector(2 downto 0);
      CENTERYJK_R25_N : in std_logic;

      -- VIDEO OUTPUT
      PVIDEOR : out std_logic_vector(5 downto 0);
      PVIDEOG : out std_logic_vector(5 downto 0);
      PVIDEOB : out std_logic_vector(5 downto 0);
      PVIDEODE : out std_logic;

      PVIDEOHS_N : out std_logic;
      PVIDEOVS_N : out std_logic;
      PVIDEOCS_N : out std_logic;

      PVIDEODHCLK : out std_logic;
      PVIDEODLCLK : out std_logic;

      -- DISPLAY RESOLUTION (0=15KHZ, 1=31KHZ)
      DISPRESO : in std_logic;

      NTSC_PAL_TYPE : in std_logic;
      FORCED_V_MODE : in std_logic;
      LEGACY_VGA : in std_logic
    );
  end component;

  component megaram
    port (
      clk21m : in std_logic;
      reset : in std_logic;
      clkena : in std_logic;
      req : in std_logic;
      ack : out std_logic;
      wrt : in std_logic;
      adr : in std_logic_vector(15 downto 0);
      dbi : out std_logic_vector( 7 downto 0);
      dbo : in std_logic_vector(7 downto 0);
      ramreq : out std_logic;
      ramwrt : out std_logic;
      ramadr : out std_logic_vector(20 downto 0);
      ramdbi : in std_logic_vector(7 downto 0);
      ramdbo : out std_logic_vector(7 downto 0);

      mapsel : in std_logic_vector(1 downto 0);  -- "-0":SCC+, "01":ASC8K, "11":ASC16K

      wavl : out std_logic_vector(14 downto 0);
      wavr : out std_logic_vector(14 downto 0)
    );
  end component;

  component scc_wave_mul
    port (
      a : in std_logic_vector(7 downto 0); 
      b : in std_logic_vector(3 downto 0);
      c : out std_logic_vector(11 downto 0)
    );
  end component;

  component scc_wave
    port(
      clk21m : in std_logic;
      reset : in std_logic;
      clkena : in std_logic;
      req : in std_logic;
      ack : out std_logic;
      wrt : in std_logic;
      adr : in std_logic_vector(7 downto 0);
      dbi : out std_logic_vector(7 downto 0);
      dbo : in std_logic_vector(7 downto 0);
      wave : out std_logic_vector(14 downto 0)
    );
  end component;

  component system_timer
    port(
      clk21m : in std_logic;
      reset : in std_logic;
      req : in std_logic;
      ack : out std_logic;
      adr : in std_logic_vector(15 downto 0);
      dbi : out std_logic_vector(7 downto 0);
      dbo : in std_logic_vector(7 downto 0)
    );
  end component;

  component tr_pcm 
    port(
      clk21m : in std_logic;
      reset : in std_logic;
      req : in std_logic;
      ack : out std_logic;
      wrt : in std_logic;
      adr : in std_logic;
      dbi : out std_logic_vector(7 downto 0);
      dbo : in std_logic_vector(7 downto 0);
      wave_in : in std_logic_vector(7 downto 0);
      wave_out : out std_logic_vector(7 downto 0)
    );
  end component;

  component eseopll
    port(
      clk21m : in std_logic;
      reset : in std_logic;
      clkena : in std_logic;
      enawait : in std_logic;
      req : in std_logic;
      ack : out std_logic;
      wrt : in std_logic;
      adr : in std_logic_vector(15 downto 0);
      dbo : in std_logic_vector(7 downto 0);
      wav : out std_logic_vector(13 downto 0)
   );
  end component;

  component psg
    port(
      clk21m : in std_logic;
      reset : in std_logic;
      clkena : in std_logic;
      req : in std_logic;
      ack : out std_logic;
      wrt : in std_logic;
      adr : in std_logic_vector(15 downto 0);
      dbi : out std_logic_vector(7 downto 0);
      dbo : in std_logic_vector(7 downto 0);

      joya : in std_logic_vector(5 downto 0);
      stra : out std_logic;
      joyb : in std_logic_vector(5 downto 0);
      strb : out std_logic;

      kana : out std_logic;
      cmtin : in std_logic;
      keymode : in std_logic;

      wave : out std_logic_vector(9 downto 0) -- fix caro
   );
  end component;

  component switched_io_ports
    port(
      clk21m : in std_logic;
      reset : in std_logic;
      req : in std_logic;
      ack : out std_logic;
      wrt : in std_logic;
      adr : in std_logic_vector(15 downto 0);
      dbi : out std_logic_vector(7 downto 0);
      dbo : in std_logic_vector(7 downto 0);
      -- 'REGS' group
      io40_n : inout std_logic_vector(7 downto 0); -- ID Manufacturers/Devices :   $08 (008), $D4 (212=1chipMSX), $FF (255=null)
      io41_id212_n : inout std_logic_vector(7 downto 0); -- $41 ID212 states :   Smart Commands
      io42_id212 : inout std_logic_vector(7 downto 0); -- $42 ID212 states :   Virtual DIP-SW states
      io43_id212 : inout std_logic_vector(7 downto 0); -- $43 ID212 states :   Lock Mask for port $42 functions, cmt and reset key
      io44_id212 : inout std_logic_vector(7 downto 0); -- $44 ID212 states :   Lights Mask have the green leds control when Lights Mode is enabled
      OpllVol : inout std_logic_vector(2 downto 0); -- OPLL Volume
      SccVol : inout std_logic_vector(2 downto 0); -- SCC-I Volume
      PsgVol : inout std_logic_vector(2 downto 0); -- PSG Volume
      MstrVol : inout std_logic_vector(2 downto 0); -- Master Volume
      CustomSpeed : inout std_logic_vector(3 downto 0); -- Counter limiter of CPU wait control
      tMegaSD : inout std_logic; -- Turbo on MegaSD access :   3.58MHz to 5.37MHz autoselection
      tPanaRedir : inout std_logic; -- tPana Redirection switch
      VdpSpeedMode : inout std_logic; -- VDP Speed Mode :   0=Normal, 1=Fast
      V9938_n : inout std_logic; -- V9938 Status :   0=V9938, 1=V9958
      Mapper_req : inout std_logic; -- Mapper req :   Warm or Cold Reset are necessary to complete the request
      Mapper_ack : out std_logic; -- Current Mapper state
      MegaSD_req : inout std_logic; -- MegaSD req :   Warm or Cold Reset are necessary to complete the request
      MegaSD_ack : out std_logic; -- Current MegaSD state
      io41_id008_n : inout std_logic; -- $41 ID008 BIT-0 state :   0=5.37MHz, 1=3.58MHz (write_n only)
      swioKmap : inout std_logic; -- Keyboard layout selector
      CmtScro : inout std_logic; -- CMT state
      swioCmt : inout std_logic; -- CMT enabler
      LightsMode : inout std_logic; -- Custom green led states
      Red_sta : inout std_logic; -- Custom red led state
      LastRst_sta : inout std_logic; -- Last reset state :   0=Cold Reset, 1=Warm Reset (MSX2+) / 1=Cold Reset, 0=Warm Reset (MSXtR)
      RstReq_sta : inout std_logic; -- Reset request state :   0=No, 1=Yes
      Blink_ena : inout std_logic; -- MegaSD blink led enabler
      pseudoStereo : inout std_logic; -- RCA-LEFT(red) = External Audio Card / RCA-RIGHT(white) = Internal Sounds
      extclk3m : inout std_logic; -- External Clock 3.58MHz :   0=No, 1=Yes
      ntsc_pal_type : inout std_logic; -- NTSC/PAL Type :   0=Forced, 1=Auto
      forced_v_mode : inout std_logic; -- Forced Video Mode :   0=60Hz, 1=50Hz
      right_inverse : inout std_logic; -- Right Inverse Audio :   0=Off (Normal Wave), 1=On (Inverse Wave)
      vram_slot_ids : inout std_logic_vector(7 downto 0); -- VRAM Slot IDs :   MSB(4bits)=0-15 for Page 1, LSB(4bits)=0-15 for Page 0
      DefKmap : inout std_logic; -- Default keyboard layout  :   0=JP, 1=Non-JP (as UK,FR,..)
      -- 'DIP-SW' group
      ff_dip_req : in std_logic_vector(7 downto 0); -- DIP-SW states/reqs
      ff_dip_ack : inout std_logic_vector(7 downto 0); -- DIP-SW acks
      -- 'KEYS' group
      SdPaus : in std_logic;
      Scro : in std_logic;
      ff_Scro : in std_logic;
      Reso : in std_logic;
      ff_Reso : in std_logic;
      FKeys : in std_logic_vector(7 downto 0);
      vFKeys : in std_logic_vector(7 downto 0);
      LevCtrl : out std_logic_vector(2 downto 0); -- Volume and high-speed level
      GreenLvEna : out std_logic;
      -- 'RESET' group
      swioRESET_n : inout std_logic; -- Reset Pulse
      warmRESET : inout std_logic; -- 0=Cold Reset, 1=Warm Reset
      WarmMSXlogo : inout std_logic; -- Show MSX logo with Warm Reset
      -- 'MACHINES' group
      ZemmixNeo : inout std_logic; -- Machine type :   0=1chipMSX, 1=Zemmix Neo
      -- 'IPL-ROM' group
      JIS2_ena : inout std_logic; -- JIS2 enabler :   0=JIS1 only (BIOS 384 kB), 1=JIS1+JIS2 (BIOS 512 kB)
      portF4_mode : inout std_logic; -- Port F4 mode :   0=F4 Device Inverted (MSX2+), 1=F4 Device Normal (MSXtR)
      ff_ldbios_n : in    std_logic; -- OCM-BIOS loading status
      -- 'SPECIAL' group
      RatioMode : inout std_logic_vector(2 downto 0); -- Pixel Ratio 1:1 for LED Display (default is 0) (range 0-7) (60Hz only)
      centerYJK_R25_n : inout std_logic; -- Centering YJK Modes/R25 Mask (0=centered, 1=shifted to the right)
      legacy_sel : inout std_logic; -- Legacy Output selector :   0=Assigned to VGA, 1=Assigned to VGA+
      Slot0_req : inout std_logic; -- Slot0 Primary Mode req :   Warm Reset is necessary to complete the request
      Slot0Mode : inout std_logic -- Current Slot0 state :   0=Primary, 1=Expanded
    );
  end component;


end;-- package types_zx_main_top;

