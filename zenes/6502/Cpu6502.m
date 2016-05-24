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
        self.reg_pc = 0x8000;
    }
    return self;
}

- (void)setMemory:(int8_t *)memory {
    memcpy(_memory, memory, sizeof(_memory));
}

- (int8_t *)memory {
    return _memory;
}

@end
