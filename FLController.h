/* Copyright (C) 1996 Dave Vasilevsky
 * This file is licensed under the GNU General Public License,
 * see the file Copying.txt for details. */

@class FLScanner;
@class FLDirectory;
@class FLView;

@interface FLController : NSObject 

- (void) refresh;

- (void) setRootDir: (FLDirectory *) dir;
- (FLDirectory *) rootDir;

@end
