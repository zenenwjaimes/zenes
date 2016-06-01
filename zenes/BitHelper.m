//
//  BitHelper.m
//  zenes
//
//  Created by zenen jaimes on 5/31/16.
//  Copyright © 2016 zenen jaimes. All rights reserved.
//

#import "BitHelper.h"

@implementation BitHelper

+ (NSString *)intToBinary:(uint8_t)number {
    // Number of bits
    int bits =  sizeof(number) * 8;
    
    // Create mutable string to hold binary result
    NSMutableString *binaryStr = [NSMutableString string];
    
    // For each bit, determine if 1 or 0
    // Bitwise shift right to process next number
    for (; bits > 0; bits--, number >>= 1)
    {
        // Use bitwise AND with 1 to get rightmost bit
        // Insert 0 or 1 at front of the string
        [binaryStr insertString:((number & 1) ? @"1" : @"0") atIndex:0];
    }
    
    return (NSString *)binaryStr;
}

@end
