//! @file registers.h
//! @brief Driver for Emu-Lator Video Controller on Zynq7020/Arty-Z7

#ifndef REGISTERS_H
#define REGISTERS_H

#include <stdint.h>

#define EMU_VIDEO_CTRL_BASE_ADDR (XPAR_S_VDMA_AXI_LITE_BASEADDR)

// Standard Video IP registers
#define EMU_VIDEO_CONTROL_REG_OFFSET       (0x0L)

// The registers below are not related to the Video controller
// and used as extension in the register address space
// to save on resources
#define EMU_MEM_WRITE_TEST_REG_OFFSET     (0x114L)
#define EMU_CONTROL_OFFSET       (0x118L)
#define EMU_BRAM_OFFSET                   (0x12CL)

#define MEM_TEST_PASS_CNTR_OFFSET        (0x14CL)
#define MEM_TEST_FAIL_CNTR_OFFSET        (0x150L)

#define MEM_MMC_DI_OFFSET                (0x154L)
#define MEM_MMC_RO_OFFSET                (0x158L)
#define PS2_KBD_OFFSET                   (0x15CL)
#define JOYSTICK_OFFSET                  (0x160L)

#define EMU_VRAM_SIZE (0x1B00)
#define EMU_VRAM_MIN_ALIGNMENT (0x2000)


//!@brief C structure representing EMU-Lator Display control register.
typedef union
{
    uint32_t u32;
    struct
    {
        uint32_t sw_enable :1;
        uint32_t reg_update :1;
        uint32_t aspect_ratio_16_9 :1;
        uint32_t emu_screen_enabled :1;
        uint32_t bypass_enable :1;
        uint32_t test_pattern_enable :1;
        uint32_t reserved_1 :1;
        uint32_t reserved_2 :1;
        uint32_t upscaler_enable :1;
        uint32_t reserved_3 :22;
        uint32_t sw_reset :1;
    } bits;

} reg_EMU_Control_Struct;


//!@brief C structure representing a register for testing ZX address and data bus mapper.
typedef union
{
    uint32_t u32;
    struct
    {
        uint32_t address : 2;
        uint32_t data : 8;
        uint32_t reserved : 21;
        uint32_t vdp_control_override : 1;
    } bits;

} reg_EMU_mem_write_test_Struct;

//!@brief C structure representing ZX Spectrum 2022 control register.
typedef union
{
    uint32_t u32;
    struct
    {
        uint32_t cpu_halt_req : 1;
        uint32_t cpu_restore_pc : 1;
        uint32_t cpu_one_cycle_wait_req : 1;
        uint32_t cpu_reset : 1;
        uint32_t magic_button : 1;
        uint32_t cpu_trace_req : 1;
        uint32_t trdos_flag : 1; 
        uint32_t trdos_wait : 1; 
        uint32_t cpu_pc : 16;
        uint32_t cpu_int : 8;
    } bits;
 
} reg_EMU_cpu_control_Struct;

//!@brief C structure representing ZX Spectrum 2022 mouse register (currently not used).
typedef union
{
    uint32_t u32;
    struct
    {
        uint32_t mouse_x : 8;
        uint32_t mouse_y : 8;
        uint32_t mouse_buttons : 8;
        uint32_t reserved : 8;
    } bits;

} reg_EMU_mouse_Struct;

//!@brief C structure representing ZX Spectrum 2022 BRAM register.
typedef union
{
    uint32_t u32;
    struct
    {
        uint32_t data : 8;
        uint32_t address : 24;
    } bits;

} reg_EMU_BRAM_Struct;

typedef union
{
    uint32_t u32;
    struct
    {
        uint32_t r : 32;
    } bits;

} reg_Mem_Test_Pass_Cntr_Struct;

typedef union
{
    uint32_t u32;
    struct
    {
        uint32_t r : 32;
    } bits;

} reg_Mem_Test_Fail_Cntr_Struct;

typedef union
{
    uint32_t u32;
    struct
    {
        uint32_t data : 8;
        uint32_t cs : 1;
        uint32_t pending_write : 1;
        uint32_t reserved : 22;
    } bits;

} reg_MMC_DI_Struct;

typedef union
{
    uint32_t u32;
    struct
    {
        uint32_t data : 8;
        uint32_t reserved : 24;
    } bits;

} reg_MMC_DO_Struct;

typedef union
{
    uint32_t u32;
    struct
    {
        uint32_t scancode : 8;
        uint32_t extended : 1;
        uint32_t pressed : 1;
        uint32_t toggle : 1;
        uint32_t reserved : 21;
    } bits;

} reg_PS2_Kbd_Struct;


typedef union
{
    uint32_t u32;
    struct
    {
        uint32_t joy1_down : 1;
        uint32_t joy1_up : 1;
        uint32_t joy1_right : 1;
        uint32_t joy1_left : 1;
        uint32_t joy1_trigger_a : 1;
        uint32_t joy1_trigger_b : 1;
        uint32_t reserved_1 : 2;
        uint32_t joy2_down : 1;
        uint32_t joy2_up : 1;
        uint32_t joy2_right : 1;
        uint32_t joy2_left : 1;
        uint32_t joy2_trigger_a : 1;
        uint32_t joy2_trigger_b : 1;
        uint32_t reserved_2 : 18;
    } bits;

} reg_Joystick_Struct;



//! @brief Writes to the control register
//! @param *value is a pointer to reg_EMU_Control_Struct to be written
void emu_control_reg_write(reg_EMU_Control_Struct* value);

//! @brief Sets both the bitmap and color attribute addresses for standard Spectrum screen
//! @param bitmap_address is the start of the bitmap regiion, the address of the color 
//! attributes is calculated as offset from the bitmap address
void emu_vdma_start_address_set(uint32_t bitmap_address, uint8_t store_border);

//! @brief Enables or disables the video controller
//! @param enabled set to 0 to disable, 1 to enable
void emu_vdma_enable_set(uint8_t enabled);

void emu_vdma_aspect_16_9_set(uint8_t aspect_ratio_16_9);

//! @brief Enables or disables generation of a test pattern
//! @param enabled set to 0 to disable, 1 to enable
void emu_test_mode_set(uint8_t enabled);

//! @brief Writes to the memory test register
//! @param *value is a pointer to reg_EMU_mem_write_test_Struct to be written
void emu_mem_write_reg_write(reg_EMU_mem_write_test_Struct* value);

//! @brief High level function for writing to memory through ZX Spectrum Address and Data bus mapper
//! @param address to be written at
//! @param 8 bit value to be written at a given address
void emu_mem_write(uint32_t address, uint8_t value);

//! @brief Writes to the ZX Spectrum CPU control register
//! @param *value is a pointer to reg_EMU_cpu_control_Struct to be written
void emu_cpu_control_reg_write(reg_EMU_cpu_control_Struct* value);

//! @brief Reads from the ZX Spectrum CPU control register
//! @param *value is a pointer to reg_EMU_cpu_control_Struct to be read
void emu_cpu_control_reg_read(reg_EMU_cpu_control_Struct* value);

void emu_bram_reg_write(reg_EMU_BRAM_Struct* value);

void emu_vdma_converter_bypass_set(uint8_t bypass);

void emu_vdma_aspect_16_9_invert(void);

void emu_screen_enabled_set(uint8_t screen_enabled);

void emu_upscaler_enabled_set(uint8_t upscaler_enabled);

void mem_test_pass_reg_read(reg_Mem_Test_Pass_Cntr_Struct* value);

void mem_test_fail_reg_read(reg_Mem_Test_Fail_Cntr_Struct* value);

void mem_mmc_di_reg_read(reg_MMC_DI_Struct* value);

void mem_mmc_do_reg_write(reg_MMC_DO_Struct* value);

void ps2_kbd_write(reg_PS2_Kbd_Struct* value);

void joystick_write(reg_Joystick_Struct* value);

#endif
