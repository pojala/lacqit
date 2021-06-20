//
//  LQGLacefxViewController.h
//  Lacqit
//
//  Created by Pauli Ojala on 13.9.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#import "LQGViewController.h"
#import <Lacefx/Lacefx.h>


@interface LQGLacefxViewController : LQGViewController {

    id _contentDelegate;
}

// factory method, returns platform-specific concrete implementation
+ (id)lacefxViewController;

- (void)setContentDelegate:(id)del;
- (id)contentDelegate;

@end



@interface NSObject (LQGLacefxViewControllerContentDelegate)

- (LXTextureRef)contentTextureForLacefxViewController:(id)viewCtrl;

- (void)drawContentsForLacefxViewController:(id)viewCtrl inSurface:(LXSurfaceRef)lxSurface;

@end

