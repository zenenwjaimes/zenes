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
    self.reg_status = 0x00;//0x28;
    self.reg_x = 0;
    self.reg_y = 0;
    self.reg_acc = 0;
    self.reg_sp = 0x1FFF;
    uint8_t tempMemory[0xFFFF] = {};
    
    for (int i = 0; i < sizeof(tempMemory); i++) {
        tempMemory[i] = 0xFF;
    }
    
    self.memory = tempMemory;
    
    // Clear interrupt flag and enable decimal mode on boot
    self.reg_status ^= (-1 ^ self.reg_status) & (1 << STATUS_UNUSED_BIT);
    [self enableZeroFlag];
    [self clearInterruptsFlag];
    [self enableDecimalFlag];
}

- (void)setMemory:(uint8_t *)memory {
    memcpy(_memory, memory, sizeof(_memory));
}

- (uint8_t *)memory {
    return _memory;
}

- (void)enableZeroFlag {
    self.reg_status ^= (-1 ^ self.reg_status) & (1 << STATUS_ZERO_BIT);
}

// This means that interrupts CAN happen
- (void)clearInterruptsFlag {
    self.reg_status ^= (-1 ^ self.reg_status) & (0 << STATUS_IRQ_BIT);
}

- (void)enableDecimalFlag {
    self.reg_status ^= (-1 ^ self.reg_status) & (1 << STATUS_DECIMAL_BIT);
}

@end
