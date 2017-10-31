//
//  NesWindow.m
//  zenes
//
//  Created by zenen jaimes on 5/31/16.
//  Copyright © 2016 zenen jaimes. All rights reserved.
//

#import "NesWindow.h"

@implementation NesWindow

- (IBAction)playButton:(id)sender
{
 //   if (self.nesInstance.cpu.isRunning == YES) {
        [self.nesInstance run];
  //  }
}

- (IBAction)pauseButton:(id)sender
{
 //   if (self.nesInstance.cpu.isRunning == NO) {
  //      [self.nesInstance.cpu setIsRunning: YES];
  //  } else {
 //       [self.nesInstance.cpu setIsRunning: NO];
 //   }
}

- (IBAction)stepIntoButton:(id)sender
{
 //   if (self.nesInstance.cpu.isRunning == NO) {
 //       [self.nesInstance.cpu setIsRunning: YES];
  //  }
    [self.nesInstance runNextInstructionInline];
    
    
}


- (IBAction)memoryDumpButton:(id)sender
{
    if (self.nesInstance.debuggerEnabled == YES) {
        self.nesInstance.debuggerEnabled = NO;
    } else {
        self.nesInstance.debuggerEnabled = YES;
    }
}

- (void)keyDown:(NSEvent *)theEvent
{
    [self.nesInstance keyDown: theEvent];
}

- (void)keyUp:(NSEvent *)theEvent
{
    [self.nesInstance keyUp: theEvent];
}

@end
