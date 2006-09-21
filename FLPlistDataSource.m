/* Copyright (C) 1996 Dave Vasilevsky
 * This file is licensed under the GNU General Public License,
 * see the file Copying.txt for details. */

#import "FLPlistDataSource.h"

@implementation FLPlistDataSource

- (id) init
{
    if (self = [super init]) {
        NSBundle *bundle = [NSBundle mainBundle];
        NSString *path = [bundle pathForResource: @"DataSource" ofType: @"plist"];
        NSData *data = [NSData dataWithContentsOfFile: path];
        
        NSString *error;
        m_plist = [NSPropertyListSerialization
                                propertyListFromData: data
                                    mutabilityOption: kCFPropertyListImmutable
                                              format: NULL
                                    errorDescription: &error];
        [m_plist retain];
        NSAssert(!error, error);
    }
    
    return self;
}

- (void) dealloc
{
    [m_plist release];
    [super dealloc];
}

- (id) realItemFor: (id)item
{
    return item ? item : m_plist;
}

- (id) view: (NSView *)view child: (int)index ofItem: (id)item
{
    item = [self realItemFor: item];
    return [item objectAtIndex: index];
}

- (int) view: (NSView *)view numberOfChildrenOfItem: (id)item
{
    item = [self realItemFor: item];
    return [item respondsToSelector: @selector(count)] ? [item count] : 0;
}

- (float) view: (NSView *)view weightOfItem: (id)item
{
    item = [self realItemFor: item];
    if ([item respondsToSelector: @selector(floatValue)]) {
        return [item floatValue];
    } else {
        float acc = 0.0;
        NSEnumerator *e = [item objectEnumerator];
        id obj;
        
        while (obj = [e nextObject]) {
            acc += [self view: view weightOfItem: obj];
        }
        return acc;
    }
}

@end
