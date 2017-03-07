//
//  Screen.m
//  zenes
//
//  Created by zenen jaimes on 6/6/16.
//  Copyright © 2016 zenen jaimes. All rights reserved.
//

#import "Screen.h"

@implementation Screen

- (void) prepareOpenGL
{
    self.currIndex = 0;
    [super prepareOpenGL];
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    glOrtho(0, 256, 240, 0, 0, 1);
    glMatrixMode(GL_MODELVIEW);
}

- (void)drawRect:(NSRect)dirtyRect
{
  //[super drawRect:dirtyRect];
    glClearColor(1, 1, 1, 0);
    glClear(GL_COLOR_BUFFER_BIT);

    //[self drawFrame];
    for (int i = 0; i < 240*256; i++) {
            uint8_t x = pixels[i][0];
            uint8_t y = pixels[i][1];
            uint8_t r = pixels[i][2];
            uint8_t g = pixels[i][3];
            uint8_t b = pixels[i][4];
            
            glBegin(GL_POINTS);
            glColor3ub(r, g, b);
            glVertex2i(x, y);
            glEnd();
    }
    
    glFlush();
    [[self openGLContext] flushBuffer];
}

- (void)resetScreen
{
    for (int i = 0; i < 240*256; i++) {
        pixels[i][0] = 0;
        pixels[i][1] = 0;
        pixels[i][2] = 0;
        pixels[i][3] = 0;
        pixels[i][4] = 0;
    }
}

- (void)loadPixelsToDrawAtX: (uint8_t)x atY: (uint8_t)y withR: (uint8_t)r G: (uint8_t)g B: (uint8_t)b
{
    pixels[self.currIndex][0] = x;
    pixels[self.currIndex][1] = y;
    pixels[self.currIndex][2] = r;
    pixels[self.currIndex][3] = g;
    pixels[self.currIndex][4] = b;
    
    self.currIndex++;
    if (self.currIndex >= 256*240) {
        self.currIndex = 0;
    }
}

@end
