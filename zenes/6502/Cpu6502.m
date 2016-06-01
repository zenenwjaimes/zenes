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
        self.interruptPeriod = 7;
        [self bootupSequence];
    }
    return self;
}

- (void)bootupSequence {
    // Reset/Boot
    self.op1 = 0x0;
    self.op2 = 0x0;
    self.counter = self.interruptPeriod;
    self.reg_pc = 0x0;
    self.reg_status = 0x0;
    self.reg_x = 0x0;
    self.reg_y = 0x0;
    self.reg_acc = 0x0;
    self.reg_sp = 0x1FFF;
    uint8_t tempMemory[0x10000] = {};
    
    //TODO: Set everything to 0xFF on bootup. this could be wrong
    for (int i = 0; i < 0x10000; i++) {
        tempMemory[i] = 0xFF;
    }
    
    self.memory = tempMemory;
    
    // Clear interrupt flag and enable decimal mode on boot
    self.reg_status ^= (-1 ^ self.reg_status) & (1 << STATUS_UNUSED_BIT);
    [self enableZeroFlag];
    [self enableInterrupts];
    [self enableDecimalFlag];
    
    NSLog(@"Status Register: %@", [BitHelper intToBinary: self.reg_status]);
}

- (void)setMemory:(uint8_t *)memory {
    memcpy(_memory, memory, sizeof(_memory));
}

- (uint8_t *)memory {
    return _memory;
}

- (void)writePrgRom: (uint8_t *)rom toAddress: (uint16_t)address {
    for (int i = 0; i < 0x4000; i++) {
        self.memory[address+i] = rom[i];
    }
}

- (void)enableSignFlag {
    self.reg_status |= (1 << STATUS_NEGATIVE_BIT);
}

- (void)disableSignFlag {
    self.reg_status &= ~ (1 << STATUS_NEGATIVE_BIT);
}

- (void)enableZeroFlag {
    self.reg_status |= (1 << STATUS_ZERO_BIT);
}

- (void)disableZeroFlag {
    self.reg_status &= ~ (1 << STATUS_ZERO_BIT);
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
}

- (void)disableDecimalFlag {
    self.reg_status &= ~ (1 << STATUS_DECIMAL_BIT);
}

- (void)runNextInstruction {
    enum opcodes opcode;
    opcode = self.memory[self.reg_pc];
    self.op1 = self.op2 = 0x0;
    
    NSLog(@"next instruction: %X", opcode);
    NSLog(@"current pc: %X", self.reg_pc);
    
    switch(opcode) {
        // CLD (Clear Decimal Flag)
        case CLD:
            NSLog(@"clear decimal");
            [self disableDecimalFlag];
            // Cycles: 2
            self.counter -= 2;
            // 1 byte OP, jump to the next byte address
            self.reg_pc++;
            break;
            
        // LDA (Load Acc Immediate)
        case LDA_IMM:
            self.op1 = self.reg_pc+1;
            // Cycles: 2
            self.counter -= 2;
            self.reg_acc = self.memory[self.op1];
            // 1 byte OP, jump to the next byte address
            NSLog(@"lda imm");
            
            // Accumulator is 0, enable the zero flag
            if (self.reg_acc == 0x00) {
                [self enableZeroFlag];
            } else {
                [self disableZeroFlag];
            }
            
            // Sign flag is set if bit 7 is set on the accumulator
            if ((self.reg_acc >> 7) & 1) {
                [self enableSignFlag];
            } else {
                [self disableSignFlag];
            }
            
            self.reg_pc += 2;
            break;
        
        // LDX (Load X Immediate)
        case LDX_IMM:
            self.op1 = self.reg_pc+1;
            // Cycles: 2
            self.counter -= 2;
            self.reg_x = self.memory[self.op1];
            // 1 byte OP, jump to the next byte address
            NSLog(@"ldx imm: %X", self.reg_x);
            
            // Accumulator is 0, enable the zero flag
            if (self.reg_x == 0x00) {
                [self enableZeroFlag];
            } else {
                [self disableZeroFlag];
            }
            
            // Sign flag is set if bit 7 is set on the accumulator
            if ((self.reg_x >> 7) & 1) {
                [self enableSignFlag];
            } else {
                [self disableSignFlag];
            }
            
            self.reg_pc += 2;
            break;
            
        // SEI (Set Interrupt)
        case SEI:
            NSLog(@"set interrupt flag");
            [self enableInterrupts];
            // Cycles: 2
            self.counter -= 2;
            // 1 byte OP, jump to the next byte address
            self.reg_pc++;
            break;
            
        // STA (Store Accumulator Immediate)
        case STA:
            NSLog(@"store accumulator");
            self.op1 = self.reg_pc+1;
            self.op2 = self.reg_pc+2;
            self.memory[(self.memory[self.op2] << 8 | self.memory[self.op1])] = self.reg_acc;
            // Cycles: 2
            self.counter -= 4;
            // 1 byte OP, jump to the next byte address
            self.reg_pc += 3;
            break;
        
        // Unknown OP
        default:
            NSLog(@"OP not found: %X", opcode);
            @throw [NSException exceptionWithName: @"Unknown OP" reason: @"Unknown OP" userInfo: nil];
            break;
    }
    
    NSLog(@"status flag: %@", [BitHelper intToBinary: self.reg_status]);
}

- (void)run {
    [self runNextInstruction];
    
    if(self.counter <= 0)
    {
        self.counter += self.interruptPeriod;
    }
}

@end
