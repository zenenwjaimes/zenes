//
//  Nes.m
//  zenes
//
//  Created by zenen jaimes on 5/24/16.
//  Copyright © 2016 zenen jaimes. All rights reserved.
//

#import "Nes.h"

@implementation Nes

- (id) initWithRom: (Rom *)rom {
    if (self = [super init]) {
        self.rom = rom;
        
        self.cpu = [[Cpu6502 alloc] init];
        
        uint16_t prgRom0 = [self.rom.mapper getPrgRomAddress: 0];
        uint16_t prgRom1 = [self.rom.mapper getPrgRomAddress: 1];
        
        uint8_t bank0[0x4000] = {};
        uint8_t bank1[0x4000] = {};

        [self.rom.data getBytes: bank0 range: NSMakeRange(prgRom0, 0x4000)];
        [self.rom.data getBytes: bank1 range: NSMakeRange(prgRom1, 0x4000)];

        // write prg rom to cpu mem
        [self.cpu writePrgRom:bank0 toAddress: (prgRom0-16)+0x8000];
        [self.cpu writePrgRom:bank1 toAddress: (prgRom1-16)+0x8000];
        
        // set pc to the address stored at FFFD/FFFC (usually 0x8000)
        self.cpu.reg_pc = (self.cpu.memory[0xFFFD] << 8) | (self.cpu.memory[0xFFFC]);
    }
    return self;
}

- (void) run {
    while (1) {
        
    }
}


@end
