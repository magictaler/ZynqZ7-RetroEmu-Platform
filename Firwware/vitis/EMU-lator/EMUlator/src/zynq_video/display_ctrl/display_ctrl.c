/************************************************************************/
/*                                                                      */
/*  display_ctrl.c    --    Digilent Display Controller Driver          */
/*                                                                      */
/*  Patched to work with Emu-Lator Video Controller                     */
/*                                                                      */
/*  Ported in 2022 by Dmitry Pakhomenko.                                */
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
/*        This module provides an easy to use API for controlling a     */
/*        Display attached to a Digilent system board via VGA or HDMI.  */
/*        run-time resolution setting and seamless framebuffer-swapping */
/*        for tear-free animation.                                      */
/*                                                                      */
/*        To use this driver, you must have a Xilinx Video Timing       */
/*        Controller core (vtc), Xilinx axi_vdma core, a Digilent       */
/*        axi_dynclk core, a Xilinx AXI Stream to Video core, and either*/
/*        a Digilent RGB2VGA or RGB2DVI core all present in your design.*/
/*        See the Video in or Display out reference projects for your   */
/*        system board to see how they need to be connected. Digilent   */
/*        reference projects and IP cores can be found at               */
/*        www.github.com/Digilent.                                      */
/*                                                                      */
/*        The following steps should be followed to use this driver:    */
/*        1) Create a DisplayCtrl object and pass a pointer to it to    */
/*           DisplayInitialize.                                         */
/*        2) Call DisplaySetMode to set the desired mode                */
/*        3) Call DisplayStart to begin outputting data to the display  */
/*        4) To create a seamless animation, draw the next image to a   */
/*           framebuffer currently not being displayed. Then call       */
/*           DisplayChangeFrame to begin displaying that frame.         */
/*           Repeat as needed, only ever modifying inactive frames.     */
/*        5) To change the resolution, call DisplaySetMode, followed by */
/*           DisplayStart again.                                        */
/*                                                                      */
/*                                                                      */
/************************************************************************/
/*  Revision History:                                                   */
/*                                                                      */
/*       2/20/2014(SamB): Created                                       */
/*      11/25/2015(SamB): Changed from axi_dispctrl to Xilinx cores     */
/*                        Separated Clock functions into dynclk library */
/*                                                                      */
/************************************************************************/
/*
 * TODO: It would be nice to remove the need for users above this to access
 *       members of the DisplayCtrl struct manually. This can be done by
 *       implementing get/set functions for things like video mode, state,
 *       etc.
 */


/* ------------------------------------------------------------ */
/*                Include File Definitions                      */
/* ------------------------------------------------------------ */

#include "display_ctrl.h"
#include "xdebug.h"
#include "xil_io.h"
#include "../../emu_io/registers.h"
#include "../../emu_io/emu_config.h"

#define REF_CLK_SCALING_FACTOR 0.8590908f //1.12f 100 vs 112 MHz for ZX Spectrum, 100 vs 85.90908 MHz for MSX2+

/* ------------------------------------------------------------ */
/*                Procedure Definitions                         */
/* ------------------------------------------------------------ */

/***    DisplayStop(DisplayCtrl *dispPtr)
**
**    Parameters:
**        dispPtr - Pointer to the initialized DisplayCtrl struct
**
**    Return Value: int
**        XST_SUCCESS if successful.
**        XST_DMA_ERROR if an error was detected on the DMA channel. The
**            Display is still successfully stopped, and the error is
**            cleared so that subsequent DisplayStart calls will be
**            successful. This typically indicates insufficient bandwidth
**            on the AXI Memory-Map Interconnect (VDMA<->DDR)
**
**    Description:
**        Halts output to the display
**
*/
int DisplayStop(DisplayCtrl *dispPtr)
{
    /*
     * If already stopped, do nothing
     */
    if (dispPtr->state == DISPLAY_STOPPED)
    {
        return XST_SUCCESS;
    }

    /*
     * Stop the VDMA core
     */
    emu_vdma_enable_set(0);

    /*
     * Update Struct state
     */
    dispPtr->state = DISPLAY_STOPPED;

    //TODO: consider stopping the clock here

    //TODO: get errors from the VDMA and return non-success status if this is the case?

    return XST_SUCCESS;
}


/***    DisplayStart(DisplayCtrl *dispPtr)
**
**    Parameters:
**        dispPtr - Pointer to the initialized DisplayCtrl struct
**
**    Return Value: int
**        XST_SUCCESS if successful, XST_FAILURE otherwise
**
**    Errors:
**
**    Description:
**        Starts the display.
**
*/
int DisplayStart(DisplayCtrl *dispPtr)
{
    ClkConfig clkReg;
    ClkMode clkMode;

    xdbg_printf(XDBG_DEBUG_GENERAL, "display start entered\n\r");
    /*
     * If already started, do nothing
     */
    if (dispPtr->state == DISPLAY_RUNNING)
    {
        return XST_SUCCESS;
    }

    emu_vdma_enable_set(0);

    /*
     * Calculate the PLL divider parameters based on the required pixel clock frequency
     */
    ClkFindParams(dispPtr->vMode->freq / REF_CLK_SCALING_FACTOR, &clkMode);

    /*
     * Store the obtained frequency to pxlFreq. It is possible that the PLL was not able to
     * exactly generate the desired pixel clock, so this may differ from vMode.freq.
     */
    dispPtr->pxlFreq = clkMode.freq;

    /*
     * Write to the PLL dynamic configuration registers to configure it with the calculated
     * parameters.
     */
    if (!ClkFindReg(&clkReg, &clkMode))
    {
        xdbg_printf(XDBG_DEBUG_GENERAL, "Error calculating CLK register values\n\r");
        return XST_FAILURE;
    }
    ClkWriteReg(&clkReg, dispPtr->dynClkAddr);

    /*
     * Enable the dynamically generated clock
    */
    ClkStop(dispPtr->dynClkAddr);
    ClkStart(dispPtr->dynClkAddr);

    emu_vdma_enable_set(1);
    emu_vdma_aspect_16_9_set(dispPtr->vMode->aspect_16_9);
    emu_vdma_converter_bypass_set(0);
    emu_vdma_start_address_set((uint32_t)dispPtr->framePtr[dispPtr->curFrame], 1);

    dispPtr->state = DISPLAY_RUNNING;

    return XST_SUCCESS;
}


/***    DisplayInitialize(DisplayCtrl *dispPtr, u32 dynClkAddr, u8 *framePtr[DISPLAY_NUM_FRAMES])
**
**    Parameters:
**        dispPtr - Pointer to the struct that will be initialized
**        dynClkAddr - BASE ADDRESS of the axi_dynclk core
**        framePtr - array of pointers to the framebuffers. The framebuffers must be instantiated above this driver, and there must be 3
**
**    Return Value: int
**        XST_SUCCESS if successful, XST_FAILURE otherwise
**
**    Errors:
**
**    Description:
**        Initializes the driver struct for use.
**
*/
int DisplayInitialize(DisplayCtrl *dispPtr, u32 dynClkAddr, u8 *framePtr[DISPLAY_NUM_FRAMES])
{
    int i;
    ClkConfig clkReg;
    ClkMode clkMode;

    /*
     * Initialize all the fields in the DisplayCtrl struct
     */
    dispPtr->curFrame = 0;
    dispPtr->dynClkAddr = dynClkAddr;
    for (i = 0; i < DISPLAY_NUM_FRAMES; i++)
    {
        dispPtr->framePtr[i] = framePtr[i];
    }
    dispPtr->state = DISPLAY_STOPPED;
    dispPtr->vMode = &VMODE_1280x720; //&VMODE_720x576;

    ClkFindParams(dispPtr->vMode->freq / REF_CLK_SCALING_FACTOR, &clkMode);

    /*
     * Store the obtained frequency to pxlFreq. It is possible that the PLL was not able to
     * exactly generate the desired pixel clock, so this may differ from vMode.freq.
     */
    dispPtr->pxlFreq = clkMode.freq;

    /*
     * Write to the PLL dynamic configuration registers to configure it with the calculated
     * parameters.
     */
    if (!ClkFindReg(&clkReg, &clkMode))
    {
        xdbg_printf(XDBG_DEBUG_GENERAL, "Error calculating CLK register values\n\r");
        return XST_FAILURE;
    }
    ClkWriteReg(&clkReg, dispPtr->dynClkAddr);

    /*
     * Enable the dynamically generated clock
    */
    ClkStart(dispPtr->dynClkAddr);

    return XST_SUCCESS;
}


/***    DisplaySetMode(DisplayCtrl *dispPtr, const VideoMode *newMode)
**
**    Parameters:
**        dispPtr - Pointer to the initialized DisplayCtrl struct
**        newMode - The VideoMode struct describing the new mode.
**
**    Return Value: int
**        XST_SUCCESS if successful, XST_FAILURE otherwise
**
**    Errors:
**
**    Description:
**        Changes the resolution being output to the display. If the display
**        is currently started, it is automatically stopped (DisplayStart must
**        be called again).
**
*/
int DisplaySetMode(DisplayCtrl *dispPtr, const VideoMode *newMode)
{
    int Status;
    /*
     * If currently running, stop
     */
    if (dispPtr->state == DISPLAY_RUNNING)
    {
        Status = DisplayStop(dispPtr);
        if (Status != XST_SUCCESS)
        {
            xdbg_printf(XDBG_DEBUG_GENERAL, "Cannot change mode, unable to stop display %d\r\n", Status);
            return XST_FAILURE;
        }
    }
    dispPtr->vMode = newMode;
    return XST_SUCCESS;
}

/***    DisplayChangeFrame(DisplayCtrl *dispPtr, u32 frameIndex)
**
**    Parameters:
**        dispPtr - Pointer to the initialized DisplayCtrl struct
**        frameIndex - Index of the framebuffer to change to (must
**                be between 0 and (DISPLAY_NUM_FRAMES - 1))
**
**    Return Value: int
**        XST_SUCCESS if successful, XST_FAILURE otherwise
**
**    Errors:
**
**    Description:
**        Changes the frame currently being displayed.
**
*/
int DisplayChangeFrame(DisplayCtrl *dispPtr, u32 frameIndex)
{
    dispPtr->curFrame = frameIndex;
    /*
     * If currently running, then the DMA needs to be told to start reading from the desired frame
     * at the end of the current frame
     */
    if (dispPtr->state == DISPLAY_RUNNING)
    {
        emu_vdma_start_address_set((uint32_t)dispPtr->framePtr[frameIndex], 1);
    }
    return XST_SUCCESS;
}

/************************************************************************/

