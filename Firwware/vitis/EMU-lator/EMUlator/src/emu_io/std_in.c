/*
 Keyboard emulation through serial
 ===================================================

 These helper functions allow to emulate keyboard
 via serial console

 Designed in Magictale Electronics.

 Copyright (c) 2026 Dmitry Pakhomenko.
 dmitryp@magictale.com
 http://magictale.com
 SPDX-License-Identifier: CC0-1.0
 
*/

#include "std_in.h"
#include "../zynq_usb/tinyusb/class/hid/hid.h"
#include "xparameters.h"
#include "xuartps_hw.h"

#define ESCAPE_START 0x1B
#define ESCAPE_SECOND 0x5B

static uint8_t escape_seq = 0;
uint8_t const conv_table[128][2] =  { HID_ASCII_TO_KEYCODE };

uint8_t bcd_to_bin(uint8_t value)
{
  uint8_t hex = 10;
  hex *= (value & 0xF0) >> 4;
  hex += (value & 0x0F);
  return hex;
}

bool read_std_in(uint8_t* in_char)
{
    bool read = false;
    uint8_t received_byte;
    if (XUartPs_IsReceiveData(STDIN_BASEADDRESS))
    {
        received_byte = (uint8_t)XUartPs_ReadReg(STDIN_BASEADDRESS, XUARTPS_FIFO_OFFSET);
        if ((received_byte == ESCAPE_START) && (escape_seq == 0))
        {
            escape_seq = 1;
        }
        else if ((received_byte == ESCAPE_SECOND) && (escape_seq == 1))
        {
            escape_seq = 2;
        }
        else if (escape_seq == 2)
        {
            // escaped characters
            if (received_byte == 0x44)
            {
                *in_char = HID_KEY_ARROW_LEFT;
                read = true;
            }
            else if (received_byte == 0x43)
            {
                *in_char = HID_KEY_ARROW_RIGHT;
                read = true;
            }
            else if (received_byte == 0x41)
            {
                *in_char = HID_KEY_ARROW_UP;
                read = true;
            }
            else if (received_byte == 0x42)
            {
                *in_char = HID_KEY_ARROW_DOWN;
                read = true;
            }
            escape_seq = 0;
        }
        else
        {
            // regular characters
#ifdef DEBUG_CONSOLE_INPUT
            xil_printf("ASCII = 0x%x, ", received_byte);
#endif
            uint8_t hid_scancode = conv_table[received_byte][1]; // Ignoring the upper/lower case for now
            *in_char = hid_scancode;
#ifdef DEBUG_CONSOLE_INPUT
            xil_printf("HID = 0x%x\r\n", hid_scancode);
#endif
            read = true;
        }
    }
    return read;
}

