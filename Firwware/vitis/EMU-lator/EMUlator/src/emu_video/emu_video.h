//! @file emu_video.h
//! @brief High level API for Video Controller

#ifndef EMU_VIDEO_H
#define EMU_VIDEO_H

#include <stdbool.h>
#include "../emu_io/registers.h"

typedef struct
{
    uint8_t emu_spectrum_frameBuf[EMU_VRAM_SIZE] __attribute__ ((aligned (EMU_VRAM_MIN_ALIGNMENT)));
} EmuFrameBufStruct;

//! @brief Initialise Emu video
void emu_video_init(void);

//! @brief Switch to a specific video page
//! @param page number to switch to
//! @return true if shell videopage was successfully activated false otherwise
bool emu_activate_shell_vpage(uint32_t page);

//! @brief Get a pointer to the video memory of a specific video page
//! @param page number
//! @return a pointer to the start address of the given page
uint8_t* emu_shell_vpage_address(uint32_t page);

//! @brief Iterate to the next resolution mode
//! @return true if resolution mode was successfully switched false otherwise
bool emu_iterate_vmode(void);


#endif
