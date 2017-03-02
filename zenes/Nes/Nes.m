//
//  Nes.m
//  zenes
//
//  Created by zenen jaimes on 5/24/16.
//  Copyright © 2016 zenen jaimes. All rights reserved.
//

#import "Nes.h"

#import "AppDelegate.h"
#import "Ppu.h"

@implementation Nes

- (id) initWithRom: (Rom *)rom {
    if (self = [super init]) {
        self.rom = rom;
        self.cpu = [[Cpu6502 alloc] init];
        self.cpu.nes = self;
        self.debuggerEnabled = NO;

        uint16_t prgRom0 = 0x00;
        uint16_t prgRom1 = 0x00;
        uint8_t bank0[0x4000] = {};
        uint8_t bank1[0x4000] = {};
        
        prgRom0 = [self.rom.mapper getPrgRomAddress: 0];
        prgRom1 = [self.rom.mapper getPrgRomAddress: 1];

        if (self.rom.prgRomSize == 1) {
            prgRom1 = prgRom0;
        }
        
        NSLog(@"prg0: %X, prg1: %X", prgRom0, prgRom1);
        
        [self.rom.data getBytes: bank0 range: NSMakeRange(prgRom0, 0x4000)];
        [self.rom.data getBytes: bank1 range: NSMakeRange(prgRom1, 0x4000)];
        
        // Offset from the last rom bank, this is where vrom lies in the nes format
        uint8_t chrRom[0x2000] = {};
        
        [self.rom.data getBytes: chrRom range: NSMakeRange(prgRom1+0x4000, 0x2000*self.rom.chrRomSize)];
        
        self.ppu = [[Ppu alloc] initWithCpu: self.cpu andChrRom: chrRom];

        uint16_t prgBank0 = (prgRom0-16)+0x8000;
        uint16_t prgBank1 = (prgRom1-16)+0x8000;

        if (self.rom.prgRomSize == 1) {
            prgBank1 += 0x4000;
        }
        
        NSLog(@"prgBank0: %X, prgBank1: %X", prgBank0, prgBank1);
        
        // write prg rom to cpu mem
        [self.cpu writePrgRom:bank0 toAddress: prgBank0];
        [self.cpu writePrgRom:bank1 toAddress: prgBank1];
        
        // set pc to the address stored at FFFD/FFFC (usually 0x8000)
        self.cpu.reg_pc = (self.cpu.memory[0xFFFD] << 8) | (self.cpu.memory[0xFFFC]);
        NSLog(@"Boot Reg PC: %X", self.cpu.reg_pc);

        self.cpu.ppu = self.ppu;
    }
    return self;
}

//TODO: Fix this run loop up a bit. Make it so you can step through operations
- (void) run {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        for (;;) {
            [self runNextInstruction];
            
            if (self.cpu.isRunning == YES) {
                if (self.debuggerEnabled == YES) {
                    dispatch_sync(dispatch_get_main_queue(), ^{
                        if (self.cpu.currentLine != nil) {
                            [(AppDelegate *)[[NSApplication sharedApplication] delegate] appendToDebuggerWindow: self.cpu.currentLine];
                        }
                    });
                    
                    dispatch_sync(dispatch_get_main_queue(), ^{
                        [[NSNotificationCenter defaultCenter] postNotification: [NSNotification notificationWithName: @"debuggerUpdate" object: nil]];
                    });
                }
            }
        }
    });
}

- (void) runNextInstructionInline {
    [self.cpu runNextInstruction];
    
    if (self.debuggerEnabled) {
        [(AppDelegate *)[[NSApplication sharedApplication] delegate] appendToDebuggerWindow: self.cpu.currentLine];
        [[NSNotificationCenter defaultCenter] postNotification: [NSNotification notificationWithName: @"debuggerUpdate" object: nil]];
    }
}

- (void) runNextInstruction {
    [self.cpu runNextInstruction];
    [self.ppu drawFrame];
}

- (void)buttonStrobe: (int) button
{
    if (self.buttonPressed == (button+1)) {
        [self.cpu writeValue: 1 toAddress: 0x4016];
        self.buttonPressed = 0;
    } else {
        [self.cpu writeValue: 0 toAddress: 0x4016];
    }
}

- (void)keyDown:(NSEvent *)theEvent
{
    int key = [[theEvent valueForKey: @"keyCode"] intValue];
    switch (key) {
        case 0:
            //NSLog(@"A Key Pressed");
            self.buttonPressed = 1;
            break;
        case 1:
            //NSLog(@"B Key Pressed");
            self.buttonPressed = 2;
            break;
        case 126:
            //NSLog(@"Up Key Pressed");
            self.buttonPressed = 5;
            break;
        case 125:
            //NSLog(@"Down Key Pressed");
            self.buttonPressed = 6;
            break;
        case 123:
            //NSLog(@"Left Key Pressed");
            self.buttonPressed = 7;
            break;
        case 124:
            //NSLog(@"Right Key Pressed");
            self.buttonPressed = 8;
            break;
        case 36:
            //self.debuggerEnabled = YES;

            //NSLog(@"Start Key Pressed");
            if (self.debuggerEnabled == NO) {
            //    [self setDebuggerEnabled: YES];
            } else {
            //    [self setDebuggerEnabled: NO];
            }
            self.buttonPressed = 4;
            break;
        case 42:
            //NSLog(@"Select Key Pressed");
            self.buttonPressed = 3;
            break;
            // Ignore all other input
        default:
            self.buttonPressed = 0;
            break;
    }
}

@end
