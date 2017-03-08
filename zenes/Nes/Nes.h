//
//  Nes.h
//  zenes
//
//  Created by zenen jaimes on 5/24/16.
//  Copyright © 2016 zenen jaimes. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NesInc.h"

@interface Nes : NSObject
{
    uint16_t _buttonsPressed;
    uint8_t _joystickStrobe;
    uint8_t _joystickLastWrite;
}

@property (retain) Rom *rom;
@property (retain) Cpu6502 *cpu;
@property (retain) Screen *screen;
@property (retain) Ppu *ppu;
@property BOOL debuggerEnabled;

- (id) initWithRom: (Rom *)rom;
- (void) run;
- (void) runNextInstruction;
- (void) runNextInstructionInline;
- (void)keyDown:(NSEvent *)theEvent;
- (void)keyUp:(NSEvent *)theEvent;
- (uint8_t)joystickRead;
- (uint8_t)joystickReadZapper;
- (void)joystickWrite: (uint8_t)value;

@end
