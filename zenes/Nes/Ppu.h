//
//  Ppu.h
//  
//
//  Created by zenen jaimes on 6/11/16.
//
//

#import <Foundation/Foundation.h>

@interface Ppu : NSObject
{
    uint8_t _memory[0x10000];
}


@property (assign, nonatomic) uint8_t *memory;

@end
