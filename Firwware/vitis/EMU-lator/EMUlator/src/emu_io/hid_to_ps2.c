/*
 HID to PS/2 scancode mapper 
 ===================================================

 This logic alows translation of HID into PS/2 
 keyboard scancodes

 Designed in Magictale Electronics.

 Poered in 2024 by Dmitry Pakhomenko.
 dmitryp@magictale.com
 http://magictale.com

 Constants derived from the HIDman opensource project
 
*/

#include "hid_to_ps2.h"
#include "registers.h"
#include "../zynq_usb/tinyusb/tusb.h"
#include <xparameters.h>
#include <xil_io.h>

static hid_keyboard_report_t prev_kbd_report;
static bool scan_code_toggle = true;

#define PS2_DEBUG

// HID callback
void tuh_hid_report_received_cb(uint8_t dev_addr, uint8_t instance, uint8_t const* report, uint16_t len)
{
    uint8_t const itf_protocol = tuh_hid_interface_protocol(dev_addr, instance);
    switch (itf_protocol)
    {
        case HID_ITF_PROTOCOL_KEYBOARD:
#ifdef PS2_DEBUG
            //xil_printf("HID receive boot keyboard report\r\n");
#endif
            hid_keyboard_process_report( (hid_keyboard_report_t const*) report );
        break;
    }
    // continue to request to receive report
    if (!tuh_hid_receive_report(dev_addr, instance))
    {
#ifdef PS2_DEBUG
        xil_printf("Error: cannot request to receive report\r\n");
#endif
    }
}

// HID callback
void tuh_hid_mount_cb(uint8_t dev_addr, uint8_t instance, uint8_t const* desc_report, uint16_t desc_len)
{
    // request to receive report
    // tuh_hid_report_received_cb() will be invoked when report is available
    if (!tuh_hid_receive_report(dev_addr, instance))
    {
#ifdef PS2_DEBUG
        xil_printf("Error: cannot request to receive report\r\n");
#endif
    }
}

bool hid_report_find(hid_keyboard_report_t const *report, uint8_t scancode)
{
    bool found = false;
    for (uint8_t i = 0; i < sizeof(report->keycode) / sizeof(uint8_t); i++)
    {
        if (report->keycode[i] == scancode)
        {
            found = true;
            break;
        }
    }
    return found;
}

void hid_to_joy1(const uint8_t hid_scancode, bool is_make)
{
    reg_Joystick_Struct joy_reg;
    joy_reg.u32 = 0;
    if (hid_scancode == 0x21)
    {
        if (is_make == true)
        {
            joy_reg.bits.joy1_left = 1;
        }
        else
        {
            joy_reg.bits.joy1_left = 0;
        }
    }
    else if (hid_scancode == 0x23)
    {
        if (is_make == true)
        {
            joy_reg.bits.joy1_right = 1;
        }
        else
        {
            joy_reg.bits.joy1_right = 0;
        }
    }
    else if (hid_scancode == 0x1F)
    {
        if (is_make == true)
        {
            joy_reg.bits.joy1_down = 1;
        }
        else
        {
            joy_reg.bits.joy1_right = 0;
        }
    }
    else if (hid_scancode == 0x25)
    {
        if (is_make == true)
        {
            joy_reg.bits.joy1_up = 1;
        }
        else
        {
            joy_reg.bits.joy1_up = 0;
        }
    }
    else if (hid_scancode == 0x22)
    {
        if (is_make == true)
        {
            joy_reg.bits.joy1_trigger_a = 1;
        }
        else
        {
            joy_reg.bits.joy1_trigger_a = 0;
        }
    }
    else if (hid_scancode == 0x27)
    {
        if (is_make == true)
        {
            joy_reg.bits.joy1_trigger_b = 1;
        }
        else
        {
            joy_reg.bits.joy1_trigger_b = 0;
        }
    }

    joystick_write(&joy_reg);
}

void hid_to_ps2_send(const uint8_t * ps2_scancodes, bool is_make)
{
    reg_PS2_Kbd_Struct ps_kbd_reg;
    uint8_t seq_len = *ps2_scancodes;
    bool valid_kbd_code = false;
    bool valid_joy_code = false;
    ps2_scancodes++; // Move to the first scan code
    // Skip all sequences longer than 3 bytes as the PL logic doesn't handle
    // multibyte scancodes by the look of things
    if (seq_len <= 3)
    {
        if (seq_len == 3)
        {
            if ((ps2_scancodes[0] == PS2_EXT_PREFIX) && (ps2_scancodes[1] == PS2_BREAK_PREFIX))
            {
                // This is an extended break scancode
                ps_kbd_reg.bits.extended = 1;
                ps2_scancodes += 2;
                valid_kbd_code = true;
            }
        }
        else if (seq_len == 2)
        {
            if (ps2_scancodes[0] == PS2_EXT_PREFIX)
            {
                // This is an extended make scancode
                ps_kbd_reg.bits.extended = 1;
                valid_kbd_code = true;
            }
            else if (ps2_scancodes[0] == PS2_BREAK_PREFIX)
            {
                // This is an ordinary break scancode
                ps_kbd_reg.bits.extended = 0;
                valid_kbd_code = true;
                // Extra handler for joystick emulation (numpad keys are treated like joystick)
                if ((ps2_scancodes[1] >= 0x69) && (ps2_scancodes[1] <= 0x7D))
                {
                    // Numpad key break
                    valid_joy_code = true;
                }
            }
            ps2_scancodes++;
        }
        else
        {
            // This is an ordinary make scancode
            ps_kbd_reg.bits.extended = 0;
            valid_kbd_code = true;
            // Extra handler for joystick emulation (numpad keys are treated like joystick)
            if ((ps2_scancodes[0] >= 0x69) && (ps2_scancodes[1] <= 0x7D))
            {
                // Numpad key make
                valid_joy_code = true;
            }
        }
        if (valid_kbd_code == true)
        {
            is_make ? (ps_kbd_reg.bits.pressed = 1) : (ps_kbd_reg.bits.pressed = 0);
            scan_code_toggle ? (ps_kbd_reg.bits.toggle = 1) : (ps_kbd_reg.bits.toggle = 0);
            ps_kbd_reg.bits.scancode = *ps2_scancodes;
#ifdef PS2_DEBUG
            xil_printf("Map to PS/2: scancode = 0x%x, toggle = %d, extended = %d, pressed = %d\r\n",
                ps_kbd_reg.bits.scancode, ps_kbd_reg.bits.toggle, ps_kbd_reg.bits.extended, ps_kbd_reg.bits.pressed);
#endif
            ps2_kbd_write(&ps_kbd_reg);
            scan_code_toggle = !scan_code_toggle;
        }
        if (valid_joy_code == true)
        {
            reg_Joystick_Struct joy_reg;
            joy_reg.u32 = 0;

            // Numpad keys emulate joystick 1
            if (is_make)
            {
                if ((*ps2_scancodes == KEY_PAD4_MAKE[1]) || (*ps2_scancodes == KEY_4_MAKE[1]))
                {
                    joy_reg.bits.joy1_left = 1;
                }
                else if ((*ps2_scancodes == KEY_PAD6_MAKE[1]) || (*ps2_scancodes == KEY_6_MAKE[1]))
                {
                    joy_reg.bits.joy1_right = 1;
                }
                else if ((*ps2_scancodes == KEY_PAD8_MAKE[1]) || (*ps2_scancodes == KEY_8_MAKE[1]))
                {
                    joy_reg.bits.joy1_up = 1;
                }
                else if ((*ps2_scancodes == KEY_PAD2_MAKE[1]) || (*ps2_scancodes == KEY_2_MAKE[1]))
                {
                    joy_reg.bits.joy1_down = 1;
                }
                else if ((*ps2_scancodes == KEY_PAD5_MAKE[1]) || (*ps2_scancodes == KEY_5_MAKE[1]))
                {
                    joy_reg.bits.joy1_trigger_a = 1;
                }
                else if ((*ps2_scancodes == KEY_PAD0_MAKE[1]) || (*ps2_scancodes == KEY_0_MAKE[1]))
                {
                    joy_reg.bits.joy1_trigger_b = 1;
                }
            }
            else
            {
                if ((*ps2_scancodes == KEY_PAD4_BREAK[2]) || (*ps2_scancodes == KEY_4_BREAK[2]))
                {
                    joy_reg.bits.joy1_left = 0;
                }
                else if ((*ps2_scancodes == KEY_PAD6_BREAK[2]) || (*ps2_scancodes == KEY_6_BREAK[2]))
                {
                    joy_reg.bits.joy1_right = 0;
                }
                else if ((*ps2_scancodes == KEY_PAD8_BREAK[2]) || (*ps2_scancodes == KEY_8_BREAK[2]))
                {
                    joy_reg.bits.joy1_up = 0;
                }
                else if ((*ps2_scancodes == KEY_PAD2_BREAK[2]) || (*ps2_scancodes == KEY_2_BREAK[2]))
                {
                    joy_reg.bits.joy1_down = 0;
                }
                else if ((*ps2_scancodes == KEY_PAD5_BREAK[2]) || (*ps2_scancodes == KEY_6_BREAK[2]))
                {
                    joy_reg.bits.joy1_trigger_a = 0;
                }
                else if ((*ps2_scancodes == KEY_PAD0_BREAK[2]) || (*ps2_scancodes == KEY_0_BREAK[2]))
                {
                    joy_reg.bits.joy1_trigger_b = 0;
                }
            }

            joystick_write(&joy_reg);    
        }
    }
}

void hid_to_ps2_map(const uint8_t hid_scancode, bool is_make, hid_keyboard_report_t const *paired_report)
{
    if ((hid_scancode) && (hid_report_find(paired_report, hid_scancode) == false))
    {
        if (hid_scancode <= HID_KEY_KEYPAD_EQUAL)
        {
            hid_to_ps2_send(is_make ? hid_to_ps2_make[hid_scancode] : hid_to_ps2_break[hid_scancode], is_make);
        }
        else if (hid_scancode > HID_KEY_CONTROL_LEFT && hid_scancode <= HID_KEY_GUI_RIGHT)
        {
            hid_to_ps2_send(is_make ? mod_to_ps2_make[hid_scancode - HID_KEY_CONTROL_LEFT] :
                mod_to_ps2_break[hid_scancode - HID_KEY_CONTROL_LEFT], is_make);
        }
    }
}


void hid_handle_modifiers(uint8_t cur_modif, uint8_t prev_modif)
{
    for (uint8_t i = 0; i < 8; i++)
    {
        uint8_t cur_flag = (cur_modif >> i) & 0x1;
        uint8_t prev_flag = (prev_modif >> i) & 0x1;
        if (cur_flag == 1 && prev_flag == 0)
        {
            // Make event
            hid_to_ps2_send(mod_to_ps2_make[i], true);
        }
        else if (cur_flag == 0 && prev_flag == 1)
        {
            // Break event
            hid_to_ps2_send(mod_to_ps2_break[i], false);
        }
    }
}

void hid_keyboard_process_report(hid_keyboard_report_t const *report)
{
    // Handle modifiers separately
    hid_handle_modifiers(report->modifier, prev_kbd_report.modifier);
    // Generate PS/2 make events
    for (uint8_t i = 0; i < sizeof(report->keycode) / sizeof(uint8_t); i++)
    {
        hid_to_ps2_map(report->keycode[i], true, &prev_kbd_report);
    }
    // Generate PS/2 break events
    for (uint8_t i = 0; i < sizeof(prev_kbd_report.keycode) / sizeof(uint8_t); i++)
    {
        hid_to_ps2_map(prev_kbd_report.keycode[i], false, report);
    }
    memcpy(&prev_kbd_report, report, sizeof(hid_keyboard_report_t));
}


