//
//  LQDirect3DLacefxView.h
//  Lacqit
//
//  Created by Pauli Ojala on 4.6.2010.
//  Copyright 2010 Lacquer oy/ltd. All rights reserved.
//

#import "LQWin32ChildView.h"
#import "LQLacefxViewBaseMixin.h"

#import <d3d9.h>
#import <Lacefx/Lacefx.h>


@interface LQDirect3DLacefxView : LQWin32ChildView {

    IBOutlet id     _delegate;

    id              _baseMixin;
    
    IDirect3DSwapChain9 *_swapChain;    
    LXSurfaceRef _lxSurface;
    
    LXUInteger      _fitToViewMode;
}


// see LQLacefxViewBaseMixin.h for the delegate methods
- (void)setDelegate:(id)del;
- (id)delegate;

// the cell delegate can be used to intercept events within cells (see LQLacefxViewBaseMixin.h for the methods)
- (void)setCellDelegate:(id)del;
- (id)cellDelegate;

- (void)addCell:(LQXCell *)cell;
- (void)removeCell:(LQXCell *)cell;
- (LQXCell *)cellNamed:(NSString *)name;
- (NSArray *)cells;


- (void)present;  // copies the Direct3D backbuffer onscreen

- (void)drawNow;  // an alias for -present, compatible with the GL version

- (LXSurfaceRef)lxSurface;

@end
