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
#import "Nes/Screen.h"
#import "Cpu6502.h"

@interface AppDelegate : NSObject <NSApplicationDelegate, NSTableViewDataSource, NSTableViewDelegate>

@property IBOutlet NSTextView *debuggerWindow;
@property IBOutlet NSTableView *debuggerTable;

- (void)appendToDebuggerWindow:(NSString*)text;

@end

