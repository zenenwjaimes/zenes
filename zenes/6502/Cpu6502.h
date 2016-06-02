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

@property uint16_t op1;
@property uint16_t op2;
@property uint8_t interruptPeriod;
@property uint8_t counter;
@property uint8_t reg_acc;
@property uint8_t reg_x;
@property uint8_t reg_y;
@property uint16_t reg_sp;
@property uint8_t reg_status;
@property uint16_t reg_pc;
@property (assign, nonatomic) uint8_t *memory;

- (void)writePrgRom: (uint8_t *)rom toAddress: (uint16_t)address;
- (void)enableZeroFlag;
- (void)disableZeroFlag;
- (void)enableInterrupts;
- (void)disableInterrupts;
- (void)enableDecimalFlag;
- (void)disableDecimalFlag;
- (uint8_t)checkFlag: (uint8_t)flag;

- (void)runNextInstruction;
- (void)run;

@end

enum opcodes {
    BPL = 0x10,
    CLD = 0xD8,
    LDA_ABS = 0xAD,
    LDA_IMM = 0xA9,
    LDX_IMM = 0xA2,
    LDY_IMM = 0xA0,
    SEI = 0x78,
    STA = 0x8D,
    TXS = 0x9A
};