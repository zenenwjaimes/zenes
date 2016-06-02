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
    Rom *rom = [[Rom alloc] init: @"/Users/slasherx/Desktop/mario.nes"];
    Nes *nesInstance = [[Nes alloc] initWithRom: rom];
    
    self.window.nesInstance = nesInstance;
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

@end
