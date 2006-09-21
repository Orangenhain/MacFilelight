/* Copyright (C) 1996 Dave Vasilevsky
 * This file is licensed under the GNU General Public License,
 * see the file Copying.txt for details. */

#import "FLFile.h"

// Data source using files in a directory
@interface FLDirectoryDataSource : NSObject {
    FLDirectory *m_rootDir;
}

- (NSString *) rootPath;
- (void) setRootPath: (NSString *) path;

@end
