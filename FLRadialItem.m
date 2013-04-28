/* Copyright (C) 1996 Dave Vasilevsky
 * This file is licensed under the GNU General Public License,
 * see the file Copying.txt for details. */

#import "FLRadialItem.h"
#import "FLRadialPainter.h"

@interface FLRadialItem ()

@property (readwrite, assign) id    dataSource;
@property (readwrite, assign) id    item;
@property (readwrite, assign) float weight;
@property (readwrite, assign) float startAngle;
@property (readwrite, assign) float endAngle;
@property (readwrite, assign) int   level;

@end

@implementation FLRadialItem

- (id) initWithItem: (id)item
         dataSource: (id)dataSource
             weight: (float)weight
         startAngle: (float)a1
           endAngle: (float)a2
              level: (int)level
{
    if (self = [super init]) {
        self.item = item;
        self.dataSource = dataSource;
        self.weight = weight;
        self.startAngle = a1;
        self.endAngle = a2;
        self.level = level;
    }
    return self;
}

- (float) midAngle
{
    return ([self startAngle] + [self endAngle]) / 2.0;
}

- (float) angleSpan
{
    return [self endAngle] - [self startAngle];
}

- (NSArray *) children
{
    if ([self weight] == 0.0) {
        return @[];
    }
    
    float curAngle = [self startAngle];
    float anglePerWeight = [self angleSpan] / [self weight];
    id item = [self item];
    
    int m = [self.dataSource numberOfChildrenOfItem: item];
    NSMutableArray *children = [NSMutableArray arrayWithCapacity: m];
    
    int i;
    for (i = 0; i < m; ++i) {
        id sub = [self.dataSource child: i ofItem: item];
        float subw = [self.dataSource weightOfItem: sub];
        float subAngle = anglePerWeight * subw;
        float nextAngle = curAngle + subAngle;
        
        id child = [[FLRadialItem alloc] initWithItem: sub
                                           dataSource: self.dataSource
                                               weight: subw
                                           startAngle: curAngle
                                             endAngle: nextAngle
                                                level: [self level] + 1];
        [children addObject: child];
        [child release];
        
        curAngle = nextAngle;
    }
    return children;
}

- (NSEnumerator *)childEnumerator
{
    return [[self children] objectEnumerator];
}

+ (FLRadialItem *) rootItemWithDataSource: (id)dataSource
{
    float weight = [dataSource weightOfItem: nil];
    FLRadialItem *ri = [[FLRadialItem alloc] initWithItem: nil
                                               dataSource: dataSource
                                                   weight: weight
                                               startAngle: 0
                                                 endAngle: 360
                                                    level: -1];
    return [ri autorelease];
}


@end
