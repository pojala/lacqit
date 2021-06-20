/*
 *  LQGCommonUIControllerSubtypeMethods.h
 *  Lacqit
 *
 *  Created by Pauli Ojala on 15.11.2008.
 *  Copyright 2008 Lacquer oy/ltd. All rights reserved.
 *
 */

/*
This header contains the methods that are implemented by the LQGCommonUIController subclasses
both on Cocoa and Lagoon, so that callers don't have to include a platform-specific class header
*/

#import "LQGCommonUIController.h"


@interface LQGCommonUIController (SliderAndFieldMethods)

- (double)doubleValue;
- (void)setDoubleValue:(double)d;

- (void)setSliderMin:(double)smin max:(double)smax;

- (void)setEnabled:(BOOL)f;

- (void)setLabelFont:(NSFont *)font;

@end

@interface LQGCommonUIController (NumberPairMethods)

- (double)xValue;
- (double)yValue;
- (void)setXValue:(double)d;
- (void)setYValue:(double)d;

@end

@interface LQGCommonUIController (ColorPickerMethods)

- (NSString *)label;
- (void)setLabel:(NSString *)label;

- (LXRGBA)rgbaValue;
- (void)setRGBAValue:(LXRGBA)rgba;

@end

@interface LQGCommonUIController (CheckboxMethods)

- (BOOL)boolValue;
- (void)setBoolValue:(BOOL)f;

@end


@interface LQGCommonUIController (SelectorButtonMethods)

- (void)setItemTitles:(NSArray *)items;
- (NSArray *)itemTitles;

- (void)setIndexOfSelectedItem:(LXInteger)index;
- (LXInteger)indexOfSelectedItem;

- (NSString *)titleOfSelectedItem;

@end

@interface LQGCommonUIController (ButtonWithDetailMethods)

- (NSString *)detailString;
- (void)setDetailString:(NSString *)str;

- (NSString *)buttonLabel;
- (void)setButtonLabel:(NSString *)str;

@end

@interface LQGCommonUIController (TextBoxMethods)

- (NSString *)stringValue;
- (void)setStringValue:(NSString *)str;

- (BOOL)isMultiline;
- (void)setMultiline:(BOOL)f;

- (BOOL)hasSaveAndRevert;
- (void)setHasSaveAndRevert:(BOOL)f;

- (BOOL)isEditable;
- (void)setEditable:(BOOL)f;

- (BOOL)isSecure;
- (void)setSecure:(BOOL)f;

- (void)attachScriptEditorWithClass:(Class)cls interpreter:(id)interpreter;

@end

@interface LQGCommonUIController (ContainerMethods)

- (void)setContainedViewController:(LQGCommonUIController *)viewCtrl;
- (LQGCommonUIController *)containedViewController;

@end

@interface LQGCommonUIController (TableMethods)

- (LXInteger)numberOfVisibleRows;
- (void)setNumberOfVisibleRows:(LXInteger)n;

- (BOOL)allowsRowReordering;
- (void)setAllowsRowReordering:(BOOL)f;

- (NSArray *)tableData;    
- (void)setTableData:(NSArray *)data;

- (NSArray *)columnDescriptions;
- (void)setColumnDescriptions:(NSArray *)colDicts;

- (NSArray *)buttonDescriptions;
- (void)setButtonDescriptions:(NSArray *)buttonDicts;

- (id)detailViewController;
- (void)setDetailViewController:(LQGViewController *)viewCtrl;

- (void)clearSelection;

- (NSIndexSet *)selectedIndexes;

@end

@interface LQGCommonUIController (CanvasMethods)

- (void)setCanvasSize:(NSSize)size;
- (NSSize)canvasSize;

@end
