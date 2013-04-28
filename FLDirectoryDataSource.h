/* Copyright (C) 1996 Dave Vasilevsky
 * This file is licensed under the GNU General Public License,
 * see the file Copying.txt for details. */

@class FLDirectory;

// Data source using files in a directory
@interface FLDirectoryDataSource : NSObject

@property (retain) FLDirectory *rootDir;

@end
