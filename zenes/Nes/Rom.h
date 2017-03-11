//
//  Rom.h
//  zenes
//
//  Created by zenen jaimes on 5/24/16.
//  Copyright © 2016 zenen jaimes. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Mapper.h"

@class Nes;

@interface Rom : NSObject

@property (copy) NSData *data;
@property (assign) uint16_t header;
@property (assign) uint8_t prgRomSize;
@property (assign) uint8_t chrRomSize;
@property (retain) Mapper *mapper;
@property uint8_t mapperType;
@property uint8_t reg0;
@property uint8_t reg1;
@property uint8_t reg2;
@property uint8_t reg3;
@property uint8_t shiftRegisterCounter;
@property uint8_t shiftRegister;
@property BOOL clearShiftRegister;
@property (strong) Nes *nesInstance;

- (id) init: (NSString *) path;
- (void)processMapper: (uint16_t)address withValue: (uint8_t) value;

@end
