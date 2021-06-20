//
//  LQUIConstants.h
//  Lacqit
//
//  Created by Pauli Ojala on 12.9.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#import "LQUIFrameworkHeader.h"
#import "LacqitExport.h"
#import <Lacefx/LXRefTypes.h>


// UI contexts
LACQIT_EXPORT_VAR NSString * const kLQUIContext_Inspector;
LACQIT_EXPORT_VAR NSString * const kLQUIContext_Floater;
LACQIT_EXPORT_VAR NSString * const kLQUIContext_NodeView;
LACQIT_EXPORT_VAR NSString * const kLQUIContext_Viewer;

// standard object description keys
LACQIT_EXPORT_VAR NSString * const kLQUIKey_Label;
LACQIT_EXPORT_VAR NSString * const kLQUIKey_Identifier;
LACQIT_EXPORT_VAR NSString * const kLQUIKey_ContentType;
LACQIT_EXPORT_VAR NSString * const kLQUIKey_TemplateName;
LACQIT_EXPORT_VAR NSString * const kLQUIKey_Icon;

// names for common bindings (meant for JavaScript use)
LACQIT_EXPORT_VAR NSString * const kLQUIDataSourceBinding;
LACQIT_EXPORT_VAR NSString * const kLQUIActionBinding;
LACQIT_EXPORT_VAR NSString * const kLQUISelectionActionBinding;


#define kLQUIDefaultFontSize 10


// UI color styles
enum {
    kLQSystemTint = 0,
    
    kLQLightTint,
    kLQSemiLightTint,
    kLQSemiDarkTint,
    kLQDarkTint,
    
    kLQDarkDashboardTint = 0x20,
    
    kLQFloaterTint = 0x100
};
typedef LXUInteger LQInterfaceTint;

LACQIT_EXPORT LQInterfaceTint LQInterfaceTintForUIContext(NSString *ctx);


// view scaling
enum {
    kLQFitMode_CenterWithoutScaling = 0,
    kLQFitMode_ScaleAndMatchAspect = 1,
    kLQFitMode_StretchToFill = 2
};
typedef LXUInteger LQFitToViewMode;

// following two functions perform the same operation

LACQIT_EXPORT LXRect LQFitRectToView(LXSize outputSize, LXRect onscreenRect, LXInteger fitToViewMode, double sourcePAR);

LACQIT_EXPORT LXTransform3DRef LQFitRectToView_CreateTransform(LXSize outputSize, LXRect onscreenRect, LXInteger fitToViewMode, double sourcePAR);


