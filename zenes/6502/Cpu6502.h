//
//  Cpu.h
//  zenes
//
//  Created by zenen jaimes on 5/24/16.
//  Copyright © 2016 zenen jaimes. All rights reserved.
//

#import <Foundation/Foundation.h>
#include "ProcessorStatus.h"

@interface Cpu6502 : NSObject
{
    uint8_t _memory[0xFFFF];
}

@property uint8_t reg_acc;
@property uint8_t reg_x;
@property uint8_t reg_y;
@property uint16_t reg_sp;
@property uint8_t reg_status;
@property uint16_t reg_pc;
@property (assign, nonatomic) uint8_t *memory;

@end