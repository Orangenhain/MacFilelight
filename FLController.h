/* Copyright (C) 1996 Dave Vasilevsky
 * This file is licensed under the GNU General Public License,
 * see the file Copying.txt for details. */

@interface FLController : NSObject {
    IBOutlet id dataSource;
    IBOutlet id sizer;
}

- (IBAction) open: (id) sender; 

@end
