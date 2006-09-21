/* Copyright (C) 1996 Dave Vasilevsky
* This file is licensed under the GNU General Public License,
* see the file Copying.txt for details. */

#import "FLDirectoryDataSource.h"

@implementation FLDirectoryDataSource

- (id) init
{
    if (self = [super init]) {
        NSString *path = [[NSBundle mainBundle]
            objectForInfoDictionaryKey: @"FLShowDirectory"];
        m_rootDir = [[FLDirectory alloc] initWithPath: path];
    }    
    return self;
}

- (FLFile *) realItemFor: (id)item
{
    return item ? item : m_rootDir;
}

- (id) view: (NSView *)view child: (int)index ofItem: (id)item
{
    FLFile *file = [self realItemFor: item];
    return [[(FLDirectory *)file children] objectAtIndex: index];
}

- (int) view: (NSView *)view numberOfChildrenOfItem: (id)item
{
    FLFile *file = [self realItemFor: item];
    return [file respondsToSelector: @selector(children)]
        ? [[(FLDirectory *)file children] count]
        : 0;
}

- (float) view: (NSView *)view weightOfItem: (id)item
{
    FLFile *file = [self realItemFor: item];
    return (float)[file size];
}

@end
