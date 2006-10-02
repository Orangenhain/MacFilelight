/* Copyright (C) 1996 Dave Vasilevsky
 * This file is licensed under the GNU General Public License,
 * see the file Copying.txt for details. */

typedef unsigned long long FLFile_size;

typedef enum {
    SIZE_TYPE_SI_BINARY     = 0x1,  // 1 KiB = 1024 bytes
    SIZE_TYPE_SI_DECIMAL    = 0x2,  // 1 KB = 1000 bytes
    SIZE_TYPE_OLD_BINARY    = 0x3,  // 1 KB = 1024 bytes
    
    SIZE_TYPE_SHORT         = 0x10,
    SIZE_TYPE_LONG          = 0x20
} FLFileSizeType;

@interface FLFile : NSObject {
    NSString *m_path;
    FLFile_size m_size;
}

- (id) initWithPath: (NSString *) path size: (FLFile_size) size;
- (NSString *) path;
- (FLFile_size) size;

- (NSString *) humanReadableSizeOfType: (FLFileSizeType) type
                               sigFigs: (size_t) figs;
- (NSString *) displaySize;
@end

@interface FLDirectory : FLFile {
    NSMutableArray *m_children;
}

- (id) initWithPath: (NSString *) path;
- (void) addChild: (FLFile *) child;
- (NSArray *) children;
@end
