/* Copyright (C) 1996 Dave Vasilevsky
 * This file is licensed under the GNU General Public License,
 * see the file Copying.txt for details. */

typedef unsigned long long FLFile_size;

@interface FLFile : NSObject {
    NSString *m_path;
    FLFile_size m_size;
}

- (id) initWithPath: (NSString *) path size: (FLFile_size) size;
- (NSString *) path;
- (FLFile_size) size;
@end

@interface FLDirectory : FLFile {
    NSMutableArray *m_children;
}

- (id) initWithPath: (NSString *) path;
- (void) addChild: (FLFile *) child;
- (NSArray *) children;
@end
