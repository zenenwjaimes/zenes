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
//        cpu = [[Cpu6502 alloc] init];
        cpu = calloc(sizeof(StateCpu), 1);
        cpu->memory = malloc(16 * 0x1000);
        //cpu.nes = self;
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
        uint8_t chrRom[0x10000] = {};
        [self.rom.data getBytes: chrRom range: NSMakeRange(prgRom1+0x4000, 0x2000*self.rom.chrRomSize)];
        
        self.ppu = [[Ppu alloc] initWithCpu: cpu andChrRom: chrRom];

        uint16_t prgBank0 = (prgRom0-16)+0x8000;
        uint16_t prgBank1 = (prgRom1-16)+0x8000;

        if (self.rom.prgRomSize == 1) {
            prgBank1 += 0x4000;
        }
        
        NSLog(@"prgBank0: %X, prgBank1: %X", prgBank0, prgBank1);
        
        // write prg rom to cpu mem
        //[cpu writePrgRom:bank0 toAddress: prgBank0];
        //[cpu writePrgRom:bank1 toAddress: prgBank1];
        // FIXME: Fix the writing of prg rom to memory
        
        // set pc to the address stored at FFFD/FFFC (usually 0x8000)
        cpu->reg_pc = (cpu->memory[0xFFFD] << 8) | (cpu->memory[0xFFFC]);
        NSLog(@"Boot Reg PC: %X", cpu->reg_pc);

        [self.screen resetScreen];
        //cpu.ppu = self.ppu;
        // FIXME: eeeeh
        
        _joystickStrobe = _joystickLastWrite = 0;
    }
    return self;
}

//TODO: Fix this run loop up a bit. Make it so you can step through operations
- (void) run {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        for (;;) {
            [self runNextInstruction];
            
            if (cpu->is_running == YES) {
                if (self.debuggerEnabled == YES) {
                    dispatch_sync(dispatch_get_main_queue(), ^{
                        //if (cpu.currentLine != nil) {
                        //    [(AppDelegate *)[[NSApplication sharedApplication] delegate] appendToDebuggerWindow: cpu.currentLine];
                        //}
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
    //[cpu runNextInstruction];
    
    if (self.debuggerEnabled) {
    //    [(AppDelegate *)[[NSApplication sharedApplication] delegate] appendToDebuggerWindow: cpu.currentLine];
    //    [[NSNotificationCenter defaultCenter] postNotification: [NSNotification notificationWithName: @"debuggerUpdate" object: nil]];
    }
}

- (void) runNextInstruction {
   // [cpu runNextInstruction];
    [self.ppu drawFrame];
}

- (uint8_t)joystickRead
{
    uint8_t ret = 0x00;
    
    switch (_joystickStrobe) {
        case 0:
        case 1:
        case 2:
        case 3:
        case 4:
        case 5:
        case 6:
        case 7:
            ret = (_buttonsPressed & (uint32_t)pow(2.0,_joystickStrobe+1.0))?1:0;
            break;
        case 8:
        case 9:
        case 10:
        case 11:
        case 12:
        case 13:
        case 14:
        case 15:
        case 16:
        case 17:
        case 18:
            ret = 0;
            break;
        case 19:
            ret = 1;
            break;
        case 20:
        case 21:
        case 22:
        case 23:
            ret = 0;
        break;
    }

    _joystickStrobe++;
    if (_joystickStrobe == 24) {
        _joystickStrobe = 0;
    }
    
    return ret;
}

- (uint8_t)joystickReadZapper
{
    uint8_t ret = 0x00;
    
    switch (_joystickStrobe) {
        case 0:
        case 1:
        case 2:
        case 3:
        case 4:
        case 5:
        case 6:
        case 7:
            ret = (_buttonsPressed & (uint32_t)pow(2.0,_joystickStrobe+1.0))?1:0;
            break;
        case 8:
        case 9:
        case 10:
        case 11:
        case 12:
        case 13:
        case 14:
        case 15:
        case 16:
        case 17:
        case 18:
            ret = 1;
            break;
        case 19:
            ret = 0;
            break;
        case 20:
        case 21:
        case 22:
        case 23:
            ret = 0;
            break;
    }
    
    _joystickStrobe++;
    if (_joystickStrobe == 24) {
        _joystickStrobe = 0;
    }
    
    return ret;
}

- (void)joystickWrite: (uint8_t)value
{
    if ((value&1) == 0 && (_joystickLastWrite&1) == 1) {
        _joystickStrobe = 0;
    }
    _joystickLastWrite = value;
}

- (void)keyDown:(NSEvent *)theEvent
{
    int key = [[theEvent valueForKey: @"keyCode"] intValue];
    switch (key) {
        case 0:
            //NSLog(@"A Key Pressed");
            _buttonsPressed |= 2;
            break;
        case 1:
            //NSLog(@"B Key Pressed");
            _buttonsPressed |= 4;
            break;
        case 126:
            //NSLog(@"Up Key Pressed");
            _buttonsPressed |= 32;
            break;
        case 125:
            //NSLog(@"Down Key Pressed");
            _buttonsPressed |= 64;
            break;
        case 123:
            //NSLog(@"Left Key Pressed");
            _buttonsPressed |= 128;
            break;
        case 124:
            //NSLog(@"Right Key Pressed");
            _buttonsPressed |= 256;
            break;
        case 36:
            //NSLog(@"Start Key Pressed");
            _buttonsPressed |= 16;
            break;
        case 42:
            //NSLog(@"Select Key Pressed");
            _buttonsPressed |= 8;
            break;
    }
}

- (void)keyUp:(NSEvent *)theEvent
{
    int key = [[theEvent valueForKey: @"keyCode"] intValue];
    switch (key) {
        case 0:
            //NSLog(@"A Key UnPressed");
            _buttonsPressed &= ~2;
            break;
        case 1:
            //NSLog(@"B Key UnPressed");
            _buttonsPressed &= ~4;
            break;
        case 126:
            //NSLog(@"Up Key UnPressed");
            _buttonsPressed &= ~32;
            break;
        case 125:
            //NSLog(@"Down Key UnPressed");
            _buttonsPressed &= ~64;
            break;
        case 123:
            //NSLog(@"Left Key UnPressed");
            _buttonsPressed &= ~128;
            break;
        case 124:
            //NSLog(@"Right Key UnPressed");
            _buttonsPressed &= ~256;
            break;
        case 36:
            //NSLog(@"Start Key UnPressed");
            _buttonsPressed &= ~16;
            break;
        case 42:
            //NSLog(@"Select Key UnPressed");
            _buttonsPressed &= ~8;
            break;
    }
}

@end
