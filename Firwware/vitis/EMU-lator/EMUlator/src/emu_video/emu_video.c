/*
 EMUlator Video high level API
 ===================================================

 This API allows for high level Emulator Video 
 initialisation and switching between video pages

 Designed in Magictale Electronics.
 
 Copyright (c) 2024 Dmitry Pakhomenko.
 dmitryp@magictale.com
 http://magictale.com
 SPDX-License-Identifier: CC0-1.0
*/

#include "emu_video.h"
#include "../zynq_video/display_ctrl/display_ctrl.h"
#include "../zynq_misc/timer_ps/timer_ps.h"
#include "../emu_io/emu_config.h"
#include "xil_cache.h"
#include "xil_printf.h"

#define SCU_TIMER_ID XPAR_SCUTIMER_DEVICE_ID
#define DYNCLK_BASEADDR XPAR_AXI_DYNCLK_0_BASEADDR
#define VID_VTC_IRPT_ID XPS_FPGA3_INT_ID
#define VID_GPIO_IRPT_ID XPS_FPGA4_INT_ID

// Display Driver structs
DisplayCtrl dispCtrl;

// Framebuffers for video data
static EmuFrameBufStruct emu_frameBufs[DISPLAY_NUM_FRAMES];
uint8_t *pFrames[DISPLAY_NUM_FRAMES]; // array of pointers to the frame buffers

static uint8_t __attribute__((section (".splashscreen_ram"))) splashscreen_ram[0x384000];


void emu_video_init()
{
    int Status;
    // Initialize an array of pointers to the 3 frame buffers
    for (uint8_t frame_index = 0; frame_index < DISPLAY_NUM_FRAMES; frame_index++)
    {
        pFrames[frame_index] = emu_frameBufs[frame_index].emu_spectrum_frameBuf;
    }
    emu_screen_enabled_set(false);
    emu_upscaler_enabled_set(true);
    // Initialize a timer used for a simple delay
    TimerInitialize(SCU_TIMER_ID);
    // Initialize the Display controller and start it
    Status = DisplayInitialize(&dispCtrl, DYNCLK_BASEADDR, pFrames);
    if (Status != XST_SUCCESS)
    {
        xil_printf("Display Ctrl initialization failed during initialization%d\r\n", Status);
        return;
    }
    Status = DisplayStart(&dispCtrl);
    if (Status != XST_SUCCESS)
    {
        xil_printf("Couldn't start display during initialization%d\r\n", Status);
        return;
    }
    return;
}


void emu_framebuffer_clear()
{
    // Splashscreen
    // First frame
    uint32_t* vram_data;
    uint32_t* splashscreen_src = (uint32_t*)&splashscreen_ram;
    vram_data = (uint32_t*)VIDEO_MEMORY_AREA_START;
    for (uint32_t i = 0; i <
        DISPLAY_HDMI_MAX_HRESOLUTION * DISPLAY_HDMI_MAX_VRESOLUTION;
        i++)
    {
        *vram_data = *splashscreen_src;
        vram_data++;
        splashscreen_src++;
    }
    // Second frame
    splashscreen_src = (uint32_t*)&splashscreen_ram;
    vram_data = (uint32_t*)(VIDEO_MEMORY_AREA_START +
        DISPLAY_HDMI_MAX_HRESOLUTION * DISPLAY_HDMI_MAX_VRESOLUTION * DISPLAY_HDMI_MAX_BYTES_PER_PIXEL);
    for (uint32_t i = 0; i <
        DISPLAY_HDMI_MAX_HRESOLUTION * DISPLAY_HDMI_MAX_VRESOLUTION;
        i++)
    {
        *vram_data = *splashscreen_src;
        vram_data++;
        splashscreen_src++;
    }
    Xil_DCacheFlushRange(VIDEO_MEMORY_AREA_START,
        DISPLAY_HDMI_MAX_HRESOLUTION * DISPLAY_HDMI_MAX_VRESOLUTION * DISPLAY_HDMI_MAX_BYTES_PER_PIXEL * DISPLAY_NUM_FRAMES);
}
 
bool emu_iterate_vmode()
{
    if (dispCtrl.vMode == &VMODE_1280x720)
    {
        DisplaySetMode(&dispCtrl, &VMODE_720x576);
    }
    else
    {
        DisplaySetMode(&dispCtrl, &VMODE_1280x720);
    }
    DisplayStart(&dispCtrl);
    vTaskDelay(200);
    emu_framebuffer_clear();
    return true;
}


bool emu_activate_shell_vpage(uint32_t page)
{
    int result = XST_FAILURE;
    if (page < DISPLAY_NUM_FRAMES)
    {
        result = DisplayChangeFrame(&dispCtrl, page);
    }
    return result == XST_SUCCESS;
}

uint8_t* emu_shell_vpage_address(uint32_t page)
{
    uint8_t* result = NULL;
    if (page < DISPLAY_NUM_FRAMES)
    {
        result = pFrames[page];
    }
    return result;
}
