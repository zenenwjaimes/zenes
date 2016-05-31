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

@interface Cpu6502 : NSObject
{
    uint16_t _memory[0x10000];
}

@property uint8_t reg_acc;
@property uint8_t reg_x;
@property uint8_t reg_y;
@property uint16_t reg_sp;
@property uint8_t reg_status;
@property uint16_t reg_pc;
@property (assign, nonatomic) uint16_t *memory;

- (void)writePrgRom: (uint16_t *)rom toAddress: (uint16_t)address;
- (void)enableZeroFlag;
- (void)enableInterrupts;
- (void)disableInterrupts;
- (void)enableDecimalFlag;

@end