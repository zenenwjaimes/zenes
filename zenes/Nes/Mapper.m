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
        NSLog(@"Mapper Type %d", self.mapperType);
    }
    
    return self;
}


// @TODO: Implement trainer checks because this could break if one is available
- (uint16_t) getPrgRomAddress: (uint8_t) bank {
    // offset for the header
    uint8_t offset = 16;
    uint16_t address = 0x0;
    
    switch (self.mapperType) {
        case 1:
            address = ((0x4000 * bank) + offset);
            break;
        default:
            @throw [NSException exceptionWithName: @"InvalidMapperType" reason: @"This rom isn't supported" userInfo: nil];
            break;
    }
    
    return address;
}

@end
