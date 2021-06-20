//
//  LaBCompUIController.m
//  Lacqit
//
//  Created by Pauli Ojala on 1.9.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#import "LaBCompUIController.h"
#import <Lacqit/LACMutablePatch.h>
#import <Lacqit/LACParser.h>
#import <Lacqit/EDUICompNodeView.h>
#import <Lacqit/EDUINSImageAdditions.h>

#import <Lacqit/LQLacNodeView.h>
#import <Lacqit/LQLacCompConnector.h>



@implementation LaBCompUIController

- (void)awakeFromNib
{
    [NSImage addBundleForImageSearch:[NSBundle mainBundle]];

    NSLog(@"%s -- compview: %@ -- compviewctrl: %@", __func__, _compView, _compViewController);
    
    NSLog(@"tableview datasource: %@", [_nodesTableView dataSource]);
    
    [_nodesTableView reloadData];
    
    
    // test patch
    NSString *testStr = @"   Func 'main' (bindInAs: iterCount, bindOutAt: theLoop) { \n"
                         "        Open 'i' (centerPoint: [100, 350]) \n"
                         "        Sum 'addToOne' <- [i, i] (centerPoint: [220, 300]) \n"
                         "        Sum 'add' <- [addToOne, addToOne] (centerPoint: [360, 250]) \n"
                         "      LoopCloser 'theLoop' <- [add, iterCount] (isCollecting: false, centerPoint: [500, 180]) \n"

                         "      Number 'yksi' (doubleValue: 1.0, centerPoint: [280, 380]) \n"
                         "      addToOne <- [i, yksi] \n"
                         "   } \n";

    LACParser *parser = [LACParser alloc];
    NSArray *parsed = [parser parseLacString:testStr];
    [parser release];
    
    NSAssert1([parsed count] > 0, @"test patch parse failed (object is: %@)", parsed);
    
    LACPatch *patch = [parsed objectAtIndex:0];
    
    
    [_compView setBackgroundColor://[NSColor colorWithDeviceRed:0.45 green:0.43 blue:0.465 alpha:1.0]
                                  [NSColor colorWithDeviceRed:0.95 green:0.97 blue:0.99 alpha:1.0]
                ];
    
    [_compViewController setNodeGraph:patch];
    
    NSArray *nodeViews = [_compViewController nodeViews];
    NSEnumerator *viewEnum = [nodeViews objectEnumerator];
    EDUICompNodeView *nview;
    while (nview = [viewEnum nextObject]) {
        [nview setUsesHorizontalLayout:YES];
    }
}


#pragma mark --- CompUI delegate ---

- (void)connectionsWereModifiedForNodes:(NSSet *)nodes
{

}

- (void)compViewSelectionWasModified
{

}


#pragma mark --- CompUI view customisation ---

- (Class)nodeViewClassForNode:(id)node
{
    return [LQLacNodeView class];
}

- (NSColor *)unselectedColorForNode:(id)node
{
    return [NSColor colorWithDeviceRed:0.75 green:0.92 blue:0.89 alpha:1.0];
}

- (NSColor *)selectedColorForNode:(id)node
{
    return [NSColor colorWithDeviceRed:0.3 green:0.3 blue:0.42 alpha:1.0];
}


- (NSColor *)borderLineColorForNode:(id)node
{
    static NSColor *defColor = nil;
    if (!defColor)
        defColor = [[NSColor colorWithDeviceRed:0.0 green:0.1 blue:0.3 alpha:0.5] retain];

    //return [NSColor colorWithDeviceRed:1.0 green:1.0 blue:1.0 alpha:1.0];

    //return [NSColor colorWithDeviceRed:0.0 green:0.05 blue:0.35 alpha:0.9];

    return defColor;
}


- (id)customConnectorForConnectionFromOutputView:(EDUICompInputView *)outpView toInputView:(EDUICompInputView *)inpView
{
    LQLacCompConnector *conn = [[[LQLacCompConnector alloc] init] autorelease];
    
    [conn connectFrom:outpView to:inpView];

    return conn;
}


#pragma mark --- tableview data source ---

- (LXInteger)numberOfRowsInTableView:(NSTableView *)aTableView {
    return 8;
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(LXInteger)rowIndex
{
    id colId = [tableColumn identifier];

	if ([colId isEqualToString:@"className"]) {
		return [NSString stringWithFormat:@"Slider %i", rowIndex+1];
	}
	else
        return nil;
}

- (void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(LXInteger)rowIndex
{
    id colId = [tableColumn identifier];
    
    if ([colId isEqualToString:@"exportName"]) {
        //NSLog(@"exportname: %@", object);
	}
}


@end
