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

- (CGFloat) maxRadius
{
    NSRect bounds = [self bounds];
    NSSize size = bounds.size;
    CGFloat minDim = size.width < size.height ? size.width : size.height;
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

- (void) setMinRadiusFraction: (CGFloat)fraction
{
    NSParameterAssert(fraction >= 0.0 && fraction <= 1.0);
    NSParameterAssert(fraction < [self maxRadiusFraction]);

    _minRadiusFraction = fraction;
}

- (void) setMaxRadiusFraction: (CGFloat)fraction
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

- (CGFloat) radiusFractionPerLevel
{
    CGFloat availFraction = [self maxRadiusFraction] - [self minRadiusFraction];
    return availFraction / [self maxLevels];
}

#pragma mark Painting


- (CGFloat) innerRadiusFractionForLevel: (int)level
{
    // TODO: Deal with concept of "visible levels" <= maxLevels
    NSAssert(level <= [self maxLevels], @"Level too high!");    
    return [self minRadiusFraction] + ([self radiusFractionPerLevel] * level);
}

// Default coloring scheme
- (NSColor *) colorForItem: (id __attribute__ ((unused))) item
                 angleFrac: (CGFloat) angle
                 levelFrac: (CGFloat) level
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
    CGFloat angleFrac = midAngle / 360.0;
    
    angleFrac -= floor(angleFrac);
    NSAssert(angleFrac >= 0 && angleFrac <= 1.0,
             @"Angle fraction must be between zero and one");
    
    id c = self.colorer ?: self;
    return [c colorForItem: [ritem item]
                 angleFrac: angleFrac
                 levelFrac: levelFrac];
}

- (void) drawItem: (FLRadialItem *)ritem
{
    NSView<FLHasDataSource> *view = [self view];
    
    int level = [ritem level];
    CGFloat inner = [self innerRadiusFractionForLevel: level];
    CGFloat outer = [self innerRadiusFractionForLevel: level + 1];
    NSColor *fill = [self colorForItem: ritem];
    
    NSBezierPath *bp = [NSBezierPath
        circleSegmentWithCenter: [view center]
                     startAngle: [ritem startAngle]
                       endAngle: [ritem endAngle]
                    smallRadius: inner * [view maxRadius]
                      bigRadius: outer * [view maxRadius]];
    
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
    for (FLRadialItem *child in [ritem children]) {
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
             angle: (CGFloat)th
{
    NSAssert(depth >= 0, @"Depth must be at least zero");
    NSAssert(th >= [ritem startAngle], @"Not searching the correct tree");
    
    if (![self wantItem: ritem]) {
        return nil;
    }
    
    if (depth == 0) {
        return [ritem item];
    }
    
    for (FLRadialItem *child in [ritem children]) {
        if ([child endAngle] >= th) {
            return [self findChildOf: child depth: depth - 1 angle: th];
        }
    }
    
    return nil;
}

- (id) itemAt: (NSPoint)point
{
    NSView <FLHasDataSource> *view = [self view];
    
    CGFloat r, th;
    [FLPolar coordsForPoint: point center: [view center] intoRadius: &r angle: &th];
    
    CGFloat rfrac = r / [view maxRadius];
    if (rfrac < [self minRadiusFraction] || rfrac >= [self maxRadiusFraction]) {
        return nil;
    }
    
    CGFloat usedFracs = rfrac - [self minRadiusFraction];
    int depth = (int)floor(usedFracs / [self radiusFractionPerLevel]) + 1;
    return [self findChildOf: [self root] depth: depth angle: th];
}


@end
