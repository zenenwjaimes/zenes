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
    [self.debuggerWindow setEditable: NO];
    [self.debuggerWindow setFont: [NSFont fontWithName: @"Menlo" size: 11.0]];
    [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(updateRegs:) name: @"debuggerUpdate" object: nil];
}

- (void)updateRegs: (NSNotification *) notification{
    NSLog(@"update regs?????");
    [self.debuggerTable reloadData];
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


- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return 11;
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    // Get an existing cell with the MyView identifier if it exists
    NSTextField *result = [tableView makeViewWithIdentifier:@"MyView" owner:self];
    
    // There is no existing cell to reuse so create a new one
    if (result == nil) {
        
        // Create the new NSTextField with a frame of the {0,0} with the width of the table.
        // Note that the height of the frame is not really relevant, because the row height will modify the height.
        result = [[NSTextField alloc] initWithFrame: CGRectMake(0, 0, 0, 0)];
        // The identifier of the NSTextField instance is set to MyView.
        // This allows the cell to be reused.
        result.identifier = @"MyView";
        result.bezeled = NO;
    }

    switch (row) {
        case 0:
            if ([tableColumn.identifier isEqualToString: @"reg"]) {
                result.stringValue = @"OP1";
            } else {
                result.stringValue = [[NSNumber numberWithUnsignedInteger: self.window.nesInstance.cpu.op1] stringValue];
            }
            break;
        case 1:
            if ([tableColumn.identifier isEqualToString: @"reg"]) {
                result.stringValue = @"OP2";
            } else {
                result.stringValue = [[NSNumber numberWithUnsignedInteger: self.window.nesInstance.cpu.op2] stringValue];
            }
            break;
        case 2:
            if ([tableColumn.identifier isEqualToString: @"reg"]) {
                result.stringValue = @"OP3";
            } else {
                result.stringValue = [[NSNumber numberWithUnsignedInteger: self.window.nesInstance.cpu.op3] stringValue];
            }
            break;
        case 3:
            if ([tableColumn.identifier isEqualToString: @"reg"]) {
                result.stringValue = @"IntP";
            } else {
                result.stringValue = [[NSNumber numberWithInt: self.window.nesInstance.cpu.interruptPeriod] stringValue];
            }
            break;
        case 4:
            if ([tableColumn.identifier isEqualToString: @"reg"]) {
                result.stringValue = @"Counter";
            } else {
                result.stringValue = [[NSNumber numberWithLong: self.window.nesInstance.cpu.counter] stringValue];
            }
            break;
        case 5:
            if ([tableColumn.identifier isEqualToString: @"reg"]) {
                result.stringValue = @"ACC";
            } else {
                result.stringValue = [[NSNumber numberWithUnsignedInteger: self.window.nesInstance.cpu.reg_acc] stringValue];
            }
            break;
        case 6:
            if ([tableColumn.identifier isEqualToString: @"reg"]) {
                result.stringValue = @"X";
            } else {
                result.stringValue = [[NSNumber numberWithUnsignedInteger: self.window.nesInstance.cpu.reg_x] stringValue];
            }
            break;
        case 7:
            if ([tableColumn.identifier isEqualToString: @"reg"]) {
                result.stringValue = @"Y";
            } else {
                result.stringValue = [[NSNumber numberWithUnsignedInteger: self.window.nesInstance.cpu.reg_y] stringValue];
            }
            break;
        case 8:
            if ([tableColumn.identifier isEqualToString: @"reg"]) {
                result.stringValue = @"SP";
            } else {
                result.stringValue = [[NSNumber numberWithUnsignedInteger: self.window.nesInstance.cpu.reg_sp] stringValue];
            }
            break;
        case 9:
            if ([tableColumn.identifier isEqualToString: @"reg"]) {
                result.stringValue = @"STATUS";
            } else {
                result.stringValue = [[NSNumber numberWithUnsignedInteger: self.window.nesInstance.cpu.reg_status] stringValue];
            }
            break;
        case 10:
            if ([tableColumn.identifier isEqualToString: @"reg"]) {
                result.stringValue = @"PC";
            } else {
                result.stringValue = [[NSNumber numberWithDouble: self.window.nesInstance.cpu.op1] stringValue];
            }
            break;
    }
    //result.stringValue = @"test";
    
    // Return the result
    return result;
}

@end
