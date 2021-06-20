//
//  LQGTableController_cocoa.m
//  Lacqit
//
//  Created by Pauli Ojala on 6.7.2009.
//  Copyright 2009 Lacquer oy/ltd. All rights reserved.
//

#import "LQGTableController_cocoa.h"
#import "LQGViewController_priv.h"
#import "LQFlippedView.h"
#import "LQJSUtils.h"



static NSString * const kLQGTablePrivateDragDataType = @"LQGTablePrivateDragDataType";



@implementation LQGTableController_cocoa

- (id)init
{
    self = [super initWithResourceName:nil bundle:[NSBundle bundleForClass:[self class]]];
    
    return self;
}

- (void)dealloc
{
    [_label release];
    [_columnDicts release];
    [_buttonDicts release];
    [_tableData release];
    
    [[_detailViewCtrl nativeView] removeFromSuperview];
    [_detailViewCtrl release];
    
    [super dealloc];
}

/*- (void)willBeRemovedFromView
{
    [[_detailViewCtrl nativeView] removeFromSuperview];
    NSLog(@"%s: %@", __func__, self);
}*/

- (NSString *)label {
    return (_label) ? _label : [_labelField stringValue];
}

- (void)setLabel:(NSString *)label {
    [_label release];
    _label = [label copy];
    
    [_labelField setStringValue:(_label) ? _label : @""];
}

- (NSArray *)columnDescriptions {
    return _columnDicts; }
    
- (void)setColumnDescriptions:(NSArray *)colDicts {
    [_columnDicts release];
    _columnDicts = [colDicts retain];
}

- (NSArray *)buttonDescriptions {
    return _buttonDicts; }
    
- (void)setButtonDescriptions:(NSArray *)buttonIds {
    [_buttonDicts release];
    _buttonDicts = [[NSMutableArray alloc] initWithArray:buttonIds];
    
    LXInteger count = [_buttonDicts count];
    LXInteger i;
    for (i = 0; i < count; i++) {
        id dict = [_buttonDicts objectAtIndex:i];
        NSString *templName = [dict objectForKey:kLQUIKey_TemplateName];
        NSMutableDictionary *newDict = nil;
        
        // the button needs an identifier, so figure out one
        if ( ![dict objectForKey:kLQUIKey_Identifier]) {
            newDict = ([dict isKindOfClass:[NSDictionary class]]) ? [NSMutableDictionary dictionaryWithDictionary:dict] : [NSMutableDictionary dictionary];
            
            NSString *newID = (templName) ? templName : [NSString stringWithFormat:@"tableButton_%ld", (long)i+1];
            
            [newDict setObject:newID forKey:kLQUIKey_Identifier];
        }
        if (newDict) {
            [(NSMutableArray *)_buttonDicts replaceObjectAtIndex:i withObject:newDict];
        }
    }
}


- (LXInteger)numberOfVisibleRows {
    return _numVisibleRows; }
    
- (void)setNumberOfVisibleRows:(LXInteger)n {
    _numVisibleRows = n; }

- (BOOL)allowsRowReordering {
    return _allowsReordering; }
    
- (void)setAllowsRowReordering:(BOOL)f {
    _allowsReordering = f; }


- (NSArray *)tableData {
    return _tableData; }
    
    
- (void)_updateTableView {
    [_tableView reloadData];
    [_tableView setEnabled:([_tableData count] > 0)];
    [_tableView setNeedsDisplay:YES];
    ///NSLog(@"%s (%@): tableview is %@", __func__, self, _tableView);
}

- (void)setTableData:(NSArray *)data
{
    [_tableData release];
    _tableData = [LQArrayByConvertingKeyedItemsToDictionariesInArray(data) mutableCopy];

    [self _updateTableView];
}


- (void)clearSelection
{
    [_tableView deselectAll:nil];
}

- (NSIndexSet *)selectedIndexes {
    return [_tableView selectedRowIndexes]; }


- (void)tableButtonAction:(id)sender
{
    LXInteger buttonIndex = [sender tag] - 1000;
    NSAssert(buttonIndex >= 0 && buttonIndex < [_buttonDicts count], @"invalid button tag");

    if ([_delegate respondsToSelector:@selector(actionInViewController:context:info:)]) {
        NSDictionary *buttonDict = [_buttonDicts objectAtIndex:buttonIndex];        
        NSString *tname = [buttonDict objectForKey:kLQUIKey_TemplateName];
        
        if ([tname isEqualToString:kLQGTemplateName_AddButton]) {
            [_delegate actionInViewController:self context:kLQGActionContext_AddButtonClicked info:buttonDict];
        }
        else if ([tname isEqualToString:kLQGTemplateName_DeleteButton]) {
            [_delegate actionInViewController:self context:kLQGActionContext_DeleteButtonClicked info:buttonDict];
        }
        else {
            [_delegate actionInViewController:self context:kLQGActionContext_ButtonClicked info:buttonDict];
        }
    }
}


- (id)detailViewController {
    return _detailViewCtrl; }
    
- (void)setDetailViewController:(LQGViewController *)viewCtrl {
    [_detailViewCtrl autorelease];
    _detailViewCtrl = [viewCtrl retain];
}

- (void)loadView
{
    if (_tableView) return;
    
    id val = nil;
    
    double defaultW = 300;
    double x =       ((val = [_styleDict objectForKey:kLQGStyle_PaddingLeft])) ? [val doubleValue] : 8.0;
    double rMargin = ((val = [_styleDict objectForKey:kLQGStyle_PaddingRight])) ? [val doubleValue] : 8.0;
    double y =       ((val = [_styleDict objectForKey:kLQGStyle_MarginTop])) ? [val doubleValue] : 8.0;
    double w = round(defaultW - x - rMargin);

    double rowHeight = 13;
    LXInteger numRows = (_numVisibleRows > 0 && _numVisibleRows < 1000) ? _numVisibleRows : 9;

    const double scrollbarW = 16.0;  // HARDCODED
    const double headerH = 16.0;  // HARDCODED
    
    BOOL hasLabel = [[self label] length] > 0;
    BOOL tableHasHeader = ([_columnDicts count] > 0);
    BOOL hasButtonRow = ([_buttonDicts count] > 0);
    ///NSLog(@"tableview button count: %i", [_buttonDicts count]);
    
    NSView *detailView = nil;
    double detailViewH = 0;
    if (_detailViewCtrl) {
        [_detailViewCtrl loadView];
        
        detailView = (NSView *)[_detailViewCtrl nativeView];
        detailViewH = (detailView) ? ([detailView frame].size.height + 8) : 0.0;
        
        [_detailViewCtrl _setEnclosingViewController:self];
    }

    NSRect viewRect = NSMakeRect(0, 0, defaultW, (numRows * rowHeight + headerH + 4) + (hasLabel ? 20 : 6) + (hasButtonRow ? 26 : 6) + detailViewH);

    [_view autorelease];
    _view = [[LQFlippedView alloc] initWithFrame:viewRect];
    [_view setAutoresizingMask:NSViewWidthSizable];
    
    ///static LXInteger s_loadCount = 100;
    ///[(LQFlippedView *)_view setTag:s_loadCount++];
    
    ///NSLog(@"%s: view size is %@ - autoresize mask is %i", __func__, NSStringFromRect([_view frame]), [_view autoresizingMask]);

    
    if (hasLabel) {
        NSSize labelSize = NSMakeSize(defaultW - x*2.0, 12);
        NSAttributedString *attrLabel = [[[NSAttributedString alloc] initWithString:[self label] attributes:[self labelAttributes]] autorelease];
    
        NSTextField *nameField = [[NSTextField alloc] initWithFrame:NSMakeRect(x,  y - 1.0,  //viewRect.size.height - labelSize.height - (y-1.0),
                                                            labelSize.width+4.0,  labelSize.height)];
        [nameField setEditable:NO];
        [nameField setStringValue:(NSString *)attrLabel];
        [nameField setAlignment:NSLeftTextAlignment];
        [nameField setBezeled:NO];
        [nameField setDrawsBackground:NO];
        [nameField setAutoresizingMask:(NSViewWidthSizable | NSViewMaxYMargin)];
        
        [_view addSubview:[nameField autorelease]];

        _labelField = nameField;
        y += labelSize.height + 4;
    } else {
        _labelField = nil;
    }
    
    if (hasButtonRow) {
        LXInteger buttonCount = [_buttonDicts count];
        LXInteger i;
        double buttonX = x + 3;
        double buttonY = viewRect.size.height - detailViewH - 20;
        for (i = 0; i < buttonCount; i++) {
            id buttonDict = [_buttonDicts objectAtIndex:i];
            NSString *tname = [buttonDict objectForKey:kLQUIKey_TemplateName];
            NSButton *button = nil;
            double buttonW = 0;
            
            ///NSLog(@"... %i: %@", i, buttonDict);
            
            if ([tname isEqualToString:kLQGTemplateName_AddButton] || [tname isEqualToString:kLQGTemplateName_DeleteButton]) {
                buttonW = 18;
                button = [[NSButton alloc] initWithFrame:NSMakeRect(buttonX, buttonY, buttonW, 18)];
                
                BOOL isAdd = ([tname isEqualToString:kLQGTemplateName_AddButton]);
                NSImage *image = [NSImage imageNamed:(isAdd) ? @"NSAddTemplate" : @"NSRemoveTemplate"];  // templates available in OS X 10.5+
                if (image) {
                    [button setImage:image];
                    [button setTitle:@""];
                } else {
                    [button setFont:[NSFont boldSystemFontOfSize:11]];
                    [button setTitle:(isAdd) ? @"+" : @"-"];
                }
                
                [button setBezelStyle:NSTexturedSquareBezelStyle];
                [[button cell] setControlSize:NSMiniControlSize];
            }
            else {
                // not a template button
                NSString *label = [buttonDict objectForKey:kLQUIKey_Label];
                if ([label length] < 1)
                    label = [buttonDict objectForKey:kLQUIKey_Identifier];
                
                const double fontSize = 9.0;
                NSFont *font = [NSFont boldSystemFontOfSize:fontSize];
                NSDictionary *titleAttrs = [NSDictionary dictionaryWithObjectsAndKeys:
                                                font, NSFontAttributeName,
                                                nil];
    
                NSSize titleSize = [label sizeWithAttributes:titleAttrs];
                
                buttonW = round(titleSize.width + 12);
                button = [[NSButton alloc] initWithFrame:NSMakeRect(buttonX, buttonY, buttonW, 18)];
                [button setFont:font];
                [button setTitle:label];
                
                [button setBezelStyle:NSTexturedSquareBezelStyle];
                [[button cell] setControlSize:NSMiniControlSize];
            }
            
            if (button) {
                [button setAutoresizingMask:(NSViewMaxXMargin | NSViewMinYMargin)];
                [button setTag:1000 + i];
                [button setTarget:self];
                [button setAction:@selector(tableButtonAction:)];
                
                [_view addSubview:[button autorelease]];
                buttonX += buttonW + 4;
            }
        }
    }
    
    if (detailView) {
        NSRect frame = [detailView frame];
        frame.origin.x = x + 5;
        frame.origin.y = viewRect.size.height - 4 - frame.size.height;
        frame.size.width = w - 10;

        [detailView setAutoresizingMask:(NSViewWidthSizable | NSViewMinYMargin)];        
        [detailView setFrame:frame];
        
        ///NSLog(@"detailview is %@ - frame is %@", detailView, NSStringFromRect(frame));
        
        [_view addSubview:detailView];
    }
    
    
    NSRect tableBoxRect = NSMakeRect(x, y, w, numRows * rowHeight + headerH + 4);
    NSFont *tableFont = [NSFont systemFontOfSize:kLQUIDefaultFontSize];
    NSFont *headerFont = [NSFont boldSystemFontOfSize:kLQUIDefaultFontSize];
    const double tableW = tableBoxRect.size.width - scrollbarW;
    const double tableH = tableBoxRect.size.height - 4;
    
    NSTableView *table = [[NSTableView alloc] initWithFrame:NSMakeRect(x, y,  tableW, tableH)];
    [table setAutoresizingMask:(NSViewWidthSizable | NSViewMaxYMargin)];
    [table setRowHeight:rowHeight];
    [table setUsesAlternatingRowBackgroundColors:YES];
#if !defined(__COCOTRON__)
    [table setColumnAutoresizingStyle://NSTableViewSequentialColumnAutoresizingStyle];  
                                      NSTableViewUniformColumnAutoresizingStyle];
#endif
    [table setDataSource:(id)self];
    [table setDelegate:(id)self];
    
    if (_allowsReordering) {
        [table registerForDraggedTypes:[NSArray arrayWithObject:kLQGTablePrivateDragDataType]];
    }
    
    if ([_columnDicts count] < 1) {
        // create only the default column if columns have not been specified
        NSTableColumn *column = [[NSTableColumn alloc] initWithIdentifier:kLQMetadata_Name];
        [[column dataCell] setFont:tableFont];
        [[column headerCell] setFont:headerFont];
        [column setEditable:NO];
        [column setWidth:tableW];
#if !defined(__COCOTRON__)
        [column setResizingMask:NSTableColumnAutoresizingMask];
#endif
        [table addTableColumn:column];
    }
    else {
        // create columns from user-given definition
        NSEnumerator *colEnum = [_columnDicts objectEnumerator];
        NSDictionary *colInfo;
        LXInteger n = 0;
        BOOL showsHeaders = YES;
        
        while (colInfo = [colEnum nextObject]) {
            NSString *colID = [colInfo objectForKey:kLQGTableKey_ColumnIdentifier];
            NSString *colLabel = [colInfo objectForKey:kLQGTableKey_ColumnLabel];
            NSString *colType = [colInfo objectForKey:kLQGTableKey_ColumnContentType];
            NSString *colNumberFormat = [colInfo objectForKey:@"numberFormat"];
            id val;
            double colWidth = ((val = [colInfo objectForKey:@"fixedWidth"]) && [val respondsToSelector:@selector(doubleValue)]) ? [val doubleValue] : 0.0;
            
            NSString *templName;
            if ((templName = [colInfo objectForKey:kLQUIKey_TemplateName])) {
                if ([templName isEqualToString:@"autoGeneratedIndex"] || [templName isEqualToString:@"autoGeneratedIndexFromOne"]) {
                    colID = ([templName isEqualToString:@"autoGeneratedIndex"]) ? @"__autoGenIndex" : @"__autoGenIndexFromOne";
                    colLabel = @"Index";
                    colType = nil;
                    colWidth = 40;
                }
            }
        
            if ([colID length] > 0) {
                NSTableColumn *column = [[NSTableColumn alloc] initWithIdentifier:colID];
                [[column dataCell] setFont:tableFont];
                [[column headerCell] setFont:headerFont];
                
                if (n == 0) {
                    showsHeaders = ([colLabel length] > 0);
                    tableHasHeader = (tableHasHeader && showsHeaders);
                }
                if (showsHeaders) {
                    [[column headerCell] setStringValue:(colLabel) ? colLabel : @""];
                }
                
                [column setEditable:([colType isEqualToString:kLQGTableContentType_EditableText]) ? YES : NO];
                
                ///NSLog(@"creating column '%@': width %.1f, label '%@'", colID, colWidth, colLabel);
                
                if (colWidth > 0.0) {
                    [column setWidth:colWidth];
                    [column setMinWidth:colWidth];
#if !defined(__COCOTRON__)
                    [column setResizingMask:NSTableColumnNoResizing];
#endif
                } else {
                    if ([colLabel length] > 0) {
                        double labelW = ceil([colLabel sizeWithAttributes:[NSDictionary dictionaryWithObject:headerFont forKey:NSFontAttributeName]].width);
                        [column setWidth:labelW + 8];
                        [column setMinWidth:labelW + 8];
                    }
#if !defined(__COCOTRON__)
                    [column setResizingMask:NSTableColumnAutoresizingMask];
#endif
                }
                
                if (colNumberFormat) {
                    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
                    [formatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
                    
                    if ((val = [colNumberFormat valueForKey:@"numberStyle"]) && [val isEqualToString:@"percent"]) {
                        [formatter setNumberStyle:NSNumberFormatterPercentStyle];
                    } else {
                        [formatter setNumberStyle:NSNumberFormatterDecimalStyle];
                    }
                    
                    if ((val = [colNumberFormat valueForKey:@"minFractionDigits"]) && [val respondsToSelector:@selector(doubleValue)]) {
                        [formatter setMinimumFractionDigits:[val doubleValue]];
                    }
                    if ((val = [colNumberFormat valueForKey:@"maxFractionDigits"]) && [val respondsToSelector:@selector(doubleValue)]) {
                        [formatter setMaximumFractionDigits:[val doubleValue]];
                    }
                    if ((val = [colNumberFormat valueForKey:@"minIntegerDigits"]) && [val respondsToSelector:@selector(doubleValue)]) {
                        [formatter setMinimumIntegerDigits:[val doubleValue]];
                    }
                    if ((val = [colNumberFormat valueForKey:@"maxIntegerDigits"]) && [val respondsToSelector:@selector(doubleValue)]) {
                        [formatter setMaximumIntegerDigits:[val doubleValue]];
                    }
                    NSAssert([column dataCell], @"column has no data cell");
                    [[column dataCell] setFormatter:[formatter autorelease]];
                }
                
                [table addTableColumn:column];
                n++;
            }
        }
    }
    
    if ( !tableHasHeader)
        [table setHeaderView:nil];
        
    // place into scrollview
    NSView *packedView = table;
    const BOOL hasScroller = YES;
    if (hasScroller) {
        NSScrollView *scrollView = [[NSScrollView alloc] initWithFrame:tableBoxRect];
        [scrollView setHasHorizontalScroller:NO];
        [scrollView setHasVerticalScroller:YES];
        [scrollView setAutohidesScrollers:YES];
#if !defined(__COCOTRON__)
        [[scrollView verticalScroller] setControlSize:NSSmallControlSize];
#endif
        [table setFrame:NSMakeRect(0, 0, tableW, tableBoxRect.size.height)];
        [scrollView setDocumentView:[table autorelease]];
        [scrollView setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];  //(NSViewMaxYMargin | NSViewWidthSizable)];
        packedView = scrollView;
    }

    [table sizeToFit];

    [_view addSubview:[packedView autorelease]];
    
    _tableView = table;
    
    [self _updateTableView];
}


#pragma mark --- tableview data source ---

- (LXInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return [_tableData count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(LXInteger)rowIndex
{
    NSString *colID = [tableColumn identifier];
    
    if ([colID isEqualToString:@"__autoGenIndex"]) {
        return [NSNumber numberWithLong:rowIndex];
    }
    else if ([colID isEqualToString:@"__autoGenIndexFromOne"]) {
        return [NSNumber numberWithLong:rowIndex + 1];
    }
    
    id data = [_tableData objectAtIndex:rowIndex];
    id val = [data valueForKey:colID];
    
    // sanity checks to prevent containers from being written to the table
    LXInteger n = 0;
    while ([val isKindOfClass:[NSDictionary class]]) {
        val = [val objectForKey:[[val keyEnumerator] nextObject]];
        if (++n > 100) break;
    }
    n = 0;
    while ([val isKindOfClass:[NSArray class]] && [val count] > 0) {
        val = [val objectAtIndex:0];
        if (++n > 100) break;
    }

    if ([val isKindOfClass:[NSNumber class]] && [[[tableColumn dataCell] formatter] isKindOfClass:[NSNumberFormatter class]]) {
        return val;
    } else {
        return (val) ? [val description] : @"";
    }
}

- (void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(LXInteger)rowIndex
{
    NSString *colID = [tableColumn identifier];
    id data = [_tableData objectAtIndex:rowIndex];
    NSAssert2([data isKindOfClass:[NSDictionary class]], @"invalid data object (%@, row %ld)", [data class], rowIndex);
    
    id newData = [NSMutableDictionary dictionaryWithDictionary:(NSDictionary *)data];
    [newData setObject:object forKey:colID];
    
    [_tableData replaceObjectAtIndex:rowIndex withObject:newData];
    
    if ([_delegate respondsToSelector:@selector(valuesDidChangeInViewController:context:info:)]) {
        NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:
                                                colID, kLQGTableKey_ColumnIdentifier,
                                                [NSNumber numberWithLong:rowIndex], kLQGTableKey_RowIndex,
                                                object, @"newValue",
                                                nil];
                                                
        [_delegate valuesDidChangeInViewController:self context:@"Table::didModifyRow" info:info];
    }
    else if ([_delegate respondsToSelector:@selector(valuesDidChangeInViewController:)]) {
        [_delegate valuesDidChangeInViewController:self];
    }
        
    [self _updateTableView];
}


// drag&drop start
- (BOOL)tableView:(NSTableView *)tv writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard *)pboard
{
    if ( !_allowsReordering) return NO;

    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:rowIndexes];
    [pboard declareTypes:[NSArray arrayWithObject:kLQGTablePrivateDragDataType] owner:self];
    [pboard setData:data forType:kLQGTablePrivateDragDataType];
    return YES;
}

// drag&drop validation
- (NSDragOperation)tableView:(NSTableView *)tv validateDrop:(id <NSDraggingInfo>)info proposedRow:(LXInteger)row proposedDropOperation:(NSTableViewDropOperation)op
{
    return NSDragOperationEvery;
}

// drag&drop end
- (BOOL)tableView:(NSTableView *)tv acceptDrop:(id <NSDraggingInfo>)info row:(LXInteger)dropRow dropOperation:(NSTableViewDropOperation)operation
{
    NSPasteboard *pboard = [info draggingPasteboard];
    NSData *rowData = [pboard dataForType:kLQGTablePrivateDragDataType];
    if ( !rowData) return NO;
    
    NSIndexSet *rowIndexes = [NSKeyedUnarchiver unarchiveObjectWithData:rowData];
    LXInteger dragRow = [rowIndexes firstIndex];
 
    if (dragRow < 0 || dragRow > [_tableData count]) {
        NSLog(@"** %s: invalid drag row (%ld)", __func__, dragRow);
        return NO;
    }
    
    id rowObj = [[_tableData objectAtIndex:dragRow] retain];
    [_tableData removeObjectAtIndex:dragRow];
    
    LXInteger insertionRow = dropRow;
    if (insertionRow > dragRow) insertionRow--;

    if (insertionRow >= [_tableData count]) {
        [_tableData addObject:rowObj];
    } else {
        [_tableData insertObject:rowObj atIndex:insertionRow];
    }
    
    [rowObj release];
    
    if ([_delegate respondsToSelector:@selector(valuesDidChangeInViewController:context:info:)]) {
        NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:
                                                [NSArray arrayWithObject:[NSNumber numberWithLong:dragRow]], kLQGTableKey_SourceRowIndexes,
                                                [NSArray arrayWithObject:[NSNumber numberWithLong:dropRow]], kLQGTableKey_DestinationRowIndexes,
                                                [NSArray arrayWithObject:rowObj], kLQGTableKey_MovedObjects,
                                                nil];
                                                
        [_delegate valuesDidChangeInViewController:self context:@"Table::didReorderRows" info:info];
    }
    else if ([_delegate respondsToSelector:@selector(valuesDidChangeInViewController:)]) {
        [_delegate valuesDidChangeInViewController:self];
    }
    
    return YES;
}



#pragma mark --- tableview delegate & actions ---

- (void)tableViewSelectionDidChange:(NSNotification *)notif
{
    LXInteger rowIndex = [_tableView selectedRow];

    if ([_delegate respondsToSelector:@selector(actionInViewController:context:info:)]) {
        NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:
                                                [NSNumber numberWithLong:rowIndex], kLQGTableKey_RowIndex,
                                                nil];
    
        [_delegate actionInViewController:self context:kLQGActionContext_SelectionChanged info:info];
    }    
}

@end
