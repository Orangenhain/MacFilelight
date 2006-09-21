/* Copyright (C) 1996 Dave Vasilevsky
 * This file is licensed under the GNU General Public License,
 * see the file Copying.txt for details. */

@interface FLFile : NSObject {
    NSString *m_path;
    NSString *m_name;
    unsigned long long m_size;
}

// Get a file of a directory, whichever is appropriate
+ (id) fsObjectAtPath: (NSString *)path;

- (id) initWithPath: (NSString *)path;

- (unsigned long long) size;
- (NSString *)name;
- (NSString *)path;
@end

@interface FLDirectory : FLFile {
    NSMutableArray *m_children;
}

- (NSArray *) children;
@end