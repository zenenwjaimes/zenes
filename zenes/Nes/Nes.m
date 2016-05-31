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
        
        NSLog(@"%X", (prgRom0-16)+0x8000);
        NSLog(@"%X", (prgRom1-16)+0x8000);

        uint16_t bank0[0x4000] = {};
        uint16_t bank1[0x4000] = {};

        [self.rom.data getBytes: bank0 range: NSMakeRange(prgRom0, 0x4000)];
        [self.rom.data getBytes: bank1 range: NSMakeRange(prgRom1, 0x4000)];

        // write prg rom to cpu mem
        [self.cpu writePrgRom:bank0 toAddress: (prgRom0-16)+0x8000];
        [self.cpu writePrgRom:bank1 toAddress: (prgRom1-16)+0x8000];
        
        //NSLog(@"%X", self.cpu.memory[0x802F]);
        for (int i = 0; i < 0x10000; i++) {
           NSLog(@"%x", self.cpu.memory[i]);
        }
    }
    return self;
}

- (void) run {

}


@end
