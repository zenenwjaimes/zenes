//
//  BitHelper.h
//  zenes
//
//  Created by zenen jaimes on 5/31/16.
//  Copyright © 2016 zenen jaimes. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BitHelper : NSObject

+ (NSString *)intToBinary:(uint8_t)number;
+ (uint8_t)checkBit: (uint8_t)p on: (uint8_t)value;

@end
