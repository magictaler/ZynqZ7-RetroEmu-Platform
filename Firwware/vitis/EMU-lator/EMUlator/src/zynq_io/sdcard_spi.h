//! @file sdcard_spi.h
//! @brief Interface with SD card by means of GPIO bitbanging using legacy SPI interface

#ifndef SDCARD_SPI_H
#define SDCARD_SPI_H

#include <stdbool.h>
#include "xstatus.h"
#include <stdint.h>

//! @brief Initialise SDCARD driver
//! @return XST_SUCCESS in case of sucess or an error code otherwise
int32_t sdcard_spi_init(void);

//! @brief Write a byte to SD card
//! @param cs is the chip select state during write (during init sequence CS is required to be inactive)
//! @param wvalue is an 8 bit value to be written
//! @param rvalue is a reference to a valirable to be filled with read value
//! @return XST_SUCCESS in case of sucess or an error code otherwise
int32_t sdcard_spi_rd_wr(bool cs, uint8_t wvalue, uint8_t* rvalue);

#endif //SDCARD_SPI_H

