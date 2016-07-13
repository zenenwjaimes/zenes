//
//  Screen.m
//  zenes
//
//  Created by zenen jaimes on 6/6/16.
//  Copyright © 2016 zenen jaimes. All rights reserved.
//

#import "Screen.h"

@implementation Screen

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    glClearColor(0, 0, 0, 0);
    glClear(GL_COLOR_BUFFER_BIT);

    // Draw the next frame

    //[self drawFrame: ];
    
    glFlush();
}

- (void)test {
    NSLog(@"testing here");
}

- (void)drawFrame: (uint8_t **)frameData {
    
}

@end
