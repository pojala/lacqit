//
//  LQGTableController_cocoa.h
//  Lacqit
//
//  Created by Pauli Ojala on 6.7.2009.
//  Copyright 2009 Lacquer oy/ltd. All rights reserved.
//

#import "LQGCommonUIController.h"


@interface LQGTableController_cocoa : LQGCommonUIController {

    NSTableView *_tableView;
    NSTextField *_labelField;
        
    NSString *_label;
    LXInteger _numVisibleRows;
    BOOL _allowsReordering;

    NSArray *_columnDicts;
    NSArray *_buttonDicts;
    
    NSMutableArray *_tableData;
    
    id _detailViewCtrl;
}

- (NSString *)label;
- (void)setLabel:(NSString *)label;

- (LXInteger)numberOfVisibleRows;
- (void)setNumberOfVisibleRows:(LXInteger)n;

- (BOOL)allowsRowReordering;
- (void)setAllowsRowReordering:(BOOL)f;

- (NSArray *)columnDescriptions;
- (void)setColumnDescriptions:(NSArray *)colDicts;

// tableData is copied, and when copying array entries are recreated as dicts as necessary
// (e.g. if they are JavaScript object wrappers or something else that looks like a dict but isn't)
- (NSArray *)tableData;
- (void)setTableData:(NSArray *)tableData;

- (NSArray *)buttonDescriptions;
- (void)setButtonDescriptions:(NSArray *)buttonDicts;

- (id)detailViewController;
- (void)setDetailViewController:(LQGViewController *)viewCtrl;

@end
