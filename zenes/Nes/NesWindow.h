//
//  NesWindow.h
//  zenes
//
//  Created by zenen jaimes on 5/31/16.
//  Copyright © 2016 zenen jaimes. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Nes.h"

@interface NesWindow : NSWindow

@property (strong) Nes *nesInstance;

- (IBAction)playButton:(id)sender;
- (IBAction)pauseButton:(id)sender;
- (IBAction)stepIntoButton:(id)sender;


@end
