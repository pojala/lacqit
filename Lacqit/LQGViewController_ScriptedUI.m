//
//  LQGViewController_ScriptedUI.m
//  Lacqit
//
//  Created by Pauli Ojala on 13.1.2010.
//  Copyright 2010 Lacquer oy/ltd. All rights reserved.
//

#import "LQGViewController_ScriptedUI.h"
#import "LQGViewController_priv.h"
#import "LQGCommonUIControllerSubtypeMethods.h"
#import "LQGCommonUINSViewController.h"
#import "LQGUITextField.h"
#import "LQGUIButton.h"
#import "LQGUISegmentedButton.h"
#import "LQNSColorAdditions.h"


// presenter type names are case-insensitive, so must be lowercase here
NSString * const kLQGScriptedUIPresenterType_Label = @"label";
NSString * const kLQGScriptedUIPresenterType_Button = @"button";
NSString * const kLQGScriptedUIPresenterType_MultiButton = @"multibutton";
NSString * const kLQGScriptedUIPresenterType_CheckBox = @"checkbox";
NSString * const kLQGScriptedUIPresenterType_NumberInput = @"numberinput";
NSString * const kLQGScriptedUIPresenterType_TextInput = @"textinput";
NSString * const kLQGScriptedUIPresenterType_ColorPicker = @"colorpicker";
NSString * const kLQGScriptedUIPresenterType_Canvas = @"canvas";
NSString * const kLQGScriptedUIPresenterType_HorizontalList = @"hlist";
NSString * const kLQGScriptedUIPresenterType_SelectorButton = @"select";


@implementation LQGViewController (ScriptedUI)

+ (LQGViewController *)viewControllerFromScriptedUIDefinition:(NSDictionary *)dict
{
    if ( !dict) return nil;
    if ( ![dict respondsToSelector:@selector(objectForKey:)]) {
        NSLog(@"*** %s: warning - unsupported object (%@)", __func__, [dict class]);
        return nil;
    }

    NSString *ctrlType = [[dict objectForKey:@"type"] lowercaseString];  // these are case-insensitive
    
    // also remove dashes (so that e.g. 'colorpicker' and 'color-picker' are equivalent)
    NSMutableString *m = [NSMutableString stringWithString:ctrlType];
    [m replaceOccurrencesOfString:@"-" withString:@"" options:0 range:NSMakeRange(0, m.length)];
    ctrlType = m;
    
    NSString *ctrlID = [dict objectForKey:@"id"];
    NSString *ctrlText = [dict objectForKey:@"text"];
    NSString *ctrlLabel = [dict objectForKey:@"label"];
    id ctrlWidth = [dict objectForKey:@"width"];
    id ctrlHeight = [dict objectForKey:@"height"];
    NSString *ctrlWindowStyle = [dict objectForKey:@"windowStyle"];
    const BOOL isFloater = ([ctrlWindowStyle isEqual:@"dark"]);
    NSString *lqUIContext = (isFloater) ? kLQUIContext_Floater : nil;
    
    NSView *nsView = nil;
    id forwardControl = nil;
    id controlToSetTargetFor = nil;
    NSMutableDictionary *styleAttrs = nil;
    id val;
    double xPad = 2;
    double yPad = 2;
    NSSize canvasSize = NSZeroSize;
    /*
    if ((val = [dict objectForKey:@"paddingH"]) && isfinite([val doubleValue])) {
        xPad = [val doubleValue];
    }
    if ((val = [dict objectForKey:@"paddingV"]) && isfinite([val doubleValue])) {
        yPad = [val doubleValue];
    }
    */
    
    double topPad = 0;
    double leftPad = 0;
    double rightPad = 0;
    double bottomPad = 0;
    if ((val = [dict objectForKey:kLQGStyle_PaddingTop]) && isfinite([val doubleValue])) topPad = [val doubleValue];
    if ((val = [dict objectForKey:kLQGStyle_PaddingLeft]) && isfinite([val doubleValue])) leftPad = [val doubleValue];
    if ((val = [dict objectForKey:kLQGStyle_PaddingRight]) && isfinite([val doubleValue])) rightPad = [val doubleValue];
    if ((val = [dict objectForKey:kLQGStyle_PaddingBottom]) && isfinite([val doubleValue])) bottomPad = [val doubleValue];
    
    ///NSLog(@"ctrltype '%@', paddings %.1f, %.1f, %.1f, %.1f", ctrlType, topPad, leftPad, rightPad, bottomPad);
    
    
    styleAttrs = [NSMutableDictionary dictionaryWithObjectsAndKeys:[NSFont boldSystemFontOfSize:kLQUIDefaultFontSize], kLQGStyle_Font,
                                                                   [NSNumber numberWithDouble:2.0],   kLQGStyle_PaddingLeft,
                                                                   [NSNumber numberWithDouble:2.0],   kLQGStyle_PaddingRight,
                                                                    nil];

    if ((val = [dict objectForKey:@"color"])) {
        NSColor *c = [NSColor colorWithHTMLFormattedSRGBString:[val description]];
        if (c)
            [styleAttrs setObject:c forKey:kLQGStyle_ForegroundColor];
    }
    
    
    id newCtrl = nil;

    if ([ctrlType isEqual:kLQGScriptedUIPresenterType_NumberInput]) {
        newCtrl = [LQGCommonUIController commonUIControllerOfType:kLQGCommonUI_SliderAndField subtype:nil];
        // available subtype: @"smallFullWidthSlider";
        
        if (ctrlLabel) {
            [newCtrl setLabel:ctrlLabel];  // set label right away so its size is computed properly
            ctrlLabel = nil;
        }        
    }
    if ([ctrlType isEqual:kLQGScriptedUIPresenterType_TextInput]) {
        newCtrl = [LQGCommonUIController commonUIControllerOfType:kLQGCommonUI_TextBox subtype:nil];
        
        if (ctrlLabel) {
            [newCtrl setLabel:ctrlLabel];  // set label right away so its size is computed properly
            ctrlLabel = nil;
        }
        
        if ([[dict objectForKey:@"multiline"] boolValue]) {
            [newCtrl setMultiline:YES];
            
            if (ctrlHeight && [ctrlHeight doubleValue] > 0.0) {
                [newCtrl loadView];
                NSView *view = [newCtrl view];
                NSRect frame = view.frame;
                frame.size.height = [ctrlHeight doubleValue];
                view.frame = frame;
            }
        }
        if ([dict objectForKey:@"editable"] && ![[dict objectForKey:@"editable"] boolValue]) {
            [newCtrl setEditable:NO];
        }
        if ([[dict objectForKey:@"secure"] boolValue]) {
            [newCtrl setSecure:YES];
        }
    }
    else if ([ctrlType isEqual:kLQGScriptedUIPresenterType_ColorPicker]) {
        newCtrl = [LQGCommonUIController commonUIControllerOfType:kLQGCommonUI_ColorPicker subtype:nil];
        if (ctrlLabel) {
            [newCtrl setLabel:ctrlLabel];
            ctrlLabel = nil;
        }
    }
    else if ([ctrlType isEqual:kLQGScriptedUIPresenterType_CheckBox]) {
        newCtrl = [LQGCommonUIController commonUIControllerOfType:kLQGCommonUI_Checkbox subtype:nil];
    }
    else if ([ctrlType isEqual:kLQGScriptedUIPresenterType_SelectorButton]) {
        newCtrl = [LQGCommonUIController commonUIControllerOfType:kLQGCommonUI_SelectorButton subtype:nil];
        if (ctrlLabel) {
            [newCtrl setLabel:ctrlLabel];
            ctrlLabel = nil;
        }
        
        NSArray *itemTitles = ((val = [dict objectForKey:@"items"]) && [val isKindOfClass:[NSArray class]]) ? val : [NSArray array];
        [newCtrl setItemTitles:itemTitles];
    }
    else if ([ctrlType isEqual:kLQGScriptedUIPresenterType_Label]) {
        newCtrl = [LQGCommonUIController commonUIControllerOfType:kLQGCommonUI_GenericNSView subtype:nil];
        
        id control = [LQGUITextField labelWithString:(ctrlText) ? [ctrlText description] : (NSString *)@"(no text)"
                                            name:ctrlID context:lqUIContext];
        NSRect frame = [control frame];
        
        if (ctrlWidth && [ctrlWidth doubleValue] > 0.0) {
            frame.size.width = [ctrlWidth doubleValue];
        }
        if (ctrlHeight && [ctrlHeight doubleValue] > 0.0) {
            frame.size.height = [ctrlHeight doubleValue];
            //NSLog(@"%s, ctrl h %.1f -- frame %@", __func__, frame.size.height, NSStringFromRect(frame));
        }

        frame.origin = NSMakePoint(xPad + leftPad, yPad + bottomPad);
        [control setFrame:frame];

        frame.size.width += 2*xPad + leftPad + rightPad;
        frame.size.height += 2*yPad + bottomPad + topPad;
        frame.origin = NSMakePoint(0, 0);
        nsView = [[[NSView alloc] initWithFrame:frame] autorelease];
        [nsView addSubview:control];
        
        //NSLog(@"label view frame: %@", NSStringFromRect(frame));
        
        if ((val = [dict objectForKey:@"color"])) {
            [(NSTextField *)control setTextColor:[NSColor colorWithHTMLFormattedSRGBString:[val description]]];
        }
        forwardControl = control;
    }
    else if ([ctrlType isEqual:kLQGScriptedUIPresenterType_Button]) {
        newCtrl = [LQGCommonUIController commonUIControllerOfType:kLQGCommonUI_GenericNSView subtype:nil];
        
        id control = [LQGUIButton pushButtonWithLabel:(ctrlText) ? [ctrlText description] : (NSString *)@"(Button)"
                                            name:ctrlID context:lqUIContext target:nil action:NULL];

        NSRect frame = [control frame];
        if (ctrlWidth && [ctrlWidth doubleValue] > 0.0) {
            frame.size.width = [ctrlWidth doubleValue];
            frame.origin = NSMakePoint(xPad + bottomPad, yPad + leftPad);
            frame.size.width += rightPad;
            frame.size.height += topPad;
            [control setFrame:frame];
        }

        frame.size.width += 2*xPad;
        frame.size.height += 2*yPad;
        frame.origin = NSMakePoint(0, 0);
        nsView = [[[NSView alloc] initWithFrame:frame] autorelease];
        [nsView addSubview:control];
        
        [control setAction:@selector(delegatingButtonAction:)];  // target will be set later
        controlToSetTargetFor = control;
        forwardControl = control;
    }
    else if ([ctrlType isEqual:kLQGScriptedUIPresenterType_MultiButton]) {
        newCtrl = [LQGCommonUIController commonUIControllerOfType:kLQGCommonUI_GenericNSView subtype:nil];

        NSDictionary *paramDesc = dict;  // this code is from PixMathScriptableBufNode.m in Conduit, hence the var names
        NSString *trackModeStr = [paramDesc objectForKey:@"selectable"];
        LXUInteger trackMode;
        if ([trackModeStr isEqual:@"any"]) {
            trackMode = kLQSegmentSwitchTrackingSelectAny;
        } else if ([trackModeStr isEqual:@"none"]) {
            trackMode = kLQSegmentSwitchTrackingMomentary;
        } else {
            trackMode = kLQSegmentSwitchTrackingSelectOne;
        }
        LXInteger count = ((val = [paramDesc objectForKey:@"count"])) ? [val doubleValue] : 0;
        NSArray *labels = ((val = [paramDesc objectForKey:@"labels"]) && [val isKindOfClass:[NSArray class]]) ? val : [NSArray array];
        LXInteger i;
        if (count > [labels count]) {
            NSMutableArray *newLabels = [NSMutableArray arrayWithArray:labels];
            for (i = [labels count]; i < count; i++) {
                [newLabels addObject:[NSString stringWithFormat:@"%i", (int)i+1]];
            }
            labels = newLabels;
        } else {
            count = [labels count];
        }
        
        if (count > 0) {
            LQGUISegmentedButton *control = [LQGUISegmentedButton segmentedButtonWithLabels:labels
                                                        name:ctrlID context:lqUIContext target:nil action:NULL];
            
            [control setTrackingMode:trackMode];
            
            NSRect frame = [control frame];
            if (ctrlWidth && [ctrlWidth doubleValue] > 0.0) {
                frame.size.width = [ctrlWidth doubleValue];
                frame.origin = NSMakePoint(xPad + bottomPad, yPad + leftPad);
                frame.size.width += rightPad;
                frame.size.height += topPad;
                [control setFrame:frame];
            }
            
            frame.size.width += 2*xPad;
            frame.size.height += 2*yPad;
            frame.origin = NSMakePoint(0, 0);
            nsView = [[[NSView alloc] initWithFrame:frame] autorelease];
            [nsView addSubview:control];
            
            [control setAction:@selector(delegatingSegmentedControlAction:)];  // target will be set later
            controlToSetTargetFor = control;
            forwardControl = control;
        }
    }
    else if ([ctrlType isEqual:kLQGScriptedUIPresenterType_Canvas]) {
        newCtrl = [LQGCommonUIController commonUIControllerOfType:kLQGCommonUI_Canvas subtype:nil];
        
        LXInteger w = 200;
        LXInteger h = 150;
        if (ctrlWidth && [ctrlWidth doubleValue] > 0.0)
            w = lround([ctrlWidth doubleValue]);
        if (ctrlHeight && [ctrlHeight doubleValue] > 0.0)
            h = lround([ctrlHeight doubleValue]);
            
        canvasSize = NSMakeSize(w, h);
    }
    else if ([ctrlType isEqual:kLQGScriptedUIPresenterType_HorizontalList]) {
        newCtrl = [LQGCommonUIController commonUIControllerOfType:kLQGCommonUI_GenericNSView subtype:nil];

        NSArray *subitems = [dict objectForKey:@"items"];
        NSMutableArray *subviewCtrls = [NSMutableArray array];
        double totalW = 0.0;
        double maxH = 0.0;
        if ([subitems isKindOfClass:[NSArray class]]) {
            // instantiate the subviews
            for (NSDictionary *item in subitems) {
                id subviewCtrl = [self viewControllerFromScriptedUIDefinition:item];
                if (subviewCtrl) {
                    [subviewCtrls addObject:subviewCtrl];
                    NSRect frame = [[subviewCtrl nativeView] frame];
                    frame.origin.x = totalW;
                    //frame.origin.y += yPad;
                    [[subviewCtrl nativeView] setFrame:frame];
                    
                    totalW += frame.size.width;
                    maxH = NSMaxY(frame);
                }
            }
        }
        
        NSRect totalFrame = NSMakeRect(0, 0, totalW + leftPad + rightPad, maxH + bottomPad + topPad);
        
        nsView = [[[NSView alloc] initWithFrame:totalFrame] autorelease];
        
        for (id subviewCtrl in subviewCtrls) {
            NSView *subview = [subviewCtrl nativeView];
            NSRect frame = [subview frame];
            frame.origin.x += leftPad;
            frame.origin.y += bottomPad;
            [subview setFrame:frame];
            [nsView addSubview:subview];
        }
        
        [newCtrl setSubviewControllers:subviewCtrls];
    }
    
    
    // done with creating views, now setup common parameters
    
    if ( !newCtrl) {
        NSLog(@"** unsupported view controller type specified in plist: '%@'", ctrlType);
        return nil;  // ---
    }
    
    if (ctrlID) {
        [(LQGViewController *)newCtrl setName:ctrlID];
    }    
    if (styleAttrs) {
        [newCtrl setStyleAttributes:styleAttrs];
    }
    if (canvasSize.width > 0) {
        [newCtrl setCanvasSize:canvasSize];
    }
    
    id ctrlResize = [[dict objectForKey:@"resize"] description];
    BOOL resizeW = (ctrlResize && [ctrlResize rangeOfString:@"width"].location != NSNotFound);
    BOOL resizeH = (ctrlResize && [ctrlResize rangeOfString:@"height"].location != NSNotFound);
    
    if (nsView) {
        LXUInteger resizeMask = [nsView autoresizingMask];
        
        if (resizeW)
            resizeMask |= NSViewWidthSizable;
        if (resizeH)
            resizeMask |= NSViewHeightSizable;

        [nsView setAutoresizingMask:resizeMask];
        
        [newCtrl setNativeView:nsView];
        
        [newCtrl setForwardControl:forwardControl];
        
        [controlToSetTargetFor setTarget:newCtrl];
    }
    else {
        [newCtrl loadView];

        NSView *view = [newCtrl nativeView];
        if ([view isKindOfClass:[NSView class]]) {            
            [view setAutoresizingMask:(resizeW) ? ([view autoresizingMask] | NSViewWidthSizable) : ([view autoresizingMask] & ~NSViewWidthSizable)];
            
            if (resizeH) {
                [view setAutoresizingMask:([view autoresizingMask] | NSViewHeightSizable)];
            }
            if ( !resizeW && ctrlWidth && [ctrlWidth doubleValue] > 0.0) {
                NSRect frame = [view frame];
                frame.size.width = [ctrlWidth doubleValue];
                [view setFrame:frame];
            }
        }
    }

    if (ctrlLabel && [newCtrl respondsToSelector:@selector(setLabel:)]) {
        [newCtrl setLabel:ctrlLabel];
        [newCtrl setTitle:ctrlLabel];
    }

    if (ctrlText && nsView && [nsView respondsToSelector:@selector(setStringValue:)]) {
        [(id)nsView setStringValue:ctrlText];
    }
    
    if ([newCtrl respondsToSelector:@selector(setEnabled:)] && (val = [dict objectForKey:@"enabled"]) && [val respondsToSelector:@selector(boolValue)]) {
        [newCtrl setEnabled:[val boolValue]];
    }
    
    if ([newCtrl respondsToSelector:@selector(setSliderMin:max:)]) {
        id minv = [dict objectForKey:@"min"];
        id maxv = [dict objectForKey:@"max"];
        if (minv || maxv) 
            [newCtrl setSliderMin:(minv ? [minv doubleValue] : [maxv doubleValue]-1) max:(maxv ? [maxv doubleValue] : [minv doubleValue]+1)];
    }
    
    if ([newCtrl respondsToSelector:@selector(setDoubleValue:)] && (val = [dict objectForKey:@"default"])) {
        [newCtrl setDoubleValue:[val doubleValue]];
    }
    
    if ([newCtrl respondsToSelector:@selector(setIncrement:)] && (val = [dict objectForKey:@"increment"])) {
        [newCtrl setIncrement:[val doubleValue]];
    }
    
    NSMutableDictionary *jsBindings = [NSMutableDictionary dictionary];
    
    if ((val = [dict objectForKey:kLQUIActionBinding])) {
        [jsBindings setObject:[val description] forKey:kLQUIActionBinding];
    }
    
    if ([jsBindings count] > 0) {
        [newCtrl setScriptBindings:jsBindings];
    }
    
    return (LQGViewController *)newCtrl;
}

@end

