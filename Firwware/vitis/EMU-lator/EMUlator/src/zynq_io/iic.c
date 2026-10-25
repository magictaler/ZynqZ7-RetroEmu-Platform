//! @file iic_handler.c
//! @brief Low-level communication with iic slaves
//! @details
//! This module initializes the iic bus, and provides basic IO with iic slaves.
#include "iic.h"

#include <FreeRTOS.h>
#include <semphr.h>

#include <xiic.h>
#include <xparameters.h>
#include <xstatus.h>
#include <sleep.h>
#include <xscugic.h>
#include <xil_exception.h>
#include <xil_printf.h>

#ifndef IIC_USE_PS
#include "xiic_i.h"
#endif

#define IIC_SCLK_RATE 100000 // In Hz
#define DEBUG_IIC

// Uncomment to work in a polling mode otherwise it is interrupt driven
#define POLLING_MODE


#ifdef IIC_USE_PS
static XIicPs iic_device;
#else
static XIic iic_device;
#endif

#ifdef IIC_USE_PS
static void iic_busy_wait()
{
    while (XIicPs_BusIsBusy(&iic_device))
    {
        ;// NOP
    }
}
#endif

uint8_t iic_selftest()
{
#ifdef IIC_USE_PS
	return XIicPs_SelfTest(&iic_device) == XST_SUCCESS;
#else
    return XIic_SelfTest(&iic_device) == XST_SUCCESS;
#endif

}

uint8_t iic_init(void)
{
    int32_t status = XST_FAILURE;
#ifdef IIC_USE_PS
    XIicPs_Config* p_xiic_config;
    p_xiic_config = XIicPs_LookupConfig(IIC_DEVICE_ID);
    if (p_xiic_config != NULL)
    {
        status = XIicPs_CfgInitialize(&iic_device, p_xiic_config, p_xiic_config->BaseAddress);
        if (status == XST_SUCCESS)
        {
            status = XIicPs_SelfTest(&iic_device);
            if (status == XST_SUCCESS)
            {
  #ifndef POLLING_MODE
                status = setup_interruptSystem(&iic_device);
                if (status == XST_SUCCESS)
                {
                    XIicPs_SetStatusHandler(&iic_device, (void *) &iic_device, iic_intr_handler);
                }
  #endif
                status = XIicPs_SetSClk(&iic_device, IIC_SCLK_RATE);
            }
        }
    }
#else
    XIic_Config *config;
    config = XIic_LookupConfig(IIC_DEVICE_ID);
    if (NULL == config)
    {
#ifdef DEBUG_IIC
        xil_printf("IIC XIic_LookupConfig Failed!\r\n");
#endif
    }
    else
    {
        status = XIic_CfgInitialize(&iic_device, config, config->BaseAddress);
        if (status != XST_SUCCESS)
        {
            xil_printf("IIC XIic_CfgInitialize Failed!\r\n");
        }
        else
        {
            status = XIic_SelfTest(&iic_device);
        }
    }
#endif
    return status == XST_SUCCESS;
}

int32_t iic_read(uint8_t slaveaddr, uint8_t *data, int32_t len)
{
    int32_t status = XST_FAILURE;
#ifdef IIC_USE_PS
    iic_busy_wait();
#ifdef POLLING_MODE
    status = XIicPs_MasterRecvPolled(&iic_device, data, len, slaveaddr);
#else
    send_complete = FALSE;
    XIicPs_MasterSend(&iic_device, &offset, 1, slaveaddr);
    while (!send_complete)
    {
        if (0 == total_error_count)
        {
            return XST_SUCCESS;
        }
    }
    XIicPs_ClearOptions(&iic_device, XIICPS_REP_START_OPTION);
    XIicPs_MasterRecv(&iic_device, data, len, slaveaddr);
#endif //polling mode
    iic_busy_wait();
#else //ps
    status = XIic_SetAddress(&iic_device, XII_ADDR_TO_RESPOND_TYPE, slaveaddr);
    if (status == XST_SUCCESS)
    {
        status = XIic_MasterRecv(&iic_device, data, len);
        if (status != XST_SUCCESS)
        {
#ifdef DEBUG_IIC
            xil_printf("IIC read Failed!\r\n");
#endif
        }
    }
#endif
    return status;
}

int32_t iic_write(uint8_t slaveaddr, uint8_t *data, int32_t len)
{
    int32_t status;
#ifdef IIC_USE_PS
    iic_busy_wait();
#ifdef POLLING_MODE
    status = XIicPs_MasterSendPolled(&iic_device, data, len, slaveaddr);
#else
    send_complete = FALSE;
    XIicPs_MasterSend(&iic_device, data, len, slaveaddr);
#ifdef DEBUG_IIC
    xil_printf("IIC send_complete: %d\r\n", send_complete);
#endif
    while (send_complete == FALSE)
    {
        if (0 != total_error_count)
        {
            return XST_FAILURE;
        }
    }
#endif
    iic_busy_wait();
#else
    status = XIic_SetAddress(&iic_device, XII_ADDR_TO_SEND_TYPE, slaveaddr);
    if (status == XST_SUCCESS)
    {
        status = XIic_MasterSend(&iic_device, data, len);
        if (status != XST_SUCCESS)
        {
#ifdef DEBUG_IIC
            xil_printf("IIC write Failed!\r\n");
#endif
        }
    }
    else
    {
#ifdef DEBUG_IIC
        xil_printf("IIC set address Failed!\r\n");
#endif
    }
#endif
    return status;
}
