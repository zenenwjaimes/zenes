//
//  Ppu.m
//  
//
//  Created by zenen jaimes on 6/11/16.
//
//

#import "Ppu.h"

@implementation Ppu

-(id)initWithCpu: (Cpu6502 *)cpu {
    if (self = [super init]) {
        self.cpu = cpu;
        [self bootupSequence];
    }
    return self;
}

- (void)bootupSequence {
    self.currentScanline = 0;
    self.skipVBlank = NO;

    uint8_t tempMemory[0x10000] = {};
    
    //TODO: Set everything to 0xFF on bootup. this could be wrong
    for (int i = 0; i < 0x10000; i++) {
        tempMemory[i] = 0xFF;
    }
    
    self.memory = tempMemory;    
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

- (void)setBackgroundDataFrom: (Cpu6502 *)cpu toPixels: (int **)pixels
{
    for (int i = 0; i < 262; i++) {
        for (int j = 0; j < 340; j++) {
            pixels[i][j] = i+j;
        }
    }
}

@end
