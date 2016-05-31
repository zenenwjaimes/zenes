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
    }
    return self;
}

- (void) run {
    
}


@end
