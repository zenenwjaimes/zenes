//
//  Ppu.h
//  
//
//  Created by zenen jaimes on 6/11/16.
//
//

#import <Foundation/Foundation.h>
#import "NesInc.h"

@interface Ppu : NSObject
{
    uint8_t _memory[0x10000];
    uint8_t _chrRom[0x2000];
    uint8_t _oamMemory[0x100];
    uint8_t colorPalette[64][3];
}

@property (retain) Cpu6502 *cpu;
@property (retain) Screen *screen;
@property uint16_t currentScanline;
@property uint16_t currentVerticalLine;
@property BOOL canDraw;
@property BOOL canDrawBg;
@property BOOL skipVBlank;
@property BOOL firstWrite;
@property (assign, nonatomic) uint8_t incrementStep;
@property (assign, nonatomic) uint16_t currVramAddress;
@property (assign, nonatomic) uint8_t *memory;
@property (assign, nonatomic) uint8_t *oamMemory;
@property uint8_t oamAddress;

- (id)initWithCpu: (Cpu6502 *)cpu andChrRom: (uint8_t *)tmpRom;
- (void)checkVBlank;
- (void)drawFrame;
- (void)setVramAddress:(uint16_t)vramAddress;
- (void)observeCpuChanges;

@end

// $2000 - PPU Control Reg 1
static const int CR1_NAMETABLE_LOW = 0;
static const int CR1_NAMETABLE_HIGH = 1;
static const int CR1_INCREMENT_BY_32 = 2;
static const int CR1_SPRITE_PATTERN_TABLE_ADDRESS = 3;
static const int CR1_SCREEN_PATTERN_TABLE_ADDRESS = 4;
static const int CR1_SPRITE_SIZE = 5;
static const int CR1_PPU_SLAVE_MODE = 6;
static const int CR1_VBLANK_ENABLE = 7;

// $2001 - PPU Control Reg 2
static const int CR2_IS_MONOCHROME = 0;
static const int CR2_CLIP_BACKGROUND = 1;
static const int CR2_CLIP_SPRITES = 2;
static const int CR2_SHOW_BACKGROUND = 3;
static const int CR2_SHOW_SPRITES = 4;

// $2002 - PPU Status Register / READ ONLY
static const int PSR_IGNORE_VRAM_WRITES = 4;
static const int PSR_SPRITE_OVERLOAD_SCANLINE = 5;
static const int PSR_HIT_FLAG = 6;
static const int PSR_VBLANK_STATE = 7;
