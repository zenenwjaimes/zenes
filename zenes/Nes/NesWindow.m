//
//  NesWindow.m
//  zenes
//
//  Created by zenen jaimes on 5/31/16.
//  Copyright © 2016 zenen jaimes. All rights reserved.
//

#import "NesWindow.h"

@implementation NesWindow

- (IBAction)playButton:(id)sender {
    //NSLog(@"Play button");
    if (self.nesInstance.cpu.isRunning == YES) {
        [self.nesInstance run];
    }
}

- (IBAction)pauseButton:(id)sender {
    //NSLog(@"Pause button");
    if (self.nesInstance.cpu.isRunning == NO) {
        [self.nesInstance.cpu setIsRunning: YES];
    } else {
        [self.nesInstance.cpu setIsRunning: NO];
    }
}

- (IBAction)stepIntoButton:(id)sender {
    [self.nesInstance runNextInstruction];
}

@end
