//
//  Rom.h
//  zenes
//
//  Created by zenen jaimes on 5/24/16.
//  Copyright © 2016 zenen jaimes. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Mapper.h"

@interface Rom : NSObject

@property (copy) NSData *data;
@property (assign) uint16_t header;
@property (assign) uint8_t prgRomSize;
@property (assign) uint8_t chrRomSize;
@property (retain) Mapper *mapper;

- (id) init: (NSString *) path;

@end
