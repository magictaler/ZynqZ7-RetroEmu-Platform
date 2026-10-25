# Constraints file for ARTY-Z7020 board from Digilent + RetroEMU addons from Magictale Electronics
# Engineer: Dmitry Pakhomenko, 
# 28.12.2025 

##--- HDMI output ---
set_property -dict {PACKAGE_PIN L17 IOSTANDARD TMDS_33} [get_ports TMDS_clk_n]
set_property -dict {PACKAGE_PIN L16 IOSTANDARD TMDS_33} [get_ports TMDS_clk_p]

set_property IOSTANDARD TMDS_33 [get_ports {TMDS_data_n[0]}]

set_property PACKAGE_PIN K17 [get_ports {TMDS_data_p[0]}]
set_property PACKAGE_PIN K18 [get_ports {TMDS_data_n[0]}]
set_property IOSTANDARD TMDS_33 [get_ports {TMDS_data_p[0]}]

set_property IOSTANDARD TMDS_33 [get_ports {TMDS_data_n[1]}]

set_property PACKAGE_PIN K19 [get_ports {TMDS_data_p[1]}]
set_property PACKAGE_PIN J19 [get_ports {TMDS_data_n[1]}]
set_property IOSTANDARD TMDS_33 [get_ports {TMDS_data_p[1]}]

set_property IOSTANDARD TMDS_33 [get_ports {TMDS_data_n[2]}]

set_property PACKAGE_PIN J18 [get_ports {TMDS_data_p[2]}]
set_property PACKAGE_PIN H18 [get_ports {TMDS_data_n[2]}]
set_property IOSTANDARD TMDS_33 [get_ports {TMDS_data_p[2]}]

set_property PACKAGE_PIN R19 [get_ports {HDMI_HPD_tri_i[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {HDMI_HPD_tri_i[0]}]

set_property -dict {PACKAGE_PIN M17 IOSTANDARD LVCMOS33} [get_ports HDMI_DDC_scl_io]
set_property -dict {PACKAGE_PIN M18 IOSTANDARD LVCMOS33} [get_ports HDMI_DDC_sda_io]

##--- Audio output ---
set_property PACKAGE_PIN R18 [get_ports AUD_PWM]
set_property IOSTANDARD LVCMOS33 [get_ports AUD_PWM]

##--- Audio enable ---
set_property PACKAGE_PIN T17 [get_ports AUD_SD]
set_property IOSTANDARD LVCMOS33 [get_ports AUD_SD]

##--- VGA output ---
## Pmod Header JA
## 1 JA1_P Y18
## 2 JA1_N Y19
## 3 JA2_P Y16
## 4 JA2_N Y17
## 7 JA3_P U18
## 8 JA3_N U19
## 9 JA4_P W18
## 10 JA4_N W19
set_property -dict {PACKAGE_PIN Y18 IOSTANDARD LVCMOS33} [get_ports {VGA_R[0]}]

set_property -dict {PACKAGE_PIN Y19 IOSTANDARD LVCMOS33} [get_ports {VGA_R[1]}]
set_property -dict {PACKAGE_PIN Y16 IOSTANDARD LVCMOS33} [get_ports {VGA_R[2]}]
set_property -dict {PACKAGE_PIN Y17 IOSTANDARD LVCMOS33} [get_ports {VGA_R[3]}]
set_property -dict {PACKAGE_PIN U18 IOSTANDARD LVCMOS33} [get_ports {VGA_B[0]}]
set_property -dict {PACKAGE_PIN U19 IOSTANDARD LVCMOS33} [get_ports {VGA_B[1]}]
set_property -dict {PACKAGE_PIN W18 IOSTANDARD LVCMOS33} [get_ports {VGA_B[2]}]
set_property -dict {PACKAGE_PIN W19 IOSTANDARD LVCMOS33} [get_ports {VGA_B[3]}]

## Pmod Header JB
## 1 JB1_P W14
## 2 JB1_N Y14
## 3 JB2_P T11
## 4 JB2_N T10
## 7 JB3_P V16
## 8 JB3_N W16
## 9 JB4_P V12
## 10 JB4_N W13
set_property -dict {PACKAGE_PIN W14 IOSTANDARD LVCMOS33} [get_ports {VGA_G[0]}]
set_property -dict {PACKAGE_PIN Y14 IOSTANDARD LVCMOS33} [get_ports {VGA_G[1]}]
set_property -dict {PACKAGE_PIN T11 IOSTANDARD LVCMOS33} [get_ports {VGA_G[2]}]
set_property -dict {PACKAGE_PIN T10 IOSTANDARD LVCMOS33} [get_ports {VGA_G[3]}]
set_property -dict {PACKAGE_PIN V16 IOSTANDARD LVCMOS33} [get_ports VGA_HS]
set_property -dict {PACKAGE_PIN W16 IOSTANDARD LVCMOS33} [get_ports VGA_VS]

##---  MMC/SD Card SPI connector ---
set_property -dict {PACKAGE_PIN W15 IOSTANDARD LVCMOS33} [get_ports MMC_MISO]
set_property -dict {PACKAGE_PIN T12 IOSTANDARD LVCMOS33} [get_ports MMC_MOSI]
set_property -dict {PACKAGE_PIN F16 IOSTANDARD LVCMOS33} [get_ports MMC_CS]
set_property -dict {PACKAGE_PIN H15 IOSTANDARD LVCMOS33} [get_ports MMC_CLK]

##---  LEDs ---
set_property -dict {PACKAGE_PIN R14 IOSTANDARD LVCMOS33} [get_ports LED0_RED]
set_property -dict {PACKAGE_PIN P14 IOSTANDARD LVCMOS33} [get_ports LED1_RED]

##---  SDRAM ---
#set_property -dict {PACKAGE_PIN ??? IOSTANDARD LVCMOS33} [get_ports MEM_CKE] pulled HIGH in hardware
# CK_IO32
set_property -dict {PACKAGE_PIN V8 IOSTANDARD LVCMOS33} [get_ports SDRAM_CLK]
set_property PULLTYPE PULLUP [get_ports SDRAM_CLK]
# CK_A7
set_property -dict {PACKAGE_PIN F20 IOSTANDARD LVCMOS33} [get_ports SDRAM_CS]
# CK_A6
set_property -dict {PACKAGE_PIN F19 IOSTANDARD LVCMOS33} [get_ports SDRAM_RAS]
# CK_IO1
set_property -dict {PACKAGE_PIN U12 IOSTANDARD LVCMOS33} [get_ports SDRAM_CAS]
# CK_IO28
set_property -dict {PACKAGE_PIN V6 IOSTANDARD LVCMOS33} [get_ports SDRAM_WE]
#set_property -dict {PACKAGE_PIN ??? IOSTANDARD LVCMOS33} [get_ports SDRAM_UDQ] connected to A12 in hardware
#set_property -dict {PACKAGE_PIN ??? IOSTANDARD LVCMOS33} [get_ports SDRAM_LDQ] connected to A11 in hardware
# CK_A9
set_property -dict {PACKAGE_PIN B20 IOSTANDARD LVCMOS33} [get_ports {SDRAM_BA[1]}]
# CK_A8
set_property -dict {PACKAGE_PIN C20 IOSTANDARD LVCMOS33} [get_ports {SDRAM_BA[0]}]
#set_property -dict {PACKAGE_PIN ??? IOSTANDARD LVCMOS33} [get_ports SDRAM_DAT_EN]
# CK_A10
set_property -dict {PACKAGE_PIN B19 IOSTANDARD LVCMOS33} [get_ports {SDRAM_A[0]}]
# CK_A11
set_property -dict {PACKAGE_PIN A20 IOSTANDARD LVCMOS33} [get_ports {SDRAM_A[1]}]
# CK_IO0
set_property -dict {PACKAGE_PIN T14 IOSTANDARD LVCMOS33} [get_ports {SDRAM_A[2]}]
# CK_IO26
set_property -dict {PACKAGE_PIN U5 IOSTANDARD LVCMOS33} [get_ports {SDRAM_A[3]}]
# CK_IO2
set_property -dict {PACKAGE_PIN U13 IOSTANDARD LVCMOS33} [get_ports {SDRAM_A[4]}]
# CK_IO29
set_property -dict {PACKAGE_PIN U7 IOSTANDARD LVCMOS33} [get_ports {SDRAM_A[5]}]
# CK_IO3
set_property -dict {PACKAGE_PIN V13 IOSTANDARD LVCMOS33} [get_ports {SDRAM_A[6]}]
# CK_IO30
set_property -dict {PACKAGE_PIN V7 IOSTANDARD LVCMOS33} [get_ports {SDRAM_A[7]}]
# CK_IO4
set_property -dict {PACKAGE_PIN V15 IOSTANDARD LVCMOS33} [get_ports {SDRAM_A[8]}]
# CK_IO31
set_property -dict {PACKAGE_PIN U8 IOSTANDARD LVCMOS33} [get_ports {SDRAM_A[9]}]
# CK_IO27
set_property -dict {PACKAGE_PIN V5 IOSTANDARD LVCMOS33} [get_ports {SDRAM_A[10]}]
# CK_IO5
set_property -dict {PACKAGE_PIN T15 IOSTANDARD LVCMOS33} [get_ports {SDRAM_A[11]}]
# CK_IO10
set_property -dict {PACKAGE_PIN T16 IOSTANDARD LVCMOS33} [get_ports {SDRAM_A[12]}]
# CK_IO41
set_property -dict {PACKAGE_PIN Y9 IOSTANDARD LVCMOS33} [get_ports {SDRAM_DQ[0]}]
# CK_IO40
set_property -dict {PACKAGE_PIN W9 IOSTANDARD LVCMOS33} [get_ports {SDRAM_DQ[1]}]
# CK_IO13
set_property -dict {PACKAGE_PIN N17 IOSTANDARD LVCMOS33} [get_ports {SDRAM_DQ[2]}]
# CK_IO39
set_property -dict {PACKAGE_PIN Y8 IOSTANDARD LVCMOS33} [get_ports {SDRAM_DQ[3]}]
# CK_IO12
set_property -dict {PACKAGE_PIN P18 IOSTANDARD LVCMOS33} [get_ports {SDRAM_DQ[4]}]
# CK_IO38
set_property -dict {PACKAGE_PIN W8 IOSTANDARD LVCMOS33} [get_ports {SDRAM_DQ[5]}]
# CK_IO11
set_property -dict {PACKAGE_PIN R17 IOSTANDARD LVCMOS33} [get_ports {SDRAM_DQ[6]}]
# CK_IO37
set_property -dict {PACKAGE_PIN Y7 IOSTANDARD LVCMOS33} [get_ports {SDRAM_DQ[7]}]
# CK_IO6
set_property -dict {PACKAGE_PIN R16 IOSTANDARD LVCMOS33} [get_ports {SDRAM_DQ[8]}]
# CK_IO36
set_property -dict {PACKAGE_PIN Y6 IOSTANDARD LVCMOS33} [get_ports {SDRAM_DQ[9]}]
# CK_IO33
set_property -dict {PACKAGE_PIN V10 IOSTANDARD LVCMOS33} [get_ports {SDRAM_DQ[10]}]
# CK_IO7
set_property -dict {PACKAGE_PIN U17 IOSTANDARD LVCMOS33} [get_ports {SDRAM_DQ[11]}]
# CK_IO34
set_property -dict {PACKAGE_PIN W10 IOSTANDARD LVCMOS33} [get_ports {SDRAM_DQ[12]}]
# CK_IO8
set_property -dict {PACKAGE_PIN V17 IOSTANDARD LVCMOS33} [get_ports {SDRAM_DQ[13]}]
# CK_IO35
set_property -dict {PACKAGE_PIN W6 IOSTANDARD LVCMOS33} [get_ports {SDRAM_DQ[14]}]
# CK_IO9
set_property -dict {PACKAGE_PIN V18 IOSTANDARD LVCMOS33} [get_ports {SDRAM_DQ[15]}]


# CK_IOA
set_property -dict {PACKAGE_PIN Y13 IOSTANDARD LVCMOS33} [get_ports DAC_DATA]
# CK_A5
set_property -dict {PACKAGE_PIN U10 IOSTANDARD LVCMOS33} [get_ports DAC_BCLK]
# CK_A4
set_property -dict {PACKAGE_PIN T5 IOSTANDARD LVCMOS33} [get_ports DAC_LRCLK]
# CK_A3
set_property -dict {PACKAGE_PIN V11 IOSTANDARD LVCMOS33} [get_ports MOUSE_CLK]
# CK_A2
set_property -dict {PACKAGE_PIN W11 IOSTANDARD LVCMOS33} [get_ports MOUSE_DAT]
# CK_A1
set_property -dict {PACKAGE_PIN Y12 IOSTANDARD LVCMOS33} [get_ports KBD_CLK]
# CK_A0
set_property -dict {PACKAGE_PIN Y11 IOSTANDARD LVCMOS33} [get_ports KBD_DAT]


##---  I2C ---
set_property -dict {PACKAGE_PIN P16 IOSTANDARD LVCMOS33} [get_ports I2C_SCL]
set_property -dict {PACKAGE_PIN P15 IOSTANDARD LVCMOS33} [get_ports I2C_SDA]
