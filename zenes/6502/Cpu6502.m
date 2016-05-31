//
//  Cpu.m
//  zenes
//
//  Created by zenen jaimes on 5/24/16.
//  Copyright © 2016 zenen jaimes. All rights reserved.
//

#import "Cpu6502.h"

@implementation Cpu6502

-(id)init {
    if (self = [super init]) {
        [self bootupSequence];
    }
    return self;
}

- (void)bootupSequence {
    //
    self.reg_pc = 0x8000;
    self.reg_status = 0x00;
    self.reg_x = 0;
    self.reg_y = 0;
    self.reg_acc = 0;
    self.reg_sp = 0x1FFF;
    uint16_t tempMemory[0x10000] = {};
    
    for (int i = 0; i < 0x10000; i++) {
        tempMemory[i] = 0xFF;
    }
    
    self.memory = tempMemory;
    
    // Clear interrupt flag and enable decimal mode on boot
    self.reg_status ^= (-1 ^ self.reg_status) & (1 << STATUS_UNUSED_BIT);
    [self enableZeroFlag];
    [self enableInterrupts];
    [self enableDecimalFlag];
    
    NSLog(@"Status Register: %@", [self intToBinary: self.reg_status]);
}

- (void)setMemory:(uint16_t *)memory {
    memcpy(_memory, memory, sizeof(_memory));
}

- (uint16_t *)memory {
    return _memory;
}

- (void)enableZeroFlag {
    //self.reg_status ^= (-1 ^ self.reg_status) & (1 << STATUS_ZERO_BIT);
    self.reg_status |= (1 << STATUS_ZERO_BIT);
}

// This means that interrupts CAN happen
- (void)enableInterrupts {
    self.reg_status |= (1 << STATUS_IRQ_BIT);
}

// This means that interrupts CAN happen
- (void)disableInterrupts {
    self.reg_status &= ~ (1 << STATUS_IRQ_BIT);
}

- (void)enableDecimalFlag {
    self.reg_status |= (1 << STATUS_DECIMAL_BIT);
    //self.reg_status ^= (-1 ^ self.reg_status) & (1 << STATUS_DECIMAL_BIT);
}

- (NSString *)intToBinary:(uint8_t)number {
    // Number of bits
    int bits =  sizeof(number) * 8;
    
    // Create mutable string to hold binary result
    NSMutableString *binaryStr = [NSMutableString string];
    
    // For each bit, determine if 1 or 0
    // Bitwise shift right to process next number
    for (; bits > 0; bits--, number >>= 1)
    {
        // Use bitwise AND with 1 to get rightmost bit
        // Insert 0 or 1 at front of the string
        [binaryStr insertString:((number & 1) ? @"1" : @"0") atIndex:0];
    }
    
    return (NSString *)binaryStr;
}

@end
