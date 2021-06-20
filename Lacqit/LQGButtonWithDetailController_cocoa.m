//
//  LQGButtonWithDetailController_cocoa.m
//  Lacqit
//
//  Created by Pauli Ojala on 11.10.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#import "LQGButtonWithDetailController_cocoa.h"
#import "LQFlippedView.h"


@implementation LQGButtonWithDetailController_cocoa

- (id)init
{
    self = [super initWithResourceName:nil bundle:[NSBundle bundleForClass:[self class]]];
    
    return self;
}

- (void)dealloc
{
    [_label release];
    [super dealloc];
}

- (NSString *)label {
    return (_label) ? _label : [_labelField stringValue];
}

- (void)setLabel:(NSString *)label {
    [_label autorelease];
    _label = [label copy];
    
    [_labelField setStringValue:(_label) ? _label : @""];
}

- (LXInteger)tag {
    return _tag; }
    
- (void)setTag:(LXInteger)tag {
    _tag = tag;
    [_button setTag:tag]; }


#define DETAILFIELDH 50

- (NSString *)detailString {
    return _detailStr; }
    
- (void)setDetailString:(NSString *)str
{
    [_detailStr autorelease];
    _detailStr = [str copy];
    
    [_detailField setStringValue:(_detailStr) ? _detailStr : @""];
    
    BOOL hasDetailText = ([str length] > 0);
    if (hasDetailText && [_detailField isHidden]) {
        NSRect frame = [_view frame];
        frame.size.height += DETAILFIELDH;
        [_view setFrame:frame];
        [_detailField setHidden:NO];    
    }
    else if ( !hasDetailText && ![_detailField isHidden]) {
        NSRect frame = [_view frame];
        frame.size.height -= DETAILFIELDH;
        [_view setFrame:frame];        
        [_detailField setHidden:YES];
    }
}

- (NSDictionary *)buttonAttributes
{
    return [NSDictionary dictionaryWithObjectsAndKeys:
                [NSFont systemFontOfSize:[NSFont systemFontSizeForControlSize:NSMiniControlSize]],  NSFontAttributeName,
                nil];
}

- (NSString *)buttonLabel {
    return _buttonLabel; }
    
- (void)setButtonLabel:(NSString *)str
{
    [_buttonLabel autorelease];
    _buttonLabel = [(str ? str : @"") copy];
    
    [_button setTitle:_buttonLabel];
    
    NSSize size = [_buttonLabel sizeWithAttributes:[self buttonAttributes]];
    
    NSRect frame = [_button frame];
    frame.size.width = size.width + 24;
    [_button setFrame:frame];
}


- (void)buttonAction:(id)sender
{
    if ([_delegate respondsToSelector:@selector(actionInViewController:context:info:)])
        [_delegate actionInViewController:self context:kLQGActionContext_ButtonClicked info:nil];
}


- (void)loadView
{
    if (_view) return;

    double selectorH = 28.0;
    NSRect viewRect = NSMakeRect(0, 0, 300, selectorH);

    NSString *detailStr = [self detailString];
    BOOL hasDetailText = ([detailStr length] > 0);

    if (hasDetailText)
        viewRect.size.height += DETAILFIELDH;

    [_view autorelease];
    _view = [[LQFlippedView alloc] initWithFrame:viewRect];
    [_view setAutoresizingMask:NSViewWidthSizable];

    double x = 8.0;             // left margin
    double y = 4.0;             // bottom margin
    double nameHeight = 12.0;   // label's height
    NSSize titleSize = NSMakeSize(viewRect.size.width - 22, 18);

    NSString *label = [self label];
    if ( !label)  label = @"";
    
			
			
            BOOL hasLabel = [label length] > 0;
			if (hasLabel) {
                NSAttributedString *attrLabel = [[[NSAttributedString alloc] initWithString:label attributes:[self labelAttributes]] autorelease];
            
                NSTextField *nameField = [[NSTextField alloc] initWithFrame:NSMakeRect(x,  y-1.0,
																	titleSize.width+4.0,  nameHeight)];
                [nameField setEditable:NO];
                [nameField setStringValue:(NSString *)attrLabel];
                [nameField setAlignment:NSLeftTextAlignment];
                [nameField setBezeled:NO];
                [nameField setDrawsBackground:NO];
                [nameField setAutoresizingMask:(NSViewMaxYMargin | NSViewMaxXMargin)];
                
                [_view addSubview:[nameField autorelease]];

                _labelField = nameField;
                y+= nameHeight + 4;
			} else
                _labelField = nil;
                
            
            NSRect selRect =  NSMakeRect(x + 16.0, y, viewRect.size.width - 24, 40);
            
            NSButton *button = [[NSButton alloc] initWithFrame:NSMakeRect(selRect.origin.x, selRect.origin.y,   90, 18)];            
            
            [button setTitle:([_buttonLabel length] > 0) ? _buttonLabel : @"Choose File..."];            
            [button setBezelStyle:NSRoundedBezelStyle];
            [[button cell] setFont:[[self buttonAttributes] objectForKey:NSFontAttributeName]];
            [[button cell] setControlSize:NSMiniControlSize];
            
            [button setTarget:self];
            [button setAction:@selector(buttonAction:)];

            NSTextField *field = [[NSTextField alloc] initWithFrame:NSMakeRect(selRect.origin.x, selRect.origin.y + 18 + 6,  400, 34)];
            [field setStringValue:(detailStr) ? detailStr : @""];
            [field setFont:[NSFont systemFontOfSize:kLQUIDefaultFontSize]];
            [field setBackgroundColor:[NSColor colorWithDeviceRed:0.91 green:0.91 blue:0.91 alpha:1.0]];
            [field setEditable:NO];
            [field setBezeled:NO];
            [field setDrawsBackground:NO];
            
            [field setHidden: !hasDetailText];
            
            
    [_view addSubview:[field autorelease]];
    [_view addSubview:[button autorelease]];

    _detailField = field;
    _button = button;
    
    if (_buttonLabel)
        [self setButtonLabel:_buttonLabel];
        
    if (_detailStr)
        [self setDetailString:_detailStr];
}


@end
