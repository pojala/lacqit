//
//  LQUIConstants.m
//  Lacqit
//
//  Created by Pauli Ojala on 12.9.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#import "LQUIConstants.h"
#import <Lacefx/LXBasicTypeFunctions.h>
#import <Lacefx/LXTransform3D.h>


NSString * const kLQUIContext_Inspector = @"LQUIContext_Inspector";
NSString * const kLQUIContext_Floater = @"LQUIContext_Floater";
NSString * const kLQUIContext_NodeView = @"LQUIContext_NodeView";
NSString * const kLQUIContext_Viewer = @"LQUIContext_Viewer";

// !! it's not safe to modify these key and binding names because they are used by external JS code !!
NSString * const kLQUIKey_Label = @"label";
NSString * const kLQUIKey_Identifier = @"id";
NSString * const kLQUIKey_ContentType = @"contentType";
NSString * const kLQUIKey_TemplateName = @"templateId";
NSString * const kLQUIKey_Icon = @"icon";

NSString * const kLQUIDataSourceBinding = @"dataBinding";
NSString * const kLQUIActionBinding = @"actionBinding";
NSString * const kLQUISelectionActionBinding = @"selectionActionBinding";



LQInterfaceTint LQInterfaceTintForUIContext(NSString *ctx)
{
    if ([ctx isEqualToString:kLQUIContext_Floater])
        return kLQFloaterTint;
    else if ([ctx isEqualToString:kLQUIContext_NodeView])
        return kLQSemiDarkTint;
        
    else
        return kLQLightTint;
}


static inline LXRect absoluteRect(LXRect rect)
{
    if (rect.w < 0.0) {
        rect.x += rect.w;
        rect.w = -rect.w;
    }
    if (rect.h < 0.0) {
        rect.y += rect.h;
        rect.h = -rect.h;
    }
    return rect;
}

LXTransform3DRef LQFitRectToView_CreateTransform(LXSize outputSize, LXRect onscreenRect, LXInteger fitToViewMode, double sourcePAR)
{
    LXTransform3DRef trs = LXTransform3DCreateIdentity();
    
    switch (fitToViewMode) {
        default:
        case kLQFitMode_StretchToFill:
            LXTransform3DScale(trs,  onscreenRect.w / outputSize.w,  onscreenRect.h / outputSize.h,  1.0);
            break;
            
        case kLQFitMode_CenterWithoutScaling: {
            outputSize.w *= sourcePAR;        
        
            LXTransform3DTranslate(trs,  round((onscreenRect.w - outputSize.w) * 0.5),  round((onscreenRect.h - outputSize.h) * 0.5),  0.0);
            break;
        }
            
        case kLQFitMode_ScaleAndMatchAspect: {
            outputSize.w *= sourcePAR;
        
            double asp = (double)outputSize.w / outputSize.h;
            double winAsp = (double)onscreenRect.w / onscreenRect.h;
            double scale;
            
            if (asp >= winAsp) {  // letterbox (bars at top and bottom)
                scale = (double)onscreenRect.w / outputSize.w;

                LXTransform3DScale(trs,  scale, scale, 1.0);                
                LXTransform3DTranslate(trs,  0.0,  0.5*((double)onscreenRect.h - (scale*outputSize.h)),  0.0);
            }
            else {                // windowbox (bars at left and right)
                scale = (double)onscreenRect.h / outputSize.h;
                
                LXTransform3DScale(trs,  scale, scale, 1.0);
                LXTransform3DTranslate(trs,  0.5*((double)onscreenRect.w - (scale*outputSize.w)),  0.0,  0.0);
            }
            break;
        }
    }
    
    return trs;
}


LXRect LQFitRectToView(LXSize outputSize, LXRect onscreenRect, LXInteger fitToViewMode, double sourcePAR)
{
	onscreenRect = absoluteRect(onscreenRect);

    if (fitToViewMode == kLQFitMode_StretchToFill) {  // stretch to fit -- no need to do anything here
        return onscreenRect;
    }
    
    outputSize.w *= sourcePAR;
    
	double asp = (double)outputSize.w / outputSize.h;
	double winAsp = (double)onscreenRect.w / onscreenRect.h;
	
    double x = 0.0, y = 0.0, w = 0.0, h = 0.0;
	
	if (fitToViewMode == kLQFitMode_ScaleAndMatchAspect) {
		if (asp >= winAsp) {  // letterbox wide (bars at top&bottom)
			x = onscreenRect.x;
			w = onscreenRect.w;
			h = w / asp;
			y = (onscreenRect.h - h) * 0.5;
		}
		else {				  // letterbox tall (bars at right&left)
			y = onscreenRect.y;
			h = onscreenRect.h;
			w = h * asp;
			x = (onscreenRect.w - w) * 0.5;
		}
	}
	else {  // put image at center
		w = outputSize.w;
        h = outputSize.h;
		x = (onscreenRect.w - w) * 0.5;
		y = (onscreenRect.h - h) * 0.5;
	}
	
    x = round(x);
	y = round(y);
	h = round(h);
    // why isn't w rounded here? I guess there must be a reason for it :)
	
	return LXMakeRect(x, y, w, h);
}
