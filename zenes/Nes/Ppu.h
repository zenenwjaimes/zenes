//
//  Ppu.h
//  
//
//  Created by zenen jaimes on 6/11/16.
//
//

#import <Foundation/Foundation.h>
#import "Cpu6502.h"

@interface Ppu : NSObject
{
    
}

@property (retain) Cpu6502 *cpu;
@property uint8_t currentScanline;


-(id)initWithCpu: (Cpu6502 *)cpu;

@end
