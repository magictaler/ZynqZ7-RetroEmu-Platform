/************************************************************************/
/*                                                                      */
/*  vga_modes.h    --    VideoMode definitions                          */
/*                                                                      */
/*  Patched to work with Emu-Lator Video Controller                     */
/*                                                                      */
/*  Ported in 2022 Dmitry Pakhomenko.                                   */
/*  dmitryp@magictale.com                                               */
/*  http://magictale.com                                                */
/*                                                                      */
/*                                                                      */
/************************************************************************/
/*    Author: Sam Bobrowicz                                             */
/*    Copyright 2014, Digilent Inc.                                     */
/************************************************************************/
/*  Module Description:                                                 */
/*                                                                      */
/*        This file contains the definition of the VideoMode type, and  */
/*        also defines several common video modes                       */
/*                                                                      */
/************************************************************************/
/*  Revision History:                                                   */
/*                                                                      */
/*        2/17/2014(SamB): Created                                      */
/*                                                                      */
/************************************************************************/

#ifndef VGA_MODES_H_
#define VGA_MODES_H_

typedef struct 
{
    char label[64];  /* Label describing the resolution */
    u32 aspect_16_9; /* Aspect ratio */
    double freq;     /* Pixel Clock frequency */
} VideoMode;

static const VideoMode VMODE_1280x720 = 
{
    .label = "1280x720@50Hz",
    .aspect_16_9 = 1,
    .freq = 62.0 //61.250 - ZX Spectrum, 61.999 - MSX2+ VDP
};

static const VideoMode VMODE_720x576 = 
{
    .label = "720x576@50Hz",
    .aspect_16_9 = 0,
    .freq = 26.700
};



#endif /* VGA_MODES_H_ */
