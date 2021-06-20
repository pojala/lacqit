//
//  LQGListItemWrapperController.m
//  Lacqit
//
//  Created by Pauli Ojala on 31.10.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#import "LQGListItemWrapperController_cocoa.h"
#import "LQFlippedView.h"



@implementation LQGListItemWrapperController_cocoa

- (id)init
{
    self = [super initWithResourceName:nil bundle:[NSBundle bundleForClass:[self class]]];
    
    return self;
}

- (void)dealloc
{
    [_containedCtrl release];
    [_addButton release];
    [_delButton release];
    [super dealloc];
}


- (void)setContainedViewController:(LQGCommonUIController *)viewCtrl
{
    [_containedCtrl autorelease];
    _containedCtrl = [viewCtrl retain];
    
    if ( !_view)
        return;
    else {
        NSRect viewFrame = [_view bounds];
        
        NSView *subview = [viewCtrl nativeView];
        if ( !subview) {
            NSLog(@"** %s (%@): no view (%@)", __func__, [self name], viewCtrl);
            return;
        }
        
        NSRect frame = [subview frame];
        frame.size.width = viewFrame.size.width - _buttonAreaW;
        [subview setAutoresizingMask:NSViewWidthSizable];
        [subview setFrame:frame];
        
        ///NSLog(@"%s: subview %@, myview %@", __func__, NSStringFromRect(frame), NSStringFromRect(viewFrame));
        
        viewFrame.size.height = frame.size.height;
        [_view setFrame:viewFrame];
        
        [_view addSubview:subview];
    }
}

- (LQGCommonUIController *)containedViewController {
    return _containedCtrl; }



- (void)buttonAction:(id)sender
{
    NSInteger tag = [sender tag];
    
    if ([_delegate respondsToSelector:@selector(actionInViewController:context:info:)]) {
        [_delegate actionInViewController:self context:(tag == 1) ? kLQGActionContext_AddButtonClicked : kLQGActionContext_DeleteButtonClicked info:nil];
    }
}

- (void)loadView
{
    if (_view) return;

    id contained = _containedCtrl;

    float viewH = (contained) ? [(NSView *)[contained nativeView] frame].size.height : 30.0;
    NSRect viewRect = NSMakeRect(0, 0, 300, viewH);

    _view = [[LQFlippedView alloc] initWithFrame:viewRect];
    [_view setAutoresizingMask:NSViewWidthSizable];
    
    
    double butW = 22;
    double butH = 20;
    double rMargin = 6;
    double tMargin = 4;
    double butInterval = 5;
    NSRect addFrame = NSMakeRect(viewRect.size.width - rMargin - butW,  tMargin,  butW, butH);
    NSRect delFrame = NSMakeRect(viewRect.size.width - rMargin - butW - butInterval - butW,  tMargin,  butW, butH);
    
    _buttonAreaW = rMargin + butW + butInterval + butW;
    
    NSButton *button;
    NSUInteger arMask = (NSViewMinXMargin | NSViewMaxYMargin);
    NSFont *font = [NSFont boldSystemFontOfSize:11.0];
    NSImage *img;
            
            button  = [[NSButton alloc] initWithFrame:addFrame];
            
            img = nil; //[NSImage imageNamed:@"NSAddTemplate"];
            if (img) {
                [button setImage:img];
            } else
                [button setTitle:@"+"];

            [button setAutoresizingMask:arMask];
            [[button cell] setFont:font];
            [[button cell] setControlSize:NSMiniControlSize];
            [[button cell] setBezelStyle:NSRecessedBezelStyle];
            
            [button setTarget:self];
            [button setAction:@selector(buttonAction:)];
            [button setTag:1];
        _addButton = button;


            button  = [[NSButton alloc] initWithFrame:delFrame];
            
            img = nil; //[NSImage imageNamed:@"NSRemoveTemplate"];
            if (img)
                [button setImage:img];
            else
                [button setTitle:@"-"];
                
            [button setAutoresizingMask:arMask];
            [[button cell] setFont:font];
            [[button cell] setControlSize:NSMiniControlSize];
            [[button cell] setBezelStyle:NSRecessedBezelStyle];
            
            [button setTarget:self];
            [button setAction:@selector(buttonAction:)];
            [button setTag:2];
        _delButton = button;

    [_view addSubview:_addButton];
    [_view addSubview:_delButton];
    
    if (contained)
        [self setContainedViewController:contained];
}

@end
