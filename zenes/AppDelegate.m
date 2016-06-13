//
//  AppDelegate.m
//  zenes
//
//  Created by zenen jaimes on 5/23/16.
//  Copyright © 2016 zenen jaimes. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate ()

@property (weak) IBOutlet NesWindow *window;

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    Rom *rom = [[Rom alloc] init: @"/Users/slasherx/Desktop/donkey.nes"];
    Nes *nesInstance = [[Nes alloc] initWithRom: rom];
    
    self.window.nesInstance = nesInstance;
    [self.debuggerWindow setEditable: NO];
    [self.debuggerWindow setFont: [NSFont fontWithName: @"Menlo" size: 11.0]];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

- (void)appendToDebuggerWindow:(NSString*)text
{
    dispatch_async(dispatch_get_main_queue(), ^{
        NSAttributedString* attr = [[NSAttributedString alloc] initWithString:text];
        [[self.debuggerWindow textStorage] appendAttributedString:attr];
        [self.debuggerWindow scrollRangeToVisible:NSMakeRange([[self.debuggerWindow string] length], 0)];
    });
}

@end
