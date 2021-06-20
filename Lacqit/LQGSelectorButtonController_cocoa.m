//
//  LQGSelectorButtonController_cocoa.m
//  Lacqit
//
//  Created by Pauli Ojala on 11.10.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#import "LQGSelectorButtonController_cocoa.h"
#import "LQFlippedView.h"


@implementation LQGSelectorButtonController_cocoa

- (id)init
{
    self = [super initWithResourceName:nil bundle:[NSBundle bundleForClass:[self class]]];
    
    return self;
}

- (void)dealloc
{
    [_label release];
    [_items release];
    [super dealloc];
}

- (NSString *)label {
    return (_label) ? _label : [_labelField stringValue];
}

- (void)setLabel:(NSString *)label {
    [_label release];
    _label = [label retain];
    
    [_labelField setStringValue:(_label) ? _label : @""];
}

- (LXInteger)tag {
    return _tag; }
    
- (void)setTag:(LXInteger)tag {
    _tag = tag;
    [_popUpButton setTag:tag];
}

- (void)_updateTitlesInPopUp
{
    ///NSLog(@"%s: %p, %@", __func__, _popUpButton, _items);
    if (_popUpButton) {
        [_popUpButton removeAllItems];
        
        if ([_items count] > 0) {
            [_popUpButton addItemsWithTitles:_items];
        }
    }
}

- (void)setItemTitles:(NSArray *)items {
    [_items autorelease];
    _items = [items retain];    
    
    [self _updateTitlesInPopUp];
}

- (NSArray *)itemTitles {
    return _items; }

- (void)setIndexOfSelectedItem:(LXInteger)index {
    _selIndex = index;
    
    if (_popUpButton) {
        [_popUpButton selectItemAtIndex:_selIndex];
    }
}
    
- (LXInteger)indexOfSelectedItem {
    return _selIndex; }
    
- (NSString *)titleOfSelectedItem {
    return ([_items count] > 0) ? [_items objectAtIndex:_selIndex] : nil; }

    
- (double)doubleValue {
    return _selIndex; }
    
- (void)setDoubleValue:(double)f {
    LXInteger index = lround(f);
    
    if (index >= 0 && index < [_items count]) {
        [self setIndexOfSelectedItem:index];
    }
}


- (void)popUpButtonAction:(id)sender
{
    ///NSLog(@"%s (%p): %@", __func__, self, sender);
    
    _selIndex = [sender indexOfSelectedItem];
    
    [_delegate valuesDidChangeInViewController:self];
}


- (void)loadView
{
    if (_view) return;

    id val;
    NSRect viewRect = NSMakeRect(0, 0, 300, 26);

    [_view autorelease];
    _view = [[LQFlippedView alloc] initWithFrame:viewRect];
    [_view setAutoresizingMask:NSViewWidthSizable];

    double x =       ((val = [_styleDict objectForKey:kLQGStyle_PaddingLeft])) ? [val doubleValue] : 8.0;
    double rMargin = ((val = [_styleDict objectForKey:kLQGStyle_PaddingRight])) ? [val doubleValue] : 8.0;
    double y = 8.0;             // top margin
    double w = round(viewRect.size.width - x - rMargin);
    double nameHeight = 12.0;   // label's height

    NSString *label = [self label];
    if ( !label)  label = @"";
    
    NSDictionary *labelAttribs = [self labelAttributes];
    NSAttributedString *attrLabel = [[[NSAttributedString alloc] initWithString:label attributes:labelAttribs] autorelease];
    NSSize labelSize = [label sizeWithAttributes:labelAttribs];
    labelSize.width = ceil(labelSize.width);

//    NSSize titleSize = NSMakeSize(60, 18);

    ///NSLog(@"selectorbutton: labelsize %@ (%@)", NSStringFromSize(labelSize), label);

			NSTextField *nameField = [[NSTextField alloc] initWithFrame:NSMakeRect(x,  y-1.0,
																	labelSize.width+10.0,  nameHeight)];
			[nameField setEditable:NO];
			//[nameField setFont:labelFont];
			[nameField setStringValue:(NSString *)attrLabel];
			[nameField setAlignment:NSLeftTextAlignment];
			[nameField setBezeled:NO];
			[nameField setDrawsBackground:NO];
			[nameField setAutoresizingMask:(NSViewMinYMargin | NSViewMaxXMargin)];
			
			
			NSPopUpButton *popUpButton = [[NSPopUpButton alloc] initWithFrame:NSMakeRect(
													x + labelSize.width + 14.0, 
                                                    y - 4.0,
													w - labelSize.width - 12.0,  18.0)
											pullsDown:NO];
			
            NSFont *font = [[self styleAttributes] objectForKey:kLQGStyle_Font];
            
			[[popUpButton cell] setControlSize:NSMiniControlSize];
			[[popUpButton cell] setFont:(font) ? font :
                                            [NSFont systemFontOfSize:kLQUIDefaultFontSize]];
			[popUpButton setAutoresizingMask:(NSViewMinYMargin | NSViewWidthSizable)];
			
			[popUpButton setTarget:self];
			[popUpButton setAction:@selector(popUpButtonAction:)];

    [_view addSubview:[nameField autorelease]];
    [_view addSubview:[popUpButton autorelease]];

    _labelField = nameField;
    _popUpButton = popUpButton;
    
    [self _updateTitlesInPopUp];    
}


@end
