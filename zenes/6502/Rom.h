//
//  Rom.h
//  zenes
//
//  Created by zenen jaimes on 5/24/16.
//  Copyright © 2016 zenen jaimes. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Rom : NSObject

@property (copy) NSData *data;
@property (assign) uint16_t header;

@end
