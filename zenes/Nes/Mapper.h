//
//  Mapper.h
//  zenes
//
//  Created by zenen jaimes on 5/31/16.
//  Copyright © 2016 zenen jaimes. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Mapper : NSObject

@property (assign) uint8_t mapperType;

- (id) initWithType: (uint8_t) mapperType;
@end