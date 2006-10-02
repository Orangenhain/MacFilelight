/* Copyright (C) 1996 Dave Vasilevsky
 * This file is licensed under the GNU General Public License,
 * see the file Copying.txt for details. */

#import "ThreadWorker.h"
#import "FLScanner.h"

@interface FLController : NSObject {
    IBOutlet id sizer;
    IBOutlet id tabView;
    IBOutlet id progress;
    IBOutlet id scanDisplay;
    IBOutlet id window;
    
    ThreadWorker *m_worker;
}

- (IBAction) cancelScan: (id) sender;
- (IBAction) open: (id) sender; 

@end
