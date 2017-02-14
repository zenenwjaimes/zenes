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

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    Rom *rom = [[Rom alloc] init: @"/Users/zenenjaimes/Desktop/nestest.nes"];
    Nes *nesInstance = [[Nes alloc] initWithRom: rom];

    self.window.nesInstance = nesInstance;
//    [self.debuggerWindow setEditable: NO];
//    [self.debuggerWindow setFont: [NSFont fontWithName: @"Menlo" size: 11.0]];
    
    [self.debuggerMemory setEditable: NO];
    [self.debuggerMemory setFont: [NSFont fontWithName: @"Menlo" size: 11.0]];
    [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(updateRegs:) name: @"debuggerUpdate" object: nil];
}

- (void)updateRegs: (NSNotification *) notification
{
    [self.debuggerTable reloadData];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification
{
    // Insert code here to tear down your application
}

- (void)appendToDebuggerWindow:(NSString*)text
{
    dispatch_async(dispatch_get_main_queue(), ^{
        NSAttributedString* attr = [[NSAttributedString alloc] initWithString: text];
        [[self.debuggerMemory textStorage] appendAttributedString:attr];
        [self.debuggerMemory scrollRangeToVisible:NSMakeRange([[self.debuggerMemory string] length], 0)];
    });
}

- (void)setDebuggerMemoryText: (uint8_t *) memory
{
    dispatch_async(dispatch_get_main_queue(), ^{
        //NSMutableString *text = [NSMutableString string];
        
        //for (int i = 0; i < 0x10000; i++) {
        //    [text appendString: [NSString stringWithFormat: @"%X: %X\n", i, memory[i]]];
        //}
        
        //NSAttributedString* attr = [[NSAttributedString alloc] initWithString:@"px"];
        //[[self.debuggerMemory textStorage] appendAttributedString: attr];
    });
}


- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return 20;
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
                result.stringValue = [NSString stringWithFormat: @"%X", self.window.nesInstance.cpu.op1];
            }
            break;
        case 1:
            if ([tableColumn.identifier isEqualToString: @"reg"]) {
                result.stringValue = @"OP2";
            } else {
                result.stringValue = [NSString stringWithFormat: @"%X", self.window.nesInstance.cpu.op2];
            }
            break;
        case 2:
            if ([tableColumn.identifier isEqualToString: @"reg"]) {
                result.stringValue = @"OP3";
            } else {
                result.stringValue = [NSString stringWithFormat: @"%X",  self.window.nesInstance.cpu.op3];
            }
            break;
        case 3:
            if ([tableColumn.identifier isEqualToString: @"reg"]) {
                result.stringValue = @"IntP";
            } else {
                result.stringValue = [BitHelper intToBinary: self.window.nesInstance.cpu.interruptPeriod];
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
                result.stringValue = [NSString stringWithFormat: @"%X", self.window.nesInstance.cpu.reg_acc];
            }
            break;
        case 6:
            if ([tableColumn.identifier isEqualToString: @"reg"]) {
                result.stringValue = @"X";
            } else {
                result.stringValue = [NSString stringWithFormat: @"%X", self.window.nesInstance.cpu.reg_x];
            }
            break;
        case 7:
            if ([tableColumn.identifier isEqualToString: @"reg"]) {
                result.stringValue = @"Y";
            } else {
                result.stringValue = [NSString stringWithFormat: @"%X",  self.window.nesInstance.cpu.reg_y];
            }
            break;
        case 8:
            if ([tableColumn.identifier isEqualToString: @"reg"]) {
                result.stringValue = @"SP";
            } else {
                result.stringValue = [NSString stringWithFormat: @"%X", self.window.nesInstance.cpu.reg_sp];
            }
            break;
        case 9:
            if ([tableColumn.identifier isEqualToString: @"reg"]) {
                result.stringValue = @"STATUS";
            } else {
                result.stringValue = [BitHelper intToBinary: self.window.nesInstance.cpu.reg_status];
            }
            break;
        case 10:
            if ([tableColumn.identifier isEqualToString: @"reg"]) {
                result.stringValue = @"PC";
            } else {
                result.stringValue = [NSString stringWithFormat: @"%X", self.window.nesInstance.cpu.op1];
            }
            break;
        case 11:
            if ([tableColumn.identifier isEqualToString: @"reg"]) {
                result.stringValue = @"Curr SP Val";
            } else {
                if (self.window.nesInstance.cpu.isRunning == YES) {
                    result.stringValue = [NSString stringWithFormat: @"%X", self.window.nesInstance.cpu.memory[0x100+self.window.nesInstance.cpu.reg_sp+1]];
                }
            }
            break;
        case 12:
            if ([tableColumn.identifier isEqualToString: @"reg"]) {
                result.stringValue = @"Sign Flag";
            } else {
                result.stringValue = [NSString stringWithFormat: @"%@", [self.window.nesInstance.cpu checkFlag: STATUS_NEGATIVE_BIT]?@"Y":@"N"];
            }
            break;
        case 13:
            if ([tableColumn.identifier isEqualToString: @"reg"]) {
                result.stringValue = @"Zero Flag";
            } else {
                result.stringValue = [NSString stringWithFormat: @"%@", [self.window.nesInstance.cpu checkFlag: STATUS_ZERO_BIT]?@"Y":@"N"];
            }
            break;
        case 14:
            if ([tableColumn.identifier isEqualToString: @"reg"]) {
                result.stringValue = @"IRQ Flag";
            } else {
                result.stringValue = [NSString stringWithFormat: @"%@", [self.window.nesInstance.cpu checkFlag: STATUS_IRQ_BIT]?@"Y":@"N"];
            }
            break;
        case 15:
            if ([tableColumn.identifier isEqualToString: @"reg"]) {
                result.stringValue = @"Decimal Flag";
            } else {
                result.stringValue = [NSString stringWithFormat: @"%@", [self.window.nesInstance.cpu checkFlag: STATUS_DECIMAL_BIT]?@"Y":@"N"];
            }
            break;
        case 16:
            if ([tableColumn.identifier isEqualToString: @"reg"]) {
                result.stringValue = @"Carry Flag";
            } else {
                result.stringValue = [NSString stringWithFormat: @"%@", [self.window.nesInstance.cpu checkFlag: STATUS_CARRY_BIT]?@"Y":@"N"];
            }
            break;
        case 17:
            if ([tableColumn.identifier isEqualToString: @"reg"]) {
                result.stringValue = @"Overflow Flag";
            } else {
                result.stringValue = [NSString stringWithFormat: @"%@", [self.window.nesInstance.cpu checkFlag: STATUS_OVERFLOW_BIT]?@"Y":@"N"];
            }
            break;
        case 18:
            if ([tableColumn.identifier isEqualToString: @"reg"]) {
                result.stringValue = @"Unused Flag";
            } else {
                result.stringValue = [NSString stringWithFormat: @"%@", [self.window.nesInstance.cpu checkFlag: STATUS_UNUSED_BIT]?@"Y":@"N"];
            }
            break;
        case 19:
            if ([tableColumn.identifier isEqualToString: @"reg"]) {
                result.stringValue = @"Break Flag";
            } else {
                result.stringValue = [NSString stringWithFormat: @"%@", [self.window.nesInstance.cpu checkFlag: STATUS_BREAK_BIT]?@"Y":@"N"];
            }
            break;
    }
    //result.stringValue = @"test";
    
    // Return the result
    return result;
}

@end
