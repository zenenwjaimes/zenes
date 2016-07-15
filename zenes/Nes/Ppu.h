//
//  Ppu.h
//  
//
//  Created by zenen jaimes on 6/11/16.
//
//

#import <Foundation/Foundation.h>
#import "Cpu6502.h"

@interface Ppu : NSObject
{
    
}

@property (retain) Cpu6502 *cpu;
@property uint8_t currentScanline;
@property BOOL isDrawing;
@property BOOL skipVBlank;

-(id)initWithCpu: (Cpu6502 *)cpu;
- (BOOL)shouldProcessVBlank;

@end

static const int CR1_VERTICAL_WRITE = 2;
static const int CR1_SPRITE_PATTERN_TABLE_ADDRESS = 3;
static const int CR1_SCREEN_PATTERN_TABLE_ADDRESS = 4;
static const int CR1_SPRITE_SIZE = 5;
static const int CR1_PPU_SLAVE_MODE = 6;
static const int CR1_VBLANK_ENABLE = 7;

static const int CR2_UNKNOWN= 0;
static const int CR2_IMAGE_MASK = 1;
static const int CR2_SPRITE_MASK = 2;
static const int CR2_SCREEN_ENABLE = 3;
static const int CR2_SPRITES_ENABLE = 4;

static const int PSR_HIT_FLAG = 6;
static const int PSR_VBLANK_STATE = 7;
