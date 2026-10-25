//! @file mcp79410.h
//! @brief Driver for mcp79410 I2C real time clock/calendar + SRAM + EEPROM.
//! @details Provides functionality to set/get clock/calendar

#ifndef MCP79410_H_
#define MCP79410_H_

#include <stdint.h>
#include <stdbool.h>
#include "../../../zynq_io/iic.h"

#define I2C_RTC_MCP79410_REG_ADDRESS 0x6F
#define I2C_RTC_MCP79410_EEPROM_ADDRESS 0x57

#define I2C_RTC_MCP79410_RTCC_CTRL 0x7
#define I2C_RTC_MCP79410_RTCC_SECONDS 0x0
#define I2C_RTC_MCP79410_RAM_START 0x20
#define I2C_RTC_MCP79410_RAM_END 0x5F
#define I2C_RTC_MCP79410_EEPROM_START 0x0
#define I2C_RTC_MCP79410_EEPROM_END 0x7F
#define I2C_RTC_MCP79410_PROTECTED_EEPROM_START 0xF0
#define I2C_RTC_MCP79410_PROTECTED_EEPROM_END 0xF7
#define I2C_RTC_MCP79410_EEPROM_PAGE_SIZE 0x8
#define I2C_RTC_MCP79410_EEPROM_BLK_PROT_CTRL 0xFF

// MCP79410 control port
typedef union
{
    uint8_t byte;
    struct
    {
        uint8_t sqwfs: 2;
        uint8_t crstrim: 1;
        uint8_t extosc: 1;
        uint8_t alm0en: 1;
        uint8_t alm1en: 1;
        uint8_t sqwen: 1;
        uint8_t out: 1;
    } bits;
} mcp79410_config_t;

// MCP79410 seconds
typedef union
{
    uint8_t byte;
    struct
    {
        uint8_t secone: 4;
        uint8_t secten: 3;
        uint8_t st: 1;
    } bits;
} mcp79410_seconds_t;


// MCP79410 EEPROM block protection control
typedef union
{
    uint8_t byte;
    struct
    {
        uint8_t reserved_1: 2;
        uint8_t bp0: 1;
        uint8_t bp1: 1;
        uint8_t reserved_2: 4;
    } bits;
} mcp79410_eeprom_blk_prot_ctrl_t;

//! @brief Writes pca9536 register offset
//! @param slaveaddr is the slave address of the I2C device to use
//! @param cmd is the register offset
//! @return true - successfully written the register offset, false - otherwise
uint8_t mcp79410_offset_set(uint8_t slaveaddr, uint8_t offset);

//! @brief Writes pca9536 register with a given value
//! @param slaveaddr is the slave address of the I2C device to use
//! @param cmd is the register offset
//! @param register_val is value to be written to a register
//! @return true - successfully written the value to the selected register, false - otherwise
uint8_t mcp79410_reg_set(uint8_t slaveaddr, uint8_t offset, uint8_t register_val);

//! @brief Reads pca9536 current register value
//! @param slaveaddr is the slave address of the I2C device to use
//! @param register_val is a pointer to a value which will be holding the read value
//! @return true - successfully read register value, false - otherwise
uint8_t mcp79410_reg_get(uint8_t slaveaddr, uint8_t* register_val);

uint8_t retro_emu_hat_rtcc_init();

uint8_t retro_emu_hat_ram_read(uint8_t start, uint8_t len, uint8_t* buf);

uint8_t retro_emu_hat_ram_write(uint8_t start, uint8_t len, uint8_t* p_buf);

uint8_t retro_emu_hat_eeprom_read(uint8_t start, uint8_t len, uint8_t* buf);

uint8_t retro_emu_hat_eeprom_write(uint8_t start, uint8_t len, uint8_t* p_buf);

uint8_t mcp79410_eeprom_ctrl_get(mcp79410_eeprom_blk_prot_ctrl_t* register_val);

uint8_t mcp79410_eeprom_ctrl_set(mcp79410_eeprom_blk_prot_ctrl_t* register_val);

#endif /*PCA9536_H_*/
