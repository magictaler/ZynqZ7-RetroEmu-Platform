//! @file pca9536.h
//! @brief Driver for pca9536 I2C Port Expander.
//! @details Provides functionality to set/get status of 4 push-pull outputs of PCA9536.

#ifndef PCA9536_H_
#define PCA9536_H_

#include <stdint.h>
#include <stdbool.h>
#include "../../../zynq_io/iic.h"

#define I2C_GPIO_PCA9536_ADDRESS 0x41

#define I2C_GPIO_PCA9536_INPUT_PORT 0x0
#define I2C_GPIO_PCA9536_OUTPUT_PORT 0x1
#define I2C_GPIO_PCA9536_POLARITY_INVERSION_PORT 0x2
#define I2C_GPIO_PCA9536_CONFIGURATION_PORT 0x3


// PCA9536 config port
typedef union
{
    uint8_t byte;
    struct
    {
        uint8_t io0_as_input: 1;
        uint8_t io1_as_input: 1;
        uint8_t io2_as_input: 1;
        uint8_t io3_as_input: 1;
        uint8_t reserved1: 1;
        uint8_t reserved2: 1;
        uint8_t reserved3: 1;
        uint8_t reserved4: 1;
    } bits;
} pca9536_config_t;

// PCA9536 output port
typedef union
{
    uint8_t byte;
    struct
    {
        uint8_t o0: 1;
        uint8_t o1: 1;
        uint8_t o2: 1;
        uint8_t o3: 1;
        uint8_t reserved1: 1;
        uint8_t reserved2: 1;
        uint8_t reserved3: 1;
        uint8_t reserved4: 1;
    } bits;
} pca9536_output_t;

// PCA9536 input port
typedef union
{
    uint8_t byte;
    struct
    {
        uint8_t i0: 1;
        uint8_t i1: 1;
        uint8_t i2: 1;
        uint8_t i3: 1;
        uint8_t reserved1: 1;
        uint8_t reserved2: 1;
        uint8_t reserved3: 1;
        uint8_t reserved4: 1;
    } bits;
} pca9536_input_t;

// PCA9536 control register
typedef union
{
    uint8_t byte;
    struct
    {
        uint8_t b1: 1;
        uint8_t b2: 1;
        uint8_t reserved1: 1;
        uint8_t reserved2: 1;
        uint8_t reserved3: 1;
        uint8_t reserved4: 1;
        uint8_t reserved5: 1;
        uint8_t reserved6: 1;
    } bits;
} pca9536_control_t;


//! @brief Writes pca9536 register offset
//! @param slaveaddr is the slave address of the I2C device to use
//! @param cmd is the register offset
//! @return true - successfully written the register offset, false - otherwise
bool pca9536_offset_set(uint8_t slaveaddr, uint8_t cmd);

//! @brief Writes pca9536 register with a given value
//! @param slaveaddr is the slave address of the I2C device to use
//! @param cmd is the register offset
//! @param register_val is value to be written to a register
//! @return true - successfully written the value to the selected register, false - otherwise
bool pca9536_reg_set(uint8_t slaveaddr, uint8_t cmd, uint8_t register_val);

//! @brief Reads pca9536 current register value
//! @param slaveaddr is the slave address of the I2C device to use
//! @param register_val is a pointer to a value which will be holding the read value
//! @return true - successfully read register value, false - otherwise
bool pca9536_reg_get(uint8_t slaveaddr, uint8_t* register_val);

bool retro_emu_hat_gpio_init();

bool retro_emu_hat_gpio_heartbeat();


#endif /*PCA9536_H_*/
