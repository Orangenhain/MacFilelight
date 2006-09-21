/* Copyright (C) 1996 Dave Vasilevsky
 * This file is licensed under the GNU General Public License,
 * see the file Copying.txt for details. */

#import "FLFile.h"

// As defined in stat(2)
#define BLOCK_SIZE 512

@implementation FLFile

+ (id) fsObjectAtPath: (NSString *)path
{
    BOOL isDir;
    BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath: path
                                                       isDirectory: &isDir];
    NSAssert(exists, @"Nothing exists at given path!");
    
    if (isDir) {
        return [[[FLDirectory alloc] initWithPath: path] autorelease];
    } else {
        return [[[FLFile alloc] initWithPath: path] autorelease];
    }
}

- (id) initWithPath: (NSString *)path
{
    if (self = [super init]) {
        m_path = [path retain];
        m_name = [[[NSFileManager defaultManager]
            displayNameAtPath: path] retain];
        
        /* Use stat, so we get size in blocks (including resource fork and
         * any other miscellany */
        const char *cpath = [path fileSystemRepresentation];
        struct stat sb;
        int err = lstat(cpath, &sb);
        
        NSAssert(!err, @"Stat failed!");
        m_size = sb.st_blocks * BLOCK_SIZE;
//        NSLog(@"File %@ has size %llu", path, m_size);
    }
    
    return self;
}

- (void) dealloc
{
    [m_path release];
    [m_name release];
    [super dealloc];
}

- (unsigned long long) size
{
    return m_size;
}

- (NSString *) path
{
    return [[m_path copy] autorelease];
}

- (NSString *) name
{
    return [[m_name copy] autorelease];
}

@end


@implementation FLDirectory

- (id) initWithPath: (NSString *)path
{
    if (self = [super initWithPath: path]) {
        NSArray *childNames = [[NSFileManager defaultManager]
            directoryContentsAtPath: path];
        NSAssert(childNames, @"Directory could not be read");
        
        m_children = [[NSMutableArray alloc] init];
        id obj;
        NSEnumerator *e = [childNames objectEnumerator];
        while (obj = [e nextObject]) {
            NSString *subPath = [path stringByAppendingPathComponent: obj];
            FLFile *subObj = [FLFile fsObjectAtPath: subPath];
            [m_children addObject: subObj];
            
            m_size += [subObj size];
        }
        
//        NSLog(@"Dir  %@ has size %llu", path, m_size);
    }
    
    return self;
}

- (void) dealloc
{
    [m_children release];
    [super dealloc];
}

- (NSArray *) children
{
    return m_children;
}

@end
