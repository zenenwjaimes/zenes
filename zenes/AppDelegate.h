//
//  AppDelegate.h
//  zenes
//
//  Created by zenen jaimes on 5/23/16.
//  Copyright © 2016 zenen jaimes. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Nes/NesWindow.h"
#import "Nes/Nes.h"
#import "Nes/Rom.h"

@interface AppDelegate : NSObject <NSApplicationDelegate>

@property IBOutlet NSTextView *debuggerWindow;

- (void)appendToDebuggerWindow:(NSString*)text;

@end

