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

@property (retain) Rom *rom;
@property (retain) Cpu6502 *cpu;
@property (retain) Screen *screen;
@property (retain) Ppu *ppu;
@property int buttonPressed;
@property BOOL debuggerEnabled;

- (id) initWithRom: (Rom *)rom;
- (void) run;
- (void) runNextInstruction;
- (void) runNextInstructionInline;
- (void)keyDown:(NSEvent *)theEvent;
- (void)buttonStrobe: (int) button;

@end
