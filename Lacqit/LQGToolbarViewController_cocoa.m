//
//  LQGToolbarViewController.m
//  Lacqit
//
//  Created by Pauli Ojala on 29.12.2009.
//  Copyright 2009 Lacquer oy/ltd. All rights reserved.
//

#import "LQGToolbarViewController_cocoa.h"
#import "LQJSUtils.h"
#import "LQFlippedView.h"
#import "LQSegmentedControl.h"


@implementation LQGToolbarViewController_cocoa

- (id)init
{
    self = [super initWithResourceName:nil bundle:[NSBundle bundleForClass:[self class]]];
 
    _buttonViews = [[NSMutableArray alloc] init];
          
    return self;
}

- (void)dealloc
{
    [_buttonViews release];
    [_toolInfoDicts release];
    [super dealloc];
}

- (NSArray *)toolbarItems {
    return _toolInfoDicts;
}

- (NSArray *)buttonViews {
    return _buttonViews;
}


- (void)_updateButtonsInView
{
    LXInteger itemCount = [_toolInfoDicts count];
    
    NSEnumerator *enumerator = [_buttonViews objectEnumerator];
    NSView *button;
    while (button = [enumerator nextObject]) {
        [button removeFromSuperview];
    }
    [_buttonViews removeAllObjects];
    
    double w = 38.0;
    
    if (itemCount < 1) {
        [_view setFrame:NSMakeRect(0, 0, w, w)];
        return;
    }
    
    NSSize buttonSize = NSMakeSize(32, 23);
    double xMargin = 5;
    double yMargin = 6;
    double intv = 2.0;

    [_view setFrame:NSMakeRect(0, 0, w, buttonSize.height*itemCount + intv*(itemCount-1) + 2*yMargin)];
    
    double y = yMargin;
    LXInteger i;
    for (i = 0; i < itemCount; i++) {
        NSDictionary *itemDict = [_toolInfoDicts objectAtIndex:i];
        
        ///NSLog(@"... %i: dict %@", i, itemDict);
    
        LQSegmentedControl *seg = [[LQSegmentedControl alloc] initWithFrame:NSMakeRect(xMargin, y, buttonSize.width, buttonSize.height)];
    
        [seg setSegmentCount:1];
        [seg setTag:1 + i];
        
        [seg setWidth:buttonSize.width+4 forSegment:0];
        
        [seg setInterfaceTint:kLQDarkTint];

        [[seg cell] setControlSize:NSSmallControlSize];
        [[seg cell] setTrackingMode:NSSegmentSwitchTrackingSelectOne];
        
        NSString *toolTip = [itemDict objectForKey:@"toolTip"];
        if (toolTip) {
            [seg setToolTip:toolTip];
        }
        
        NSImage *icon = [itemDict objectForKey:kLQUIKey_Icon];
        if (icon) {
            NSSize iconSize = [icon size];
            if (iconSize.width > 28.0 || iconSize.height > 28.0)
                iconSize = NSMakeSize(18, 18);
                
            [seg setImage:icon withFixedSize:iconSize opacity:1.0];
        }
        else {
            NSString *label = [itemDict objectForKey:kLQUIKey_Label];
            if ( !label) label = @"(Untitled)";
            
            [seg setLabel:label forSegment:0];
        }
        
        [seg setAction:@selector(toolbarButtonAction:)];
        [seg setTarget:self];
        
        [seg setAutoresizingMask:NSViewMaxXMargin | NSViewMaxYMargin];
        
        ///NSLog(@"... toolbar button %i: frame %@", i, NSStringFromRect([seg frame]));
        
        [_buttonViews addObject:[seg autorelease]];
        [_view addSubview:seg];
        
        y += buttonSize.height + intv;
    }
}

- (void)setToolbarItems:(NSArray *)itemDicts
{
    [_toolInfoDicts release];
    _toolInfoDicts = [LQArrayByConvertingKeyedItemsToDictionariesInArray(itemDicts) retain];
    
    [self _updateButtonsInView];
    [self setIndexOfSelectedItem:_selItem];
}

- (LXInteger)indexOfSelectedItem {
    return _selItem; }
    
- (void)setIndexOfSelectedItem:(LXInteger)index
{
    _selItem = index;
    LXInteger i;
    for (i = 0; i < [_buttonViews count]; i++) {
        id seg = [_buttonViews objectAtIndex:i];
        if (i != index)
            [seg setSelected:NO forSegment:0];
        else
            [seg setSelected:YES forSegment:0];
    }
}

- (NSString *)identifierOfSelectedItem
{
    return (NSString *)[[_toolInfoDicts objectAtIndex:_selItem] objectForKey:kLQUIKey_Identifier];
}

- (void)selectItemWithIdentifier:(NSString *)item
{
    LXInteger index = NSNotFound;
    NSEnumerator *enumerator = [_toolInfoDicts objectEnumerator];
    id toolInfo;
    LXInteger n = 0;
    while (toolInfo = [enumerator nextObject]) {
        if ([[toolInfo objectForKey:kLQUIKey_Identifier] isEqualToString:item]) {
            index = n;
            break;
        }
        n++;
    }

    if (index != NSNotFound) {
        [self setIndexOfSelectedItem:index];
    }
}


- (void)loadView
{
    if (_view) return;
    
    _view = [[LQFlippedView alloc] initWithFrame:NSMakeRect(0, 0, 30, 30)];
    [_view setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
    
    if (_toolInfoDicts) {
        [self _updateButtonsInView];
        
        [self setIndexOfSelectedItem:_selItem];
    }
}


- (void)toolbarButtonAction:(id)sender
{
    LXInteger index = [sender tag] - 1;
    
    [self setIndexOfSelectedItem:index];
    
    if ([_delegate respondsToSelector:@selector(actionInViewController:context:info:)])
        [_delegate actionInViewController:self context:kLQGActionContext_ButtonClicked info:nil];
}

@end

