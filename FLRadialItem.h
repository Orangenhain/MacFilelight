/* Copyright (C) 1996 Dave Vasilevsky
 * This file is licensed under the GNU General Public License,
 * see the file Copying.txt for details. */

// Data source: generalization of NSOutlineViewDataSource
// nil object means the root.
@protocol FLRadialPainterDataSource
- (id) child: (NSUInteger) index ofItem: (id) item;
- (NSUInteger) numberOfChildrenOfItem: (id) item;

- (float) weightOfItem: (id) item;
@end

@interface FLRadialItem : NSObject

@property (unsafe_unretained, readonly) id    item;
@property (readonly) float weight;
@property (readonly) float startAngle;
@property (readonly) float endAngle;
@property (readonly) int   level;

+ (FLRadialItem *) rootItemWithDataSource: (id <FLRadialPainterDataSource>)dataSource;

- (float) midAngle;
- (float) angleSpan;

- (NSArray *) children;

@end
