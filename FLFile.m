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
        self.path = path;
        self.size = size;
    }
    return self;
}


+ (NSString *) humanReadableSize: (FLFile_size) size
                            type: (FLFileSizeType) type
                         sigFigs: (size_t) figs
{
    unsigned idx, base, digits, deci;
    double fsize;
    FLFileSizeType length, baseType;
    NSString *pref, *suf;
    
    NSArray *prefixes = @[@"", @"kilo", @"mega", @"giga", @"peta", @"exa", @"zetta", @"yotta"];
    
    baseType = type & SizeTypeBaseMask;
    base = (baseType == SizeTypeSIDecimal) ? 1000 : 1024;
    
    // Find proper prefix
    fsize = size;
    idx = 0;
    while (fsize >= base && idx < [prefixes count]) {
        ++idx;
        fsize /= base;
    }
    pref = prefixes[idx];
    
    // Precision
    digits = 1 + (unsigned)log10(fsize);
    deci = (digits > figs || idx == 0) ? 0 : figs - digits;
    fsize = pow(10.0, 0.0 - deci) * rint(fsize * pow(10.0, 0.0 + deci));
    
    // Unit suffix
    length = type & SizeTypeLengthMask;
    suf = (length == SizeTypeLong) ? @"byte" : @"B";
    if (length == SizeTypeLong && fsize != 1.0) { // plural
        suf = [suf stringByAppendingString: @"s"];
    }
    
    // Unit prefix
    if (idx > 0) {
        if (length == SizeTypeShort) {
            pref = [[pref substringToIndex: 1] uppercaseString];
            if (baseType == SizeTypeSIBinary) {
                pref = [pref stringByAppendingString: @"i"];
            }
        } else if (baseType == SizeTypeSIBinary) {
            pref = [[pref substringToIndex: 2] stringByAppendingString: @"bi"];
        }
    }
    
    return [NSString stringWithFormat: @"%.*f %@%@", deci, fsize, pref, suf];
}

- (NSString *) displaySize
{
    return [FLFile humanReadableSize: [self size]
                                type: SizeTypeOldBinary | SizeTypeShort
                             sigFigs: 3];
}

- (FLFile_size)size
{
    return [[[NSUserDefaults standardUserDefaults] stringForKey:@"shouldCount"] isEqualToString:@"file size"] ? _size : 1;
}

@end


@interface FLDirectory ()

@property (readwrite, strong) NSArray     *children;
@property (weak)            FLDirectory *parent;

@property (copy) NSString *countedOnLastRequest;

@end

@implementation FLDirectory

- (id) initWithPath: (NSString *) path parent: (FLDirectory * __attribute__ ((unused))) parent
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

- (FLFile_size)size
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
