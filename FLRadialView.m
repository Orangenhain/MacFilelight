/* Copyright (C) 1996 Dave Vasilevsky
* This file is licensed under the GNU General Public License,
* see the file Copying.txt for details. */

#import "FLRadialView.h"
#import "NSBezierPath+Segment.h"

@implementation FLRadialView

- (id) initWithFrame: (NSRect)frame
{
    if (self = [super initWithFrame: frame]) {
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

#pragma mark Drawing


- (float) innerRadiusFractionForLevel: (int)level
{
    // TODO: Deal with concept of "visible levels" <= maxLevels
    
    NSAssert(level <= [self maxLevels], @"Level too high!");    
    float availFraction = [self maxRadiusFraction] - [self minRadiusFraction];
    float perLevel = availFraction / [self maxLevels];
    return [self minRadiusFraction] + (perLevel * level);
}

- (void) drawSegmentWithStartAngle: (float)a1
                          endAngle: (float)a2
                     innerFraction: (float)f1
                     outerFraction: (float)f2
                              fill: (NSColor *)fill
{
    NSRect bounds = [self bounds];
    NSPoint center = NSMakePoint(NSMidX(bounds), NSMidY(bounds));
    
    NSSize size = bounds.size;
    float minDim = size.width < size.height ? size.width : size.height;
    float maxRadius = minDim / 2.0;
    
    NSBezierPath *bp = [NSBezierPath circleSegmentWithCenter: center
                                                  startAngle: a1
                                                    endAngle: a2
                                                 smallRadius: f1 * maxRadius
                                                   bigRadius: f2 * maxRadius];
    
    [fill set];
    [bp fill];
    [[NSColor blackColor] set];
    [bp stroke];
}

- (NSColor *) colorForStartAngle: (float)a1
                        endAngle: (float)a2
                           level: (int)level
{
    float levelFrac = (float)level / ([self maxLevels] - 1);
    float midAngle = (a1 + a2) / 2;
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

- (void) drawSegmentWithStartAngle: (float)a1
                          endAngle: (float)a2
                             level: (int)level
{
    float inner = [self innerRadiusFractionForLevel: level];
    float outer = [self innerRadiusFractionForLevel: level + 1];
    NSColor *fill = [self colorForStartAngle: a2 endAngle: a2 level: level];
    
    [self drawSegmentWithStartAngle: a1
                           endAngle: a2
                      innerFraction: inner
                      outerFraction: outer
                               fill: fill];
}

- (void) drawChildrenOf: (id)item
             startAngle: (float)a1
               endAngle: (float)a2
                  level: (int)level
{
    if (level >= [self maxLevels]) {
        return;
    }
    
    float totalWeight = [dataSource view: self weightOfItem: item];
    if (totalWeight == 0) {
        return;
    }
    
    float anglePerWeight = (a2 - a1) / totalWeight;
    float curAngle = a1;
    
    int m = [dataSource view: self numberOfChildrenOfItem: item];
    int i;
    for (i = 0; i < m; ++i) {
        id sub = [dataSource view: self child: i ofItem: item];
        float weight = [dataSource view: self weightOfItem: sub];
        float subAngle = anglePerWeight * weight;
        float nextAngle = curAngle + subAngle;
        
        [self drawSegmentWithStartAngle: curAngle
                               endAngle: nextAngle 
                                  level: level];
        [self drawChildrenOf: sub
                  startAngle: curAngle
                    endAngle: nextAngle
                       level: level + 1];
        
        curAngle = nextAngle;
    }
}

- (void) drawRect: (NSRect)rect
{
    [self drawChildrenOf: nil startAngle: 0 endAngle: 360 level: 0];
}

@end
