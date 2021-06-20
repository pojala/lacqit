//
//  LQCollectionItem.h
//  Lacqit
//
//  Created by Pauli Ojala on 4.5.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface LQCollectionItem : NSObject  <NSCopying> {

    BOOL _isSelected;
    id   _repObj;
    NSView *_owner;
    
    NSString *_name;
    
    double _w, _h;
}

- (void)setRepresentedObject:(id)obj;
- (id)representedObject;

- (void)setName:(NSString *)name;
- (NSString *)name;

- (void)setSelected:(BOOL)f;
- (BOOL)isSelected;

- (double)displayAspectRatio;
- (double)displayWidth;
- (double)displayHeight;

- (NSView *)collectionView;

@end
