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
        self.canDraw = self.canDrawBg = YES;
        
        for (long i = 0; i < 0x2000; i++) {
            self.memory[i] = tmpRom[i];
        }
    }
    return self;
}

- (void)bootupSequence {
    self.currentScanline = 0;
    self.skipVBlank = NO;
    self.firstWrite = YES;
    self.incrementStep = 1;
    self.currentVerticalLine = self.currentScanline = 0;
    
    [self setupColorPalette];
    
    uint8_t tempMemory[0x10000] = {};

    //TODO: Set everything to 0xFF on bootup. this could be wrong
    for (long i = 0; i < 0x10000; i++) {
        tempMemory[i] = 0x00;
    }
    
    self.memory = tempMemory;
}

- (void)setMemory:(uint8_t *)memory {
    memcpy(_memory, memory, sizeof(_memory));
}

- (uint8_t*)memory {
    return _memory;
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
//        NSLog(@"changing increment step to 32");
        self.incrementStep = 32;
    }
    
    // VRAM address is stored in 2 bytes, first write is low, second write is high
    if (self.firstWrite == YES) {
        self.currVramAddress = (vramAddress << 8);

        self.firstWrite = NO;
    } else {
        self.currVramAddress |= vramAddress;
        self.currVramAddress &= 0x3FFF;
        
        self.firstWrite = YES;
    }
}

- (void)observeCpuChanges
{
    // NOTICE: DO NOT USE READ/WRITE METHODS FROM CPU HERE
    // DOING SO WILL CAUSE A LOOP AND CRASH!
    uint8_t value = self.cpu.memory[self.cpu.notifyPpuAddress];
    
    switch (self.cpu.notifyPpuAddress) {
        case 0x2000:
            if (self.cpu.notifyPpuWrite == YES) {
                if ([BitHelper checkBit: CR1_INCREMENT_BY_32 on: self.cpu.memory[0x2000]]) {
                    self.incrementStep = 32;
                } else {
                    self.incrementStep = 1;
                }
            }
            break;
            
        case 0x2001:
            if (([BitHelper checkBit: CR2_SHOW_BACKGROUND on: self.cpu.memory[0x2001]])) {
                self.canDrawBg = YES;
            } else {
                self.canDrawBg = NO;
            }
            break;
        case 0x2002:
            if (self.cpu.notifyPpuWrite == NO) {
                self.cpu.memory[0x2002] = (self.cpu.memory[0x2002] & (1<<7));
                self.cpu.memory[0x2005] = self.cpu.memory[0x2006] = 0;
                
                if (self.cpu.memory[0x2000] >> 7) {
                    [self.cpu triggerInterrupt: INT_NMI];
                }
            }
            break;
        case 0x2006:
            if (self.cpu.notifyPpuWrite == YES) {
                [self setVramAddress: value];
            } else {

            }
            break;
        case 0x2007:
            [self setCanDraw: YES];
            
            if (self.cpu.notifyPpuWrite == YES) {
                self.memory[self.currVramAddress] = self.cpu.memory[0x2007];
                if (self.currVramAddress >= 0x2000 && self.currVramAddress <= 0x2400) {
                    self.memory[self.currVramAddress+0x800] = self.cpu.memory[0x2007];
                }
                if (self.currVramAddress >= 0x2400 && self.currVramAddress <= 0x2800) {
                    self.memory[self.currVramAddress+0x800] = self.cpu.memory[0x2007];
                }
                
                if (self.currVramAddress == 0x3F00 || self.currVramAddress == 0x3F04 || self.currVramAddress == 0x3F08 || self.currVramAddress == 0x3F0C) {
                    self.memory[self.currVramAddress+0x10] = self.cpu.memory[0x2007];
                }

                self.currVramAddress += self.incrementStep;
            } else {
                NSLog(@"Read of 0x2007");
            }
            break;
    }
}

- (uint16_t)getNameTableAddress
{
    uint16_t nameTableAddress = 0x00;
    uint8_t ppuControlReg1 = self.cpu.ppuReg1;
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
    
    return nameTableAddress;
}

- (uint16_t)getBgColorAddress: (uint8_t)colorLookup withAttr: (uint8_t)attr
{
    switch (attr) {
        case 0:
            attr = 0;
            break;
        case 1:
            attr = 0x04;
            break;
        case 2:
            attr = 0x08;
            break;
        case 3:
            attr = 0xC;
            break;
    }
    return self.memory[0x3F00+colorLookup+attr];
}

- (uint16_t)getAttributeTableAddress
{
    return [self getNameTableAddress]+0x03C0;
}

- (uint16_t)getPatternTableAddress
{
    switch ([BitHelper checkBit: 4 on: self.cpu.ppuReg1]) {
        case 0:
            return 0x0000;
            break;
        case 1:
            return 0x1000;
            break;
    }
    
    return 0x0000;
}

- (uint8_t*)getBackgroundDataForX: (uint16_t)x andY: (uint16_t)y
{
    uint8_t *pixel = malloc(sizeof(uint8_t)*5);
    pixel[0] = x;
    pixel[1] = y;
    
    uint8_t tileNumberX = x/8;
    uint8_t tileNumberY = y/8;
    uint16_t nameTable = [self getNameTableAddress];
    uint16_t attributeTable = [self getAttributeTableAddress];
    uint16_t patternTable = [self getPatternTableAddress];
    uint16_t nameByteAddress = 0x00;
    
    if (tileNumberY == 0) {
        nameByteAddress = tileNumberX;
    } else {
        nameByteAddress = tileNumberY*32+tileNumberX;
    }

    // TODO: IMPLIMENT FETCHING ATTRIBUTE TABLE DATA
    uint8_t pixelPos = (x & 0xF0 >> 4);
    if (pixelPos > 7) {
        pixelPos -=8;
    }
    
    uint8_t pixelyPos = (y & 0xF0 >> 4);
    if (pixelyPos > 7) {
        pixelyPos -=8;
    }
    
    uint8_t nameByte = self.memory[nameTable+nameByteAddress];
    uint8_t firstPattern, secondPattern = 0;
    
    firstPattern =  self.memory[patternTable+(nameByte*16)+(pixelyPos)];
    secondPattern =  self.memory[patternTable+(nameByte*16)+(pixelyPos)+8];

    uint8_t attrLookup = self.memory[attributeTable + [self getTileAddressForRow: tileNumberY andCol: tileNumberX]];
    uint8_t highColorBit = ([BitHelper checkBit: ([self getSquareTileForX: pixelPos andY: pixelyPos]*2)+1 on: attrLookup] << 1) | ([BitHelper checkBit: ([self getSquareTileForX: pixelPos andY: pixelyPos]*2) on: attrLookup]);
    uint8_t colorLookup = [self getBgColorAddress: (((firstPattern >> ((pixelPos-7) * -1)) & 1) | (((secondPattern >> ((pixelPos-7) * -1)) & 1) << 1)) withAttr: highColorBit];
    //(lowattrLookup >> ([self getSquareTileForX: pixelPos andY: pixelyPos]*2));
    //    highColorBit += (attrLookup >> (([self getSquareTileForX: pixelPos andY: pixelyPos]*2)+1));

    //highColorBit <<= 1;
    if (tileNumberX == 19 && tileNumberY == 9) {
        for (int i = 0; i < 10; i++) {
          //  NSLog(@"palette entry at %X is: %X", 0x3F00+i, self.memory[0x3F00+i]);
        }
        //NSLog(@"high color %X: %d, %d, %X", highColorBit << , x, y, 0x3F00+(((firstPattern >> ((pixelPos-7) * -1)) & 1) | (((secondPattern >> ((pixelPos-7) * -1)) & 1) << 1)));
        //NSLog(@"attr lookup found: %d, attr: %X total: %X", [self getTileAddressForRow: tileNumberY andCol: tileNumberX], attributeTable, attributeTable + [self getTileAddressForRow: tileNumberY andCol: tileNumberX]);
        //NSLog(@"color bit: %X", highColorBit);
        //NSLog(@"value for 16/9 is: %@ (%d), (%d, %d) %d (%X)", [BitHelper intToBinary: attrLookup], (attrLookup >> ([self getSquareTileForX: pixelPos andY: pixelyPos]*2)),x,y, [self getSquareTileForX:pixelPos andY: pixelyPos], highColorBit);
        
       // NSLog(@"color lookup %X for address: %X high color bit: %X (%d, %d)", colorLookup, (((firstPattern >> ((pixelPos-7) * -1)) & 1) | (((secondPattern >> ((pixelPos-7) * -1)) & 1) << 1)), highColorBit, x, y);
    }
        pixel[2] = colorPalette[colorLookup][0];// r
        pixel[3] = colorPalette[colorLookup][1];// g
        pixel[4] = colorPalette[colorLookup][2];// b
        
    return pixel;
}

- (uint8_t)getTileAddressForRow: (uint8_t)row andCol: (uint8_t)col
{
    uint8_t tileAddress = (col/4);
    if (row/4 == 0) {
        tileAddress += 0x00;
    } else if (row/4 == 1) {
        tileAddress += 8;
    } else if (row/4 == 2) {
        tileAddress += 16;
    } else if (row/4 == 3) {
        tileAddress += 24;
    } else if (row/4 == 4) {
        tileAddress += 32;
    } else if (row/4 == 5) {
        tileAddress += 40;
    } else if (row/4 == 6) {
        tileAddress += 48;
    } else if (row/4 == 7) {
        tileAddress += 56;
    }
    
    return tileAddress;
}

- (uint8_t)getSquareTileForX: (uint8_t)x andY: (uint8_t)y
{
    uint8_t squareCol = x/4;//(x & 0xF0 >> 4)/8;
    uint8_t squareRow = y/4;//(y & 0xF0 >> 4)/8;
    uint8_t square = 0x00;

    if (squareCol == 0 && squareRow == 0) {
        square = 0;
    } else if (squareCol == 1 && squareRow == 0) {
        square = 1;
    } else if (squareCol == 0 && squareRow == 1) {
        square = 2;
    } else if (squareCol == 1 && squareRow == 1) {
        square = 3;
    }
    
    return square;
}

- (void)checkVBlank
{
    // Vblank set
    if (self.cpu.counter >= 29781) {
    //if (self.currentScanline == 1 && self.currentVerticalLine == 0) {
        self.cpu.memory[0x2002] = (self.cpu.memory[0x2002] | (1<<7));
        
        // Generate nmi if set in control reg 1
        if (self.cpu.memory[0x2000] >> 7) {
            [self.cpu triggerInterrupt: INT_NMI];
        }
        
        self.cpu.counter = 0;
    }
    
    // Vblank has finished. read the value so it clears
    if (self.cpu.memory[0x2002] >> 7 && self.cpu.counter >= 21*256) {
        [self.cpu readValueAtAddress: 0x2002];
        self.cpu.counter = 0;
    }
}

- (void)drawFrame
{
    if (self.currentScanline > 21) {
        // Drawing 3 pixels at a time since each 3 is cpu cycles * 3
        if (self.currentVerticalLine < 253) {
            uint8_t *pixel1 = [self getBackgroundDataForX: self.currentVerticalLine andY: self.currentScanline-22];
            [self.screen loadPixelsToDrawAtX:pixel1[0] atY: pixel1[1] withR: pixel1[2] G: pixel1[3] B: pixel1[4]];
            free(pixel1);
            
            uint8_t *pixel2 = [self getBackgroundDataForX: self.currentVerticalLine+1 andY: self.currentScanline-22];
            [self.screen loadPixelsToDrawAtX:pixel2[0] atY: pixel2[1] withR: pixel2[2] G: pixel2[3] B: pixel2[4]];
            free(pixel2);
            
            uint8_t *pixel3 = [self getBackgroundDataForX: self.currentVerticalLine+2 andY: self.currentScanline-22];
            [self.screen loadPixelsToDrawAtX:pixel3[0] atY: pixel3[1] withR: pixel3[2] G: pixel3[3] B: pixel3[4]];
            free(pixel3);
            
            self.currentVerticalLine += 3;
        } else {
            // Draw after every line... this will change
            
            if (self.currentVerticalLine > 339) {
                self.currentScanline++;
                self.currentVerticalLine = 0;
            } else {
                self.currentVerticalLine += 3;
            }
            
            if (self.currentScanline > 261) {
                self.currentScanline = 0;
                [self.screen setNeedsDisplay: YES];
            }
        }
    } else {
        [self checkVBlank];
        if (self.currentVerticalLine > 339) {
            self.currentScanline++;
            self.currentVerticalLine = 0;
        } else {
            self.currentVerticalLine += 3;
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
