//! @file std_in.h
//! @brief keyboard control via serial console

#ifndef STD_IN_H
#define STD_IN_H

#include <stdint.h>
#include <stdbool.h>

bool read_std_in(uint8_t* in_char);

#endif
