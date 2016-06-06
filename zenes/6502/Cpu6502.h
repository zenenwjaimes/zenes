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
@property uint8_t counter;
@property uint8_t reg_acc;
@property uint8_t reg_x;
@property uint8_t reg_y;
@property uint8_t reg_sp;
@property uint8_t reg_status;
@property uint16_t reg_pc;
@property (assign, nonatomic) uint8_t *memory;
@property (retain) NSObject *delegate;

- (void)writePrgRom: (uint8_t *)rom toAddress: (uint16_t)address;
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

- (void)runNextInstruction;
- (void)run;
- (void)dumpMemoryToLog;

+ (NSString *)getOpcodeName: (uint8_t)opcode;

@end

enum opcodes {
    ADC_IMM = 0x69,
    AND_IMM = 0x29,
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
    INX = 0xE8,
    INY = 0xC8,
    JMP_ABS = 0x4C,
    JMP_IND = 0x6C,
    JSR = 0x20,
    LDA_ABS = 0xAD,
    LDA_ABSX = 0xBD,
    LDA_ABSY = 0xB9,
    LDA_IMM = 0xA9,
    LDX_IMM = 0xA2,
    LDY_IMM = 0xA0,
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
    STA_ABS = 0x8D,
    STA_ZP = 0x85,
    STX_ZP = 0x86,
    STY_ZP = 0x84,
    TAX = 0xAA,
    TXA = 0x8A,
    TAY = 0xA8,
    TYA = 0x98,
    TSX = 0xBA,
    TXS = 0x9A
};