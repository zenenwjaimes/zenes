//
//  Rom.m
//  zenes
//
//  Created by zenen jaimes on 5/24/16.
//  Copyright © 2016 zenen jaimes. All rights reserved.
//

#import "Rom.h"
#import "BitHelper.h"

@implementation Rom

- (id) init: (NSString *) path {
    if (self = [super init]) {
        self.data = [[NSFileManager defaultManager] contentsAtPath: path];
        
        self.prgRomSize = ((uint8_t  *)[self.data bytes])[4];
        self.chrRomSize = ((uint8_t  *)[self.data bytes])[5];
        
        NSLog(@"Program Rom Size: %X", ((uint8_t  *)[self.data bytes])[4]);
        NSLog(@"Character Rom Size: %X", ((uint8_t  *)[self.data bytes])[5]);

        self.mapper = [[Mapper alloc] init];
    }
    
    return self;
}

@end
