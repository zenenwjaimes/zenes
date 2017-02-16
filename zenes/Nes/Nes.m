//
//  Nes.m
//  zenes
//
//  Created by zenen jaimes on 5/24/16.
//  Copyright © 2016 zenen jaimes. All rights reserved.
//

#import "Nes.h"

#import "AppDelegate.h"

@implementation Nes

- (id) initWithRom: (Rom *)rom {
    if (self = [super init]) {
        self.rom = rom;
        self.cpu = [[Cpu6502 alloc] init];
        self.ppu = [[Ppu alloc] initWithCpu: self.cpu];
        
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
            //self.cpu.reg_pc = 0x8000;
        }
        
    }
    return self;
}

//TODO: Fix this run loop up a bit. Make it so you can step through operations
- (void) run {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        for (;;) {
            [self runNextInstruction];
            
            if (self.cpu.isRunning == YES) {
                dispatch_sync(dispatch_get_main_queue(), ^{
                    [(AppDelegate *)[[NSApplication sharedApplication] delegate] appendToDebuggerWindow: self.cpu.currentLine];
                });
                
                //dispatch_sync(dispatch_get_main_queue(), ^{
                //    [(AppDelegate *)[[NSApplication sharedApplication] delegate] setDebuggerMemoryText: self.cpu.memory];
                //});
            
                dispatch_sync(dispatch_get_main_queue(), ^{
                    [[NSNotificationCenter defaultCenter] postNotification: [NSNotification notificationWithName: @"debuggerUpdate" object: nil]];
                });
            }
            
            //[NSThread sleepForTimeInterval:0.005];
        }
    });
}

- (void) runNextInstructionInline {
    if ([self.ppu shouldProcessVBlank] == NO) {
        [self.cpu runNextInstruction];
    } else {
        [self.cpu triggerInterrupt: INT_NMI];
        
        // Cheese it
        self.cpu.counter -= 341*262;
    }
    
    //[self.screen drawFrame: [self.ppu drawBackground: self.cpu]];
    //[self.screen performSelector: @selector(drawBackground:) withObject];
    //uint8_t pixels[362][240];
    
    int r=262, c=340;
    int **pixels;
    
    pixels  = (int **)malloc(sizeof(int *) * r);
    pixels[0] = (int *)malloc(sizeof(int) * c * r);
    
    for(int i = 0; i < r; i++)
        pixels[i] = (*pixels + c * i);
    
    for (int i = 0; i <  r; i++)
        for (int j = 0; j < c; j++)
            pixels[i][j] = 9;
    [self.ppu setBackgroundDataFrom: self.cpu toPixels: pixels];
    [self.screen setFrameData: pixels];
    //TODO: FUCK, make sure to copy pixels into the screen and not just leak memory
    //free(pixels);

    [(AppDelegate *)[[NSApplication sharedApplication] delegate] appendToDebuggerWindow: self.cpu.currentLine];
    [[NSNotificationCenter defaultCenter] postNotification: [NSNotification notificationWithName: @"debuggerUpdate" object: nil]];
}

- (void) runNextInstruction {
    if ([self.ppu shouldProcessVBlank] == NO) {
        [self.cpu runNextInstruction];
    } else {
        [self.cpu triggerInterrupt: INT_NMI];
        
        // Cheese it
        self.cpu.counter -= 341*262;
    }
}

@end
