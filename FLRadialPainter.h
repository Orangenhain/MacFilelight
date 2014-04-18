/* Copyright (C) 1996 Dave Vasilevsky
 * This file is licensed under the GNU General Public License,
 * see the file Copying.txt for details. */

// Utility functions
@interface NSView (FLRadialPainter)
- (NSPoint) center;
- (CGFloat) maxRadius;
@end

// Colorer
@interface NSObject (FLColorer)
- (NSColor *) colorForItem: (id) item
                 angleFrac: (CGFloat) angle
                 levelFrac: (CGFloat) level;
@end

@protocol FLHasDataSource
- (id) dataSource;
@end

@interface FLRadialPainter : NSObject

@property (nonatomic, assign) int maxLevels;
@property (nonatomic, assign) CGFloat minRadiusFraction, maxRadiusFraction;
@property (assign) float minPaintAngle;
@property (weak) NSView <FLHasDataSource> *view;
@property (strong) id colorer;

- (id) initWithView: (NSView <FLHasDataSource> *)view;

- (void)drawRect: (NSRect)rect;
- (id)itemAt: (NSPoint)point;

@end
