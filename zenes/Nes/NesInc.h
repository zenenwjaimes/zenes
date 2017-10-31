//
//  NesInc.h
//  zenes
//
//  Created by zenen jaimes on 2/16/17.
//  Copyright © 2017 zenen jaimes. All rights reserved.
//

#ifndef NesInc_h
#define NesInc_h

#import "Rom.h"
//#import "Cpu6502.h"
#import "Screen.h"
#import "Cpu.h"

struct ppuFrameData;

typedef struct ppuFrameData {
    uint8_t pixels[340][262];
} ppuFrameData;

#endif /* NesInc_h */
