//
//  AppDelegate.m
//  zenes
//
//  Created by zenen jaimes on 5/23/16.
//  Copyright © 2016 zenen jaimes. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
    
//    NSData *romData = [[NSFileManager defaultManager] contentsAtPath: @"/Users/slasherx/Desktop/mario.nes"];
    
    Cpu6502 *cpu6502 = [[Cpu6502 alloc] init];
    NSLog(@"%X", cpu6502.reg_pc);
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

@end
