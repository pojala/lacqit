//
//  LQGViewController.m
//  Lacqit
//
//  Created by Pauli Ojala on 12.9.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#import "LQGViewController.h"
#import "LacqitInit.h"


// style attributes
NSString * const kLQGStyle_Font = @"font";
NSString * const kLQGStyle_ForegroundColor = @"foregroundColor";
NSString * const kLQGStyle_PaddingTop = @"paddingTop";
NSString * const kLQGStyle_PaddingLeft = @"paddingLeft";
NSString * const kLQGStyle_PaddingRight = @"paddingRight";
NSString * const kLQGStyle_PaddingBottom = @"paddingBottom";
NSString * const kLQGStyle_MarginLeft = @"marginLeft";
NSString * const kLQGStyle_MarginRight = @"marginRight";
NSString * const kLQGStyle_MarginTop = @"marginTop";
NSString * const kLQGStyle_MarginBottom = @"marginBottom";


@implementation LQGViewController

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p (%@, title '%@')>",
                        [self class], self,
                        [self name], [self title]
                    ];
}


- (id)initWithResourceName:(NSString *)nibName bundle:(NSBundle *)nibBundle
{
    self = [super init];
    
    _resName = [nibName retain];
    _resBundle = [nibBundle retain];
    
    _title = [@"(Untitled)" retain];
    
    return self;
}

- (id)init
{
    return [self initWithResourceName:nil bundle:nil];
}

- (void)dealloc
{
    [_view release];
    _view = nil;
    
    [_nibObjects release];
    _nibObjects = nil;    
    
    [_resName release];
    [_resBundle release];
    [_repObj release];
    [_title release];
    [_name release];

    [super dealloc];
}


// views are not instantiated when the controller is inited, so this must be always called
- (void)loadView
{
    LQInvalidAbstractInvocation();
}

- (NSString *)resourceName {
    return _resName; }
    
- (NSBundle *)resourceBundle {
    return _resBundle; }
    

- (id)representedObject {
    return _repObj; }
    
- (void)setRepresentedObject:(id)obj {
    if (obj != _repObj) {
        [_repObj autorelease];
        _repObj = [obj retain];
    }
}

- (NSString *)title {
    return _title; }
    
- (void)setTitle:(NSString *)title {
    [_title autorelease];
    _title = [title copy];
    
    if (!_name)
        _name = [_title retain];
}

- (NSString *)name {
    return _name; }
    
- (void)setName:(NSString *)name {
    [_name autorelease];
    _name = [name copy];
}


- (id)delegate {
    return _delegate; }
    
- (void)setDelegate:(id)del {
    _delegate = del; }
    
- (void)_setEnclosingViewController:(id)viewCtrl {
    _enclosingVC = viewCtrl;
}
    
- (id)enclosingViewController {
    return _enclosingVC; }
    
- (id)findEnclosingViewControllerWithNameContainingSubstring:(NSString *)substr
{
    if ( !_enclosingVC) return nil;
    NSString *encName = [_enclosingVC name];
    
    NSRange range = (encName) ? [encName rangeOfString:substr] : NSMakeRange(NSNotFound, 0);
    if (range.location != NSNotFound) {
        return _enclosingVC;
    } else {
        return [_enclosingVC findEnclosingViewControllerWithNameContainingSubstring:substr];
    }
}
    

- (id)nativeView {
    LQInvalidAbstractInvocation();
    return nil;
}
    
- (void)setNativeView:(id)view {
    LQInvalidAbstractInvocation();
}


- (id)nativeStyleAttributes {
    return nil;
}

@end
