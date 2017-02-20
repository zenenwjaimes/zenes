//
//  Screen.m
//  zenes
//
//  Created by zenen jaimes on 6/6/16.
//  Copyright © 2016 zenen jaimes. All rights reserved.
//

#import "Screen.h"

@implementation Screen
@synthesize currPixel;

- (void) prepareOpenGL
{
    [super prepareOpenGL];
    self.currPixel = 0;
    
    /*uint8_t deadPixels[3][5] = {
        {0,0,0,0,0},
        {0,0,0,0,0},
        {0,0,0,0,0}
    };
    memcpy(pixels, deadPixels, sizeof(uint8_t)*5*3);*/
}

- (void)drawRect:(NSRect)dirtyRect
{
    [super drawRect:dirtyRect];
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    glOrtho(0, 256, 240, 0, 0, 1);
    glMatrixMode(GL_MODELVIEW);
    glClearColor(1, 1, 1, 0);
    glClear(GL_COLOR_BUFFER_BIT);

    //[self drawFrame];
    int pixelCounter = 0;
    for (int row = 0; row < 240; row++) {
        for (int col = 0; col < 256; col++) {

            uint8_t x = pixels[pixelCounter][0];
            uint8_t y = pixels[pixelCounter][1];
            uint8_t r = pixels[pixelCounter][2];
            uint8_t g = pixels[pixelCounter][3];
            uint8_t b = pixels[pixelCounter][4];

            glBegin(GL_POINTS);
            glColor3ub(r, g, b);
            glVertex2i(x, y);
            glEnd();
            
            pixelCounter++;
        }
    }
    
    glFlush();
}

- (void)loadPixelsToDrawAtX: (uint8_t)x atY: (uint8_t)y withR: (uint8_t)r G: (uint8_t)g B: (uint8_t)b
{
    if (self.currPixel > 256*240) {
        self.currPixel = 0;
    }
    pixels[self.currPixel][0] = x;
    pixels[self.currPixel][1] = y;
    pixels[self.currPixel][2] = r;
    pixels[self.currPixel][3] = g;
    pixels[self.currPixel][4] = b;
    
    self.currPixel++;
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
