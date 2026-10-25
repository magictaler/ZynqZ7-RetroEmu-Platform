# README #

A retro-emulation platform for Xilinx Zynq, filling the gap left by MiSTer-style projects 
desgined exclusively for Altera hardware.

Hardware: Arty Z7-20 or AX7020 with hardware add-on peripherals which include:
- HDMI video signal output either 16:9 or 4:3 aspect ratio;
- PS/2 port for keyboard/mouse (alternatively, USB host stack supports HID interface);
- Audio via PCM5102APWR (112dB 32 bit 384kHz PCM stereo DAC);
- SD and micro-SD slots for storing ROMs/BIOS files etc of the emulated cores;
- External 32MB low latency SDRAM clocked at 80MHz for a framebuffer and core memory for the emulated machine;
- Battery backed MCP79410T-I/SN (RTC with 1Kbit EEPROM and 64B SDRAM);

Firmware: 
- FreeRTOS based retrocomputer emulator (EMU-lator) framework as a HAL layer with video/audio pipeline;
- Integrated USB host stack with HID drivers;
- As an example, ported MSX2+ core from MiSTer at https://github.com/MiSTer-devel/MSX_MiSTer to demonstrate 
    the platform's capabilities. 


Designed by Magictale Electronics, Dmitry Pakhomenko
http://magictale.com


## Building hardware

### Blueprints for PCBAs

- Arty Z7-20 needs RetroEmuHat board only, required desins files are in Hardware/ArtyZ7-20
- AX7020 needs RetroEmuHat and SDRAM32MB, required desins files are in Hardware/AX7020

## Building firmware

### Prerequisites
- Vivado 2024.2 with Vitis Classic 2024.2 (and xsct)
- Python 3 (for the splash screen converter)


### 1. Programmable logic (Vivado)
From the `Firmware/vivado` directory:
        
    vivado -mode batch -source create_project_file.tcl   # create project from block design, wrapper, constraints
    vivado -mode batch -source create_sdk_files.tcl      # synthesis, P&R, bitstream + XSA for Vitis


### 2. Splash screen
From the `Firmware/python` directory:

    python bmp_conv.py   # produces splashscreen.bin


### 3. Software (Vitis)
From `Firmware/vitis/EMU-lator`:

    xsct create_vitis.tcl

Then the project can be opened with Vitis Classic 2024.2


### 4. Boot image
The build outputs `boot.bin` in the `build` folder. Copy it to a FAT-formatted SD card
and set the boot-mode jumpers to SD;

Install RetroEmuHat and SDRAM32MB hardware add-ons;

Prepare an MSX2+ SD card by OCM-SDCREATE v2.5 and insert it into the RetroEmuHat;

Connect PS/2 keyboard, mouse and HDMI cable;

Power on the board.


## Legal note
Users must supply their own BIOS/ROMs.
