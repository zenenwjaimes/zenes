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
    [self.nesInstance run];
}

- (IBAction)pauseButton:(id)sender {
    //NSLog(@"Pause button");
}

- (IBAction)stepIntoButton:(id)sender {
    [self.nesInstance runNextInstruction];
}

@end
