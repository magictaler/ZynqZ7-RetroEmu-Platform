/*
 GPIO wrapper implementation

 Designed in Magictale Electronics.

 Copyright (c) 2024 Dmitry Pakhomenko.
 dmitryp@magictale.com
 http://magictale.com
 SPDX-License-Identifier: CC0-1.0

*/

#include "gpio.h"
#include <xscugic.h>

XGpioPs_Config* p_xgpiops_config;
XGpioPs xgpio_ps;

int32_t gpio_init()
{
    int32_t status = XST_SUCCESS;
    p_xgpiops_config = XGpioPs_LookupConfig(XGPIO_PS_IF0);
    if (p_xgpiops_config != NULL)
    {
        status = XGpioPs_CfgInitialize(&xgpio_ps, p_xgpiops_config, p_xgpiops_config->BaseAddr);
        if (status == XST_SUCCESS)
        {
            status = XGpioPs_SelfTest(&xgpio_ps);
        }
    }
    else
    {
        status = XST_FAILURE;
    }
    return status;
}


int32_t gpio_pin_read(uint8_t pin_num, uint8_t* value)
{
    uint32_t pin_value;
    int32_t status = XST_SUCCESS;
    if (xgpio_ps.IsReady)
    {
        pin_value = XGpioPs_ReadPin(&xgpio_ps, pin_num);
        *value = pin_value;
    }
    else
    {
        status = XST_FAILURE;
    }
    return status;
}

int32_t gpio_pin_dir_set(uint8_t pin_num, bool is_output)
{
    int32_t status = XST_SUCCESS;
    if (xgpio_ps.IsReady)
    {
        if (is_output == true)
        {
            XGpioPs_SetDirectionPin(&xgpio_ps, pin_num, 1);
        }
        else
        {
            XGpioPs_SetDirectionPin(&xgpio_ps, pin_num, 0);
        }
        XGpioPs_SetOutputEnablePin(&xgpio_ps, pin_num, 1);
    }
    else
    {
        status = XST_FAILURE;
    }
    return status;
}

int32_t gpio_pin_write(uint8_t pin_num, uint8_t pin_value)
{
    int32_t status = XST_SUCCESS;
    if (xgpio_ps.IsReady)
    {
        XGpioPs_WritePin(&xgpio_ps, pin_num, pin_value);
    }
    else
    {
        status = XST_FAILURE;
    }
    return status;
}

