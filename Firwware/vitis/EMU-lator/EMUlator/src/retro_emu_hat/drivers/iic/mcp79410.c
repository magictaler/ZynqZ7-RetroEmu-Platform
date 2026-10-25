//! @file mcp79410.c
//! @brief Driver for mcp79410 I2C real time clock/calendar + SRAM + EEPROM.
//! @details Provides functionality to set/get clock/calendar

#include <xstatus.h>
#include "mcp79410.h"

static mcp79410_config_t rtcc_config;

uint8_t mcp79410_offset_set(uint8_t slaveaddr, uint8_t offset)
{
    return iic_write(slaveaddr, (uint8_t*)&offset, 1) == XST_SUCCESS;
}

uint8_t mcp79410_reg_set(uint8_t slaveaddr, uint8_t offset, uint8_t register_val)
{
    uint8_t write_buf[2];
    write_buf[0] = offset;
    write_buf[1] = register_val;
    return iic_write(slaveaddr, (uint8_t*)&write_buf, 2) == XST_SUCCESS;
}

uint8_t mcp79410_reg_get(uint8_t slaveaddr, uint8_t* register_val)
{
    return iic_read(slaveaddr, register_val, 1) == XST_SUCCESS;
}

uint8_t retro_emu_hat_rtcc_init()
{
    uint8_t res;
    rtcc_config.bits.sqwfs = 0;
    rtcc_config.bits.crstrim = 0;
    rtcc_config.bits.extosc = 1;
    rtcc_config.bits.alm0en = 0;
    rtcc_config.bits.alm1en = 0;
    rtcc_config.bits.sqwen = 0;
    rtcc_config.bits.out = 0;
    res = mcp79410_reg_set(I2C_RTC_MCP79410_REG_ADDRESS, I2C_RTC_MCP79410_RTCC_CTRL, rtcc_config.byte);
    if (res == true)
    {
/*        rtcc_seconds.bits.st = 1;
        rtcc_seconds.bits.secone = 0;
        rtcc_seconds.bits.secten = 0;

        res = mcp79410_reg_set(I2C_RTC_MCP79410_REG_ADDRESS, I2C_RTC_MCP79410_RTCC_SECONDS, rtcc_seconds.byte);

        if (res == true)
        {
            res = mcp79410_offset_set(I2C_RTC_MCP79410_REG_ADDRESS, I2C_RTC_MCP79410_RTCC_SECONDS);
            res = mcp79410_reg_get(I2C_RTC_MCP79410_REG_ADDRESS, &rtcc_seconds.byte);
       }*/
    }
    return res == XST_SUCCESS;
}

uint8_t retro_emu_hat_ram_read(uint8_t start, uint8_t len, uint8_t* p_buf)
{
    uint8_t res = false;
    if ((start >= I2C_RTC_MCP79410_RAM_START) && (len + start <= I2C_RTC_MCP79410_RAM_END))
    {
        res = mcp79410_offset_set(I2C_RTC_MCP79410_REG_ADDRESS, start);
        if (res == true)
        {
            res = iic_read(I2C_RTC_MCP79410_REG_ADDRESS, p_buf, len) == XST_SUCCESS;
        }
    }
    return res;
}

uint8_t retro_emu_hat_ram_write(uint8_t start, uint8_t len, uint8_t* p_buf)
{
    uint8_t res = false;
    uint8_t tx_buf[I2C_RTC_MCP79410_RAM_END - I2C_RTC_MCP79410_RAM_START + 2]; // Maximum RAM size + one byte for I2C offset
    if ((start >= I2C_RTC_MCP79410_RAM_START) && (len + start <= I2C_RTC_MCP79410_RAM_END))
    {
        tx_buf[0] = start;
        memcpy(&tx_buf[1], p_buf, len);
        res = iic_write(I2C_RTC_MCP79410_REG_ADDRESS, (uint8_t*)&tx_buf, len + 1) == XST_SUCCESS;
    }
    return res;
}


uint8_t retro_emu_hat_eeprom_read(uint8_t start, uint8_t len, uint8_t* p_buf)
{
    uint8_t res = false;
    if ((start >= I2C_RTC_MCP79410_EEPROM_START) && (len + start <= I2C_RTC_MCP79410_EEPROM_END))
    {
        if ((start / I2C_RTC_MCP79410_EEPROM_PAGE_SIZE) == ((start + len - 1) / I2C_RTC_MCP79410_EEPROM_PAGE_SIZE))
        {
            //Start only if we don't cross a page
            res = mcp79410_offset_set(I2C_RTC_MCP79410_EEPROM_ADDRESS, start);
            if (res == true)
            {
                res = iic_read(I2C_RTC_MCP79410_EEPROM_ADDRESS, p_buf, len) == XST_SUCCESS;
            }
        }
    }
    return res;
}

uint8_t retro_emu_hat_eeprom_write(uint8_t start, uint8_t len, uint8_t* p_buf)
{
    uint8_t res = false;
    if ((start >= I2C_RTC_MCP79410_EEPROM_START) && (len + start <= I2C_RTC_MCP79410_EEPROM_END))
    {
        if ((start / I2C_RTC_MCP79410_EEPROM_PAGE_SIZE) == ((start + len - 1) / I2C_RTC_MCP79410_EEPROM_PAGE_SIZE))
        {
            //Start only if we don't cross a page

            uint8_t tx_buf[I2C_RTC_MCP79410_EEPROM_PAGE_SIZE + 1]; // Maximum page size + one byte for I2C offset
                tx_buf[0] = start;
                memcpy(&tx_buf[1], p_buf, len);
                res = iic_write(I2C_RTC_MCP79410_EEPROM_ADDRESS, (uint8_t*)&tx_buf, len + 1) == XST_SUCCESS;
        }
    }
    return res;
}

uint8_t mcp79410_eeprom_ctrl_get(mcp79410_eeprom_blk_prot_ctrl_t* register_val)
{
    uint8_t res = false;
    res = mcp79410_offset_set(I2C_RTC_MCP79410_EEPROM_ADDRESS, I2C_RTC_MCP79410_EEPROM_BLK_PROT_CTRL);
    if (res == true)
    {
        res = mcp79410_reg_get(I2C_RTC_MCP79410_EEPROM_ADDRESS, &register_val->byte);
    }
    return res;
}

uint8_t mcp79410_eeprom_ctrl_set(mcp79410_eeprom_blk_prot_ctrl_t* register_val)
{
    uint8_t res = false;
    res = mcp79410_reg_set(I2C_RTC_MCP79410_EEPROM_ADDRESS, I2C_RTC_MCP79410_EEPROM_BLK_PROT_CTRL, register_val->byte);
    return res;
}

