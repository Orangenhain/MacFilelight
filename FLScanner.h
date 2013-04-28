/* Copyright (C) 1996 Dave Vasilevsky
 * This file is licensed under the GNU General Public License,
 * see the file Copying.txt for details. */

@class FLDirectory;

@interface FLScanner : NSObject

- (id) initWithPath: (NSString *) path
           progress: (NSProgressIndicator *) progress
            display: (NSTextField *) display;

- (void) scanThenPerform: (SEL) selector on: (id) obj;

- (void) cancel;
- (BOOL) isCancelled;

- (FLDirectory *) scanResult;
- (NSString *) scanError;

+ (BOOL) isMountPoint: (NSString *) path;
+ (BOOL) isMountPointCPath: (const char *) cpath;

@end
