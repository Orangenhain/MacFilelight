/* Copyright (C) 1996 Dave Vasilevsky
 * This file is licensed under the GNU General Public License,
 * see the file Copying.txt for details. */

// Utility functions
@interface NSView (FLRadialPainter)
- (NSPoint) center;
- (float) maxRadius;
@end


@interface FLRadialPainter : NSObject
{
    int m_maxLevels;
    float m_minRadiusFraction, m_maxRadiusFraction;
    
    IBOutlet id dataSource;
    
    NSView *tmp_view;
    NSPoint tmp_center;
    float tmp_radius;
}

// Accessors
- (int) maxLevels;
- (void) setMaxLevels: (int)levels;
- (float) minRadiusFraction;
- (void) setMinRadiusFraction: (float)fraction;
- (float) maxRadiusFraction;
- (void) setMaxRadiusFraction: (float)fraction;
- (id) dataSource;
- (void) setDataSource: (id)source;

- (void)drawInView: (NSView *)view
              rect: (NSRect)rect
            center: (NSPoint)center
            radius: (float)radius;

- (id)itemAt: (NSPoint)point
      center: (NSPoint)center
      radius: (float)radius;

@end


// Data source: generalization of NSOutlineViewDataSource
// nil object means the root.
@interface NSObject (FLRadialPainterDataSource)
- (id) target: (id) target child: (int) index ofItem: (id) item;
- (int) target: (id) target numberOfChildrenOfItem: (id) item;

- (float) target: (id) target weightOfItem: (id) item;
@end
