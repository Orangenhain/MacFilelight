/* Copyright (C) 1996 Dave Vasilevsky
 * This file is licensed under the GNU General Public License,
 * see the file Copying.txt for details. */

#import "FLDirectoryDataSource.h"
#import "FLFile.h"

@implementation FLDirectoryDataSource

- (FLFile *) realItemFor: (id)item
{
    return item ?: self.rootDir;
}

- (id) child: (int)index ofItem: (id)item
{
    FLFile *file = [self realItemFor: item];
    return [(FLDirectory *)file children][index];
}

- (int) numberOfChildrenOfItem: (id)item
{
    FLFile *file = [self realItemFor: item];
    return [file respondsToSelector: @selector(children)]
        ? [[(FLDirectory *)file children] count]
        : 0;
}

- (float) weightOfItem: (id)item
{
    FLFile *file = [self realItemFor: item];
    return (float)[file size];
}

@end
