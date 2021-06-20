//
//  LQEditDelegatingView.m
//  Lacqit
//
//  Created by Pauli Ojala on 14.2.2010.
//  Copyright 2010 Lacquer oy/ltd. All rights reserved.
//

#import "LQEditDelegatingView.h"


@implementation LQEditDelegatingView

- (void)setDelegate:(id)del {
    _delegate = del; }
    
- (id)delegate {
    return _delegate; }



- (IBAction)selectAll:(id)sender
{
    if ([[self delegate] respondsToSelector:@selector(selectAll:)])
        [[self delegate] selectAll:sender];
}

- (IBAction)cut:(id)sender
{
    if ([[self delegate] respondsToSelector:@selector(cut:)])
        [[self delegate] cut:sender];
}

- (IBAction)copy:(id)sender
{
    if ([[self delegate] respondsToSelector:@selector(copy:)])
        [[self delegate] copy:sender];
}

- (IBAction)paste:(id)sender
{
    if ([[self delegate] respondsToSelector:@selector(paste:)])
        [[self delegate] paste:sender];
}

- (IBAction)undo:(id)sender
{
    if ([[self delegate] respondsToSelector:@selector(undo:)])
        [[self delegate] undo:sender];
}

- (IBAction)redo:(id)sender
{
    if ([[self delegate] respondsToSelector:@selector(redo:)])
        [[self delegate] redo:sender];
}


@end
