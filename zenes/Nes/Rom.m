//
//  Rom.m
//  zenes
//
//  Created by zenen jaimes on 5/24/16.
//  Copyright © 2016 zenen jaimes. All rights reserved.
//

#import "Rom.h"

@implementation Rom

- (id) init: (NSString *) path {
    if (self = [super init]) {
        self.data = [[NSFileManager defaultManager] contentsAtPath: path];
        
        self.prgRomSize = ((uint8_t  *)[self.data bytes])[4];
        self.chrRomSize = ((uint8_t  *)[self.data bytes])[5];
        self.mapperType = ((uint8_t  *)[self.data bytes])[6];

        NSLog(@"Program Rom Size: %X", ((uint8_t  *)[self.data bytes])[4]);
        NSLog(@"Character Rom Size: %X", ((uint8_t  *)[self.data bytes])[5]);

        self.mapper = [[Mapper alloc] initWithType: self.mapperType];
    }
    
    return self;
}

@end
