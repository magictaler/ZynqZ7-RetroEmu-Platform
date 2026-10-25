/*
 Driver for Emu-lator on Zynq7020 registers
 ===================================================

 This API allows for configuring Emu-lator hardware
 
 The hardware in FPGA fabric is configurable through 
 a set of readable and writable registers
 
 Copyright (c) 2026 Dmitry Pakhomenko.
 dmitryp@magictale.com
 http://magictale.com
 SPDX-License-Identifier: CC0-1.0
 
*/

#include "registers.h"

#include <xparameters.h>
#include <xil_io.h>

static reg_EMU_Control_Struct control_reg_value;

//! @brief Loads a register at a specific offset
//! @param reg_offset is the offset from EMU_VIDEO_CTRL_BASE_ADDR
//! @return the result of reading the register
static uint32_t reg_read(uint32_t reg_offset);

//! @brief Writes to a register at a specific offset
//! @param reg_offset is the offset from EMU_VIDEO_CTRL_BASE_ADDR
//! @param value is a 32 bit register value to be written
static void reg_write(uint32_t reg_offset, uint32_t value);


void reg_write(uint32_t reg_offset, uint32_t value)
{
    Xil_Out32(EMU_VIDEO_CTRL_BASE_ADDR + reg_offset, value);
}

static uint32_t reg_read(uint32_t reg_offset)
{
    return Xil_In32(EMU_VIDEO_CTRL_BASE_ADDR + reg_offset);
}

void emu_control_reg_write(reg_EMU_Control_Struct* value)
{
    reg_write(EMU_VIDEO_CONTROL_REG_OFFSET, value->u32);
}

void emu_mem_write_reg_write(reg_EMU_mem_write_test_Struct* value)
{
    reg_write(EMU_MEM_WRITE_TEST_REG_OFFSET, value->u32);
}

void emu_cpu_reg_write(reg_EMU_cpu_control_Struct* value)
{
    reg_write(EMU_CONTROL_OFFSET, value->u32);
}

void emu_control_reg_read(reg_EMU_cpu_control_Struct* value)
{
    value->u32 = reg_read(EMU_CONTROL_OFFSET);
}

void emu_mem_write(uint32_t address, uint8_t value)
{
    reg_EMU_mem_write_test_Struct mem_write_test_reg;
    mem_write_test_reg.bits.address = address;
    mem_write_test_reg.bits.data = value;
    emu_mem_write_reg_write(&mem_write_test_reg);
}

void emu_vdma_start_address_set(uint32_t bitmap_address, uint8_t store_border)
{
    control_reg_value.bits.reg_update = 0;
    control_reg_value.bits.sw_enable = 1;
    emu_control_reg_write(&control_reg_value);
    control_reg_value.bits.reg_update = 1;
    emu_control_reg_write(&control_reg_value);
}

void emu_vdma_enable_set(uint8_t enabled)
{
    control_reg_value.bits.sw_enable = enabled;
    emu_control_reg_write(&control_reg_value);
}

void emu_vdma_aspect_16_9_set(uint8_t aspect_ratio_16_9)
{
    control_reg_value.bits.aspect_ratio_16_9 = aspect_ratio_16_9;
    emu_control_reg_write(&control_reg_value);
}

void emu_vdma_aspect_16_9_invert()
{
    control_reg_value.bits.aspect_ratio_16_9 = !control_reg_value.bits.aspect_ratio_16_9;
    emu_control_reg_write(&control_reg_value);
}

void emu_vdma_converter_bypass_set(uint8_t bypass)
{
    control_reg_value.bits.bypass_enable = bypass;
    emu_control_reg_write(&control_reg_value);
}

void emu_test_mode_set(uint8_t enabled)
{
    control_reg_value.bits.test_pattern_enable = enabled;
    emu_control_reg_write(&control_reg_value);
}

void emu_bram_reg_write(reg_EMU_BRAM_Struct* value)
{
    reg_write(EMU_BRAM_OFFSET, value->u32);
}

void emu_screen_enabled_set(uint8_t screen_enabled)
{
    control_reg_value.bits.emu_screen_enabled = screen_enabled;
    emu_control_reg_write(&control_reg_value);
}

void emu_upscaler_enabled_set(uint8_t upscaler_enabled)
{
    control_reg_value.bits.upscaler_enable = upscaler_enabled;
    emu_control_reg_write(&control_reg_value);
}

void mem_test_pass_reg_read(reg_Mem_Test_Pass_Cntr_Struct* value)
{
    value->u32 = reg_read(MEM_TEST_PASS_CNTR_OFFSET);
}

void mem_test_fail_reg_read(reg_Mem_Test_Fail_Cntr_Struct* value)
{
    value->u32 = reg_read(MEM_TEST_FAIL_CNTR_OFFSET);
}

void mem_mmc_di_reg_read(reg_MMC_DI_Struct* value)
{
   value->u32 = reg_read(MEM_MMC_DI_OFFSET);
}

void mem_mmc_do_reg_write(reg_MMC_DO_Struct* value)
{
    reg_write(MEM_MMC_DI_OFFSET, value->u32);
}

void ps2_kbd_write(reg_PS2_Kbd_Struct* value)
{
    reg_write(PS2_KBD_OFFSET, value->u32);
}

void joystick_write(reg_Joystick_Struct* value)
{
    reg_write(JOYSTICK_OFFSET, value->u32);
}

