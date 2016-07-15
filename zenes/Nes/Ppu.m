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
    
    // Enable vblank interrupts
    //self.cpu.memory[0x2000] = (1 << 7);
}

- (BOOL)shouldProcessVBlank {
    int ppuCycles = 341*262;
    // Usually only happens on first vblank call, keeps the ppu in sequence
    if (self.cpu.counter < ppuCycles || self.skipVBlank == YES) {
        return NO;
    }

    // TODO: Add more checks
    
    return YES;
}

@end
