//
//  LQCategoryBar.h
//  Lacqit
//
//  Created by Pauli Ojala on 10.1.2010.
//  Copyright 2010 Lacquer oy/ltd. All rights reserved.
//

#import "LQUIFrameworkHeader.h"
#import "LQUIConstants.h"


@interface LQCategoryBar : NSView {

    IBOutlet id _target;
    SEL _action;

	NSArray		*_catNames;
	NSRect		*_catRects;
	
	LXInteger   _selCat;
    
    LXUInteger  _controlSize;
    LQInterfaceTint _uiTint;
    
    id _whiteAttrs;
    id _blackAttrs;
}

- (void)setCategories:(NSArray *)cats;

- (void)setActiveCategory:(LXInteger)index;
- (LXInteger)activeCategory;

- (void)setTarget:(id)target;
- (id)target;

- (void)setAction:(SEL)action;
- (SEL)action;

- (void)setControlSize:(LXUInteger)size;
- (LXUInteger)controlSize;

- (void)setInterfaceTint:(LQInterfaceTint)tint;
- (LQInterfaceTint)interfaceTint;

@end
