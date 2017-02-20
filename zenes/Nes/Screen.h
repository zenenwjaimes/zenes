//
//  Screen.h
//  zenes
//
//  Created by zenen jaimes on 6/6/16.
//  Copyright © 2016 zenen jaimes. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <OpenGL/gl.h>
#include "NesInc.h"

@interface Screen : NSOpenGLView

- (void)drawPixelAtX: (uint8_t)x atY: (uint8_t)y withR: (uint8_t)r G: (uint8_t)g B: (uint8_t)b;
- (void)drawFrame;

@end
