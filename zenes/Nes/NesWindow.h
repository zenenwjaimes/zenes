//
//  NesWindow.h
//  zenes
//
//  Created by zenen jaimes on 5/31/16.
//  Copyright © 2016 zenen jaimes. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <AppKit/AppKit.h>
#import "Nes.h"
#import "Screen.h"

@interface NesWindow : NSWindow

@property (strong) Nes *nesInstance;
@property IBOutlet Screen *nesScreen;

- (IBAction)dumpMemory:(id)sender;
- (IBAction)playButton:(id)sender;
- (IBAction)pauseButton:(id)sender;
- (IBAction)stepIntoButton:(id)sender;

@end
