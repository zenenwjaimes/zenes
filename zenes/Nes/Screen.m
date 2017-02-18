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
    glClearColor(0, 0, 0, 0);
    glClear(GL_COLOR_BUFFER_BIT);

    [self drawFrame];
    free(self.pixels);
    
    glFlush();
}

- (void)setFrameData: (int ***)frameData
{
    self.pixels = frameData;
    //[self setNeedsDisplay: YES];
}

- (void)drawFrame
{
    if (!self.pixels) {
        return;
    }
    
    for (int y = 0; y < 240; y++) {
        for (int x = 0; x < 256; x++) {
            glBegin(GL_POINTS);
            glColor3ub(self.pixels[y][x][0], self.pixels[y][x][1], self.pixels[y][x][2]);
            glVertex2i(x, y);
            
            glEnd();
        }
    }
}

@end
