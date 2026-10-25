//! @file gpio.h
//! @brief GPIO wrapper around MIO, EMIO and AXI EMIO pins

#ifndef GPIO_H
#define GPIO_H

#include <stdbool.h>
#include "xparameters.h"
#include "xstatus.h"
#include "xgpio.h"
#include "xgpiops.h"
#include <stdint.h>

//#define XGPIO_INTERFACE_0 XPAR_GPIO_0_DEVICE_ID
#define XGPIO_PS_IF0 XPAR_PS7_GPIO_0_DEVICE_ID

typedef enum
{
    SD_CD = 47, // Card detect
    SD_CS = 45, // CD/DAT3, MIO45
    SD_MISO = 42,    // DAT0, MIO42
    SD_MOSI = 41,    // CMD, MIO41
    SD_CLK = 40      // CLK, MIO40
} XGPIO_0_t;


//! @brief Initialise GPIO driver
//! @return XST_SUCCESS in case of sucess or an error code otheriwse
int32_t gpio_init(void);

//! @brief Set the state of an output pin
//! @param pin_num is the pin number
//! @param pin_value is either 0 or 1
//! @return XST_SUCCESS in case of sucess or an error code otherise
int32_t gpio_pin_write(uint8_t pin_num, uint8_t pin_value);

//! @brief Set the direction of a pin
//! @param pin_num is the pin number
//! @param is_output is set to true for output or false for input
//! @return XST_SUCCESS in case of sucess or an error code otherwise
int32_t gpio_pin_dir_set(uint8_t pin_num, bool is_output);


//! @brief Get the state of an input pin
//! @param pin_num is the pin number
//! @param *value is a reference to a variable which will hold the read value
//! @return XST_SUCCESS in case of sucess or an error code otherwise
int32_t gpio_pin_read(uint8_t pin_num, uint8_t* value);


#endif //GPIO_H

