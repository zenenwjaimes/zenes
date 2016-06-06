//
//  Screen.h
//  zenes
//
//  Created by zenen jaimes on 6/6/16.
//  Copyright © 2016 zenen jaimes. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <OpenGL/gl.h>

@interface Screen : NSOpenGLView

- (void)drawFrame: (uint8_t **)frameData;
- (void)test;

@end
