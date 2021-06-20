//
//  LQMegaDropDown.h
//  Lacqit
//
//  Created by Pauli Ojala on 24.3.2009.
//  Copyright 2009 Lacquer oy/ltd. All rights reserved.
//

#import "LQUIFrameworkHeader.h"
#import "LQUIConstants.h"
@class LQGViewController;
@class LQPopUpWindow;

/*
  This is a "mega dropdown" menu in the sense described by Jakob Nielsen:  http://www.useit.com/alertbox/mega-dropdown-menus.html
  
  The menu is implemented as a LQPopUpWindow (at least on Mac).
*/

@interface LQMegaDropDown : NSObject {

    LQPopUpWindow *_hudWindow;
    
    LQGViewController *_viewCtrl;
    id _activeView;
    
    BOOL _inModal;
    LXInteger _modalReturn;
    
    // state for sub-modal sessions
    LXUInteger _prevWindowLevel;
}

- (void)setViewController:(id)viewCtrl;
- (id)viewController;

// the clickedView argument is used to place the dropdown at the proper location.
// the dropdown runs until it's explicitly terminated (return value is 1) or the user clicks outside it (return value is 0).
- (LXInteger)runDropDownForView:(NSView *)clickedView;

- (void)endDropDown;

- (LQPopUpWindow *)popUpWindow;

- (void)containeeWillBeginModalSession:(id)sender;
- (void)containeeDidEndModalSession:(id)sender;

@end


// a view controller can implement this to be notified when it's placed in a dropdown
@interface NSObject (LQMegaDropDownViewControllerOwning)
- (void)willBeContainedInDropDown:(id)dropDown;
- (void)willBeRemovedFromDropDown:(id)dropDown;
@end