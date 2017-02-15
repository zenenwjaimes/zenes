//
//  Cpu.h
//  zenes
//
//  Created by zenen jaimes on 5/24/16.
//  Copyright © 2016 zenen jaimes. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreFoundation/CFByteOrder.h>
#import "ProcessorStatus.h"
#import "BitHelper.h"

@interface Cpu6502 : NSObject
{
    uint8_t _memory[0x10000];
}

@property BOOL isRunning;
@property uint16_t op1;
@property uint16_t op2;
@property uint16_t op3;
@property uint8_t interruptPeriod;
@property uint32_t counter;
@property uint8_t reg_acc;
@property uint8_t reg_x;
@property uint8_t reg_y;
@property uint8_t reg_sp;
@property uint8_t reg_status;
@property uint16_t reg_pc;
@property (assign, nonatomic) uint8_t *memory;
//@property (retain) NSObject *delegate;
@property (copy) NSString *currentLine;

// Memory reading instructions
- (uint8_t)readAbsoluteAddress1: (uint8_t)address1 address2: (uint8_t)address2;
- (uint8_t)readIndexedAbsoluteAddress1: (uint8_t)address1 address2: (uint8_t)address2 withOffset: (uint8_t)offset;
- (uint8_t)readIndexedIndirectAddressWithByte: (uint8_t)lowByte andOffset: (uint8_t)offset;
- (uint8_t)readIndirectIndexAddressWithByte: (uint8_t)lowByte andOffset: (uint8_t)offset;
- (uint16_t)getIndexedAbsoluteAddress1: (uint8_t)address1 address2: (uint8_t)address2 withOffset: (uint8_t)offset;
- (uint16_t)getIndirectAddressWithLow: (uint8_t)lowByte andHigh: (uint8_t)highByte;
- (uint16_t)getRelativeAddressWithAddress: (uint16_t)address andOffset: (uint8_t)offset;
- (void)writePrgRom: (uint8_t *)rom toAddress: (uint16_t)address;
- (uint8_t)readZeroPage: (uint8_t)address withRegister: (uint8_t)reg;
- (uint8_t)readZeroPage: (uint8_t)address;
- (void)writeZeroPage: (uint8_t)address withValue: (uint8_t)value;
- (void)writeValue: (uint8_t)value toAbsoluteOp1: (uint8_t)absop1 andAbsoluteOp2: (uint8_t)absop2;
- (void)writeValue: (uint8_t)value toAddress: (uint16_t)address;

// Generic register flags
- (void)enableZeroFlag;
- (void)disableZeroFlag;
- (void)enableInterrupts;
- (void)disableInterrupts;
- (void)enableDecimalFlag;
- (void)disableDecimalFlag;
- (void)enableCarryFlag;
- (void)disableCarryFlag;
- (void)enableOverflowFlag;
- (void)disableOverflowFlag;
- (uint8_t)checkFlag: (uint8_t)flag;
- (void)toggleCarryFlagForReg: (uint8_t)cpu_reg;

- (void)runNextInstruction;
- (void)run;
- (void)dumpMemoryToLog;
- (void)triggerInterrupt: (int)interruptType;

+ (NSString *)getOpcodeName: (uint8_t)opcode;

@end

enum interrupts {
    INT_RESET = 1,
    INT_IRQ = 2,
    INT_NMI = 3
};

enum opcodes {
    ADC_IMM = 0x69,
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
    BMI = 0x30,
    BNE = 0xD0,
    BPL = 0x10,
    BVC = 0x50,
    BVS = 0x70,
    CLC = 0x18,
    CLD = 0xD8,
    CLI = 0x58,
    CLV = 0xB8,
    CMP_IMM = 0xC9,
    CPX_IMM = 0xE0,
    CPY_IMM = 0xC0,
    DEX = 0xCA,
    DEY = 0x88,
    EOR_IMM = 0x49,
    INC_ZP = 0xE6,
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
    LDA_ZP = 0xA5,
    LDX_IMM = 0xA2,
    LDY_IMM = 0xA0,
    LDX_ABS = 0xAE,
    LDY_ABS = 0xAC,
    LSR_A = 0x4A,
    LSR_ZP = 0x46,
    LSR_ZPX = 0x56,
    LSR_ABS = 0x4E,
    LSR_ABSX = 0x5E,
    NOP = 0xEA,
    ORA_IMM = 0x09,
    ORA_ZP = 0x05,
    ORA_ZPX = 0x15,
    ORA_ABS = 0x0D,
    ORA_ABSX = 0x1D,
    ORA_ABSY = 0x19,
    ORA_IX = 0x01,
    ORA_IY = 0x11,
    PLA = 0x68,
    PLP = 0x28,
    PHA = 0x48,
    PHP = 0x08,
    RTS = 0x60,
    SBC_IMM = 0xE9,
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
    STX_ABS = 0x8E,
    STY_ABS = 0x8C,
    STX_ZP = 0x86,
    STY_ZP = 0x84,
    TAX = 0xAA,
    TXA = 0x8A,
    TAY = 0xA8,
    TYA = 0x98,
    TSX = 0xBA,
    TXS = 0x9A
};
