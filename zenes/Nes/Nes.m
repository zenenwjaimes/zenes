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
        
        uint16_t prgRom0 = 0x00;
        uint16_t prgRom1 = 0x00;
        uint8_t bank0[0x4000] = {};
        uint8_t bank1[0x4000] = {};
        
        // TODO: Hack
        // MMC-1
        if (self.rom.mapperType == 1) {
            prgRom0 = [self.rom.mapper getPrgRomAddress: 0];
            prgRom1 = [self.rom.mapper getPrgRomAddress: 1];
        } else { // No mapper, generic rom
            prgRom0 = [self.rom.mapper getPrgRomAddress: 0];
            prgRom1 = [self.rom.mapper getPrgRomAddress: 1];
        }
        
        // TODO: Hack
        if (self.rom.mapperType == 0) {
            prgRom1 = 0x10;
        }
        
        [self.rom.data getBytes: bank0 range: NSMakeRange(prgRom0, 0x4000)];
        [self.rom.data getBytes: bank1 range: NSMakeRange(prgRom1, 0x4000)];
        
        // TODO: Hack
        if (self.rom.mapperType == 0) {
            prgRom1 = 0x4010;
        }
        
        // write prg rom to cpu mem
        [self.cpu writePrgRom:bank0 toAddress: (prgRom0-16)+0x8000];
        [self.cpu writePrgRom:bank1 toAddress: (prgRom1-16)+0x8000];
        
        // set pc to the address stored at FFFD/FFFC (usually 0x8000)
        self.cpu.reg_pc = (self.cpu.memory[0xFFFD] << 8) | (self.cpu.memory[0xFFFC]);

        // TODO: Hack
        if (self.rom.mapperType == 0) {
            self.cpu.reg_pc = 0xC000;
        }
    }
    return self;
}

//TODO: Fix this run loop up a bit. Make it so you can step through operations
- (void) run {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        for (;;) {
            [self.cpu run];
        }
    });
}

- (void) runNextInstruction {
    [self.cpu runNextInstruction];
}

@end
