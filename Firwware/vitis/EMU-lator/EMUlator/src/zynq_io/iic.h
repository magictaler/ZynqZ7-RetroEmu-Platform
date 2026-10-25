//! @file iic.h
//! @brief Low-level communication with iic slaves
//! @details
//! This module initializes the iic bus, and provides basic IO with iic slaves.
#ifndef DRIVERS_IIC_H_
#define DRIVERS_IIC_H_

#include <stdint.h>

#define IIC_USE_PS

#include "xparameters.h"
#include "xstatus.h"

#ifdef IIC_USE_PS
  #include <xiicps.h>
  #define IIC_DEVICE_ID        XPAR_PS7_I2C_0_DEVICE_ID
  #define INTC_DEVICE_ID       XPAR_SCUGIC_SINGLE_DEVICE_ID
  #define IIC_INT_VEC_ID       XPAR_XIICPS_0_INTR
#else
  #include "xiic.h"
  #define IIC_DEVICE_ID        XPAR_IIC_5_DEVICE_ID
#endif


//! @brief This function initialize the iic bus
//! The iic bus is set up according to macro IIC_SCLK_RATE and IIC_DEVICE_ID.
uint8_t iic_init(void);

//! This function performs a driver self-test.
//! @return True if self-test passes.
uint8_t iic_selftest(void);

//! @brief This function write some data to an iic slave.
//! This function uses polling mode of the iic device.
//! @param slaveaddr Target address(usually 0x5x).
//! @param data Pointer of data to be sent.
//! @param len Length of the data.
//! @return XST_SUCCESS if successful, otherwise XST_FAILURE.
int32_t iic_write(uint8_t slaveaddr, uint8_t *data, int32_t len);

//! @brief This function read some data from an iic slave.
//! This function uses polling mode of the iic device.
//! @param slaveaddr Target address(usually 0x5x).
//! @param data Pointer of data to be read.
//! @param len Length of the data.
//! @return XST_SUCCESS if successful, otherwise XST_FAILURE.
int32_t iic_read(uint8_t slaveaddr, uint8_t *data, const int32_t len);

#endif /* SRC_DRIVERS_IIC_H_ */
