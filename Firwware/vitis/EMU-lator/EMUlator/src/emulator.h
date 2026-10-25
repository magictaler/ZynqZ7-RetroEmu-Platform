/*
 EMU-lator framework on Arty-Z7/AX7020 (Zynq7020)
 =========================================

 This is the emulator initialisation logic


 Designed in Magictale Electronics.
 
 Copyright (c) 2024 Dmitry Pakhomenko.
 dmitryp@magictale.com
 http://magictale.com
 SPDX-License-Identifier: CC0-1.0
*/


#ifndef EMULATOR_H
#define EMULATOR_H

#include <FreeRTOS.h>
#include <task.h>
#include <xil_printf.h>
#include <xil_mmu.h>
#include <lwip/sys.h>
#include "xuartps.h"
#include "xil_cache.h"
#include "xil_types.h"
#include "xparameters.h"
#include "xil_io.h"
#include "zynq_video/display_ctrl/display_ctrl.h"
#include "zynq_misc/timer_ps/timer_ps.h"
#include "emu_io/registers.h"
#include "emu_video/emu_video.h"
#include "emu_io/emu_config.h"
#include "emu_io/hid_to_ps2.h"
#include "zynq_usb/tinyusb/tusb.h"
#include "zynq_usb/tinyusb/host/usbh.h"
#include "zynq_io/gpio.h"
#include "zynq_io/sdcard_spi.h"
#include "emu_io/hid_to_ps2.h"
#include "retro_emu_hat/drivers/iic/pca9536.h"
#include "retro_emu_hat/drivers/iic/mcp79410.h"
#include "emu_io/std_in.h"

#define DEFAULT_THREAD_PRIO 2
#define ZYNQ_MARK_UNCACHEABLE 0x14de2U
#define DEMO_TIMEOUT_DEFAULT_US (5000000U)

static const uint32_t THREAD_STACKSIZE = 4096;

uint32_t emu_main_thread(void);


#endif /* EMULATOR_H */
