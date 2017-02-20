//
//  Ppu.m
//  
//
//  Created by zenen jaimes on 6/11/16.
//
//

#import "Ppu.h"
#import "AppDelegate.h"

@implementation Ppu
@synthesize firstWrite,incrementStep;

-(id)initWithCpu: (Cpu6502 *)cpu andChrRom: (uint8_t *)tmpRom {
    if (self = [super init]) {
        self.cpu = cpu;
        [self bootupSequence];
        //self.chrRom = tmpRom;
        
        for (int i = 0; i < 0x2000; i++) {
            self.memory[i] = tmpRom[i];
            NSLog(@"tmp vrom (%X): %X", i, tmpRom[i]);
        }
    }
    return self;
}

- (void)bootupSequence {
    self.currentScanline = 0;
    self.skipVBlank = NO;
    self.firstWrite = YES;
    self.incrementStep = 1;
    //self.vramAddress = 0x0000;
    self.currentVerticalLine = self.currentScanline = 0;
    
    [self setupColorPalette];
    
    uint8_t tempMemory[0x10000] = {};
    uint8_t tempChrRom[0x2000] = {};

    //TODO: Set everything to 0xFF on bootup. this could be wrong
    for (int i = 0; i < 0x10000; i++) {
        tempMemory[i] = 0x00;
    }
    
    for (int i = 0; i < 0x2000; i++) {
        tempChrRom[i] = 0x00;
    }
    
    //self.chrRom = tempChrRom;
    self.memory = tempMemory;    
}

- (void)setMemory:(uint8_t *)memory {
    memcpy(_memory, memory, sizeof(_memory));
}

- (uint8_t *)memory {
    return _memory;
}

- (void)setChrRom:(uint8_t *)chrRom {
    memcpy(_chrRom, chrRom, sizeof(_chrRom));
}

- (uint8_t *)chrRom {
    return _chrRom;
}

- (uint8_t)readPpuStatusReg: (uint8_t)flag
{
    uint8_t ppuStatusReg = self.cpu.ppuReg1;
    return ((ppuStatusReg >> flag) & 1);
}

- (void)setVramAddress:(uint16_t)vramAddress
{
    // Observe changes to increment stepping, in case any
    // games/demos switch between modes during writes to vram
    if ([self readPpuStatusReg: CR1_INCREMENT_BY_32]) {
        self.incrementStep = 32;
    }
    //NSLog(@"value passed in: %X", vramAddress);
    
    // VRAM address is stored in 2 bytes, first write is low, second write is high
    if (self.firstWrite == YES) {
        self.currVramAddress = (vramAddress << 8);
        //NSLog(@"First addy: %X", self.currVramAddress);

        self.firstWrite = NO;
    } else {
        self.currVramAddress |= vramAddress;
        // Wrap around instead of going up higher
        self.firstWrite = YES;
    }
}

- (void)observeCpuChanges
{
    // NOTICE: DO NOT USE READ/WRITE METHODS FROM CPU HERE
    // DOING SO WILL CAUSE A LOOP AND CRASH!
    uint8_t value = self.cpu.memory[self.cpu.notifyPpuAddress];//[self.cpu readValueAtAddress: self.cpu.notifyPpuAddress];

    switch (self.cpu.notifyPpuAddress) {
        case 0x2000:
            
            break;
        case 0x2002:
            if (self.cpu.notifyPpuWrite == NO) {
                //NSLog(@"clearing vblank?");
                // Any time $2002 is read, clear vblank and also the sprite/bg regs
                self.cpu.memory[0x2002] = (self.cpu.memory[0x2002] & (1<<7));
                self.cpu.memory[0x2005] = self.cpu.memory[0x2006] = 0;
            }
            break;
        case 0x2006:
            if (self.cpu.notifyPpuWrite == YES) {
                [self setVramAddress: value];
            } else {
                NSLog(@"read of 2006");
            }
            break;
        case 0x2007:
            [self setCanDraw: YES];
            
            if (self.cpu.notifyPpuWrite == YES) {
                NSLog(@"Written to $2007 (%X): %X", self.currVramAddress, self.cpu.memory[0x2007]);
                self.memory[self.currVramAddress] = self.cpu.memory[0x2007];
                self.currVramAddress += self.incrementStep;
            } else {
                NSLog(@"Read of 0x2007");
            }
            //NSLog(@"Read of 0x2007");
            break;
    }
}

- (uint16_t)getNameTableAddress
{
    uint16_t nameTableAddress = 0x00;
    uint8_t ppuControlReg1 = [self.cpu readAbsoluteAddress1: 0x00 address2: 0x20];
    uint8_t bits = [BitHelper checkBit: 0 on: ppuControlReg1] | ([BitHelper checkBit: 1 on: ppuControlReg1] << 1);
    
    switch (bits) {
        case 0:
            nameTableAddress = 0x2000;
            break;
        case 1:
            nameTableAddress = 0x2400;
            break;
        case 2:
            nameTableAddress = 0x2800;
            break;
        case 3:
            nameTableAddress = 0x2C00;
            break;

    }
    
    NSLog(@"status reg: %@ name table addy: %X with bits: %X", [BitHelper intToBinary: ppuControlReg1], nameTableAddress, bits);
    
    return nameTableAddress;
}

- (uint16_t)getPatternTableAddress
{
    uint16_t patternTableAddress = 0x0000;
    uint8_t ppuControlReg1 = [self.cpu readAbsoluteAddress1: 0x00 address2: 0x20];
    uint8_t bits = [BitHelper checkBit: 4 on: ppuControlReg1];
    
    switch (bits) {
        case 1:
            patternTableAddress = 0x1000;
            break;
    }
    
    NSLog(@"status reg: %@ name table addy: %X with bits: %X", [BitHelper intToBinary: ppuControlReg1], patternTableAddress, bits);
    
    return patternTableAddress;
}

- (void)checkVBlank
{
    // Vblank set
    if (self.currentScanline ==  241 && self.currentVerticalLine == 0) {
        //NSLog(@"vblank happening! %d", self.cpu.counter);
        //NSLog(@"current addy at vblank: %@", self.cpu.currentLine);
        self.cpu.memory[0x2002] = ([self.cpu readValueAtAddress: 0x2002] | (1<<7));
        
        // Generate nmi if set in control reg 1
        if (self.cpu.memory[0x2000] >> 7) {
            NSLog(@"TRIGGERING INT");
            [self.cpu triggerInterrupt: INT_NMI];
        }
    } else if (self.currentScanline == 261 && self.currentVerticalLine == 0) { // Vblank has finished. read the value so it clears
        [self.cpu readValueAtAddress: 0x2002];
    }
}

- (void)drawFrame
{
    [self checkVBlank];
    
    if (self.currentVerticalLine <= 340) {
        self.currentVerticalLine += 3;
    } else {
        if (self.currentScanline < 261) {
            self.currentScanline++;
        } else {
            self.currentScanline = 0;
        }
        
        self.currentVerticalLine = 0;
    }
    
    // draw 3 pixels at a time. this keeps the cpu and ppu in sync since the ppu is 3x as fast as the cpu
    if (self.canDraw == YES) {
        
    }
}

- (void)setupColorPalette
{
    uint8_t tempColorPalette[64][3] = {
        {0x75,0x75,0x75},
        {0x27,0x1B,0x8F},
        {0x00,0x00,0xAB},
        {0x47,0x00,0x9F},
        {0x8F,0x00,0x77},
        {0xAB,0x00,0x13},
        {0xA7,0x00,0x00},
        {0x7F,0x0B,0x00},
        {0x43,0x2F,0x00},
        {0x00,0x47,0x00},
        {0x00,0x51,0x00},
        {0x00,0x3F,0x17},
        {0x1B,0x3F,0x5F},
        {0x00,0x00,0x00},
        {0x00,0x00,0x00},
        {0x00,0x00,0x00},
        {0xBC,0xBC,0xBC},
        {0x00,0x73,0xEF},
        {0x23,0x3B,0xEF},
        {0x83,0x00,0xF3},
        {0xBF,0x00,0xBF},
        {0xE7,0x00,0x5B},
        {0xDB,0x2B,0x00},
        {0xCB,0x4F,0x0F},
        {0x8B,0x73,0x00},
        {0x00,0x97,0x00},
        {0x00,0xAB,0x00},
        {0x00,0x93,0x3B},
        {0x00,0x83,0x8B},
        {0x00,0x00,0x00},
        {0x00,0x00,0x00},
        {0x00,0x00,0x00},
        {0xFF,0xFF,0xFF},
        {0x3F,0xBF,0xFF},
        {0x5F,0x97,0xFF},
        {0xA7,0x8B,0xFD},
        {0xF7,0x7B,0xFF},
        {0xFF,0x77,0xB7},
        {0xFF,0x77,0x63},
        {0xFF,0x9B,0x3B},
        {0xF3,0xBF,0x3F},
        {0x83,0xD3,0x13},
        {0x4F,0xDF,0x4B},
        {0x58,0xF8,0x98},
        {0x00,0xEB,0xDB},
        {0x00,0x00,0x00},
        {0x00,0x00,0x00},
        {0x00,0x00,0x00},
        {0xFF,0xFF,0xFF},
        {0xAB,0xE7,0xFF},
        {0xC7,0xD7,0xFF},
        {0xD7,0xCB,0xFF},
        {0xFF,0xC7,0xFF},
        {0xFF,0xC7,0xDB},
        {0xFF,0xBF,0xB3},
        {0xFF,0xDB,0xAB},
        {0xFF,0xE7,0xA3},
        {0xE3,0xFF,0xA3},
        {0xAB,0xF3,0xBF},
        {0xB3,0xFF,0xCF},
        {0x9F,0xFF,0xF3},
        {0x00,0x00,0x00},
        {0x00,0x00,0x00},
        {0x00,0x00,0x00}
    };
    
    memcpy(colorPalette, tempColorPalette, sizeof(uint8_t)*64*3);
}

@end
