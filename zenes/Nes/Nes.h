//
//  Nes.h
//  zenes
//
//  Created by zenen jaimes on 5/24/16.
//  Copyright © 2016 zenen jaimes. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Rom.h"
#import "Cpu6502.h"

@interface Nes : NSObject

@property (retain) Rom *rom;
@property (retain) Cpu6502 *cpu;

- (id) initWithRom: (Rom *)rom;

- (void) run;
- (void) runNextInstruction;

@end
