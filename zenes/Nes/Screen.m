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
    NSLog(@"drawing going on?");
    //[super drawRect:dirtyRect];
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    glOrtho(0, 256, 240, 0, 0, 1);
    glMatrixMode(GL_MODELVIEW);
    glClearColor(1, 1, 1, 0);
    glClear(GL_COLOR_BUFFER_BIT);

    [self drawFrame];
    
    glFlush();
}

- (void)drawFrame
{
    
}

- (void)drawPixelAtX: (uint8_t)x atY: (uint8_t)y withR: (uint8_t)r G: (uint8_t)g B: (uint8_t)b
{
    glBegin(GL_POINTS);
    glColor3ub(r, g, b);
    glVertex2i(x, y);
    
    glEnd();
}

@end
