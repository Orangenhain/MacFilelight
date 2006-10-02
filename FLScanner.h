/* Copyright (C) 1996 Dave Vasilevsky
 * This file is licensed under the GNU General Public License,
 * see the file Copying.txt for details. */

#import "FLFile.h"

@interface FLScanner : NSObject {
    NSString *m_path;
    NSProgressIndicator *m_pi;
    NSTextField *m_display;
    
    FLDirectory *m_tree;
    NSString *m_error;
    
    double m_increment;
    double m_progress;
    unsigned long long m_nodes;
    unsigned long long m_seen;
    
    SEL m_post_sel;
    id m_post_obj;
    
    NSLock *m_lock;
    BOOL m_cancelled;
}

- (id) initWithPath: (NSString *) path
           progress: (NSProgressIndicator *) progress
            display: (NSTextField *) display;

- (void) scanThenPerform: (SEL) selector on: (id) obj;

- (void) cancel;
- (BOOL) isCancelled;

- (FLDirectory *) scanResult;
- (NSString *) scanError;

@end
