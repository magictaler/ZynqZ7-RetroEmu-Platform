 *** RETRO EMU-lator Framework milestones ***

 1. 2023.11.25: Branched off Speccy2022 project;
 2. 2023.12.11: The restructured Vivado project with Spectrum-128 emulator successfully builds (but there is again digital noise when switching videomodes);
 3. 2023.12.30: New module 'resolution_detector' works properly in the simulator;
 4. 2023.12.31: New module 'framebuf_calc' works in the simulator. Double check and optimize the o_rgb_data_addr_start calculations;
 4. 2024.01.01: 'framebuf_calc' module optimised and o_rgb_data_addr_start calculations fixed;
 5. 2024.01.03: Blank frame from VDP is present but it is off centered and spilit into two halves;
 6. 2024.01.07: The full video controller (emulator + ARTY parts) can be simulated now. The frame is still not propertly centered. Strobe is forced to '1111', now the frame is shifted to the right;
 7. 2024.01.14: Reworking scandoubler2mem state machine is progress. Writing one frame seems to be correct but next frame gets stuck;
 8. 2024.01.22: Scandouble2mem rework is finished. The frame is properly centered on horizontal axis, a bit off-centered vertically (needs to be investigrated). Frames per second rate is properly 
    calculated now.No warnings when connected to a real HDMI monitor. The FIFO is neither overflowing or undeflowing;
 9. 2024.01.24: A problem in resolution detector fixed. The frame is perfectly centered;
10. 2024.02.25: Transfer, refactor and adjustment of the emsx_top.vhd top layer;
11. 2024.03.01: More of transfer, refactor and adjustment of the emsx_top.vhd top layer;
12. 2024.03.04: More of transfer, refactor and adjustment of the emsx_top.vhd top layer;
13. 2024.03.07: More of transfer, refactor and adjustment of the emsx_top.vhd top layer;
14. 2024.03.10: More of transfer, refactor and adjustment of the emsx_top.vhd top layer;
14. 2024.03.17: Transfer and refactor of the emsx_top.vhd top layer is done;
15. 2024.03.24: DDRAM has been connected to the MSX machine. The correctness is not fully verified as chipscoping is not working for some reasons. The screen is filled with red. 
    SD emulation is not done yet;
16. 2024.04.01: Top level simulation created. The CPU boots and executes IPLROM initial loader then tries to read from SD/MMC in simulation. No SD/MMC signals toggle when running on real hardware;
17. 2024.04.05: DDRAM access problem is fixed. The hardware generates SD/MMC signals, need to hook up the interface;
18. 2024.04.07: One more problem with DDRAM access is fixed. In simulation the CPU is never stuck in WAIT anymore but this is not the case on real hardware;
19. 2024.04.28: A fix in the MegaSD module to trigger by a rising edge instead of a level which doesn't cause an infinite wait for the CPU with slow RAM. SD card is successfully initialised but doesn't do 
    a proper read command. Tried 2 and 4GB SD cards with the same result. MMC card doesn't even initialise;
20. 2024.05.04: SD/MMC cards are properly prepared. The boot loader loads files from the card and asserts s_ff_ldbios_n indicating completion. MSX memory dump shows that data is randomly corrupted;
21. 2024.05.12: s_ff_ldbios_n and s_mmc_led_en signals are routed to the ARTY's LEDs. Memory dump shows that the copy of OCM-BIOS.dat starting from 0x600000 is binary identical and is not corrupted. The
    video subsystem has been revised and looks fine. Still nothing on the display after booting OCM-BIOS;
22. 2024.05.19: Found and resolved the problem with memory corruption caused by the emu2mem module. Still nothing on video after booting except red barckground color;
23. 2024.05.24: Instead of blue there was green connected twice. After fixing there is a blue border after booting BIOS. Audio chips are connected. Still blue border after booting;
24. 2024.05.26: VDP in controlled via AXI registers at the moment. Screen mode 7 activates more than one pixel by writing a single byte. Screen mode 6 doesn't show pixels or border;
25. 2024.05.27: Writing one byte activates a single pixel in screen mode 7. The addressing works properly when controlling VDP via AXI registers;
26. 2024.05.27: VDP control is back to Z80, the system boots into BIOS;
27. 2024.06.07: Experiments with two HP ports - parking for now in favor of external SDRAM addon;
28. 2024.06.10: Added SDRAM constraints, connected at the top level;
29. 2024.06.15: Added SDRAM tester logic;
30. 2024.06.16: Added an upscaler but the implementation fails with 'not enough flip-flops' error;
31. 2024.06.20: Reworked the upscaler so now Vivado can infer BRAM and there is no problem with flip-flop counts anymore. However, the screen is blank now;
32. 2024.06.24: Connected the avalon interface for the upscaler. No video, AXI interconnect seems to be non-functional;
33. 2024.06.30: Multiple changes across the artyZ7 video. The upscaled frame has the expected dimensions and propely projected into the emu2mem space, however, it is always black;
34. 2024.06.30: Random static red, green and blue horizontal stripes on the screen regardless of the chosen interpolation mode as output from the upscaler. RGB nibbles seemed to be swapped;
35. 2024.07.01: Avalon interface is on a dedicated HP port. Vertical green stripes when OHRES and IHRES are set to 1024 and barely recognisable upscaled picture when OHRES and IHRES are set to 2048;
36. 2024.07.20: First live experiment with external SDRAM module. While no smoke comes out the RAM test is dramatically failing, roughtly every third value reads incorrectly. The clock looks not ideal on
    oscilloscope - the amplitude is balery more than 1V due to the resistor in series on ARTY board, rising and falliing edges are slow so the signal looks like a sine wave. Also the clock needs phase
    adjusment (or deskewing) by the look of things;
37. 2024.07.21: SDRAM module v.1.1 is passing the memory test for the first time at lower frequency (40MHz) after 1.5 hours of running 0 failures and 0xC0F passed counts;
38. 2024.07.25: SDRAM module v.1.1 is passing the memory test at 85.9MHz after more than 1.5 hours of running 0 failures and 0x1BDF passed counts;
39. 2024.07.29: First attempt to remap MegaSD module to an SD card driven by SDIO controller via PS pins. Looks too difficult to do it through the PS driver, looking into GPIO bitbanging instead. 
    Currenly non-fuctional;
40. 2024.08.04: The logic to communicate with SD card in SPI mode via MIO GPIO works. There are still some issues between integration PS and PL, the BIOS is not booting at the moment;
41. 2024.08.16: SD card via GPIO pins sends and receives valid bytes during card init sequence but the emulator bootloader keeps sending it, not booting;
42. 2024.08.16: A bug in bitbanging logic on PS side is fixed, the emulator boots from SD card;
43. 2024.08.25: Implemented logic for PS/2 keyboard emulation on FPGA side, needs a mapper on ARM app;
44. 2024.08.29: HID to PS/2 mapping seems to work on ARM side for regular and extended scancodes, both presses and releases. Modifiers (shift, caps lock etc) and autorepeats are not handled yet;
45. 2024.08.30: USB keyboard is properly emulated as PS/2 but the emulator is extremely slow when handling the keys, likely due to the CPU being in waiting cycles, need to switch to the external SDRAM;
46. 2024.09.03: CPU memory is switched over to the low latency SDRAM. VDP still uses BRAM. The issue with slow keyboard handling is still present;
47. 2024.09.09: The keyboard is fully functional, can navigate in DOS and shell;
48. 2024.09.11: Connected digital audio to Zynq's aplifier over PWM. Tried to run Salamander for the first time, the game starts without issues;
49. 2024.09.18: Upscaler is partially fixed, the colors are in a mess and the picture is just a half in height, the sound quality is poor and the keyboard maxtrix is not scanned in games;
50. 2024.09.18: Upscaler is working but it has a combination of really misleading settings (R and B are swapped, scaler format is 32bpp mode instead of 24bpp). Needs to be re-visited;
-51. 2024.09.21: PS/2 mouse support is added, joystick 1 is emulated over the mouse, only mouse buttons are working in Salamander. Upscaler has metastability. Sound quality is still poor;
-52. 2024.09.28: Audio looks very poor on oscilloscope. Timing closure issues probably after merging two clocks. Upsaler still not fixed. An attempt to make audio work over HDMI is not successful for now.
    Changing tactics and starting working on a hardware solution - an ultimate sheild contaning SDRAM, MicroSD card, 2 x P2/2 ports, battery backed RTC + RAM + EEPROM, I2S stereo DAC converter;
53. 2024.11.17: Rolled back 51 and 52 changes. Modifications to integrate the RetroEmuHat, I2C and PS2 are not checked yet, SDRAM is passing 6 hour stability test but unstable in emulator, micro-SD is
    working, stereo audio DAC generates sound but the quality is also poor (the original IIR filter and DC blocker from the Mister project are bypassed as non-working at the moment);
54. 2024.11.18: IIR filter and DC blocker are switched on, the sound is still poor, the problem doesn't seem to be with any of output stages but rather with the sound generator itself;
55. 2024.11.19: Both SCC1 and SCC2 channels are disabled - the audio is clean and crisp. In principle, audio subsystem works just fine, something wrong with the SCC emulation;
56. 2024.11.21: Audio data from both SCC is 16-bit signed. After setting the negative samples to 0 both SCCs began sounding clean so the problem with audio is almost solved. Must be the audio DAC which 
    thinks that the data is unsigned;
57. 2024.11.23: I2C driver is added. PCA9536 can read 'uSD card detect' and can control the blue 'READY' LED. The I2C driver is on PS side at the moment. A USB keyboard doesn't work via USB-2-PS2 adapter,
    ordered natively supporting PS/2 keyboard and mouse on ebay, moving on to fixing remaining FW issues while waiting for delivery;
58. 2024.11.24: 'READY' LED in flashing in a 'heartbeat' pattern. Vdp_req is properly trimmed without need of a black magic and CDC, it lasts until vdr_ack is received (one emu clock cycle). The VDP
    artifacts on the screen are fixed (ram.vhd was broken since it began using BRAM, will be investigated later as the issue is fully fixed for now);
59. 2024.11.29: Experimental code to demonstrate that the I2S and audio DAC work properly and can generate clean sine wave represented as signed samples. It takes us back to the SCC1 and SSC2 emulation
    and poor quality of the PCM channel, the problem is somewhere there;
60. 2024.11.30: Numpad keys of a USB keyboard are mapped to joystik 1 port, Salamander is fully playable now. Received natively supporting PS/2 keyboard from ebay, the CRO doesn't show any activity on
    clock/data lines, seems to be dead upon arrival;
61. 2024.11.30: Added splashscreen with product and company info which is displayed during ARTY boot time, ready to make a video teaser;
62. 2025.01.15: Both PCM channels are back on again, the audio quality is good enough but there is a ugly trick with choping off the negative values going via I2S and the quility has room for improvement;
63. 2025.01.19: Resolder the clock generator on the hat, not there is a 32768 Hz clock visible with oscilloscope. Initial implementation of mcp79410 driver, no seconds ticking as of now. The PS/2 pinouts
    are mirrored, the board needs a rev 1.1;
65. 2025.01.20: The RTCC is properly counting seconds while clocked by external clock source. RTCC is de-risked and rev 1.1 PCB can proceed with only PS/2 footrint fix (and maybe optional electrolytic cap
    close to the SDRAM);
66. 2025.01.23: Found a symptom of the upscaler's metastability: o_divstart fires twice, the second time is while the division is still in progress when in 'faulty' state;
67. 2025.01.27: Re-factoring C code, adding RAM and EEPROM support to the RTCC driver;
68. 2025.01.31: The project has been migrated from Vivado 2017.3 to 2024.2;
69. 2025.02.04: Keyboard is also emulated through serial console so that an AI agent running on a PC can control gaming process via console and video capturing dongle (joystick is not emulated yet);
70. 2025.02.06: Joystick is also emulated through a terminal. More or less ready for connecting to PC and running an AI agent for deep reinforce learning;
71. 2025.04.11: Contraints for SDRAM outputs solved random problems with RAM errors. Both PS/2 ports electrically functional on rev.1.1 board. PS/2 keyboard
    also works fully independent from ARM cores, the mouse still needs an RTL handler;
72. 2025.12.28: Porting project to AX-7020;
73. 2026.01.03: SDRAM test is passing;
74. 2026.10.18: Works with AX-7020 retro EMU hat. Upscaler is switched off temporary. Mouse hasn't been checked yet;
75. 2026.10.19: New upscaler works without problems. Tested the Salamander game overnight, it survived the night without issues;
77. 2026.10.24: Vivado and Vitis projects cumulative cleanup;