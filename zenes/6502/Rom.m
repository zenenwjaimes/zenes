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
        
        uint16_t tempHeader;
        [self.data getBytes: &tempHeader length: 16];
        
        self.header = tempHeader;
    }
    
    return self;
}

@end
