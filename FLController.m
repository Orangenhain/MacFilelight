/* Copyright (C) 1996 Dave Vasilevsky
* This file is licensed under the GNU General Public License,
* see the file Copying.txt for details. */

#import "FLController.h"

#import "FLDirectoryDataSource.h"

@implementation FLController

- (BOOL) application: (NSApplication *)app openFile: (NSString *)filename
{
    [[sizer dataSource] setRootPath: filename];
    [[sizer window] makeKeyAndOrderFront: self];
    return YES;
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
    if (![[sizer window] isVisible]) {
        [self open: self];
    }
}

@end
