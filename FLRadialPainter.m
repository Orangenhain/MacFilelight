/* Copyright (C) 1996 Dave Vasilevsky
 * This file is licensed under the GNU General Public License,
 * see the file Copying.txt for details. */

#import "FLRadialPainter.h"

#import "FLPolar.h"
#import "NSBezierPath+Segment.h"
#import "FLRadialItem.h"

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

@implementation FLRadialPainter

- (id) initWithView: (NSView <FLHasDataSource> *)view
{
    if (self = [super init]) {
        // Default values
        self.maxLevels = 5;
        // {min,max}RadiusFraction setters check new values based on each other, so we have to initialize at least one of those without using its setter
        _minRadiusFraction = 0.1;
        _maxRadiusFraction = 0.9;
        self.minPaintAngle = 1.0;
        
        self.view = view; // No retain, view should own us
        self.colorer = nil;
    }
    return self;
}



#pragma mark Accessors

- (void) setMaxLevels: (int)levels
{
    NSParameterAssert(levels > 0);

    _maxLevels = levels;
}

- (void) setMinRadiusFraction: (float)fraction
{
    NSParameterAssert(fraction >= 0.0 && fraction <= 1.0);
    NSParameterAssert(fraction < [self maxRadiusFraction]);

    _minRadiusFraction = fraction;
}

- (void) setMaxRadiusFraction: (float)fraction
{
    NSParameterAssert(fraction >= 0.0 && fraction <= 1.0);
    NSParameterAssert(fraction > [self minRadiusFraction]);

    _maxRadiusFraction = fraction;
}

#pragma mark Misc

- (FLRadialItem *) root
{
    return [FLRadialItem rootItemWithDataSource: [[self view] dataSource]];
}

- (BOOL) wantItem: (FLRadialItem *) ritem
{
    return [ritem level] < [self maxLevels]
        && [ritem angleSpan] >= [self minPaintAngle];
}

- (float) radiusFractionPerLevel
{
    float availFraction = [self maxRadiusFraction] - [self minRadiusFraction];
    return availFraction / [self maxLevels];
}

#pragma mark Painting


- (float) innerRadiusFractionForLevel: (int)level
{
    // TODO: Deal with concept of "visible levels" <= maxLevels
    NSAssert(level <= [self maxLevels], @"Level too high!");    
    return [self minRadiusFraction] + ([self radiusFractionPerLevel] * level);
}

// Default coloring scheme
- (NSColor *) colorForItem: (id __attribute__ ((unused))) item
                 angleFrac: (float) angle
                 levelFrac: (float) level
{
    return [NSColor colorWithCalibratedHue: angle
                                saturation: 0.6 - (level / 4)
                                brightness: 1.0
                                     alpha: 1.0];
}

- (NSColor *) colorForItem: (FLRadialItem *)ritem
{
    float levelFrac = (float)[ritem level] / ([self maxLevels] - 1);
    float midAngle = [ritem midAngle];
    float angleFrac = midAngle / 360.0;
    
    angleFrac -= floorf(angleFrac);
    NSAssert(angleFrac >= 0 && angleFrac <= 1.0,
             @"Angle fraction must be between zero and one");
    
    id c = self.colorer ?: self;
    return [c colorForItem: [ritem item]
                 angleFrac: angleFrac
                 levelFrac: levelFrac];
}

- (void) drawItem: (FLRadialItem *)ritem
{
    int level = [ritem level];
    float inner = [self innerRadiusFractionForLevel: level];
    float outer = [self innerRadiusFractionForLevel: level + 1];
    NSColor *fill = [self colorForItem: ritem];
    
    NSBezierPath *bp = [NSBezierPath
        circleSegmentWithCenter: [[self view] center]
                     startAngle: [ritem startAngle]
                       endAngle: [ritem endAngle]
                    smallRadius: inner * [[self view] maxRadius]
                      bigRadius: outer * [[self view] maxRadius]];
    
    [fill set];
    [bp fill];
    [[fill shadowWithLevel: 0.4] set];
    [bp stroke];
}



- (void) drawTreeForItem: (FLRadialItem *)ritem
{
    if (![self wantItem: ritem]) {
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

- (void)drawRect: (NSRect __attribute__ ((unused)))rect
{
    // TODO: Choose root item(s) from rect
    [self drawTreeForItem: [self root]];
}

#pragma mark Hit testing

- (id) findChildOf: (FLRadialItem *)ritem
             depth: (int)depth
             angle: (float)th
{
    NSAssert(depth >= 0, @"Depth must be at least zero");
    NSAssert(th >= [ritem startAngle], @"Not searching the correct tree");
    
    if (![self wantItem: ritem]) {
        return nil;
    }
    
    if (depth == 0) {
        return [ritem item];
    }
    
    NSEnumerator *e = [ritem childEnumerator];
    FLRadialItem *child;
    while (child = [e nextObject]) {
        if ([child endAngle] >= th) {
            return [self findChildOf: child depth: depth - 1 angle: th];
        }
    }
    
    return nil;
}

- (id) itemAt: (NSPoint)point
{
    float r, th;
    [FLPolar coordsForPoint: point center: [[self view] center] intoRadius: &r angle: &th];
    
    float rfrac = r / [[self view] maxRadius];
    if (rfrac < [self minRadiusFraction] || rfrac >= [self maxRadiusFraction]) {
        return nil;
    }
    
    float usedFracs = rfrac - [self minRadiusFraction];
    int depth = floorf(usedFracs / [self radiusFractionPerLevel]) + 1;
    return [self findChildOf: [self root] depth: depth angle: th];
}


@end
