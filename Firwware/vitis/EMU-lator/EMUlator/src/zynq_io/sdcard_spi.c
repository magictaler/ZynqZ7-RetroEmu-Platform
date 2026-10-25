/*
 Driver to communicate with SD card by means of GPIO bitbanging using SPI interface

 Designed in Magictale Electronics.

 Copyright (c) 2024 Dmitry Pakhomenko.
 dmitryp@magictale.com
 http://magictale.com
 SPDX-License-Identifier: CC0-1.0

*/

#include "sdcard_spi.h"
#include "gpio.h"

//#define SD_CARD_DEBUG

int32_t sdcard_spi_init(void)
{
    int32_t status;
    status = gpio_init();

    if (status == XST_SUCCESS)
    {
        status = gpio_pin_write(SD_CS, 1);
    }
    if (status == XST_SUCCESS)
    {
        status = gpio_pin_write(SD_MOSI, 0);
    }
    if (status == XST_SUCCESS)
    {
        status = gpio_pin_write(SD_CLK, 0);
    }
    if (status == XST_SUCCESS)
    {
        status = gpio_pin_write(SD_MISO, 1);
    }
    if (status == XST_SUCCESS)
    {
        status = gpio_pin_write(SD_CD, 0);
    }


    if (status == XST_SUCCESS)
    {
        status = gpio_pin_dir_set(SD_CS, true);
    }
    if (status == XST_SUCCESS)
    {
        status = gpio_pin_dir_set(SD_MISO, false);
    }
    if (status == XST_SUCCESS)
    {
        status = gpio_pin_dir_set(SD_MOSI, true);
    }
    if (status == XST_SUCCESS)
    {
        status = gpio_pin_dir_set(SD_CLK, true);
    }
    if (status == XST_SUCCESS)
    {
        status = gpio_pin_dir_set(SD_CD, false);
    }

    return status;
}

int32_t sdcard_spi_rd_wr(bool cs, uint8_t wvalue, uint8_t* rvalue)
{
    int32_t status;
    status = gpio_pin_write(SD_CS, cs == true);
#ifdef SD_CARD_DEBUG
    xil_printf("SD I/O: CS = %d, written 0x%x, reading: ", cs, wvalue);
#endif
    for (int32_t bit_num = 8; bit_num > 0; bit_num--)
    {
        uint8_t r_bit;
        uint8_t w_bit = wvalue >> (bit_num - 1) & 0x1;
        status = gpio_pin_write(SD_MOSI, w_bit);
        if (status != XST_SUCCESS) break;

        status = gpio_pin_write(SD_CLK, 1);
        if (status != XST_SUCCESS) break;

        status = gpio_pin_read(SD_MISO, &r_bit);
        if (status != XST_SUCCESS) break;

        status = gpio_pin_write(SD_CLK, 0);
        if (status != XST_SUCCESS) break;

        if (r_bit == 1)
        {
            *rvalue = *rvalue | (1 << (bit_num - 1));
        }
        else
        {
            *rvalue = *rvalue & ~(1 << (bit_num - 1));
        }
    }
    gpio_pin_write(SD_MOSI, 0);
    return status;
}

