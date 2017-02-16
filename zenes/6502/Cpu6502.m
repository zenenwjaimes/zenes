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
        //self.interruptPeriod = 7;
        [self bootupSequence];
        //self.delegate = (AppDelegate *)[[NSApplication sharedApplication] delegate];
    }
    return self;
}

- (void)bootupSequence {
    // Reset/Boot
    self.op1 = 0x00;
    self.op2 = 0x00;
    self.counter = 0;//self.interruptPeriod;
    self.reg_pc = 0x0000;
    self.reg_status = 0x00;
    self.reg_x = 0x00;
    self.reg_y = 0x00;
    self.reg_acc = 0x00;
    self.reg_sp = 0xFF;
    uint8_t tempMemory[0x10000] = {};
    
    //TODO: Set everything to 0xFF on bootup. this could be wrong
    for (int i = 0; i < 0x10000; i++) {
        tempMemory[i] = 0x00;
    }
    
    self.memory = tempMemory;
    
    // Clear interrupt flag and enable decimal mode on boot
    //[self enableInterrupts];
    self.reg_status ^= (-1 ^ self.reg_status) & (1 << STATUS_UNUSED_BIT);
    
    self.isRunning = YES;
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

// This means that interrupts CAN'T happen
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

- (void)enableOverflowFlag {
    self.reg_status |= (1 << STATUS_OVERFLOW_BIT);
}

- (void)disableOverflowFlag {
    self.reg_status &= ~ (1 << STATUS_OVERFLOW_BIT);
}

- (uint8_t)checkFlag: (uint8_t)flag {
    return (self.reg_status & (1 << flag));
}

- (void)triggerInterrupt: (int)interruptType {
    switch (interruptType) {
        case INT_RESET:
            break;
            
        case INT_IRQ:
            break;
            
        case INT_NMI:
            // Push current PC to the stack
            [self pushToStack: self.reg_pc >> 8];
            [self pushToStack: self.reg_pc];
            // set pc to the address stored at FFFD/FFFC (usually 0x8000)
            // TODO: FUCK
            self.reg_pc = (self.memory[0xFFFA] << 8) | (self.memory[0xFFFB]);
            self.interruptPeriod = INT_NMI;
            //NSLog(@"nmi: %X", self.reg_pc);
            // Push current reg status to stack
            [self pushToStack: self.reg_status];
            
            break;
    }
}

- (uint8_t)readZeroPage: (uint8_t)address {
    if (address > 0xFF) {
        @throw [NSException exceptionWithName: @"InvalidZeroPage" reason: @"Address passed is great than 0xFF" userInfo: nil];
    }
    uint8_t value = self.memory[address];
    
    return value;
}

/**
 * Wrap around back to 00 if it exceeds FF.
 * Mainly used for ZP X,Y
 *
 */
- (uint8_t)readZeroPage: (uint8_t)address withRegister: (uint8_t)reg {
    uint8_t value = ((self.memory[address] + reg) & 0xFF);
    
    return value;
}

- (void)writeZeroPage: (uint8_t)address withValue: (uint8_t)value {
    if (address > 0xFF) {
        @throw [NSException exceptionWithName: @"InvalidZeroPage" reason: @"Address passed is great than 0xFF" userInfo: nil];
    }
    
    self.memory[address] = value;
}

- (void)writeValue: (uint8_t)value toAbsoluteOp1: (uint8_t)absop1 andAbsoluteOp2: (uint8_t)absop2
{
    uint16_t address = (absop2 << 8 | absop1);
    [self writeValue: value toAddress: address];
}

- (void)writeValue: (uint8_t)value toAddress: (uint16_t)address
{
    self.memory[address] = value;
}

/**
 * Just a simple absolute lookup
 *
 */
- (uint8_t)readAbsoluteAddress1: (uint8_t)address1 address2: (uint8_t)address2 {
    return [self readIndexedAbsoluteAddress1: address1 address2: address2 withOffset: 0];
}

/**
 * An absolute lookup with an offset, this offset is usually reg x or reg y
 *
 */
- (uint8_t)readIndexedAbsoluteAddress1: (uint8_t)address1 address2: (uint8_t)address2 withOffset: (uint8_t)offset
{
    //uint32_t absoluteAddress = ((address2 << 8) | address1)+offset;
    uint16_t absoluteAddress = [self getIndexedAbsoluteAddress1: address1 address2: address2 withOffset: offset];
    
    // Don't wrap around, just throw an exception
    if (absoluteAddress > 0xFFFF) {
        @throw [NSException exceptionWithName: @"InvalidAbsoluteAddress" reason: @"Address passed is great than 0xFFFF" userInfo:nil];
    }
    
    return self.memory[absoluteAddress];
}

- (uint16_t)getIndexedAbsoluteAddress1: (uint8_t)address1 address2: (uint8_t)address2 withOffset: (uint8_t)offset
{
    return ((address2 << 8) | address1)+offset;
}

- (uint8_t)readIndexedIndirectAddressWithByte: (uint8_t)lowByte andOffset: (uint8_t)offset
{
    uint16_t indexIndirect = (self.memory[(lowByte + offset + 1) & 0xFF] << 8) | (self.memory[(lowByte + offset) & 0xFF]);
    //NSLog(@"indx high byte: %X", (self.memory[(lowByte + offset + 1) & 0xFF] << 8));
    //NSLog(@"indx low byte: %X", (self.memory[(lowByte + offset) & 0xFF]));
    //NSLog(@"indx index indirect: %X", indexIndirect);
    
    return self.memory[indexIndirect];
}

- (uint8_t)readIndirectIndexAddressWithByte: (uint8_t)lowByte andOffset: (uint8_t)offset
{
    uint16_t indirectIndexed = (((self.memory[(lowByte + 1) & 0xFF] << 8) | (self.memory[lowByte])) + offset) & 0xFFFF;
    
    //TODO: check if indirectIndexed before the & 0xFFFF, is the boundary is crossed
    //TODO: and increment the cycles by 1
    //NSLog(@"indy high byte: %X", (self.memory[(lowByte + 1) & 0xFF] << 8));
    //NSLog(@"indy low byte: %X", (self.memory[lowByte]));
    //NSLog(@"indy index indirect: %X", indirectIndexed);
    
    return self.memory[indirectIndexed];
}

- (uint16_t)getIndirectAddressWithLow: (uint8_t)lowByte andHigh: (uint8_t)highByte
{
    uint16_t tempAddress = ((highByte << 8) | lowByte);
    //NSLog(@"INDIRECT TEMP: %X", tempAddress);
    //NSLog(@"INDIRECT SHIFTED: %X", ((self.memory[tempAddress+1] & 0xFF) << 8) | self.memory[tempAddress]);
    return ((self.memory[tempAddress+1] & 0xFF) << 8) | self.memory[tempAddress];
}

- (uint16_t)getRelativeAddressWithAddress: (uint16_t)address andOffset: (uint8_t)offset {
    int16_t relativeAddress = 0x0000;
    
    if (offset >= 0x80) {
        relativeAddress = address-(256-offset);
        // TODO: find a better way to increment the counter, not here
        // wrap occurred, another cycle occurs
        self.counter += 1;
    } else {
        relativeAddress = address+offset;
    }
    //NSLog(@"Initial PC: %X", address);
    //NSLog(@"Offset is: %X", offset);
    //NSLog(@"Offset Address is: %X", relativeAddress);
    
    return relativeAddress;
}

- (void)toggleOverflowFlagForReg: (uint8_t)cpu_reg withBit: (uint8_t)bit {
    if ((1 << bit) & cpu_reg) {
        [self enableOverflowFlag];
    } else {
        [self disableOverflowFlag];
    }
}

- (void)toggleCarryFlagForReg: (uint8_t)cpu_reg
{
    // Sign flag set on CPU Reg
    if ((cpu_reg >> 7) & 1) {
        [self enableCarryFlag];
    } else {
        [self disableCarryFlag];
    }
}

- (void)toggleZeroAndSignFlagForReg: (uint8_t)cpu_reg
{
    // CPU Reg is 0, enable the zero flag
    if (cpu_reg == 0x00) {
        [self enableZeroFlag];
    } else {
        [self disableZeroFlag];
    }
    
    // Sign flag set on CPU Reg
    if ([BitHelper checkBit: 7 on: cpu_reg]) {
        [self enableSignFlag];
    } else {
        [self disableSignFlag];
    }
}

- (void)addWithCarry: (uint8_t)value
{
    uint16_t tempadd = self.reg_acc + value + [BitHelper checkBit: STATUS_CARRY_BIT on: self.reg_status];
    //uint8_t isOverflow = ((!(((self.reg_acc ^ value) & 0x80)!=0) && (((self.reg_acc ^ tempadd) & 0x80))!=0)?1:0);
    boolean_t isOverflow = [BitHelper checkBit: STATUS_NEGATIVE_BIT on: tempadd] != [BitHelper checkBit: STATUS_NEGATIVE_BIT on: self.reg_acc];
    
    if (isOverflow) {
        [self enableOverflowFlag];
    } else {
        [self disableOverflowFlag];
    }
    if (tempadd > 0xFF) {
        [self enableCarryFlag];
    }
    [self toggleZeroAndSignFlagForReg: tempadd];
    self.reg_acc = (tempadd & 0xFF);
}

- (void)pushToStack: (uint8_t)data {
    // Wraps around if need be. reg_sp will be lowered by 1
    [self writeZeroPage: 0x100+self.reg_sp withValue: data];
    self.reg_sp -= 1;
}

- (uint8_t)pullFromStack {
    // Wraps around if need be. reg_sp will be incremented by 1
    self.reg_sp += 1;
    return self.memory[0x100+self.reg_sp];
}

- (void)runNextInstruction {
    // Don't process instructions if not running
    if (self.isRunning == NO) {
        return;
    }
    // reset ops
    self.op1 = self.op2 = self.op3 = 0x0;
    
    enum opcodes opcode;
    opcode = self.memory[self.reg_pc];
    uint16_t currentPC = self.reg_pc;
    uint8_t currentRegStatus = self.reg_status;
    uint8_t currentRegX = self.reg_x;
    uint8_t currentRegY = self.reg_y;
    uint8_t currentRegA = self.reg_acc;
    uint8_t currentRegSP = self.reg_sp;
    uint8_t argCount = 0;
    
    // setup op1 and op2 even if they aren't used by the operation
    self.op1 = self.reg_pc+1;
    self.op2 = self.reg_pc+2;
    self.op3 = self.reg_pc+3;
    
    switch(opcode) {
        case ADC_IMM:
            argCount = 2;
            self.counter += 2;
            self.reg_pc += argCount;
            
            [self addWithCarry: self.memory[self.op1]];
            break;
        case AND_IMM:
            argCount = 2;
            self.reg_pc += argCount;
            self.counter += 2;
            self.reg_acc &= self.memory[self.op1];
            [self toggleZeroAndSignFlagForReg: self.reg_acc];
            
            break;
        case AND_ZP:
            argCount = 2;
            self.reg_pc += argCount;
            self.counter += 2;
            self.reg_acc &= [self readZeroPage: self.memory[self.op1]];
            [self toggleZeroAndSignFlagForReg: self.reg_acc];
            
            break;
        case AND_ZPX:
            argCount = 2;
            self.reg_pc += argCount;
            self.counter += 3;

            self.reg_acc &= [self readZeroPage: self.memory[self.op1] withRegister: self.reg_x];
            [self toggleZeroAndSignFlagForReg: self.reg_acc];
            
            break;
        case AND_ABS:
            argCount = 3;
            self.reg_pc += argCount;
            self.counter += 4;
            
            self.reg_acc &= [self readAbsoluteAddress1: self.memory[self.op1] address2: self.memory[self.op2]];
            [self toggleZeroAndSignFlagForReg: self.reg_acc];
            
            break;
        case AND_ABSX:
            argCount = 3;
            self.reg_pc += argCount;
            self.counter += 4;
            
            self.reg_acc &= [self readIndexedAbsoluteAddress1: self.memory[self.op1] address2: self.memory[self.op2] withOffset: self.reg_x];
            [self toggleZeroAndSignFlagForReg: self.reg_acc];
            
            break;
            
        case AND_ABSY:
            argCount = 3;
            self.reg_pc += argCount;
            self.counter += 4;
            
            self.reg_acc &= [self readIndexedAbsoluteAddress1: self.memory[self.op1] address2: self.memory[self.op2] withOffset: self.reg_y];
            [self toggleZeroAndSignFlagForReg: self.reg_acc];
            
            break;
            
        case AND_INDX:
            argCount = 2;
            self.reg_pc += argCount;
            self.counter += 6;
            
            self.reg_acc &= [self readIndexedIndirectAddressWithByte: self.memory[self.op1] andOffset: self.reg_x];
            [self toggleZeroAndSignFlagForReg: self.reg_acc];
            
            break;
            
        case AND_INDY:
            argCount = 2;
            self.reg_pc += argCount;
            self.counter += 5;
            
            self.reg_acc &= [self readIndirectIndexAddressWithByte: self.memory[self.op1] andOffset: self.reg_y];
            [self toggleZeroAndSignFlagForReg: self.reg_acc];
            
            break;
            
        case ASL_A:
            argCount = 1;
            self.reg_pc += argCount;
            uint8_t valueacc = self.reg_acc;
            [self toggleCarryFlagForReg: valueacc];

            uint8_t tempacc = (valueacc << 1) & 0xFE;
            self.reg_acc = tempacc;
            [self toggleZeroAndSignFlagForReg: self.reg_acc];
            
            self.counter += 2;
            break;
        case ASL_ZP:
            argCount = 2;
            self.reg_pc += argCount;
            self.counter += 5;
            uint8_t valuezp = [self readZeroPage: self.memory[self.op1]];
            
            [self toggleCarryFlagForReg: valuezp];
            uint8_t tempzp = (valuezp << 1) & 0xFE;
            
            [self writeZeroPage: self.memory[self.op1] withValue: tempzp];
            [self toggleOverflowFlagForReg: tempzp withBit: 7];
            [self toggleZeroAndSignFlagForReg: tempzp];
            break;
            
        case ASL_ZPX:
            argCount = 2;
            self.reg_pc += argCount;
            self.counter += 6;
            uint8_t valuezpx = [self readZeroPage: self.memory[self.op1] withRegister: self.reg_x];
            
            [self toggleCarryFlagForReg: valuezpx];
            uint8_t tempzpx = (valuezp << 1) & 0xFE;
            
            [self writeZeroPage: self.memory[self.op1] withValue: tempzpx];
            [self toggleOverflowFlagForReg: tempzpx withBit: 7];
            [self toggleZeroAndSignFlagForReg: tempzpx];
            break;
            
        case ASL_ABS:
            argCount = 3;
            self.reg_pc += argCount;
            self.counter += 6;
            uint8_t valueabs = [self readAbsoluteAddress1: self.memory[self.op1] address2: self.memory[self.op2]];
            
            [self toggleCarryFlagForReg: valueabs];
            uint8_t tempabs = (valueabs << 1) & 0xFE;
            
            [self writeValue: tempabs toAbsoluteOp1: self.memory[self.op1] andAbsoluteOp2: self.memory[self.op2]];
            [self toggleOverflowFlagForReg: tempabs withBit: 7];
            [self toggleZeroAndSignFlagForReg: tempabs];
            break;
        case ASL_ABSX:
            argCount = 3;
            self.reg_pc += argCount;
            self.counter += 7;
            uint8_t valueabsx = [self readIndexedAbsoluteAddress1: self.memory[self.op1] address2: self.memory[self.op2] withOffset: self.reg_x];
            
            [self toggleCarryFlagForReg: valueabsx];
            uint8_t tempabsx = (valueabsx << 1) & 0xFE;
            
            //[self writeValue: tempabsx toAbsoluteOp1: self.memory[self.op1] andAbsoluteOp2: self.memory[self.op2]];
            uint16_t aslabsxaddress = [self getIndexedAbsoluteAddress1: self.memory[self.op1] address2: self.memory[self.op2] withOffset: self.reg_x];
            //NSLog(@"asl absx write address: %X", aslabsxaddress);
            [self writeValue: tempabsx toAddress: aslabsxaddress];
            [self toggleOverflowFlagForReg: tempabsx withBit: 7];
            [self toggleZeroAndSignFlagForReg: tempabsx];
            break;
            
        case BCC:
            argCount = 2;
            self.reg_pc += argCount;
            self.counter += 2;
            // Branch if the carry bit is set
            if ([self checkFlag: STATUS_CARRY_BIT] == 0) {
                self.counter += 1;
                uint8_t relativeAddress = self.memory[self.op1];
                
                self.reg_pc = [self getRelativeAddressWithAddress: self.reg_pc andOffset: relativeAddress];
            }
            break;
            
        case BCS:
            argCount = 2;
            self.reg_pc += argCount;
            self.counter += 2;
            // Branch if the carry bit is set
            if ([self checkFlag: STATUS_CARRY_BIT] != 0) {
                self.counter += 1;
                uint8_t relativeAddress = self.memory[self.op1];
                
                self.reg_pc = [self getRelativeAddressWithAddress: self.reg_pc andOffset: relativeAddress];
            }
            break;
            
        case BEQ:
            argCount = 2;
            self.reg_pc += argCount;
            self.counter += 2;
            // Branch if the zero bit is not set
            if ([self checkFlag: STATUS_ZERO_BIT] != 0) {
                self.counter += 1;
                uint8_t relativeAddress = self.memory[self.op1];
                
                self.reg_pc = [self getRelativeAddressWithAddress: self.reg_pc andOffset: relativeAddress];
            }
            break;
            
        case BIT_ZP:
            argCount = 2;
            self.reg_pc += argCount;
            self.counter += 3;
            uint8_t value = [self readZeroPage: self.memory[self.op1]] & self.reg_acc;

            [self toggleZeroAndSignFlagForReg: value];
            [self toggleOverflowFlagForReg: value withBit: 6];
            break;
            
        case BMI:
            argCount = 2;
            self.reg_pc += argCount;
            self.counter += 2;
            // Branch if the zero bit is not set
            if ([self checkFlag: STATUS_NEGATIVE_BIT] != 0) {
                self.counter += 1;
                uint8_t relativeAddress = self.memory[self.op1];
                
                self.reg_pc = [self getRelativeAddressWithAddress: self.reg_pc andOffset: relativeAddress];
            }
            break;
            
        case BNE:
            argCount = 2;
            self.reg_pc += argCount;
            self.counter += 2;
            // Branch if the zero bit is not set
            if ([self checkFlag: STATUS_ZERO_BIT] == 0) {
                self.counter += 1;
                uint8_t relativeAddress = self.memory[self.op1];
                
                self.reg_pc = [self getRelativeAddressWithAddress: self.reg_pc andOffset: relativeAddress];
            }
            break;
            
        // Branch to PC+op1 if negative flag is 0
        case BPL:
            argCount = 2;
            self.reg_pc += argCount;
            self.counter += 2;
            // Branch if the negative bit is set

            if ([self checkFlag: STATUS_NEGATIVE_BIT] == 0) {
                self.counter += 1;
                uint8_t relativeAddress = self.memory[self.op1];
            
                self.reg_pc = [self getRelativeAddressWithAddress: self.reg_pc andOffset: relativeAddress];
            }
            
            break;
      
        case BVC:
            argCount = 2;
            self.reg_pc += argCount;
            self.counter += 2;
            // Branch if the overflow bit is clear
            if ([self checkFlag: STATUS_OVERFLOW_BIT] == 0) {
                self.counter += 1;
                uint8_t relativeAddress = self.memory[self.op1];
                
                self.reg_pc = [self getRelativeAddressWithAddress: self.reg_pc andOffset: relativeAddress];
            }
            
            break;
            
        case BVS:
            argCount = 2;
            self.reg_pc += argCount;
            self.counter += 2;
            // Branch if the overflow bit is set
            if ([self checkFlag: STATUS_OVERFLOW_BIT] != 0) {
                self.counter += 1;
                uint8_t relativeAddress = self.memory[self.op1];
                
                self.reg_pc = [self getRelativeAddressWithAddress: self.reg_pc andOffset: relativeAddress];
            }
            
            break;
            
        // CLC (Clear Carry Flag)
        case CLC:
            argCount = 1;
            [self disableCarryFlag];
            // Cycles: 2
            self.counter += 2;
            // 1 byte OP, jump to the next byte address
            self.reg_pc++;
            break;
            
        // CLD (Clear Decimal Flag)
        case CLD:
            argCount = 1;
            self.counter += 2;
            self.reg_pc++;
            [self disableDecimalFlag];
            break;

        case CLV:
            argCount = 1;
            self.counter += 2;
            self.reg_pc++;
            [self disableOverflowFlag];
            break;
            
        // CMP (Immediate)
        case CMP_IMM:
            argCount = 2;
            self.reg_pc += 2;
            self.counter += 2;
            uint8_t temp = (self.reg_acc - self.memory[self.op1]);
            
            [self toggleZeroAndSignFlagForReg: temp];
            if (self.reg_acc >= self.memory[self.op1]) {
                [self enableCarryFlag];
            }
            
            break;
            
        case CPX_IMM:
            argCount = 2;
            self.reg_pc += 2;
            self.counter += 2;
            
            uint8_t cmpx = self.reg_x - self.memory[self.op1];
            [self toggleZeroAndSignFlagForReg: cmpx];
            
            if (self.reg_x > self.memory[self.op1]) {
                [self enableCarryFlag];
            } else {
                [self disableCarryFlag];
            }
            
            break;
            
        case CPY_IMM:
            argCount = 2;
            self.reg_pc += argCount;
            self.counter += 2;
            
            uint8_t cmpy = self.reg_y - self.memory[self.op1];
            [self toggleZeroAndSignFlagForReg: cmpy];
            
            if (self.reg_y >= self.memory[self.op1]) {
                [self enableCarryFlag];
            } else {
                [self disableCarryFlag];
            }
            
            break;
            
        case CPY_ABS:
            argCount = 3;
            self.reg_pc += argCount;
            self.counter += 4;
            
            uint8_t cmpy_abs = self.reg_y - [self readAbsoluteAddress1: self.memory[self.op1] address2: self.memory[self.op2]];
            //NSLog(@"cmpy abs: %X", cmpy_abs);
            //NSLog(@"cmpy reg y: %X", self.reg_y);
            //NSLog(@"cmpy data at address: %X", [self readAbsoluteAddress1: self.memory[self.op1] address2: self.memory[self.op2]]);
            [self toggleZeroAndSignFlagForReg: cmpy_abs];
            
            if (self.reg_y >= [self readAbsoluteAddress1: self.memory[self.op1] address2: self.memory[self.op2]]) {
                [self enableCarryFlag];
            } else {
                [self disableCarryFlag];
            }
            
            break;
            
        case DEX:
            argCount = 1;
            self.reg_pc++;
            self.counter += 2;
            self.reg_x--;
            
            [self toggleZeroAndSignFlagForReg: self.reg_x];
            
            break;
            
        case DEY:
            argCount = 1;
            self.reg_pc++;
            self.counter += 2;
            self.reg_y--;
            
            [self toggleZeroAndSignFlagForReg: self.reg_y];
            
            break;
        case EOR_IMM:
            argCount = 2;
            self.reg_pc += 2;
            self.counter += 2;
            
            self.reg_acc ^= self.memory[self.op1];
            [self toggleZeroAndSignFlagForReg: self.reg_acc];
            
            break;
            //TODO: Memory fix
        case INC_ZP:
            argCount = 2;
            self.reg_pc += 2;
            self.counter += 5;
            
            [self writeZeroPage: self.memory[self.op1] withValue: ((self.memory[self.op1]+1) & 0xFF)];
            
            [self toggleZeroAndSignFlagForReg: [self readZeroPage: self.memory[self.op1]]];
            
            break;
        case INX:
            argCount = 1;
            self.reg_pc++;
            self.counter += 2;
            self.reg_x++;
            
            [self toggleZeroAndSignFlagForReg: self.reg_x];
            
            break;
            
        case INY:
            argCount = 1;
            self.reg_pc++;
            self.counter += 2;
            self.reg_y++;
            
            [self toggleZeroAndSignFlagForReg: self.reg_y];
            
            break;
        case JMP_ABS:
            argCount = 3;
            self.counter += 3;
            // TODO: FUCK
            self.reg_pc = (self.memory[self.op2] << 8 | self.memory[self.op1]);
            break;
            
        case JMP_IND:
            argCount = 3;
            self.counter += 5;
            self.reg_pc = [self getIndirectAddressWithLow: self.memory[self.op1] andHigh: self.memory[self.op2]];
            
            break;
        case JSR:
            argCount = 3;
            //self.reg_pc += 3;
            self.counter += 6;
            
            uint16_t stackPc = self.reg_pc-1;
            
            // Push new address to the stack and decrement the current PC
            [self pushToStack: stackPc >> 8];
            [self pushToStack: stackPc];
            //TODO: FUCK
            self.reg_pc = (self.memory[self.op2] << 8 | self.memory[self.op1]);
            
            // Cycles 6
            break;
        
        // LDA Absolute X
        case LDA_ABSX:
            argCount = 3;
            self.reg_pc += 3;
            // Cycles: 4
            // TODO: Check for page wrap, add one more cycle to the counter
            self.counter += 4;
            self.reg_acc = [self readIndexedAbsoluteAddress1: self.memory[self.op1] address2: self.memory[self.op2] withOffset: self.reg_x];
            [self toggleZeroAndSignFlagForReg: self.reg_acc];
            break;
        // LDA (Load Acc Immediate)
        case LDA_IMM:
            argCount = 2;
            self.reg_pc += 2;
            // Cycles: 2
            self.counter += 2;
            self.reg_acc = self.memory[self.op1];

            // 1 byte OP, jump to the next byte address
            // Accumulator is 0, enable the zero flag
            [self toggleZeroAndSignFlagForReg: self.reg_acc];
            break;
        
        // LDA_ZP (Load Acc ZP)
        case LDA_ZP:
            argCount = 2;
            self.reg_pc += 2;
            // Cycles: 2
            self.counter += 3;
            self.reg_acc = [self readZeroPage: self.memory[self.op1]];
            //NSLog(@"PC (%X) loading accumulator with: %X ", currentPC, self.memory[self.op1]);
            
            // 1 byte OP, jump to the next byte address
            // Accumulator is 0, enable the zero flag
            [self toggleZeroAndSignFlagForReg: self.reg_acc];
            break;
            
        // LDX (Load X Immediate)
        case LDX_IMM:
            argCount = 2;
            self.reg_pc += argCount;
            self.counter += 2;
            self.reg_x = self.memory[self.op1];

            [self toggleZeroAndSignFlagForReg: self.reg_x];
            break;
        
        case LDX_ABSY:
            argCount = 3;
            self.reg_pc += argCount;
            self.counter += 4;
            self.reg_x = [self readIndexedAbsoluteAddress1: self.memory[self.op1] address2: self.memory[self.op2] withOffset: self.reg_y];
            
            // 1 byte OP, jump to the next byte address
            // Accumulator is 0, enable the zero flag
            [self toggleZeroAndSignFlagForReg: self.reg_x];
            break;
            
        // TODO: Fix this and use actual memory methods instead
        case LDX_ABS:
            argCount = 3;
            self.reg_pc += 3;
            // Cycles: 4
            self.counter += 4;
            self.reg_x = self.memory[(self.memory[self.op2] << 8 | self.memory[self.op1])];
            
            // 1 byte OP, jump to the next byte address
            // Accumulator is 0, enable the zero flag
            [self toggleZeroAndSignFlagForReg: self.reg_x];
            break;

            // LDY (Load Y Immediate)
        case LDY_IMM:
            argCount = 2;
            self.reg_pc += 2;
            // Cycles: 2
            self.counter += 2;
            self.reg_y = self.memory[self.op1];
            // 1 byte OP, jump to the next byte address
            
            [self toggleZeroAndSignFlagForReg: self.reg_y];
            break;
            
        case LDA_INDY:
            argCount = 2;
            self.reg_pc += 2;
            self.counter += 5;
            
            // TODO: Adjust for the extra cycles on page boundaries
            self.reg_acc = [self readIndirectIndexAddressWithByte: self.memory[self.op1] andOffset: self.reg_y];
            //NSLog(@"reg acc for lda_indy: %X", self.reg_acc);
            [self toggleZeroAndSignFlagForReg: self.reg_acc];
            break;
            
        case LDY_ABS:
            argCount = 3;
            self.reg_pc += 3;
            // Cycles: 4
            self.counter += 4;
            self.reg_y = self.memory[(self.memory[self.op2] << 8 | self.memory[self.op1])];
            
            // 1 byte OP, jump to the next byte address
            // Accumulator is 0, enable the zero flag
            [self toggleZeroAndSignFlagForReg: self.reg_y];
            break;
            
        // LDA (Load Accumulator Absolute)
        case LDA_ABS:
            argCount = 3;
            self.reg_pc += 3;
            // Cycles: 4
            self.counter += 4;
            self.reg_acc = [self readAbsoluteAddress1: self.memory[self.op1] address2: self.memory[self.op2]];
            //NSLog(@"PC (%X) at low: %X high: %X loading accumulator with: %X ", currentPC, self.memory[self.op1], self.memory[self.op2], [self readAbsoluteAddress1: self.memory[self.op1] address2: self.memory[self.op2]]);

            //NSLog(@"self reg acc: %X", self.reg_acc);
            // 1 byte OP, jump to the next byte address
            // Accumulator is 0, enable the zero flag
            [self toggleZeroAndSignFlagForReg: self.reg_acc];
            break;
        case LSR_A:
            argCount = 1;
            self.reg_pc++;
            // Cycles: 4
            self.counter += 2;
            // Since the shift is right, the 7th bit of the value will always be 0
            // so we disable the sign flag
            [self disableSignFlag];
            uint8_t lsra = [self readZeroPage: self.reg_acc];
            uint8_t lsrtemp = (lsra >> 1) & 0x7F;
            
            if ([BitHelper checkBit: STATUS_CARRY_BIT on: self.reg_acc]) {
                [self enableCarryFlag];
            }
            
            if (lsrtemp == 0) [self enableZeroFlag];
            self.reg_acc = lsrtemp;
            break;
        //case LSR_ZP:
        //    break;
        //case LSR_ZPX:
        //    break;
        //case LSR_ABS:
        //    break;
        //case LSR_ABSX:
        //    break;
        // NOP (no operation, do nothing but decrement the counter and move on)
        case NOP:
            argCount = 1;
            self.counter +=1;
            self.reg_pc++;
            self.counter +=1;
            break;
        case ORA_IMM:
            argCount = 2;
            self.reg_pc += 2;
            self.counter += 2;
            self.reg_acc |= self.memory[self.op1];
            [self toggleZeroAndSignFlagForReg: self.reg_acc];
            
            break;
        // ORA on zero page address
        case ORA_ZP:
            argCount = 2;
            self.reg_acc |= [self readZeroPage: self.memory[self.op1]];
            self.reg_pc += 2;
            // Cycles
            self.counter += 3;
            [self toggleZeroAndSignFlagForReg: self.reg_acc];
            break;
        case PLA:
            argCount = 1;
            self.counter += 4;
            self.reg_pc++;
            self.reg_acc = [self pullFromStack];
            [self toggleZeroAndSignFlagForReg: self.reg_acc];
            break;
        case PLP:
            argCount = 1;
            self.counter += 4;
            self.reg_pc++;

            //NSLog(@"Current stack (%X) next SP (%X) at PC: %X", currentRegSP, currentPC);
            //for (uint8_t i = 0xFF; i >= 0xDD; i--) {
            //    NSLog(@"%X: %X", 0x100+i, self.memory[0x100+i]);
            //}
            
            self.reg_status = [self pullFromStack];
            break;
        case PHA:
            argCount = 1;
            self.counter += 3;
            self.reg_pc++;
            [self pushToStack: self.reg_acc];
            break;
        case PHP:
            argCount = 1;
            self.counter += 3;
            self.reg_pc++;
            [self pushToStack: self.reg_status];
            break;
        case RTS:
            argCount = 1;
            // 6 cycles
            self.counter += 6;
            // Pull the stack address and put it into the pc
            uint16_t little, big = 0x00;
            
            little = [self pullFromStack];
            big = [self pullFromStack];
            self.reg_pc = ((big << 8)| little)+1;
            break;
        case SBC_IMM:
            argCount = 2;
            self.counter += 2;
            self.reg_pc += 2;
            
            uint8_t tempsub = self.reg_acc - self.memory[self.op1] - (1-[BitHelper checkBit: STATUS_CARRY_BIT on: self.reg_status]);
            uint8_t tempsuboverflow = ((!(((self.reg_acc ^ self.memory[self.op1]) & 0x80)!=0) && (((self.reg_acc ^ tempsub) & 0x80))!=0)?1:0);
            
            if (tempsuboverflow != 0) {
                [self enableOverflowFlag];
            } else {
                [self disableOverflowFlag];
            }
            if (tempsub > 0x00) {
                [self enableCarryFlag];
            } else {
                [self disableCarryFlag];
            }
            [self toggleZeroAndSignFlagForReg: tempsub];
            self.reg_acc = (tempsub & 0xFF);
            break;
        // SEC (Set Carry)
        case SEC:
            argCount = 1;
            // 1 byte OP, jump to the next byte address
            self.reg_pc++;
            
            [self enableCarryFlag];
            // Cycles: 2
            self.counter += 2;
            break;
        case SED:
            argCount = 1;
            // 1 byte OP, jump to the next byte address
            self.reg_pc++;
            
            [self enableDecimalFlag];
            // Cycles: 2
            self.counter += 2;
            break;
        // SEI (Set Interrupt Disable)
        case SEI:
            argCount = 1;
            // 1 byte OP, jump to the next byte address
            self.reg_pc++;

            [self enableInterrupts];
            // Cycles: 2
            self.counter += 2;
            break;
            
        //TODO: Memory fix
        // STA_ABS (Store Accumulator Absolute)
        case STA_ABS:
            argCount = 3;
            // 1 byte OP, jump to the next byte address
            self.reg_pc += 3;
            //self.memory[(self.memory[self.op2] << 8 | self.memory[self.op1])] = self.reg_acc;
            [self writeValue: self.reg_acc toAbsoluteOp1: self.memory[self.op1] andAbsoluteOp2: self.memory[self.op2]];
            // Cycles: 4
            self.counter += 4;
            break;
            
            //TODO: Memory fix
            // STA_ABS (Store Accumulator Absolute)
        case STA_INDY:
            argCount = 2;
            // 1 byte OP, jump to the next byte address
            self.reg_pc += 2;
            // TODO: Adjust for the extra cycles on page boundaries
            // TODO: FUCK
            uint8_t low = self.memory[self.op1];
            uint16_t high = self.memory[(self.op1 + 1) & 0xFF];
            uint16_t location = ( (high | low) + self.reg_y) & 0xFFFF;
            self.reg_acc = self.memory[location];
            
            // Cycles: 4
            self.counter += 6;
            break;
        //TODO: Memory fix
        // STA_ZP (Store Accumulator Zero Page)
        case STA_ZP:
            argCount = 2;
            self.reg_pc += 2;
            // Cycles: 3
            self.counter += 3;
            [self writeZeroPage: self.memory[self.op1] withValue: self.reg_acc];
            break;
        //TODO: Memory fix
        // STX (Store X Zero Page)
        case STX_ZP:
            argCount = 2;
            self.reg_pc += 2;
            [self writeZeroPage: self.memory[self.op1] withValue: self.reg_x];
            // Cycles: 4
            self.counter += 4;
            // 1 byte OP, jump to the next byte address
            break;
        //TODO: Memory fix
        // STY (Store Y Zero Page)
        case STY_ZP:
            argCount = 2;
            self.reg_pc += 2;
            [self writeZeroPage: self.memory[self.op1] withValue: self.reg_y];
            // Cycles: 4
            self.counter += 4;
            // 1 byte OP, jump to the next byte address
            break;
        //TODO: Memory fix
        // STX (Store X Absolute Page)
        case STX_ABS:
            argCount = 3;
            self.reg_pc += 3;
            [self writeValue: self.reg_x toAbsoluteOp1: self.memory[self.op1] andAbsoluteOp2: self.memory[self.op2]];
            // Cycles: 4
            self.counter += 4;
            // 1 byte OP, jump to the next byte address
            break;
        //TODO: Memory fix
        // STY (Store Y Absolute Page)
        case STY_ABS:
            argCount = 3;
            self.reg_pc += 3;
            [self writeValue: self.reg_y toAbsoluteOp1: self.memory[self.op1] andAbsoluteOp2: self.memory[self.op2]];
            // Cycles: 4
            self.counter += 4;
            // 1 byte OP, jump to the next byte address
            break;
        case TAX:
            argCount = 1;
            self.reg_pc++;
            self.counter += 2;
            self.reg_x = self.reg_acc;
            
            [self toggleZeroAndSignFlagForReg: self.reg_x];
            break;
            
        case TXA:
            argCount = 1;
            self.reg_pc++;
            self.counter += 2;
            self.reg_acc = self.reg_x;
            
            [self toggleZeroAndSignFlagForReg: self.reg_acc];
            break;
            
        case TAY:
            argCount = 1;
            self.reg_pc++;
            self.counter += 2;
            self.reg_y = self.reg_acc;
            
            [self toggleZeroAndSignFlagForReg: self.reg_y];
            break;
            
        case TYA:
            argCount = 1;
            self.reg_pc++;
            self.counter += 2;
            self.reg_acc = self.reg_y;
            
            [self toggleZeroAndSignFlagForReg: self.reg_acc];
            break;
            
        case TXS:
            argCount = 1;
            self.reg_pc ++;
            self.counter += 2;
            
            [self pushToStack: self.reg_x];
            
            break;
            
        case TSX:
            argCount = 1;
            self.reg_pc ++;
            self.counter += 2;
            
            self.reg_x = self.reg_sp;
            break;
            
        // Unknown OP
        default:
            NSLog(@"OP not found: %X, next 3 bytes %X %X %X PC: %X", opcode, self.memory[self.op1], self.memory[self.op2], self.memory[self.op3], currentPC);
            self.isRunning = NO;
            //@throw [NSException exceptionWithName: @"Unknown OP" reason: @"Unknown OP" userInfo: nil];
            break;
    }
    
    // TODO: Clean this up, this is terrible
    NSString *line = nil;
    uint16 opcodeLength = 10-[[Cpu6502 getOpcodeName: opcode] length];
    NSString *opcodePadded = [Cpu6502 getOpcodeName: opcode];
    if (opcodeLength > 0) {
        NSString *padding = [[NSString string] stringByPaddingToLength: opcodeLength withString: @" " startingAtIndex: 0];
        opcodePadded = [opcodePadded stringByAppendingString: padding];
    }
    
    if (argCount == 1) {
        line = [NSString stringWithFormat: @"%X\t\t%X\t%@\t%@\t%@\t\t\tA:%X X:%X Y:%X P:%X SP:%X CYC:%d\n", currentPC, opcode, @"", @"", opcodePadded, currentRegA, currentRegX, currentRegY, currentRegStatus, currentRegSP, self.counter];
    } else if (argCount == 2) {
        line = [NSString stringWithFormat: @"%X\t\t%X\t%X\t%@\t%@\t\t\tA:%X X:%X Y:%X P:%X SP:%X CYC:%d\n", currentPC, opcode, self.memory[self.op1], @"", opcodePadded, currentRegA, currentRegX, currentRegY, currentRegStatus, currentRegSP, self.counter];
    } else if (argCount == 3) {
        line = [NSString stringWithFormat: @"%X\t\t%X\t%X\t%X\t%@\t\tA:%X X:%X Y:%X P:%X SP:%X CYC:%d\n", currentPC, opcode, self.memory[self.op1], self.memory[self.op2], opcodePadded, currentRegA, currentRegX, currentRegY, currentRegStatus, currentRegSP, self.counter];
    } else {
        line = [NSString stringWithFormat: @"OP not found: %X, next 3 bytes %X %X %X PC: %X", opcode, self.memory[self.op1], self.memory[self.op2], self.memory[self.op3], currentPC];
    }
    
    self.currentLine = line;
    

}

+ (NSString *)getOpcodeName: (uint8_t)opcode{
    NSString *opcodeName = nil;
    
    switch(opcode) {
        case ADC_IMM:
            opcodeName = @"ADC_IMM";
            break;
        case AND_ZP:
            opcodeName = @"AND_ZP";
            break;
        case AND_ZPX:
            opcodeName = @"AND_ZPX";
            break;
        case AND_ABS:
            opcodeName = @"AND_ABS";
            break;
        case AND_ABSX:
            opcodeName = @"AND_ABSX";
            break;
        case AND_ABSY:
            opcodeName = @"AND_ABSY";
            break;
        case AND_INDX:
            opcodeName = @"AND_INDX";
            break;
        case AND_INDY:
            opcodeName = @"AND_INDY";
            break;
        case ASL_A:
            opcodeName = @"ASL_A";
            break;
        case ASL_ZP:
            opcodeName = @"ASL_ZP";
            break;
        case ASL_ZPX:
            opcodeName = @"ASL_ZPX";
            break;
        case ASL_ABS:
            opcodeName = @"ASL_ABS";
            break;
        case ASL_ABSX:
            opcodeName = @"ASL_ABSX";
            break;
        case BCC:
            opcodeName = @"BCC";
            break;
        case BCS:
            opcodeName = @"BCS";
            break;
        case BEQ:
            opcodeName = @"BEQ";
            break;
        case BIT_ZP:
            opcodeName = @"BIT_ZP";
            break;
        case BMI:
            opcodeName = @"BMI";
            break;
        case BNE:
            opcodeName = @"BNE";
            break;
        case BPL:
            opcodeName = @"BPL";
            break;
        case BVC:
            opcodeName = @"BVC";
            break;
        case BVS:
            opcodeName = @"BVS";
            break;
            // CLC (Clear Carry Flag)
        case CLC:
            opcodeName = @"CLC";
            break;
            // CLD (Clear Decimal Flag)
        case CLD:
            opcodeName = @"CLD";
            break;
        case CLV:
            opcodeName = @"CLV";
            break;
            // CMP (Immediate)
        case CMP_IMM:
            opcodeName = @"CMP_IMM";
            break;
        case CPX_IMM:
            opcodeName = @"CPX_IMM";
            break;
        case CPY_IMM:
            opcodeName = @"CPY_IMM";
            break;
        case CPY_ZP:
            opcodeName = @"CPY_ZP";
            break;
        case CPY_ABS:
            opcodeName = @"CPY_ABS";
            break;
        case DEX:
            opcodeName = @"DEX";
            break;
        case DEY:
            opcodeName = @"DEY";
            break;
        case EOR_IMM:
            opcodeName = @"EOR_IMM";
            break;
        case INC_ZP:
            opcodeName = @"INC_ZP";
            break;
        case INX:
            opcodeName = @"INX";
            break;
        case INY:
            opcodeName = @"INY";
            break;
        case JMP_ABS:
            opcodeName = @"JMP_ABS";
            break;
        case JMP_IND:
            opcodeName = @"JMP_IND";
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
        case LDA_INDY:
            opcodeName = @"LDA_INDY";
            break;
            // LDX (Load X Immediate)
        case LDX_IMM:
            opcodeName = @"LDX_IMM";
            break;
        case LDX_ZP:
            opcodeName = @"LDX_ZP";
            break;
        case LDX_ZPY:
            opcodeName = @"LDX_ZPY";
            break;
        case LDX_ABSY:
            opcodeName = @"LDX_ABSY";
            break;
            // LDX (Load X ABS)
        case LDX_ABS:
            opcodeName = @"LDX_ABS";
            break;
            // LDY (Load Y Immediate)
        case LDY_IMM:
            opcodeName = @"LDY_IMM";
            break;
            // LDY (Load Y ABS)
        case LDY_ABS:
            opcodeName = @"LDY_ABS";
            break;
            // LDA (Load Accumulator Absolute)
        case LDA_ABS:
            opcodeName = @"LDA_ABS";
            break;
        case LDA_ZP:
            opcodeName = @"LDA_ZP";
            break;
            // NOP (no operation, do nothing but decrement the counter and move on)
        case LSR_A:
            opcodeName = @"LSR_A";
            break;
        case LSR_ZP:
            opcodeName = @"LSR_ZP";
            break;
        case LSR_ZPX:
            opcodeName = @"LSR_ZPX";
            break;
        case LSR_ABS:
            opcodeName = @"LSR_ABS";
            break;
        case LSR_ABSX:
            opcodeName = @"LSR_ABSX";
            break;
        case NOP:
            opcodeName = @"NOP";
            break;
        case ORA_IMM:
            opcodeName = @"ORA_IMM";
            break;
            // ORA on zero page address
        case ORA_ZP:
            opcodeName = @"ORA_ZP";
            break;
        case PLA:
            opcodeName = @"PLA";
            break;
        case PLP:
            opcodeName = @"PLP";
            break;
        case PHA:
            opcodeName = @"PHA";
            break;
        case PHP:
            opcodeName = @"PHP";
            break;
        case RTS:
            opcodeName = @"RTS";
            break;
        case SBC_IMM:
            opcodeName = @"SBC_IMM";
            break;
            // SEC (Set Carry)
        case SEC:
            opcodeName = @"SEC";
            break;
        case SED:
            opcodeName = @"SED";
            break;
            // SEI (Set Interrupt)
        case SEI:
            opcodeName = @"SEI";
            break;
            // STA_ABS (Store Accumulator ABS)
        case STA_ABS:
            opcodeName = @"STA_ABS";
            break;
        case STA_INDY:
            opcodeName = @"STA_INDY";
            break;
            // STA_ZP (Store Accumulator Zero Page)
        case STA_ZP:
            opcodeName = @"STA_ZP";
            break;
            // STX (Store X Zero Page)
        case STX_ZP:
            opcodeName = @"STX_ZP";
            break;
            // STY (Store Y Zero Page)
        case STY_ZP:
            opcodeName = @"STY_ZP";
            break;
        case STX_ABS:
            opcodeName = @"STX_ABS";
            break;
        case STY_ABS:
            opcodeName = @"STY_ABS";
            break;
        case TAX:
            opcodeName = @"TAX";
            break;
        case TXA:
            opcodeName = @"TXA";
            break;
        case TAY:
            opcodeName = @"TAY";
            break;
        case TYA:
            opcodeName = @"TYA";
            break;
        case TXS:
            opcodeName = @"TXS";
            break;
        case TSX:
            opcodeName = @"TSX";
            break;
            // Unknown OP
        default:
            opcodeName = @"Unknown";
            break;
    }
    
    return opcodeName;
}

- (void)dumpMemoryToLog {
    NSMutableArray *dump = [NSMutableArray arrayWithCapacity: 0xFFFF];
    if (self.isRunning == NO) {
        for (uint32_t i = 0; i < 0x10000; i++) {
            [dump addObject: [NSString stringWithFormat: @"%X->%X",i,self.memory[i]]];
        }
    }
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject: dump];
    [[NSFileManager defaultManager] createFileAtPath: @"/Users/slasherx/memory.plist" contents: data attributes: nil];
}

@end
