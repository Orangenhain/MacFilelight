/* Copyright (C) 1996 Dave Vasilevsky
* This file is licensed under the GNU General Public License,
* see the file Copying.txt for details. */

#import "FLController.h"

#import "FLDirectoryDataSource.h"

@implementation FLController

- (BOOL) application: (NSApplication *)app openFile: (NSString *)filename
{
    [tabView selectTabViewItemWithIdentifier: @"Progress"];
    [progress setDoubleValue: [progress minValue]];
    [scanDisplay setStringValue: @""];
    [window makeKeyAndOrderFront: self];
    
    FLScanner *scanner = [[FLScanner alloc] initWithPath: filename
                                                progress: progress
                                                 display: scanDisplay];
//    [scanner autorelease];
    
    if (m_worker) {
        [m_worker release];
    }
    
    m_worker = [[ThreadWorker workOn: self
                        withSelector: @selector(startScan:worker:)
                          withObject: scanner
                      didEndSelector: @selector(finishScan:)] retain];
    return YES;
}

- (id) startScan: (id) data worker: (ThreadWorker *) tw
{
    FLScanner *scanner = (FLScanner *)data;
    [scanner scanWithWorker: tw];
    return scanner;
}

- (void) finishScan: (id) data
{
    FLScanner *scanner = (FLScanner *)data;
    if ([scanner scanError]) {
        NSRunAlertPanel(@"Directory scan could not complete",
                        [scanner scanError], nil, nil, nil);
        [window orderOut: self];
    } else {
        NSLog(@"%@", [self class]);
        NSLog(@"%@", [[scanner test] class]);
        NSLog(@"%@", [[[scanner test] copy] class]);
        [[sizer dataSource] setRootDir: [scanner scanResult]];
        [tabView selectTabViewItemWithIdentifier: @"Filelight"];       
    }
}

- (IBAction) open: (id) sender
{
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    [openPanel setCanChooseDirectories: YES];
    [openPanel setCanChooseFiles: NO];
    int result = [openPanel runModalForTypes: nil];
    if (result == NSOKButton) {
        NSString *path = [[openPanel filenames] objectAtIndex: 0];
        [self application: [NSApplication sharedApplication] openFile: path];
    }
}

- (void) applicationDidFinishLaunching: (NSNotification*) notification
{
    if (![window isVisible]) {
        [self open: self];
    }
}

- (IBAction) cancelScan: (id) sender
{
    if (m_worker) {
        [m_worker markAsCancelled];
    }
}

@end
