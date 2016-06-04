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
    self.op1 = 0x00;
    self.op2 = 0x00;
    self.counter = self.interruptPeriod;
    self.reg_pc = 0x0000;
    self.reg_status = 0x00;
    self.reg_x = 0x00;
    self.reg_y = 0x00;
    self.reg_acc = 0x00;
    self.reg_sp = 0x00;
    uint8_t tempMemory[0x10000] = {};
    
    //TODO: Set everything to 0xFF on bootup. this could be wrong
    for (int i = 0; i < 0x2000; i++) {
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

- (void)enableCarryFlag {
    self.reg_status |= (1 << STATUS_CARRY_BIT);
}

- (void)disableCarryFlag {
    self.reg_status &= ~ (1 << STATUS_CARRY_BIT);
}

- (uint8_t)checkFlag: (uint8_t)flag {
    return (self.reg_status & (1 << flag));
}

- (uint8_t)readZeroPage: (uint8_t)address {
    if (address > 0xFF) {
        @throw [NSException exceptionWithName: @"InvalidZeroPage" reason: @"Address passed is great than 0xFF" userInfo: nil];
    }
    uint8_t value = self.memory[address];
    
    return value;
}

// Address format is: (address2|address1)+offset
- (uint8_t)readAbsoluteAddress1: (uint8_t)address1 Address2: (uint8_t)address2 WithOffset: (uint8_t)offset {
    uint32_t absoluteAddress = 0x10009;//((address2 << 8) | address1)+offset;
    
    // Wrap around occurred, go back to the beginning page
    if (absoluteAddress > 0xFFFF) {
        absoluteAddress &= 0xFFFF;
        self.counter++;
    }
    
    NSLog(@"absolute address for %X, %X, %X: %X", (address2 << 8), address1, offset, absoluteAddress);
    NSLog(@"address: %X value: %X", absoluteAddress, self.memory[absoluteAddress]);
    return self.memory[absoluteAddress];
}

- (void)toggleZeroAndSignFlagForReg: (uint8_t)cpu_reg {
    // CPU Reg is 0, enable the zero flag
    if (cpu_reg == 0x00) {
        NSLog(@"Enable Zero Flag");
        [self enableZeroFlag];
    } else {
        NSLog(@"Disable Zero Flag");
        [self disableZeroFlag];
    }
    
    // Sign flag set on CPU Reg
    if ((cpu_reg >> 7) & 1) {
        NSLog(@"Enable Sign");
        [self enableSignFlag];
    } else {
        NSLog(@"Disable Sign");
        [self disableSignFlag];
    }
}

- (void)pushToStack: (uint8_t)data {
    // Wraps around if need be. reg_sp will be lowered by 1
    self.memory[0x100+self.reg_sp] = data;
    self.reg_sp--;
}

- (void)runNextInstruction {
    enum opcodes opcode;
    opcode = self.memory[self.reg_pc];
    
    // setup op1 and op2 even if they aren't used by the operation
    self.op1 = self.reg_pc+1;
    self.op2 = self.reg_pc+2;
    self.op3 = self.reg_pc+3;
    
    NSLog(@"Next Instruction (0x%X): %@", opcode, [Cpu6502 getOpcodeName: opcode]);
    NSLog(@"Current PC: %X", self.reg_pc);
    
    switch(opcode) {
        //TODO: Re check the logic on the BPL, rewrite the relative addressing
        // Branch to PC+op1 if negative flag is 0
        case BPL:
            self.reg_pc += 2;
            // Branch if the negative bit is set
            if ([self checkFlag: STATUS_NEGATIVE_BIT] == 0) {
                self.counter += 3;
                uint16_t relativeAddress = self.memory[self.op1];
                
                if (relativeAddress >= 0x80) {
                    relativeAddress += (self.reg_pc-1)-256;
                    relativeAddress &= 0xFFFF;
                    
                    self.reg_pc = relativeAddress;
                
                    // wrap occurred, another cycle occurs
                    self.counter += 1;
                } else {
                    self.reg_pc += relativeAddress;
                }
                // TODO: Check for different page here. If extra page used, make sure to add one more cycle
            } else {
                self.reg_pc += 2;
                self.counter += 2;
            }
            break;
            
        // CLC (Clear Carry Flag)
        case CLC:
            [self disableCarryFlag];
            // Cycles: 2
            self.counter += 2;
            // 1 byte OP, jump to the next byte address
            self.reg_pc++;
            break;
            
        // CLD (Clear Decimal Flag)
        case CLD:
            // 1 byte OP, jump to the next byte address
            self.reg_pc++;
            [self disableDecimalFlag];
            // Cycles: 2
            self.counter += 2;
            // 1 byte OP, jump to the next byte address
            self.reg_pc++;
            break;
        
        // CMP (Immediate)
        case CMP_IMM:
            self.counter += 2;
            uint8_t temp = (self.reg_acc - self.memory[self.op1]);
            NSLog(@"acc: %d", self.reg_acc);
            NSLog(@"op1 value: %d", self.memory[self.op1]);
            NSLog(@"%@", temp >= 0x80?@"greater than 0x80":@"not greater than 0x80");
            break;
            
        case JSR:
            self.reg_pc += 3;
            NSLog(@"high: %X", self.memory[self.op2]);
            NSLog(@"low: %X", self.memory[self.op1]);
            self.counter += 6;
            
            // Push new address to the stack and decrement the current PC
            [self pushToStack: self.memory[self.reg_pc-2]];
            [self pushToStack: self.memory[self.reg_pc-1]];
            self.reg_pc = ((self.memory[self.op2] << 8 | self.memory[self.op1]) - 1);
            
            // Cycles 6
            break;
        
        // LDA Absolute X
        case LDA_ABSX:
            self.reg_pc += 3;
            // Cycles: 4
            // TODO: Check for page wrap, add one more cycle to the counter
            self.counter += 4;
            self.reg_acc = [self readAbsoluteAddress1: self.memory[self.op1] Address2: self.memory[self.op2] WithOffset: self.memory[self.op3]];
            [self toggleZeroAndSignFlagForReg: self.reg_acc];
            break;
        // LDA (Load Acc Immediate)
        case LDA_IMM:
            self.reg_pc += 2;
            // Cycles: 2
            self.counter += 2;
            self.reg_acc = self.memory[self.op1];
            
            // 1 byte OP, jump to the next byte address
            // Accumulator is 0, enable the zero flag
            [self toggleZeroAndSignFlagForReg: self.reg_acc];
            break;
        
        // LDX (Load X Immediate)
        case LDX_IMM:
            self.reg_pc += 2;
            // Cycles: 2
            self.counter += 2;
            self.reg_x = self.memory[self.op1];
            
            // 1 byte OP, jump to the next byte address
            // Accumulator is 0, enable the zero flag
            [self toggleZeroAndSignFlagForReg: self.reg_x];
            break;

            // LDY (Load Y Immediate)
        case LDY_IMM:
            self.reg_pc += 2;
            // Cycles: 2
            self.counter += 2;
            self.reg_y = self.memory[self.op1];
            // 1 byte OP, jump to the next byte address
            
            [self toggleZeroAndSignFlagForReg: self.reg_y];
            break;
            
        // LDA (Load Accumulator Absolute)
        case LDA_ABS:
            self.reg_pc += 3;
            // Cycles: 4
            self.counter += 4;
            self.reg_acc = self.memory[(self.memory[self.op2] << 8 | self.memory[self.op1])];
            
            // 1 byte OP, jump to the next byte address
            // Accumulator is 0, enable the zero flag
            [self toggleZeroAndSignFlagForReg: self.reg_acc];
            break;
        // NOP (no operation, do nothing but decrement the counter and move on)
        case NOP:
            self.counter +=1;
            self.reg_pc++;
            self.counter -=1;
            break;
        // ORA on zero page address
        case ORA_ZP:
            self.reg_pc += 2;
            self.reg_acc |= [self readZeroPage: self.memory[self.op1]];
            // Cycles
            self.counter += 3;
            [self toggleZeroAndSignFlagForReg: self.reg_acc];
            break;
        // SEI (Set Interrupt)
        case SEI:
            // 1 byte OP, jump to the next byte address
            self.reg_pc++;

            [self enableInterrupts];
            // Cycles: 2
            self.counter += 2;
            // 1 byte OP, jump to the next byte address
            self.reg_pc++;
            break;
            
        // STA (Store Accumulator Immediate)
        case STA:
            // 1 byte OP, jump to the next byte address
            self.reg_pc += 3;
            self.memory[(self.memory[self.op2] << 8 | self.memory[self.op1])] = self.reg_acc;
            // Cycles: 4
            self.counter += 4;
            // 1 byte OP, jump to the next byte address
            self.reg_pc += 3;
            break;
            
        // STX (Store X Zero Page)
        case STX_ZP:
            self.reg_pc += 2;
            self.reg_x = [self readZeroPage: self.memory[self.op1]];
            // Cycles: 4
            self.counter += 4;
            // 1 byte OP, jump to the next byte address
            break;
            
        // STY (Store Y Zero Page)
        case STY_ZP:
            self.reg_pc += 2;
            self.reg_y = [self readZeroPage: self.memory[self.op1]];
            // Cycles: 4
            self.counter += 4;
            // 1 byte OP, jump to the next byte address
            break;
            
        case TXS:
            // 1 byte OP, jump to the next byte address
            self.reg_pc ++;

            [self pushToStack: self.reg_x];
            NSLog(@"stack pointer: %X", self.reg_sp);
            // Cycles: 2
            self.counter += 2;
            // 1 byte OP, jump to the next byte address
            self.reg_pc++;
            
            break;
            
        // Unknown OP
        default:
            NSLog(@"Zero byte read: %X", [self readZeroPage: self.memory[self.op1]]);
            NSLog(@"OP not found: %X, next 3 bytes %X %X %X", opcode, self.memory[self.op1], self.memory[self.op2], self.memory[self.op3]);
            @throw [NSException exceptionWithName: @"Unknown OP" reason: @"Unknown OP" userInfo: nil];
            break;
    }
    
    // reset ops
    self.op1 = self.op2 = self.op3 = 0x0;
    NSLog(@"status flag: %@", [BitHelper intToBinary: self.reg_status]);
    NSLog(@"ACC state: %d", self.reg_acc);
}

- (void)run {
    [self runNextInstruction];
    
    if(self.counter <= 0)
    {
        self.counter += self.interruptPeriod;
    }
}

+ (NSString *)getOpcodeName: (uint8_t)opcode{
    NSString *opcodeName = nil;
    
    switch(opcode) {
        case BPL:
            opcodeName = @"BPL";
            break;
            
            // CLC (Clear Carry Flag)
        case CLC:
            opcodeName = @"CLC";
            break;
            
            // CLD (Clear Decimal Flag)
        case CLD:
            opcodeName = @"CLD";
            break;
            
            // CMP (Immediate)
        case CMP_IMM:
            opcodeName = @"CMP_IMM";
            break;
            
        case JSR:
            opcodeName = @"JSR";
            break;
            
            // LDA Absolute X
        case LDA_ABSX:
            opcodeName = @"LDA_ABSX";
            break;
            // LDA (Load Acc Immediate)
        case LDA_IMM:
            opcodeName = @"LDA_IMM";
            break;
            
            // LDX (Load X Immediate)
        case LDX_IMM:
            opcodeName = @"LDX_IMM";
            break;
            
            // LDY (Load Y Immediate)
        case LDY_IMM:
            opcodeName = @"LDY_IMM";
            break;
            
            // LDA (Load Accumulator Absolute)
        case LDA_ABS:
            opcodeName = @"LDA_ABS";
            break;
            // NOP (no operation, do nothing but decrement the counter and move on)
        case NOP:
            opcodeName = @"NOP";
            break;
            // ORA on zero page address
        case ORA_ZP:
            opcodeName = @"ORA_ZP";
            break;
            // SEI (Set Interrupt)
        case SEI:
            opcodeName = @"SEI";
            break;
            
            // STA (Store Accumulator Immediate)
        case STA:
            opcodeName = @"STA_IMM";
            break;
            
            // STX (Store X Zero Page)
        case STX_ZP:
            opcodeName = @"STX_ZP";
            break;
            
            // STY (Store Y Zero Page)
        case STY_ZP:
            opcodeName = @"STY_ZP";
            break;
            
        case TXS:
            opcodeName = @"TXS";
            
            break;
            
            // Unknown OP
        default:
            opcodeName = @"Unknown";
            break;
    }
    
    return opcodeName;
}

@end
