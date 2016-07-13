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
    NSLog(@"value at: %d", self.cpu.memory[0x8000]);
}

@end
