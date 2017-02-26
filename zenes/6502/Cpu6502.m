//
//  Cpu.m
//  zenes
//
//  Created by zenen jaimes on 5/24/16.
//  Copyright © 2016 zenen jaimes. All rights reserved.
//

#import "Nes.h"
#import "Cpu6502.h"
#import "Ppu.h"
#import "AppDelegate.h"

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
    self.joystickCounter = 0;
    uint8_t tempMemory[0x10000] = {};
    
    //TODO: Set everything to 0xFF on bootup. this could be wrong
    for (long i = 0; i < 0x10000; i++) {
        tempMemory[i] = 0x00;
    }
    
    //self.memory = tempMemory;
    [self setMemory: tempMemory];
    
    // Clear interrupt flag and enable decimal mode on boot
    //[self enableInterrupts];
    self.reg_status = 0x00;//(-1 ^ self.reg_status) & (1 << STATUS_UNUSED_BIT);
    
    self.isRunning = YES;
    
    // Hack for notifying the ppu of changes
    self.notifyPpu = NO;
    self.notifyPpuAddress = 0x0000;
    //[self.ppu che];
}

- (void)setMemory:(uint8_t *)memory {
    memcpy(_memory, memory, sizeof(_memory));
}

- (uint8_t *)memory {
    return _memory;
}

- (void)writePrgRom: (uint8_t *)rom toAddress: (uint16_t)address {
    for (long i = 0; i < 0x4000; i++) {
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
            [self pushToStack: self.reg_status];
            
            self.reg_pc = (self.memory[0xFFFB] << 8) | (self.memory[0xFFFA]);
            self.interruptPeriod = INT_NMI;
            [self enableInterrupts];
            
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
    uint8_t value = ((self.memory[(address + reg) & 0xFF]));
    
    return value;
}

- (void)writeZeroPage: (uint8_t)address withValue: (uint8_t)value {
    if (address > 0xFF) {
        @throw [NSException exceptionWithName: @"InvalidZeroPage" reason: @"Address passed is great than 0xFF" userInfo: nil];
    }
    
    self.memory[address] = value;
}

- (void)writeZeroPage: (uint8_t)address withValue: (uint8_t)value withRegister: (uint8_t)reg {
    self.memory[((address + reg) & 0xFF)] = value;
}

- (void)writeValue: (uint8_t)value toAbsoluteOp1: (uint8_t)absop1 andAbsoluteOp2: (uint8_t)absop2
{
    uint16_t address = (absop2 << 8 | absop1);
    [self writeValue: value toAddress: address];
}

- (void)writeValue: (uint8_t)value toAddress: (uint16_t)address
{
    self.memory[address] = value;
    
    // Send any notifications to the PPU about changes to regs
    if (address >= 0x2000 && address <= 0x2007) {
        self.ppuReg1 = self.memory[0x2000];//[self readValueAtAddress: 0x2000];
        self.ppuReg2 = self.memory[0x2001];//[self readValueAtAddress: 0x2001];
        self.notifyPpu = YES;
        self.notifyPpuAddress = address;
        self.notifyPpuWrite = YES;
        self.notifyPpuValue = value;
        
        [self.ppu observeCpuChanges];
    }
}

- (uint8_t)readValueAtAddress: (uint16_t)address
{
    if (address == 0x4016) {
        [self.nes buttonStrobe: self.joystickCounter];
        
        self.joystickCounter++;
        if (self.joystickCounter > 7) {
            self.joystickCounter = 0;
        }
    }
    
    uint8_t value = self.memory[address];
    if (address >= 0x2000 && address <= 0x2000) {
        self.ppuReg1 = [self readValueAtAddress: 0x2000];
        self.ppuReg2 = [self readValueAtAddress: 0x2001];

        self.notifyPpuWrite = NO;
        self.notifyPpuAddress = address;
        [self.ppu observeCpuChanges];
    }
    
    return value;
}

/**
 * Just a simple absolute lookup
 *
 */
- (uint8_t)readAbsoluteAddress1: (uint8_t)address1 address2: (uint8_t)address2
{
    return [self readIndexedAbsoluteAddress1: address1 address2: address2 withOffset: 0];
}

- (void)writeAbsoluteAddress1: (uint8_t)address1 address2: (uint8_t)address2 andOffset: (uint8_t)offset withValue: (uint8_t)value
{
    uint16_t absoluteAddress = [self getIndexedAbsoluteAddress1: address1 address2: address2 withOffset: offset];

    //return [self readIndexedAbsoluteAddress1: address1 address2: address2 withOffset: 0];
    [self writeValue: value toAddress: absoluteAddress];
}

/**
 * An absolute lookup with an offset, this offset is usually reg x or reg y
 *
 */
- (uint8_t)readIndexedAbsoluteAddress1: (uint8_t)address1 address2: (uint8_t)address2 withOffset: (uint8_t)offset
{
    uint16_t absoluteAddress = [self getIndexedAbsoluteAddress1: address1 address2: address2 withOffset: offset];
    
    // Don't wrap around, just throw an exception
    if (absoluteAddress > 0xFFFF) {
        @throw [NSException exceptionWithName: @"InvalidAbsoluteAddress" reason: @"Address passed is great than 0xFFFF" userInfo:nil];
    }
    
    return [self readValueAtAddress: absoluteAddress];
}

- (uint16_t)getIndexedAbsoluteAddress1: (uint8_t)address1 address2: (uint8_t)address2 withOffset: (uint8_t)offset
{
    return ((address2 << 8) | address1)+offset;
}

- (uint8_t)readIndexedIndirectAddressWithByte: (uint8_t)lowByte andOffset: (uint8_t)offset
{
    uint16_t indexIndirect = (self.memory[(lowByte + offset + 1) & 0xFF] << 8) | (self.memory[(lowByte + offset) & 0xFF]);
    return [self readValueAtAddress: indexIndirect];
}

- (uint8_t)readIndirectIndexAddressWithByte: (uint8_t)lowByte andOffset: (uint8_t)offset
{
    uint16_t lowIndirectIndexed = self.memory[lowByte];
    uint16_t highIndirectIndexed = self.memory[(lowByte + 1) & 0xFF] << 8;
    uint16_t indirectIndexed = ((highIndirectIndexed | lowIndirectIndexed) + offset) & 0xFFFF;

    return [self readValueAtAddress: indirectIndexed];
}

- (void)writeIndirectIndexWithByte: (uint8_t)lowByte andOffset: (uint8_t)offset withValue: (uint8_t)value
{
    uint16_t lowIndirectIndexed = self.memory[lowByte];
    uint16_t highIndirectIndexed = self.memory[(lowByte + 1) & 0xFF] << 8;
    uint16_t indirectIndexed = ((highIndirectIndexed | lowIndirectIndexed) + offset) & 0xFFFF;
    [self writeValue: value toAddress: indirectIndexed];
}

- (uint16_t)getIndirectAddressWithLow: (uint8_t)lowByte andHigh: (uint8_t)highByte
{
    uint16_t tempAddress = ((highByte << 8) | lowByte);
    
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

- (void)subtractWithCarry: (uint8_t)value
{
    uint8_t tempsub = self.reg_acc - value - ([BitHelper checkBit: STATUS_CARRY_BIT on: self.reg_status]?0:1);
    uint8_t tempsuboverflow = ((!(((self.reg_acc ^ value) & 0x80)!=0) && (((self.reg_acc ^ tempsub) & 0x80))!=0)?1:0);
    
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
}

- (uint8_t)rotateLeft: (uint8_t)value
{
    uint8_t rolzp_shifted = (value << 1) & 0xFE;
    rolzp_shifted |= [self checkFlag: STATUS_CARRY_BIT];
    
    if ([BitHelper checkBit: 7 on: value]) {
        [self enableCarryFlag];
    } else {
        [self disableCarryFlag];
    }
    
    [self toggleZeroAndSignFlagForReg: rolzp_shifted];
    
    return rolzp_shifted;
}

- (uint8_t)rotateRight: (uint8_t)value
{
    uint8_t rorzp_shifted = (value >> 1) & 0x7F;
    
    rorzp_shifted |= ([self checkFlag: STATUS_CARRY_BIT]?0x80:0x00);
    
    if ([BitHelper checkBit: 0 on: value]) {
        [self enableCarryFlag];
    } else {
        [self disableCarryFlag];
    }
    
    [self toggleZeroAndSignFlagForReg: rorzp_shifted];
    
    return rorzp_shifted;
}

- (uint8_t)logicalShiftRight: (uint8_t)value
{
    // Since the shift is right, the 7th bit of the value will always be 0
    // so we disable the sign flag
    [self disableSignFlag];
    uint8_t lsrtemp = (value >> 1) & 0x7F;
    
    if ([BitHelper checkBit: STATUS_CARRY_BIT on: value]) {
        [self enableCarryFlag];
    } else {
        [self disableCarryFlag];
    }
    
    if (lsrtemp == 0) {
        [self enableZeroFlag];
    } else {
        [self disableZeroFlag];
    }
    
    return lsrtemp;
}

- (void)pushToStack: (uint8_t)data {
    // Wraps around if need be. reg_sp will be lowered by 1
    [self writeValue: data toAddress: 0x100+self.reg_sp];
    self.reg_sp -= 1;
}

- (uint8_t)pullFromStack {
    // Wraps around if need be. reg_sp will be incremented by 1
    self.reg_sp += 1;
    return [self readAbsoluteAddress1: self.reg_sp address2: 0x01];
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
        case ADC_ZP:
            argCount = 2;
            self.counter += 3;
            self.reg_pc += argCount;
            
            [self addWithCarry: [self readZeroPage: self.memory[self.op1]]];
            break;
            
        case ADC_ABS:
            argCount = 3;
            self.counter += 4;
            self.reg_pc += argCount;
            
            [self addWithCarry: [self readAbsoluteAddress1: self.memory[self.op1] address2: self.memory[self.op2]]];
            break;
            
        case ADC_ABSY:
            argCount = 3;
            self.counter += 4;
            self.reg_pc += argCount;
            
            [self addWithCarry: [self readIndexedAbsoluteAddress1: self.memory[self.op1] address2: self.memory[self.op2] withOffset: self.reg_y]];
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
            
            uint16_t aslabsxaddress = [self getIndexedAbsoluteAddress1: self.memory[self.op1] address2: self.memory[self.op2] withOffset: self.reg_x];
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
            
        case BIT_ABS:
            argCount = 3;
            self.reg_pc += argCount;
            self.counter += 3;
            uint8_t bitabs = [self readAbsoluteAddress1: self.memory[self.op1] address2: self.memory[self.op1]] & self.reg_acc;
            
            [self toggleZeroAndSignFlagForReg: bitabs];
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
            } else {
                
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
            self.reg_pc += argCount;
            self.counter += 2;
            uint8_t temp = (self.reg_acc - self.memory[self.op1]);
            
            [self toggleZeroAndSignFlagForReg: temp];
            if (self.reg_acc >= self.memory[self.op1]) {
                [self enableCarryFlag];
            } else {
                [self disableCarryFlag];
            }
            
            break;
            
        case CMP_ZP:
            argCount = 2;
            self.reg_pc += argCount;
            self.counter += 2;
            uint8_t tempcmpzp = (self.reg_acc - [self readZeroPage: self.memory[self.op1]]);
            
            [self toggleZeroAndSignFlagForReg: tempcmpzp];
            if (self.reg_acc >= [self readZeroPage: self.memory[self.op1]]) {
                [self enableCarryFlag];
            } else {
                [self disableCarryFlag];
            }
            
            break;
            
        case CMP_ZPX:
            argCount = 2;
            self.reg_pc += argCount;
            self.counter += 2;
            uint8_t tempcmpzpx = (self.reg_acc - [self readZeroPage: self.memory[self.op1] withRegister: self.reg_x]);
            
            [self toggleZeroAndSignFlagForReg: tempcmpzpx];
            if (self.reg_acc >= [self readZeroPage: self.memory[self.op1] withRegister: self.reg_x]) {
                [self enableCarryFlag];
            } else {
                [self disableCarryFlag];
            }
            
            break;
            
        case CMP_ABSY:
            argCount = 3;
            self.reg_pc += argCount;
            self.counter += 4;
            uint8_t tempcmpabsy = (self.reg_acc - [self readIndexedAbsoluteAddress1: self.memory[self.op1] address2: self.memory[self.op2] withOffset: self.reg_y]);
            
            [self toggleZeroAndSignFlagForReg: tempcmpabsy];
            if (self.reg_acc >= [self readIndexedAbsoluteAddress1: self.memory[self.op1] address2: self.memory[self.op2] withOffset: self.reg_y]) {
                [self enableCarryFlag];
            } else {
                [self disableCarryFlag];
            }
            
            break;
            
        case CMP_ABS:
            argCount = 3;
            self.reg_pc += argCount;
            self.counter += 4;
            uint8_t tempcmpabs = (self.reg_acc - [self readAbsoluteAddress1: self.memory[self.op1] address2: self.memory[self.op2]]);
            
            [self toggleZeroAndSignFlagForReg: tempcmpabs];
            if (self.reg_acc >= [self readAbsoluteAddress1: self.memory[self.op1] address2: self.memory[self.op2]]) {
                [self enableCarryFlag];
            } else {
                [self disableCarryFlag];
            }
            
            break;
            
        case CPX_IMM:
            argCount = 2;
            self.reg_pc += 2;
            self.counter += 2;
            
            uint8_t cmpx = self.reg_x - self.memory[self.op1];
            [self toggleZeroAndSignFlagForReg: cmpx];
            
            if (self.reg_x >= self.memory[self.op1]) {
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
            

            self.reg_x = (self.reg_x - 1) & 0xFF;
            [self toggleZeroAndSignFlagForReg: self.reg_x];
            
            break;
            
        case DEY:
            argCount = 1;
            self.reg_pc++;
            self.counter += 2;
            
            self.reg_y = (self.reg_y - 1) & 0xFF;
            [self toggleZeroAndSignFlagForReg: self.reg_y];
            
            break;
            
            
        case DEC_ZP:
            argCount = 2;
            self.reg_pc += argCount;
            self.counter += 5;

            uint8_t deczp = [self readZeroPage: self.memory[self.op1]];
            deczp = (deczp - 1) & 0xFF;
            [self writeZeroPage: self.memory[self.op1] withValue: deczp];
            [self toggleZeroAndSignFlagForReg: deczp];
            
            break;
            
        case DEC_ZPX:
            argCount = 2;
            self.reg_pc += argCount;
            self.counter += 6;
            
            uint8_t deczpx = [self readZeroPage: self.memory[self.op1] withRegister: self.reg_x];
            deczpx = (deczpx - 1) & 0xFF;

            [self writeZeroPage: self.memory[self.op1] withValue: deczpx];
            [self toggleZeroAndSignFlagForReg: deczpx];
            
            break;
            
        case DEC_ABS:
            argCount = 3;
            self.reg_pc += argCount;
            self.counter += 6;
            
            uint8_t decabs = [self readAbsoluteAddress1: self.memory[self.op1] address2: self.memory[self.op2]];
            decabs = (decabs - 1) & 0xFF;
            [self writeValue: decabs toAbsoluteOp1: self.memory[self.op1] andAbsoluteOp2: self.memory[self.op1]];
            [self toggleZeroAndSignFlagForReg: decabs];
            
            break;
            
        case DEC_ABSX:
            argCount = 3;
            self.reg_pc += argCount;
            self.counter += 7;
            
            uint8_t decabsx = [self readIndexedAbsoluteAddress1: self.memory[self.op1] address2: self.memory[self.op2] withOffset: self.reg_x];
            decabsx = (decabsx - 1) & 0xFF;

            uint16_t decabsxAddy = [self getIndexedAbsoluteAddress1: self.memory[self.op1] address2: self.memory[self.op2] withOffset: self.reg_x];
            [self writeValue: decabsx toAddress: decabsxAddy];
            [self toggleZeroAndSignFlagForReg: decabsx];
            
            break;
            
        case EOR_IMM:
            argCount = 2;
            self.reg_pc += argCount;
            self.counter += 2;
            
            self.reg_acc ^= self.memory[self.op1];
            [self toggleZeroAndSignFlagForReg: self.reg_acc];
            
            break;
        case EOR_ZP:
            argCount = 2;
            self.reg_pc += argCount;
            self.counter += 3;
            
            self.reg_acc ^= [self readZeroPage: self.memory[self.op1]];
            [self toggleZeroAndSignFlagForReg: self.reg_acc];
            
            break;
        case EOR_ZPX:
            argCount = 2;
            self.reg_pc += argCount;
            self.counter += 4;
            
            self.reg_acc ^= [self readZeroPage: self.memory[self.op1] withRegister: self.reg_x];
            [self toggleZeroAndSignFlagForReg: self.reg_acc];
            
            break;
        case INC_ZP:
            argCount = 2;
            self.reg_pc += argCount;
            self.counter += 5;
            uint8_t inczp = [self readZeroPage: self.memory[self.op1]];
            [self writeZeroPage: self.memory[self.op1] withValue: ((inczp+1) & 0xFF)];
            
            [self toggleZeroAndSignFlagForReg: [self readZeroPage: self.memory[self.op1]]];
            
            break;
            
        case INC_ABS:
            argCount = 3;
            self.reg_pc += argCount;
            self.counter += 6;
            
            uint8_t incabs = ([self readAbsoluteAddress1: self.memory[self.op1] address2: self.memory[self.op2]]+1) & 0xFF;
            [self writeValue: incabs toAbsoluteOp1: self.memory[self.op1] andAbsoluteOp2: self.memory[self.op2]];
            
            [self toggleZeroAndSignFlagForReg: incabs];
            
            break;
            
        case INX:
            argCount = 1;
            self.reg_pc++;
            self.counter += 2;
            self.reg_x = (self.reg_x + 1) & 0xFF;
            
            [self toggleZeroAndSignFlagForReg: self.reg_x];
            
            break;
            
        case INY:
            argCount = 1;
            self.reg_pc++;
            self.counter += 2;
            self.reg_y = (self.reg_y + 1) & 0xFF;
            
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
            
            uint16_t stackPc = self.reg_pc+2;
            
            // Push new address to the stack and decrement the current PC
            [self pushToStack: stackPc >> 8];
            [self pushToStack: (uint8_t)stackPc];
            
            //TODO: FUCK
            self.reg_pc = (self.memory[self.op2] << 8 | self.memory[self.op1]);
            
            // Cycles 6
            break;
        
        // LDA Absolute X
        case LDA_ABSX:
            argCount = 3;
            self.reg_pc += argCount;
            // Cycles: 4
            // TODO: Check for page wrap, add one more cycle to the counter
            self.counter += 4;
            self.reg_acc = [self readIndexedAbsoluteAddress1: self.memory[self.op1] address2: self.memory[self.op2] withOffset: self.reg_x];
            [self toggleZeroAndSignFlagForReg: self.reg_acc];
            break;
            
        case LDA_ABSY:
            argCount = 3;
            self.reg_pc += argCount;
            self.counter += 4;
            self.reg_acc = [self readIndexedAbsoluteAddress1: self.memory[self.op1] address2: self.memory[self.op2] withOffset: self.reg_y];
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
            self.reg_pc += argCount;
            // Cycles: 2
            self.counter += 3;
            self.reg_acc = [self readZeroPage: self.memory[self.op1]];

            [self toggleZeroAndSignFlagForReg: self.reg_acc];
            break;
            
        case LDA_ZPX:
            argCount = 2;
            self.reg_pc += argCount;
            // Cycles: 2
            self.counter += 4;
            self.reg_acc = [self readZeroPage: self.memory[self.op1] withRegister: self.reg_x];

            [self toggleZeroAndSignFlagForReg: self.reg_acc];
            break;
            
        case LDA_INDY:
            argCount = 2;
            self.reg_pc += argCount;
            self.counter += 5;
            
            //NSLog(@"LDA_INDY: %X at cycle: %X", (((self.memory[(self.memory[self.op1] + 1) & 0xFF] << 8) | (self.memory[self.memory[self.op1]])) + self.reg_y) & 0xFFFF, self.counter);
            
            self.reg_acc = [self readIndirectIndexAddressWithByte: self.memory[self.op1] andOffset: self.reg_y];
            [self toggleZeroAndSignFlagForReg: self.reg_acc];
            break;
            
        // LDA (Load Accumulator Absolute)
        case LDA_ABS:
            argCount = 3;
            self.reg_pc += 3;
            // Cycles: 4
            self.counter += 4;
            self.reg_acc = [self readAbsoluteAddress1: self.memory[self.op1] address2: self.memory[self.op2]];
            
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

            [self toggleZeroAndSignFlagForReg: self.reg_x];
            break;
            
        case LDX_ZP:
            argCount = 2;
            self.reg_pc += argCount;
            self.counter += 3;
            self.reg_x = [self readZeroPage: self.memory[self.op1]];

            [self toggleZeroAndSignFlagForReg: self.reg_x];
            break;
            
        case LDX_ABS:
            argCount = 3;
            self.reg_pc += argCount;
            // Cycles: 4
            self.counter += 4;
            self.reg_x = [self readAbsoluteAddress1: self.memory[self.op1] address2: self.memory[self.op2]];
            
            [self toggleZeroAndSignFlagForReg: self.reg_x];
            break;
            
        case LDY_ABS:
            argCount = 3;
            self.reg_pc += argCount;
            // Cycles: 4
            self.counter += 4;
            self.reg_y = [self readAbsoluteAddress1: self.memory[self.op1] address2: self.memory[self.op2]];
            
            [self toggleZeroAndSignFlagForReg: self.reg_y];
            break;
            
        case LDY_ABSX:
            argCount = 3;
            self.reg_pc += argCount;
            self.counter += 4;
            self.reg_y = [self readIndexedAbsoluteAddress1: self.memory[self.op1] address2: self.memory[self.op2] withOffset: self.reg_x];
            
            [self toggleZeroAndSignFlagForReg: self.reg_y];
            break;
            
        case LDY_IMM:
            argCount = 2;
            self.reg_pc += argCount;
            // Cycles: 2
            self.counter += 2;
            self.reg_y = self.memory[self.op1];
            
            [self toggleZeroAndSignFlagForReg: self.reg_y];
            break;
            
        case LDY_ZPX:
            argCount = 2;
            self.reg_pc += argCount;
            // Cycles: 2
            self.counter += 4;
            self.reg_y = [self readZeroPage: self.memory[self.op1] withRegister: self.reg_x];
            
            [self toggleZeroAndSignFlagForReg: self.reg_y];
            break;
            
        case LDY_ZP:
            argCount = 2;
            self.reg_pc += argCount;
            // Cycles: 2
            self.counter += 3;
            self.reg_y = [self readZeroPage: self.memory[self.op1]];
            
            [self toggleZeroAndSignFlagForReg: self.reg_y];
            break;
            
        case LSR_A:
            argCount = 1;
            self.reg_pc++;
            self.counter += 2;
            
            self.reg_acc = [self logicalShiftRight: self.reg_acc];
            break;
            
        case LSR_ZP:
            argCount = 2;
            self.reg_pc += argCount;
            self.counter += 5;
            uint8_t lsrzp = [self logicalShiftRight: [self readZeroPage: self.memory[self.op1]]];

            [self writeZeroPage: self.memory[self.op1] withValue: lsrzp];
            
            break;
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
            self.reg_pc += argCount;
            self.counter += 2;
            self.reg_acc |= self.memory[self.op1];
            [self toggleZeroAndSignFlagForReg: self.reg_acc];
            
            break;
        // ORA on zero page address
        case ORA_ZP:
            argCount = 2;
            self.reg_pc += argCount;

            self.reg_acc |= [self readZeroPage: self.memory[self.op1]];
            // Cycles
            self.counter += 3;
            [self toggleZeroAndSignFlagForReg: self.reg_acc];
            break;
            
        case ORA_ABSY:
            argCount = 3;
            self.reg_acc |= [self readIndexedAbsoluteAddress1: self.memory[self.op1] address2: self.memory[self.op2] withOffset: self.reg_y];

            self.reg_pc += argCount;
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
        case ROL_ACC:
            argCount = 1;
            self.counter += 2;
            self.reg_pc += argCount;
            self.reg_acc = [self rotateLeft: self.reg_acc];
            
            break;
        case ROL_ZP:
            argCount = 2;
            self.counter += 5;
            self.reg_pc += argCount;
            
            uint8_t rolzp = [self rotateLeft: [self readZeroPage: self.memory[self.op1]]];
            [self writeZeroPage: self.memory[self.op1] withValue: rolzp];
            break;
            
        case ROL_ABS:
            argCount = 3;
            self.counter += 6;
            self.reg_pc += argCount;
            
            uint8_t rolabs = [self rotateLeft: [self readAbsoluteAddress1: self.memory[self.op1] address2: self.memory[self.op2]]];
            [self writeValue: rolabs toAbsoluteOp1: self.memory[self.op1] andAbsoluteOp2: self.memory[self.op2]];
            break;
            
        case ROR_ZP:
            argCount = 2;
            self.counter += 5;
            self.reg_pc += argCount;
            
            uint8_t rorzp = [self rotateRight: [self readZeroPage: self.memory[self.op1]]];
            [self writeZeroPage: self.memory[self.op1] withValue: rorzp];
            
            break;
        case ROR_ACC:
            argCount = 1;
            self.counter += 2;
            self.reg_pc += argCount;
            
            self.reg_acc = [self rotateRight: self.reg_acc];
            
            break;
            
        case ROR_ABSX:
            argCount = 3;
            self.counter += 7;
            self.reg_pc += argCount;
            uint8_t rorabsx = [self rotateRight: [self readIndexedAbsoluteAddress1: self.memory[self.op1] address2: self.memory[self.op1] withOffset: self.reg_x]];
            [self writeAbsoluteAddress1: self.memory[self.op1] address2: self.memory[self.op2] andOffset: self.reg_x withValue: rorabsx];
            
            break;
            
        case ROR_ABS:
            argCount = 3;
            self.counter += 6;
            self.reg_pc += argCount;
            uint8_t rorabs = [self rotateRight: [self readAbsoluteAddress1: self.memory[self.op1] address2: self.memory[self.op2]]];
            [self writeAbsoluteAddress1: self.memory[self.op1] address2: self.memory[self.op2] andOffset: 0 withValue: rorabs];
            
            break;
        case RTI:
            argCount = 1;
            // 6 cycles
            self.counter += 6;
            // Pull the stack address and put it into the pc
            uint16_t littlerti, bigrti = 0x00;
            
            self.reg_status = [self pullFromStack];
            littlerti = [self pullFromStack];
            bigrti = [self pullFromStack];
            self.reg_pc = ((bigrti << 8)| littlerti);
           // NSLog(@"RTI! to :%X", self.reg_pc);

            break;
        case RTS:
            argCount = 1;
            // 6 cycles
            self.counter += 6;
            // Pull the stack address and put it into the pc
            uint8_t little, big = 0x00;
            
            little = [self pullFromStack];
            big = [self pullFromStack];
            self.reg_pc = ((big << 8)| little)+1;
            break;
        case SBC_IMM:
            argCount = 2;
            self.counter += 2;
            self.reg_pc += argCount;
            [self subtractWithCarry: self.memory[self.op1]];
            
            break;
            
        case SBC_ZP:
            argCount = 2;
            self.counter += 3;
            self.reg_pc += argCount;
            
            [self subtractWithCarry: [self readZeroPage: self.memory[self.op1]]];
            break;
            
            
        case SBC_ABSY:
            argCount = 3;
            self.counter += 4;
            self.reg_pc += argCount;
            
            [self subtractWithCarry: [self readIndexedAbsoluteAddress1: self.memory[self.op1] address2: self.memory[self.op2] withOffset: self.reg_y]];
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
            
        // STA_ABS (Store Accumulator Absolute)
        case STA_ABS:
            argCount = 3;
            // 1 byte OP, jump to the next byte address
            self.reg_pc += argCount;
            [self writeValue: self.reg_acc toAbsoluteOp1: self.memory[self.op1] andAbsoluteOp2: self.memory[self.op2]];
            // Cycles: 4
            self.counter += 4;
            break;
            
        case STA_ABSX:
            argCount = 3;
            // 1 byte OP, jump to the next byte address
            self.reg_pc += argCount;
            self.counter += 5;

            [self writeAbsoluteAddress1: self.memory[self.op1] address2: self.memory[self.op2] andOffset: self.reg_x withValue: self.reg_acc];
            break;
            
        case STA_ABSY:
            argCount = 3;
            // 1 byte OP, jump to the next byte address
            self.reg_pc += argCount;
            self.counter += 5;
            
            [self writeAbsoluteAddress1: self.memory[self.op1] address2: self.memory[self.op2] andOffset: self.reg_y withValue: self.reg_acc];
            break;
            
            // STA_ABS (Store Accumulator Absolute)
        case STA_INDY:
            argCount = 2;
            self.reg_pc += argCount;
            self.counter += 6;
            
            [self writeIndirectIndexWithByte: self.memory[self.op1] andOffset: self.reg_y withValue: self.reg_acc];
            break;
        // STA_ZP (Store Accumulator Zero Page)
        case STA_ZP:
            argCount = 2;
            self.reg_pc += argCount;
            self.counter += 3;
            
            [self writeZeroPage: self.memory[self.op1] withValue: self.reg_acc];
            break;
        case STA_ZPX:
            argCount = 2;
            self.reg_pc += argCount;
            self.counter += 4;

            [self writeZeroPage: self.memory[self.op1] withValue: self.reg_acc withRegister: self.reg_x];
            break;
        case STX_ZP:
            argCount = 2;
            self.reg_pc += argCount;
            self.counter += 4;

            [self writeZeroPage: self.memory[self.op1] withValue: self.reg_x];
            break;
        case STY_ZP:
            argCount = 2;
            self.reg_pc += argCount;
            self.counter += 4;

            [self writeZeroPage: self.memory[self.op1] withValue: self.reg_y];
            break;
        case STX_ABS:
            argCount = 3;
            self.reg_pc += argCount;
            self.counter += 4;
            
            [self writeValue: self.reg_x toAbsoluteOp1: self.memory[self.op1] andAbsoluteOp2: self.memory[self.op2]];
            break;
            
        // STY (Store Y Absolute Page)
        case STY_ABS:
            argCount = 3;
            self.reg_pc += argCount;
            self.counter += 4;

            [self writeValue: self.reg_y toAbsoluteOp1: self.memory[self.op1] andAbsoluteOp2: self.memory[self.op2]];
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
            NSLog(@"cycle counter: %X", self.counter);
            NSLog(@"Stack at current pos: %X", self.reg_sp);
            for (int i = 0x100; i <= 0x200; i++) {
                NSLog(@"Value %X at SP Pos %X", self.memory[i], i);
            }
            self.isRunning = NO;
            //@throw [NSException exceptionWithName: @"Unknown OP" reason: @"Unknown OP" userInfo: nil];
            break;
    }
    
    // TODO: Clean this up, this is terrible
    if (self.nes.debuggerEnabled == YES) {
        NSString *line = nil;
        uint16 opcodeLength = 10-[[Cpu6502 getOpcodeName: opcode] length];
        NSString *opcodePadded = [Cpu6502 getOpcodeName: opcode];
        if (opcodeLength > 0) {
            NSString *padding = [[NSString string] stringByPaddingToLength: opcodeLength withString: @" " startingAtIndex: 0];
            opcodePadded = [opcodePadded stringByAppendingString: padding];
        }
        if (argCount == 1) {
            line = [NSString stringWithFormat: @"%X\t\t%X\t%@\t%@\t%@\t\t\tA:%X X:%X Y:%X P:%@ SP:%X CYC:%d\n", currentPC, opcode, @"", @"", opcodePadded, currentRegA, currentRegX, currentRegY, [BitHelper intToBinary: currentRegStatus], currentRegSP, self.counter];
        } else if (argCount == 2) {
            line = [NSString stringWithFormat: @"%X\t\t%X\t%X\t%@\t%@\t\t\tA:%X X:%X Y:%X P:%@ SP:%X CYC:%d\n", currentPC, opcode, self.memory[self.op1], @"", opcodePadded, currentRegA, currentRegX, currentRegY, [BitHelper intToBinary: currentRegStatus], currentRegSP, self.counter];
        } else if (argCount == 3) {
            line = [NSString stringWithFormat: @"%X\t\t%X\t%X\t%X\t%@\t\tA:%X X:%X Y:%X P:%@ SP:%X CYC:%d\n", currentPC, opcode, self.memory[self.op1], self.memory[self.op2], opcodePadded, currentRegA, currentRegX, currentRegY, [BitHelper intToBinary: currentRegStatus], currentRegSP, self.counter];
        } else {
            line = [NSString stringWithFormat: @"OP not found: %X, next 3 bytes %X %X %X PC: %X", opcode, self.memory[self.op1], self.memory[self.op2], self.memory[self.op3], currentPC];
            
            NSLog(@"Stack at current pos: %X", self.reg_sp);
            for (int i = 0x100+self.reg_sp; i <= 0x200; i++) {
                NSLog(@"Value %X at SP Pos %X", self.memory[0x100+self.reg_sp], i);
            }
        }
        
        self.currentLine = line;
    }
}

+ (NSString *)getOpcodeName: (uint8_t)opcode{
    NSString *opcodeName = nil;
    
    switch(opcode) {
        case ADC_IMM:
            opcodeName = @"ADC_IMM";
            break;
        case ADC_ZP:
            opcodeName = @"ADC_ZP";
            break;
        case ADC_ABS:
            opcodeName = @"ADC_ABS";
            break;
        case ADC_ABSY:
            opcodeName = @"ADC_ABSY";
            break;
        case ADC_ABSX:
            opcodeName = @"ADC_ABSX";
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
        case AND_IMM:
            opcodeName = @"AND_IMM";
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
        case BIT_ABS:
            opcodeName = @"BIT_ABS";
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
        case CMP_ZP:
            opcodeName = @"CMP_ZP";
            break;
        case CMP_ZPX:
            opcodeName = @"CMP_ZPX";
            break;
        case CMP_ABS:
            opcodeName = @"CMP_ABS";
            break;
        case CMP_ABSX:
            opcodeName = @"CMP_ABSX";
            break;
        case CMP_ABSY:
            opcodeName = @"CMP_ABSY";
            break;
        case CMP_INDX:
            opcodeName = @"CMP_INDX";
            break;
        case CMP_INDY:
            opcodeName = @"CMP_INDY";
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
        case DEC_ZP:
            opcodeName = @"DEC_ZP";
            break;
        case DEC_ZPX:
            opcodeName = @"DEC_ZP";
            break;
        case DEC_ABS:
            opcodeName = @"DEC_ABS";
            break;
        case DEC_ABSX:
            opcodeName = @"DEC_ABSX";
            break;
        case EOR_IMM:
            opcodeName = @"EOR_IMM";
            break;
        case EOR_ZP:
            opcodeName = @"EOR_ZP";
            break;
        case EOR_ZPX:
            opcodeName = @"EOR_ZPX";
            break;
        case EOR_ABS:
            opcodeName = @"EOR_ABS";
            break;
        case EOR_ABSX:
            opcodeName = @"EOR_ABSX";
            break;
        case EOR_ABSY:
            opcodeName = @"EOR_ABSY";
            break;
        case EOR_INDX:
            opcodeName = @"EOR_INDX";
            break;
        case EOR_INDY:
            opcodeName = @"EOR_INDY";
            break;
        case INC_ZP:
            opcodeName = @"INC_ZP";
            break;
        case INC_ABS:
            opcodeName = @"INC_ABS";
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
        case LDA_ABSY:
            opcodeName = @"LDA_ABSY";
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
        case LDY_ABSX:
            opcodeName = @"LDY_ABSX";
            break;
        case LDY_ZP:
            opcodeName = @"LDY_ZP";
            break;
        case LDY_ZPX:
            opcodeName = @"LDY_ZPX";
            break;
            // LDA (Load Accumulator Absolute)
        case LDA_ABS:
            opcodeName = @"LDA_ABS";
            break;
        case LDA_ZP:
            opcodeName = @"LDA_ZP";
            break;
        case LDA_ZPX:
            opcodeName = @"LDA_ZPX";
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
        case ORA_ABSY:
            opcodeName = @"ORA_ABSY";
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
        case RTI:
            opcodeName = @"RTI";
            break;
        case RTS:
            opcodeName = @"RTS";
            break;
        case ROL_ACC:
            opcodeName = @"ROL_ACC";
            break;
        case ROL_ZP:
            opcodeName = @"ROL_ZP";
            break;
        case ROL_ZPX:
            opcodeName = @"ROL_ZPX";
            break;
        case ROL_ABS:
            opcodeName = @"ROL_ABS";
            break;
        case ROL_ABSX:
            opcodeName = @"ROL_ABSX";
            break;
        case ROR_ACC:
            opcodeName = @"ROR_ACC";
            break;
        case ROR_ZP:
            opcodeName = @"ROR_ZP";
            break;
        case ROR_ABSX:
            opcodeName = @"ROR_ABSX";
            break;
        case ROR_ABS:
            opcodeName = @"ROR_ABS";
            break;
        case SBC_IMM:
            opcodeName = @"SBC_IMM";
            break;
        case SBC_ZP:
            opcodeName = @"SBC_ZP";
            break;
        case SBC_ABSY:
            opcodeName = @"SBC_ABSY";
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
        case STA_ABSX:
            opcodeName = @"STA_ABSX";
            break;
        case STA_ABSY:
            opcodeName = @"STA_ABSY";
            break;
        case STA_INDY:
            opcodeName = @"STA_INDY";
            break;
            // STA_ZP (Store Accumulator Zero Page)
        case STA_ZP:
            opcodeName = @"STA_ZP";
            break;
        case STA_ZPX:
            opcodeName = @"STA_ZPX";
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
    NSLog(@"Stack at current pos: %X", self.reg_sp);
    for (int i = 0x100+self.reg_sp; i <= 0x200; i++) {
        NSLog(@"Value %X at SP Pos %X", self.memory[0x100+self.reg_sp], i);
    }
    
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
