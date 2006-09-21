/* Copyright (C) 1996 Dave Vasilevsky
* This file is licensed under the GNU General Public License,
* see the file Copying.txt for details. */

@interface FLFile : NSObject {
    NSString *m_path;
    unsigned long long m_size;
}

+ (id) fsObjectAtPath: (NSString *)path;

- (id) initWithPath: (NSString *)path;
- (unsigned long long) size;
@end

@interface FLDirectory : FLFile {
    NSMutableArray *m_children;
}

- (NSArray *) children;
@end