//! @file pca9536.c
//! @brief Driver for pca9536 I2C Port Expander.
//! @details Provides functionality to set/get status of 4 push-pull outputs of PCA9536.

#include <xstatus.h>
#include "pca9536.h"

static pca9536_output_t pca_out;

bool pca9536_offset_set(uint8_t slaveaddr, uint8_t cmd)
{
    return iic_write(slaveaddr, (uint8_t*)&cmd, 1) == XST_SUCCESS;
}

bool pca9536_reg_set(uint8_t slaveaddr, uint8_t cmd, uint8_t register_val)
{
    uint8_t write_buf[2];
    write_buf[0] = cmd;
    write_buf[1] = register_val;
    return iic_write(slaveaddr, (uint8_t*)&write_buf, 2) == XST_SUCCESS;
}

bool pca9536_reg_get(uint8_t slaveaddr, uint8_t* register_val)
{
    return iic_read(slaveaddr, register_val, 1) == XST_SUCCESS;
}

bool retro_emu_hat_gpio_init()
{
    bool res;
    pca9536_config_t pca_config;
    pca_config.bits.io0_as_input = 1;
    pca_config.bits.io1_as_input = 1;
    pca_config.bits.io2_as_input = 0;
    pca_config.bits.io3_as_input = 1;
    res = pca9536_reg_set(I2C_GPIO_PCA9536_ADDRESS, I2C_GPIO_PCA9536_CONFIGURATION_PORT, pca_config.byte);
    if (res == true)
    {
        res = pca9536_offset_set(I2C_GPIO_PCA9536_ADDRESS, I2C_GPIO_PCA9536_OUTPUT_PORT);
        if (res == XST_SUCCESS)
        {
            res = pca9536_reg_get(I2C_GPIO_PCA9536_ADDRESS, &pca_out.byte);
        }
    }
    return res;
}

bool retro_emu_hat_gpio_heartbeat()
{
    uint8_t res;
    pca_out.bits.o2 = 0;
    res = pca9536_reg_set(I2C_GPIO_PCA9536_ADDRESS, I2C_GPIO_PCA9536_OUTPUT_PORT, pca_out.byte);
    if (res == true)
    {
        vTaskDelay(5);
        pca_out.bits.o2 = 1;
        if (res == true)
        {
            pca9536_reg_set(I2C_GPIO_PCA9536_ADDRESS, I2C_GPIO_PCA9536_OUTPUT_PORT, pca_out.byte);
        }
    }
    return res;
}
