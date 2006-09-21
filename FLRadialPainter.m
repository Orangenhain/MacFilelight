/* Copyright (C) 1996 Dave Vasilevsky
 * This file is licensed under the GNU General Public License,
 * see the file Copying.txt for details. */

#import "FLRadialPainter.h"

#import "FLPolar.h"
#import "NSBezierPath+Segment.h"

@implementation NSView (FLRadialPainter)

- (NSPoint) center
{
    NSRect bounds = [self bounds];
    return NSMakePoint(NSMidX(bounds), NSMidY(bounds));
}

- (float) maxRadius
{
    NSRect bounds = [self bounds];
    NSSize size = bounds.size;
    float minDim = size.width < size.height ? size.width : size.height;
    return minDim / 2.0;
}

@end


@interface FLRadialItem : NSObject {
    id painter;
    id item;
    float weight;
    float startAngle;
    float endAngle;
    int level;
}

- (id) initWithItem: (id)i
            painter: (id)p
             weight: (float)w
         startAngle: (float)a1
           endAngle: (float)a2
              level: (int)l;

- (id) painter;
- (id) item;
- (float) weight;
- (float) startAngle;
- (float) endAngle;
- (float) midAngle;
- (int) level;

- (NSArray *) children;
- (NSEnumerator *)childEnumerator;

+ (FLRadialItem *) rootItemWithPainter: (id)p;

@end

@implementation FLRadialItem

- (id) initWithItem: (id)i
            painter: (id)p
             weight: (float)w
         startAngle: (float)a1
           endAngle: (float)a2
              level: (int)l;
{
    if (self = [super init]) {
        item = i;
        painter = p;
        weight = w;
        startAngle = a1;
        endAngle = a2;
        level = l;
    }
    return self;
}

- (id) painter { return painter; }
- (id) item { return item; }
- (float) weight { return weight; }
- (float) startAngle { return startAngle; }
- (float) endAngle { return endAngle; }
- (int) level { return level; }

- (float) midAngle {
     return ([self startAngle] + [self endAngle]) / 2.0;
}

- (NSArray *) children;
{
    if (weight == 0) {
        return [NSArray array];
    }
    
    float curAngle = startAngle;
    float anglePerWeight = (endAngle - curAngle) / weight;
    id dataSource = [painter dataSource];
    
    int m = [dataSource target: painter numberOfChildrenOfItem: item];
    NSMutableArray *children = [NSMutableArray arrayWithCapacity: m];
    int i;
    for (i = 0; i < m; ++i) {
        id sub = [dataSource target: painter child: i ofItem: item];
        float subw = [dataSource target: painter weightOfItem: sub];
        float subAngle = anglePerWeight * subw;
        float nextAngle = curAngle + subAngle;
        
        id child = [[FLRadialItem alloc]
            initWithItem: sub
                 painter: painter
                  weight: subw
              startAngle: curAngle
                endAngle: nextAngle
                   level: level + 1];
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

+ (FLRadialItem *) rootItemWithPainter: (id)p
{
    return [[[FLRadialItem alloc]
        initWithItem: nil
             painter: p
              weight: [[p dataSource] target: p weightOfItem: nil]
          startAngle: 0
            endAngle: 360
               level: -1] autorelease];
}


@end



@implementation FLRadialPainter

- (id) init
{
    if (self = [super init]) {
        // Default values
        m_maxLevels = 5;
        m_minRadiusFraction = 0.1;
        m_maxRadiusFraction = 0.9;        
    }
    return self;
}

- (void) dealloc
{
    [dataSource release];
    [super dealloc];
}

#pragma mark Accessors

- (int) maxLevels
{
    return m_maxLevels;
}

- (void) setMaxLevels: (int)levels
{
    NSAssert(levels > 0, @"maxLevels must be positive!");
    m_maxLevels = levels;
}

- (float) minRadiusFraction
{
    return m_minRadiusFraction;
}

- (void) setMinRadiusFraction: (float)fraction
{
    NSAssert(fraction >= 0.0 && fraction <= 1.0,
             @"fraction must be between zero and one!");
    NSAssert(fraction < [self maxRadiusFraction],
             @"minRadius must be less than maxRadius!");
    m_minRadiusFraction = fraction;
}

- (float) maxRadiusFraction
{
    return m_maxRadiusFraction;
}

- (void) setMaxRadiusFraction: (float)fraction
{
    NSAssert(fraction >= 0.0 && fraction <= 1.0,
             @"fraction must be between zero and one!");
    NSAssert(fraction > [self minRadiusFraction],
             @"minRadius must be less than maxRadius!");
    m_maxRadiusFraction = fraction;
}

- (id) dataSource
{
    return [[dataSource retain] autorelease];
}

- (void) setDataSource: (id)source
{
    if (dataSource != source) {
        [dataSource release];
        dataSource = [source retain];
    }
}

#pragma mark Painting

- (float) radiusFractionPerLevel
{
    float availFraction = [self maxRadiusFraction] - [self minRadiusFraction];
    return availFraction / [self maxLevels];
}

- (float) innerRadiusFractionForLevel: (int)level
{
    // TODO: Deal with concept of "visible levels" <= maxLevels
    NSAssert(level <= [self maxLevels], @"Level too high!");    
    return [self minRadiusFraction] + ([self radiusFractionPerLevel] * level);
}


- (NSColor *) colorForItem: (FLRadialItem *)ritem
{
    float levelFrac = (float)[ritem level] / ([self maxLevels] - 1);
    float midAngle = [ritem midAngle];
    float angleFrac = midAngle / 360.0;
    
    angleFrac -= floorf(angleFrac);
    NSAssert(angleFrac >= 0 && angleFrac <= 1.0,
             @"Angle fraction must be between zero and one");
    
    NSColor *color = [NSColor colorWithCalibratedHue: angleFrac
                                          saturation: 0.6 - (levelFrac / 4)
                                          brightness: 1.0
                                               alpha: 1.0];
    return color;
}

- (void) drawItem: (FLRadialItem *)ritem
{
    int level = [ritem level];
    float inner = [self innerRadiusFractionForLevel: level];
    float outer = [self innerRadiusFractionForLevel: level + 1];
    NSColor *fill = [self colorForItem: ritem];
    
    NSBezierPath *bp = [NSBezierPath
        circleSegmentWithCenter: tmp_center
                     startAngle: [ritem startAngle]
                       endAngle: [ritem endAngle]
                    smallRadius: inner * tmp_radius
                      bigRadius: outer * tmp_radius];
    
    [fill set];
    [bp fill];
    [[NSColor blackColor] set];
    [bp stroke];
}



- (void) drawTreeForItem: (FLRadialItem *)ritem
{
    if ([ritem level] >= [self maxLevels]) {
        return;
    }
    
    if ([ritem level] >= 0 && [ritem weight] > 0) {
        [self drawItem: ritem];
    }
    
    // Draw the children
    NSEnumerator *e = [ritem childEnumerator];
    FLRadialItem *child;
    while (child = [e nextObject]) {
        [self drawTreeForItem: child];
    }
}

- (void)drawInView: (NSView *)view
              rect: (NSRect)rect
            center: (NSPoint)center
            radius: (float)radius;
{
    tmp_view = view; // no retain!
    tmp_center = center;
    tmp_radius = radius;
    
    id ritem = [FLRadialItem rootItemWithPainter: self];
    [self drawTreeForItem: ritem];
}

#pragma mark Hit testing

- (id) findChildOf: (FLRadialItem *)ritem
             depth: (int)depth
             angle: (float)th
{
    NSAssert(depth >= 1, @"Depth must be at least one");
    NSAssert(th >= [ritem startAngle], @"Not searching the correct tree");
    
    NSEnumerator *e = [ritem childEnumerator];
    FLRadialItem *child;
    while (child = [e nextObject]) {
        if ([child endAngle] >= th) {
            if (depth == 1) {
                return [child item];
            } else {
                return [self findChildOf: child depth: depth - 1 angle: th];
            }
        }
    }
    
    return nil;
}

- (id) itemAt: (NSPoint)point
       center: (NSPoint)center
       radius: (float)radius
{
    float r, th;
    [FLPolar coordsForPoint: point center: center intoRadius: &r angle: &th];
    // NSLog(@"Click: r = %f   th = %f", r, th);
    
    float rfrac = r / radius;
    if (rfrac < [self minRadiusFraction] || rfrac >= [self maxRadiusFraction]) {
        return nil;
    }
    
    float usedFracs = rfrac - [self minRadiusFraction];
    int depth = floorf(usedFracs / [self radiusFractionPerLevel]) + 1;
    FLRadialItem *root = [FLRadialItem rootItemWithPainter: self];
    return [self findChildOf: root depth: depth angle: th];
}


@end
