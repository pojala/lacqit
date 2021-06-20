//
//  LQCollectionItem.m
//  Lacqit
//
//  Created by Pauli Ojala on 4.5.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#import "LQCollectionItem.h"


@interface LQCollectionItem (PrivateUsedByOwner)
- (void)_setCollectionView:(NSView *)view;
@end

@interface NSView (LQCollectionItemOwnerMethods)
- (void)collectionItemNeedsDisplay:(LQCollectionItem *)item;
@end

@interface NSObject (LQCollectionRepresentedObjectOptionalMethods)
- (double)displayAspectRatio;
@end


@implementation LQCollectionItem


- (void)dealloc
{
    [_repObj release];
    [super dealloc];
}

- (void)setRepresentedObject:(id)obj {
    if (obj != _repObj) {
        [_repObj release];
        _repObj = [obj retain];
        [_owner collectionItemNeedsDisplay:self];
    }
}
    
- (id)representedObject {
    return _repObj; }


- (void)setSelected:(BOOL)f {
    if (f != _isSelected) {
        _isSelected = f;
        [_owner collectionItemNeedsDisplay:self];
    }
}

- (BOOL)isSelected {
    return _isSelected; }


- (NSView *)collectionView {
    return _owner; }

- (void)_setCollectionView:(NSView *)view {
    _owner = view; }


- (void)setName:(NSString *)name {
    [_name autorelease];
    _name = [name copy]; }
    
- (NSString *)name {
    return _name; }



- (double)displayAspectRatio
{
    if ([_repObj respondsToSelector:@selector(displayAspectRatio)])
        return [_repObj displayAspectRatio];
    else
        return 0.0;
}

- (double)displayWidth {
    return _w; }
    
- (double)displayHeight {
    return _h; }



#pragma mark --- NSCopying ---

- (id)copyWithZone:(NSZone *)zone
{
    LQCollectionItem *newItem = [[LQCollectionItem alloc] init];
    [newItem setRepresentedObject:_repObj];
    [newItem setSelected:_isSelected];
    [newItem setName:_name];
    return newItem;
}

@end
