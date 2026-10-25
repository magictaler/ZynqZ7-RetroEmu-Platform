# Constraints file for AX-7020 board from ALINX + RetroEMU addons from Magictale Electronics
# Engineer: Dmitry Pakhomenko,
# 28.12.2025

##--- HDMI output ---
set_property -dict {PACKAGE_PIN P19 IOSTANDARD TMDS_33} [get_ports TMDS_clk_n]
set_property -dict {PACKAGE_PIN N18 IOSTANDARD TMDS_33} [get_ports TMDS_clk_p]

set_property PACKAGE_PIN V20 [get_ports {TMDS_data_p[0]}]
set_property PACKAGE_PIN W20 [get_ports {TMDS_data_n[0]}]
set_property IOSTANDARD TMDS_33 [get_ports {TMDS_data_n[0]}]
set_property IOSTANDARD TMDS_33 [get_ports {TMDS_data_p[0]}]

set_property PACKAGE_PIN T20 [get_ports {TMDS_data_p[1]}]
set_property PACKAGE_PIN U20 [get_ports {TMDS_data_n[1]}]
set_property IOSTANDARD TMDS_33 [get_ports {TMDS_data_n[1]}]
set_property IOSTANDARD TMDS_33 [get_ports {TMDS_data_p[1]}]

set_property PACKAGE_PIN N20 [get_ports {TMDS_data_p[2]}]
set_property PACKAGE_PIN P20 [get_ports {TMDS_data_n[2]}]
set_property IOSTANDARD TMDS_33 [get_ports {TMDS_data_n[2]}]
set_property IOSTANDARD TMDS_33 [get_ports {TMDS_data_p[2]}]

set_property PACKAGE_PIN Y19 [get_ports {HDMI_HPD_tri_i[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {HDMI_HPD_tri_i[0]}]

set_property -dict {PACKAGE_PIN R16 IOSTANDARD LVCMOS33} [get_ports HDMI_DDC_scl_io]
set_property -dict {PACKAGE_PIN R18 IOSTANDARD LVCMOS33} [get_ports HDMI_DDC_sda_io]

# V16 HDMI_OUT_EN?

##---  MMC/SD Card SPI connector ---
# MISO 27 EX_IO2_13N E19
set_property -dict {PACKAGE_PIN E19 IOSTANDARD LVCMOS33} [get_ports MMC_MISO]
# MOSI 29 EX_IO2_14N G18
set_property -dict {PACKAGE_PIN G18 IOSTANDARD LVCMOS33} [get_ports MMC_MOSI]
# SS 28 EX_IO2_13P E18
set_property -dict {PACKAGE_PIN E18 IOSTANDARD LVCMOS33} [get_ports MMC_CS]
# SCLK 26 EX_IO2_12P D19
set_property -dict {PACKAGE_PIN D19 IOSTANDARD LVCMOS33} [get_ports MMC_CLK]

##---  LEDs ---
set_property -dict {PACKAGE_PIN M14 IOSTANDARD LVCMOS33} [get_ports LED0_RED]
set_property -dict {PACKAGE_PIN M15 IOSTANDARD LVCMOS33} [get_ports LED1_RED]

##---  SDRAM ---
#set_property -dict {PACKAGE_PIN ??? IOSTANDARD LVCMOS33} [get_ports MEM_CKE] pulled HIGH in hardware
# CLK 19 EX_IO1_9N U17
set_property -dict {PACKAGE_PIN U17 IOSTANDARD LVCMOS33} [get_ports SDRAM_CLK]
set_property PULLTYPE PULLUP [get_ports SDRAM_CLK]
# CS 32 EX_IO1_15P T11
set_property -dict {PACKAGE_PIN T11 IOSTANDARD LVCMOS33} [get_ports SDRAM_CS]
# RAS 29 EX_IO1_14N U12
set_property -dict {PACKAGE_PIN U12 IOSTANDARD LVCMOS33} [get_ports SDRAM_RAS]
# CAS 30 EX_IO1_14P T12
set_property -dict {PACKAGE_PIN T12 IOSTANDARD LVCMOS33} [get_ports SDRAM_CAS]
# WE 27 EX_IO1_13N W13
set_property -dict {PACKAGE_PIN W13 IOSTANDARD LVCMOS33} [get_ports SDRAM_WE]
#set_property -dict {PACKAGE_PIN ??? IOSTANDARD LVCMOS33} [get_ports SDRAM_UDQ] connected to A12 in hardware
#set_property -dict {PACKAGE_PIN ??? IOSTANDARD LVCMOS33} [get_ports SDRAM_LDQ] connected to A11 in hardware
# BA1 9 EX_IO2_4N H18
set_property -dict {PACKAGE_PIN H18 IOSTANDARD LVCMOS33} [get_ports {SDRAM_BA[1]}]
# BA0 7 EX_IO2_3N G20
set_property -dict {PACKAGE_PIN G20 IOSTANDARD LVCMOS33} [get_ports {SDRAM_BA[0]}]
#set_property -dict {PACKAGE_PIN ??? IOSTANDARD LVCMOS33} [get_ports SDRAM_DAT_EN]
# A0 34 EX_IO1_16P B19
set_property -dict {PACKAGE_PIN B19 IOSTANDARD LVCMOS33} [get_ports {SDRAM_A[0]}]
# A1 33 EX_IO1_16N A20
set_property -dict {PACKAGE_PIN A20 IOSTANDARD LVCMOS33} [get_ports {SDRAM_A[1]}]
# A2 36 EX_IO1_17P C20
set_property -dict {PACKAGE_PIN C20 IOSTANDARD LVCMOS33} [get_ports {SDRAM_A[2]}]
# A3 35 EX_IO1_17N B20
set_property -dict {PACKAGE_PIN B20 IOSTANDARD LVCMOS33} [get_ports {SDRAM_A[3]}]
# A4 28 EX_IO1_13P V12
set_property -dict {PACKAGE_PIN V12 IOSTANDARD LVCMOS33} [get_ports {SDRAM_A[4]}]
# A5 25 EX_IO1_12N V13
set_property -dict {PACKAGE_PIN V13 IOSTANDARD LVCMOS33} [get_ports {SDRAM_A[5]}]
# A6 26 EX_IO1_12P U13
set_property -dict {PACKAGE_PIN U13 IOSTANDARD LVCMOS33} [get_ports {SDRAM_A[6]}]
# A7 23 EX_IO1_11N T15
set_property -dict {PACKAGE_PIN T15 IOSTANDARD LVCMOS33} [get_ports {SDRAM_A[7]}]
# A8 24 EX_IO1_11P T14
set_property -dict {PACKAGE_PIN T14 IOSTANDARD LVCMOS33} [get_ports {SDRAM_A[8]}]
# A9 21 EX_IO1_10N V18
set_property -dict {PACKAGE_PIN V18 IOSTANDARD LVCMOS33} [get_ports {SDRAM_A[9]}]
# A10 31 EX_IO1_15N T10
set_property -dict {PACKAGE_PIN T10 IOSTANDARD LVCMOS33} [get_ports {SDRAM_A[10]}]
# A11 22 EX_IO1_10P V17
set_property -dict {PACKAGE_PIN V17 IOSTANDARD LVCMOS33} [get_ports {SDRAM_A[11]}]
# A12 20 EX_IO1_9P T16
set_property -dict {PACKAGE_PIN T16 IOSTANDARD LVCMOS33} [get_ports {SDRAM_A[12]}]
# DQ0 4 EX_IO1_1P W18
set_property -dict {PACKAGE_PIN W18 IOSTANDARD LVCMOS33} [get_ports {SDRAM_DQ[0]}]
# DQ1 3 EX_IO1_1N W19
set_property -dict {PACKAGE_PIN W19 IOSTANDARD LVCMOS33} [get_ports {SDRAM_DQ[1]}]
# DQ2 6 EX_IO1_2P P14
set_property -dict {PACKAGE_PIN P14 IOSTANDARD LVCMOS33} [get_ports {SDRAM_DQ[2]}]
# DQ3 5 EX_IO1_2N R14
set_property -dict {PACKAGE_PIN R14 IOSTANDARD LVCMOS33} [get_ports {SDRAM_DQ[3]}]
# DQ4 8 EX_IO1_3P Y16
set_property -dict {PACKAGE_PIN Y16 IOSTANDARD LVCMOS33} [get_ports {SDRAM_DQ[4]}]
# DQ5 7 EX_IO1_3N Y17
set_property -dict {PACKAGE_PIN Y17 IOSTANDARD LVCMOS33} [get_ports {SDRAM_DQ[5]}]
# DQ6 10 EX_IO1_4P V15
set_property -dict {PACKAGE_PIN V15 IOSTANDARD LVCMOS33} [get_ports {SDRAM_DQ[6]}]
# DQ7 9 EX_IO1_4N W15
set_property -dict {PACKAGE_PIN W15 IOSTANDARD LVCMOS33} [get_ports {SDRAM_DQ[7]}]
# DQ8 17 EX_IO1_8N P16
set_property -dict {PACKAGE_PIN P16 IOSTANDARD LVCMOS33} [get_ports {SDRAM_DQ[8]}]
# DQ9 18 EX_IO1_8P P15
set_property -dict {PACKAGE_PIN P15 IOSTANDARD LVCMOS33} [get_ports {SDRAM_DQ[9]}]
# DQ10 15 EX_IO1_7N U15
set_property -dict {PACKAGE_PIN U15 IOSTANDARD LVCMOS33} [get_ports {SDRAM_DQ[10]}]
# DQ11 16 EX_IO1_7P U14
set_property -dict {PACKAGE_PIN U14 IOSTANDARD LVCMOS33} [get_ports {SDRAM_DQ[11]}]
# DQ12 13 EX_IO1_6N P18
set_property -dict {PACKAGE_PIN P18 IOSTANDARD LVCMOS33} [get_ports {SDRAM_DQ[12]}]
# DQ13 14 EX_IO1_6P N17
set_property -dict {PACKAGE_PIN N17 IOSTANDARD LVCMOS33} [get_ports {SDRAM_DQ[13]}]
# DQ14 11 EX_IO1_5N Y14
set_property -dict {PACKAGE_PIN Y14 IOSTANDARD LVCMOS33} [get_ports {SDRAM_DQ[14]}]
# DQ15 12 EX_IO1_5P W14
set_property -dict {PACKAGE_PIN W14 IOSTANDARD LVCMOS33} [get_ports {SDRAM_DQ[15]}]

# DAC_DATA 36 EX_IO2_17P K14
set_property -dict {PACKAGE_PIN K14 IOSTANDARD LVCMOS33} [get_ports DAC_DATA]
# DAC_BCLK 34 EX_IO2_16P H15
set_property -dict {PACKAGE_PIN H15 IOSTANDARD LVCMOS33} [get_ports DAC_BCLK]
# DAC_LRCLK 35 EX_IO2_17N J14
set_property -dict {PACKAGE_PIN J14 IOSTANDARD LVCMOS33} [get_ports DAC_LRCLK]

# MOUSE_CLK 14 EX_IO2_6P M19
set_property -dict {PACKAGE_PIN M19 IOSTANDARD LVCMOS33} [get_ports MOUSE_CLK]
# MOUSE_DAT 12 EX_IO2_5P L19
set_property -dict {PACKAGE_PIN L19 IOSTANDARD LVCMOS33} [get_ports MOUSE_DAT]

# KBD_CLK 32 EX_IO2_15P H16
set_property -dict {PACKAGE_PIN H16 IOSTANDARD LVCMOS33} [get_ports KBD_CLK]
# KBD_DAT 30 EX_IO2_14P G17
set_property -dict {PACKAGE_PIN G17 IOSTANDARD LVCMOS33} [get_ports KBD_DAT]

##---  I2C ---
# SCL 13 EX_IO2_6N M20
set_property -dict {PACKAGE_PIN M20 IOSTANDARD LVCMOS33} [get_ports I2C_SCL]
# SDA 11 EX_IO2_5N L20
set_property -dict {PACKAGE_PIN L20 IOSTANDARD LVCMOS33} [get_ports I2C_SDA]


