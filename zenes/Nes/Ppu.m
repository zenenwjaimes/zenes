//
//  Ppu.m
//  
//
//  Created by zenen jaimes on 6/11/16.
//
//

#import "Ppu.h"

@implementation Ppu

-(id)initWithCpu: (Cpu6502 *)cpu andChrRom: (uint8_t *)tmpRom {
    if (self = [super init]) {
        self.cpu = cpu;
        [self bootupSequence];
        self.chrRom = tmpRom;
    }
    return self;
}

- (void)bootupSequence {
    self.currentScanline = 0;
    self.skipVBlank = NO;

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
    
    self.chrRom = tempChrRom;
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

- (BOOL)shouldProcessVBlank {
    int ppuCycles = 341*262;
    if (self.cpu.interruptPeriod == INT_NMI && self.cpu.counter > ppuCycles) {
        self.cpu.interruptPeriod = 0;
        NSLog(@"");
    }
    // Usually only happens on first vblank call, keeps the ppu in sequence
    if (self.cpu.counter < ppuCycles || self.skipVBlank == YES) {
        return NO;
    }
    
    // TODO: Add more checks
    
    return YES;
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

- (void)setBackgroundDataFrom: (Cpu6502 *)cpu toPixels: (int ***)pixels
{
    uint16_t nameTableAddress = [self getNameTableAddress];
    uint16_t patternTableAddress = [self getPatternTableAddress];
    // TODO: Actually implement ppu proper drawing in sync with cpu clock
    
    //for (int i = 0; i < 64; i++) {
    //    for (int j = 0; j < 3; j++) {
    //        NSLog(@"color: %X", colorPalette[i][j]);
    //    }
    //}
    int xlen = 256;
    int ylen = 240;
    int zlen = 3;
    //int ***p;
    size_t i, j;
    
    for (i=0; i < xlen; ++i)
        pixels[i] = NULL;
    
    for (i=0; i < xlen; ++i)
        pixels[i] = malloc(ylen * sizeof *pixels[i]);
    
    for (i=0; i < xlen; ++i)
        for (j=0; j < ylen; ++j)
            pixels[i][j] = NULL;
    
    for (i=0; i < xlen; ++i)
        for (j=0; j < ylen; ++j)
            pixels[i][j] = malloc(zlen * sizeof *pixels[i][j]);
    
    if (patternTableAddress != 0x0000) {
    
        /*for (int i = 0; i < 262; i++) {
            for (int j = 0; j < 340; j++) {
                //pixels[i][j] = i*j;
            }
        }*/
        
        for (int i = 0; i < 32; i++) {
            for (int j = 0; j < 30; j++) {
                
            }
        }
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
