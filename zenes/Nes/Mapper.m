//
//  Mapper.m
//  zenes
//
//  Created by zenen jaimes on 5/31/16.
//  Copyright © 2016 zenen jaimes. All rights reserved.
//

#import "Mapper.h"

@implementation Mapper

- (id) initWithType: (uint8_t) mapperType {
    if (self = [super init]) {
        self.mapperType = mapperType;
        NSLog(@"%d", self.mapperType);
    }
    
    return self;
}

@end
