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

@property (assign, nonatomic) int **pixels;

- (void)setFrameData: (int **)frameData;
- (void)drawFrame;

@end
