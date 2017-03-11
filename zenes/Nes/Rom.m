//
//  Rom.m
//  zenes
//
//  Created by zenen jaimes on 5/24/16.
//  Copyright © 2016 zenen jaimes. All rights reserved.
//

#import "Rom.h"
#import "BitHelper.h"
#import "Nes.h"
#import "Ppu.h"

@implementation Rom

- (id) init: (NSString *) path {
    if (self = [super init]) {
        self.data = [[NSFileManager defaultManager] contentsAtPath: path];
        
        self.prgRomSize = ((uint8_t  *)[self.data bytes])[4];
        self.chrRomSize = ((uint8_t  *)[self.data bytes])[5];
        
        NSLog(@"Program Rom Size: %X", ((uint8_t  *)[self.data bytes])[4]);
        NSLog(@"Character Rom Size: %X", ((uint8_t  *)[self.data bytes])[5]);
        
        self.mapperType = ((uint8_t  *)[self.data bytes])[7] | ((((uint8_t  *)[self.data bytes])[6] &~ 0xF)>>4);
        NSLog(@"Mapper Type: %d", self.mapperType);

        self.mapper = [[Mapper alloc] init];
        
        self.clearShiftRegister = NO;
    }
    
    return self;
}

- (void)processMapper: (uint16_t)address withValue: (uint8_t) value
{
    switch (self.mapperType) {
        case 1:
            [self processMmc1Mapper: address withValue: value];
            break;
            
        default:
            break;
    }
}

// MARK: MMC1 Mapper
/*
 * MMC1 Mapper
 */
- (void)processMmc1Mapper: (uint16_t)address withValue: (uint8_t) value
{
    if (self.clearShiftRegister == NO && (address >= 0x8000 && address <= 0xFFFF)) {
        NSLog(@"bank switching? %X to address %X for data: %@", value, address, [BitHelper intToBinary: value]);
        self.reg0 = value;
        self.shiftRegister = value;
        self.clearShiftRegister = YES;
    }
    
    if (self.clearShiftRegister == YES && (address >= 0x8000 && address <= 0xFFFF)) {
        self.shiftRegisterCounter++;
        
        if (self.shiftRegisterCounter > 5) {
            NSLog(@"bank switching? %X to address %X for data: %@", value, address, [BitHelper intToBinary: value]);
            
            if (address >= 0x8000 && address <= 0x9FFF) {
                self.reg0 = value;
            } else if (address >= 0xA000 && address <= 0xBFFF) {
                self.reg1 = value;
                
                uint8_t chrRom[0x2000] = {};
                uint16_t chrRomAddress = (0x4000 * self.prgRomSize) + 16;
                
                // Switch the banks, 2 4KB
                if (!((self.reg0 >> 5) & 1)) {
                    chrRomAddress += (0x1000 * (self.reg1 & ~0xF0));
                    [self.data getBytes: chrRom range: NSMakeRange(chrRomAddress, 0x2000)];
                    
                    for (int i = 0; i < 0x1000; i++) {
                        self.nesInstance.ppu.memory[i] = chrRom[i];
                    }
                    
                }
            } else if (address >= 0xC000 && address <= 0xDFFF) {
                self.reg2 = value;
                
                uint8_t chrRom[0x2000] = {};
                uint16_t chrRomAddress = (0x4000 * self.prgRomSize) + 16;
                
                // Switch the banks, 2 4KB
                if (!((self.reg0 >> 5) & 1)) {
                    chrRomAddress += (0x1000 * (self.reg2 & ~0xF0));
                    [self.data getBytes: chrRom range: NSMakeRange(chrRomAddress, 0x2000)];

                    for (int i = 0; i < 0x1000; i++) {
                        self.nesInstance.ppu.memory[0x1000+i] = chrRom[i];
                    }
                }
            } else if (address >= 0xE000 && address <= 0xFFFF) {
                NSLog(@"cpu pc: %X", self.nesInstance.cpu.reg_pc);
                self.reg3 = value;
                
                uint8_t prgRom[0x4000] = {};
                uint8_t prgRom2[0x4000] = {};

                uint16_t swapAddress = 0x8000;
                // Swap 16KB at address in bit 2
                if ((self.reg3 >> 4) & 1) {
                    swapAddress += (self.reg3 >> 3)?0x4000:0x0000;
                } else { // Swaps 32KB at 0x8000
                    [self.data getBytes: prgRom range: NSMakeRange(0x4000+16, 0x4000)];
                    
                    for (int i = 0; i < 0x4000; i++) {
                        self.nesInstance.cpu.memory[0xC000+i] = prgRom[i];
                    }
                    
                    [self.data getBytes: prgRom2 range: NSMakeRange(16, 0x4000)];
                    
                    for (int i = 0; i < 0x4000; i++) {
                        self.nesInstance.cpu.memory[0x8000+i] = prgRom2[i];
                    }
                }
            }
            self.shiftRegisterCounter = 0;
        }
    }
}

@end
