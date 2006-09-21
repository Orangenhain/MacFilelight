/* Copyright (C) 1996 Dave Vasilevsky
* This file is licensed under the GNU General Public License,
* see the file Copying.txt for details. */

@interface FLRadialView : NSView
{
    int m_maxLevels;
    float m_minRadiusFraction, m_maxRadiusFraction;
    
    IBOutlet id dataSource;
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

@end


// Generalization of NSOutlineViewDataSource
// nil object means the root.
@interface NSObject(FLRadialViewDataSource)
- (id) view: (NSView *)view child: (int)index ofItem: (id)item;
- (int) view: (NSView *)view numberOfChildrenOfItem: (id)item;

- (float) view: (NSView *)view weightOfItem: (id)item;
@end