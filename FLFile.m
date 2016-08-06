/* Copyright (C) 1996 Dave Vasilevsky
 * This file is licensed under the GNU General Public License,
 * see the file Copying.txt for details. */

#import "FLFile.h"

@interface FLFile ()
{
    @protected
    off_t _size;  // we need a protected ivar to back the `size` @property, as we want to access the ivar in a subclass (by default auto-synthesizing gives you a private ivar)
}

@property (readwrite, copy)      NSString *path;
@property (readwrite, nonatomic) off_t     size;

@end

@implementation FLFile

- (id) initWithPath: (NSString *) path size: (off_t) size
{
    if (self = [super init]) {
        self.path = path;
        self.size = size;
    }
    return self;
}

- (NSString *) displaySize
{
    return [NSByteCountFormatter stringFromByteCount:self.size
                                          countStyle:NSByteCountFormatterCountStyleFile];
    
}

- (off_t)size
{
    // this is a quick-and-dirty hack to get file count visualization ... each file weighs 1 unit
    BOOL showSize = [[[NSUserDefaults standardUserDefaults] stringForKey:@"shouldCount"] isEqualToString:@"file size"];
    return showSize ? _size : 1;
}

@end


@interface FLDirectory ()

@property (readwrite, strong) NSArray     *children;
@property (readwrite, weak)   FLDirectory *parent;

@property (copy) NSString *countedOnLastRequest;

@end

@implementation FLDirectory

- (id) initWithPath:(NSString *)path parent:(FLDirectory *)parent
{
    if (self = [super initWithPath: path size: 0]) {
        self.parent   = parent;
        self.children = @[];
    }
    return self;
}

- (void) addChild: (FLFile *) child
{
	self.children  = [self.children arrayByAddingObject:child];
}

- (off_t)size
{
    NSString *shouldCount = [[NSUserDefaults standardUserDefaults] stringForKey:@"shouldCount"];

    // this method gets called quite often ... doing this without caching the result is not a good idea (performance wise) for bigger data sets
    if ( ![self.countedOnLastRequest isEqualToString:shouldCount])
    {
        _size = 0;
        for (FLFile *child in self.children)
        {
            _size += [child size];
        }
        // this loop is faster than [[self.children valueForKeyPath:@"@sum.size"] unsignedLongLongValue]
        
        self.countedOnLastRequest = shouldCount;
    }
    
    return _size;
}

@end
