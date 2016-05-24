//
//  Cpu.h
//  zenes
//
//  Created by zenen jaimes on 5/24/16.
//  Copyright © 2016 zenen jaimes. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Register.h"

@interface Cpu6502 : NSObject
{
    int8_t _memory[0xFFFF];
}

@property int8_t reg_acc;
@property int8_t reg_x;
@property int8_t reg_y;
@property int8_t reg_sp;
@property int8_t reg_status;
@property int16_t reg_pc;
@property (assign, nonatomic) int8_t *memory;

@end