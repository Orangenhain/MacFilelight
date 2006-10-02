/* Copyright (C) 1996 Dave Vasilevsky
 * This file is licensed under the GNU General Public License,
 * see the file Copying.txt for details. */

#import "FLFile.h"

#import "ThreadWorker.h"

@interface FLScanner : NSObject {
    NSString *m_path;
    NSProgressIndicator *m_pi;
    NSTextField *m_display;
    
    FLDirectory *m_tree;
    NSString *m_error;
    
    double m_increment;
    double m_progress;
    unsigned m_seen;
    
    id m_test;
}

- (id) initWithPath: (NSString *) path
           progress: (NSProgressIndicator *) progress
            display: (NSTextField *) display;

- (BOOL) scanWithWorker: (ThreadWorker *) tw;

- (FLDirectory *) scanResult;
- (NSString *) scanError;

@end
