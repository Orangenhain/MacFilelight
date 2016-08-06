/* Copyright (C) 1996 Dave Vasilevsky
 * This file is licensed under the GNU General Public License,
 * see the file Copying.txt for details. */


@interface FLFile : NSObject

@property (readonly) NSString *path;
@property (readonly) off_t     size;

- (instancetype) initWithPath:(NSString *)path size:(off_t)size;

- (NSString *) displaySize;

@end


@interface FLDirectory : FLFile

@property (readonly, weak) FLDirectory *parent;
@property (readonly)       NSArray     *children;

- (instancetype) initWithPath:(NSString *)path parent:(FLDirectory *)parent;
- (void) addChild:(FLFile *)child;

@end
