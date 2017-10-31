//
//  Cpu.h
//  
//
//  Created by zenen jaimes on 10/31/17.
//

#ifndef Cpu_h
#define Cpu_h

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <stdint.h>
#include <sys/time.h>


typedef struct StateCpu {
    boolean_t        is_running;
    uint32_t       counter;
    uint8_t        reg_acc;
    uint8_t        reg_x;
    uint8_t        reg_y;
    uint16_t       reg_sp;
    uint8_t        reg_status;
    uint16_t       reg_pc;
    uint8_t        *memory;
    uint8_t        interrupt_period;
    uint16_t       notify_ppu_value;
    uint16_t       notify_ppu_address;
} StateCpu;

enum interrupts {
    INT_RESET = 1,
    INT_IRQ = 2,
    INT_NMI = 3
};

enum opcodes {
    ADC_IMM = 0x69,
    ADC_ZP = 0x65,
    ADC_ZPX = 0x75,
    ADC_ABS = 0x6D,
    ADC_ABSX = 0x7D,
    ADC_ABSY = 0x79,
    ADC_INDX = 0x61,
    ADC_INDY = 0x71,
    AND_IMM = 0x29,
    AND_ZP = 0x25,
    AND_ZPX = 0x35,
    AND_ABS = 0x2D,
    AND_ABSX = 0x3D,
    AND_ABSY = 0x39,
    AND_INDX = 0x21,
    AND_INDY = 0x31,
    ASL_A = 0x0A,
    ASL_ZP = 0x06,
    ASL_ZPX = 0x16,
    ASL_ABS = 0x0E,
    ASL_ABSX = 0x1E,
    BCC = 0x90,
    BCS = 0xB0,
    BEQ = 0xF0,
    BIT_ZP = 0x24,
    BIT_ABS = 0x2C,
    BMI = 0x30,
    BNE = 0xD0,
    BPL = 0x10,
    BVC = 0x50,
    BVS = 0x70,
    BRK = 0x00,
    CLC = 0x18,
    CLD = 0xD8,
    CLI = 0x58,
    CLV = 0xB8,
    CMP_IMM = 0xC9,
    CMP_ZP = 0xC5,
    CMP_ZPX = 0xD5,
    CMP_ABS = 0xCD,
    CMP_ABSX = 0xDD,
    CMP_ABSY = 0xD9,
    CMP_INDX = 0xC1,
    CMP_INDY = 0xD1,
    CPX_IMM = 0xE0,
    CPX_ZP = 0xE4,
    CPX_ABS = 0xEC,
    
    CPY_IMM = 0xC0,
    CPY_ZP = 0xC4,
    CPY_ABS = 0xCC,
    DEC_ZP = 0xC6,
    DEC_ZPX = 0xD6,
    DEC_ABS = 0xCE,
    DEC_ABSX = 0xDE,
    DEX = 0xCA,
    DEY = 0x88,
    EOR_IMM = 0x49,
    EOR_ZP = 0x45,
    EOR_ZPX = 0x55,
    EOR_ABS = 0x4D,
    EOR_ABSX = 0x5D,
    EOR_ABSY = 0x59,
    EOR_INDX = 0x41,
    EOR_INDY = 0x51,
    INC_ZP = 0xE6,
    INC_ZPX = 0xF6,
    INC_ABS = 0xEE,
    INC_ABSX = 0xFE,
    
    INX = 0xE8,
    INY = 0xC8,
    JMP_ABS = 0x4C,
    JMP_IND = 0x6C,
    JSR = 0x20,
    LDA_ABS = 0xAD,
    LDA_ABSX = 0xBD,
    LDA_ABSY = 0xB9,
    LDA_IMM = 0xA9,
    LDA_INDY = 0xB1,
    LDA_INDX = 0xA1,
    
    LDA_ZP = 0xA5,
    LDA_ZPX = 0xB5,
    
    LDX_IMM = 0xA2,
    LDX_ZP = 0xA6,
    LDX_ZPY = 0xB6,
    LDX_ABS = 0xAE,
    LDX_ABSY = 0xBE,
    LDY_IMM = 0xA0,
    LDY_ABS = 0xAC,
    LDY_ABSX = 0xBC,
    LDY_ZPX = 0xB4,
    LDY_ZP = 0xA4,
    LSR_A = 0x4A,
    LSR_ZP = 0x46,
    LSR_ZPX = 0x56,
    LSR_ABS = 0x4E,
    LSR_ABSX = 0x5E,
    NOP = 0xEA,
    NOP1A = 0x1A,
    ORA_IMM = 0x09,
    ORA_ZP = 0x05,
    ORA_ZPX = 0x15,
    ORA_ABS = 0x0D,
    ORA_ABSX = 0x1D,
    ORA_ABSY = 0x19,
    ORA_INDX = 0x01,
    ORA_INDY = 0x11,
    PLA = 0x68,
    PLP = 0x28,
    PHA = 0x48,
    PHP = 0x08,
    ROR_ACC = 0x6A,
    ROR_ZP = 0x66,
    ROR_ZPX = 0x76,
    
    ROR_ABSX = 0x7E,
    ROR_ABS = 0x6E,
    
    ROL_ACC = 0x2A,
    ROL_ZP = 0x26,
    ROL_ZPX = 0x36,
    ROL_ABS = 0x2E,
    ROL_ABSX = 0x3E,
    RTI = 0x40,
    RTS = 0x60,
    SBC_IMM = 0xE9,
    SBC_ZP = 0xE5,
    SBC_ZPX = 0xF5,
    SBC_ABSX = 0xFD,
    SBC_ABS = 0xED,
    SBC_ABSY = 0xF9,
    SBC_INDX = 0xE1,
    SBC_INDY = 0xF1,
    
    SEC = 0x38,
    SED = 0xF8,
    SEI = 0x78,
    STA_ZP = 0x85,
    STA_ZPX = 0x95,
    STA_ABS = 0x8D,
    STA_ABSX = 0x9D,
    STA_ABSY = 0x99,
    STA_INDX = 0x81,
    STA_INDY = 0x91,
    STY_ABS = 0x8C,
    STX_ABS = 0x8E,
    STX_ZP = 0x86,
    STX_ZPY = 0x96,
    STY_ZP = 0x84,
    STY_ZPX = 0x94,
    
    TAX = 0xAA,
    TXA = 0x8A,
    TAY = 0xA8,
    TYA = 0x98,
    TSX = 0xBA,
    TXS = 0x9A
};


int Emulate6502(StateCpu* state);
void GenerateInterrupt(StateCpu* state, int interrupt_num);

#endif /* Cpu_h */
