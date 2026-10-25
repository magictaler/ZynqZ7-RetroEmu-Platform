/*
 EMU-lator framework on Arty-Z7 (Zynq7020)
 =========================================
 This is the emulator initialisation logic

 Designed in Magictale Electronics.
 
 Copyright (c) 2022-2026 Dmitry Pakhomenko.
 dmitryp@magictale.com
 http://magictale.com
 SPDX-License-Identifier: CC0-1.0
*/

#include "emulator.h"

//#define MEM_TEST
//#define DEBUG_CONSOLE_INPUT
//#define INIT_USB_HOST

static uint8_t __attribute__((section (".emulated_ram"))) emu_ram[0x1FFFFFF];


void emu_cpu_start()
{
    static reg_EMU_cpu_control_Struct emu_cpu_control;
    emu_cpu_control.bits.cpu_halt_req = 0;
    emu_cpu_control.bits.cpu_trace_req = 0; // revisit this
    emu_control_reg_write(&emu_cpu_control);
}

uint32_t emu_main_thread(void)
{
    xil_printf("ARTY Z7 Retro platform framework v1.0\r\n");
    /* This is the main thread responsible for hardware initialisation 
       and emulation of some peripherals in software which real 
       returocumpeter didn't have or wasn't aware of. This includes SD card, 
       FAT16/32 file system, USB stack and tape recorder emulator.
    */
    static reg_EMU_cpu_control_Struct emu_cpu_control;
    emu_cpu_control.bits.cpu_reset = 1;
    emu_control_reg_write(&emu_cpu_control);
    for (uint32_t i = 0; i < 0x5F00000 + 0xFFFFFF; i++)
    {
        emu_ram[i] = 0x0;
    }
    Xil_DCacheFlushRange(emu_ram, sizeof(emu_ram));
    emu_framebuffer_clear();
    emu_cpu_start();
    emu_video_init();
    vTaskDelay(500);
    emu_screen_enabled_set(true);
    emu_cpu_control.bits.cpu_reset = 0;
    emu_control_reg_write(&emu_cpu_control);
    xil_printf("Init sequence\r\n");
    sdcard_spi_init();
    iic_init();
    retro_emu_hat_gpio_init();
    retro_emu_hat_rtcc_init();
    TickType_t last_tick = xTaskGetTickCount();
#ifdef INIT_USB_HOST
    tusb_init();
#endif
    while (true)
    {
#ifdef MEM_TEST
    	reg_Mem_Test_Pass_Cntr_Struct mem_test_pass;
    	reg_Mem_Test_Fail_Cntr_Struct mem_test_fail;
    	mem_test_pass_reg_read(&mem_test_pass);
    	mem_test_fail_reg_read(&mem_test_fail);
    	xil_printf("Mem test failures: %d, passes: %d\r\n", mem_test_fail.u32, mem_test_pass.u32);
    	vTaskDelay(1000);
#else
#ifdef INIT_USB_HOST
        tuh_task();
#endif
        TickType_t current_tick = xTaskGetTickCount();
        if ((current_tick - last_tick) > 5000)
        {
            last_tick = current_tick;
            retro_emu_hat_gpio_heartbeat();
        }
        emu_vdma_converter_bypass_set(false);
        emu_upscaler_enabled_set(true);
        uint8_t hid_scancode;
        if (read_std_in(&hid_scancode))
        {
            xil_printf("%x ", hid_scancode);
            bool is_make = true;
            hid_to_ps2_send(is_make ? hid_to_ps2_make[hid_scancode] : hid_to_ps2_break[hid_scancode], is_make);
            hid_to_joy1(hid_scancode, is_make);
            is_make = false;
            vTaskDelay(100);
            hid_to_ps2_send(is_make ? hid_to_ps2_make[hid_scancode] : hid_to_ps2_break[hid_scancode], is_make);
            hid_to_joy1(hid_scancode, is_make);
        }
#endif
    }
    return -1;
}

