/* Copyright (C) 1996 Dave Vasilevsky
 * This file is licensed under the GNU General Public License,
 * see the file Copying.txt for details. */

#import "FLFile.h"

// As defined in stat(2)
#define BLOCK_SIZE 512

@implementation FLFile

- (id) initWithPath: (NSString *) path size: (FLFile_size) size
{
    if (self = [super init]) {
        m_path = [path retain];
        m_size = size;
    }
    return self;
}

- (NSString *) path
{
    return m_path;
}

- (FLFile_size) size
{
    return m_size;
}

- (void) dealloc
{
    [m_path release];
    [super dealloc];
}

@end


@implementation FLDirectory

- (id) initWithPath: (NSString *) path
{
    if (self = [super initWithPath: path size: 0]) {
        m_children = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void) addChild: (FLFile *) child
{
    [m_children addObject: child];
    m_size += [child size];
}

- (NSArray *) children
{
    return m_children;
}

- (void) dealloc
{
    if (m_children) {
        [m_children release];
    }
    [super dealloc];
}

@end
