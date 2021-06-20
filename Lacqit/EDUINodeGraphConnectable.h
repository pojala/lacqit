/*
 *  EDUINodeGraphConnectable.h
 *  Edo
 *
 *  Created by Pauli Ojala on Sun Nov 23 2003.
 *
 */

#import "LQUIFrameworkHeader.h"


@protocol EDUINodeGraphConnectable

- (NSString *)name;
- (LXUInteger)nodeType;

- (BOOL)acceptsMultipleOutputConnections;

- (LXInteger)outputCount;
- (NSString *)nameOfOutputAtIndex:(LXInteger)index;
- (LXUInteger)typeOfOutputAtIndex:(LXInteger)index;

- (LXInteger)inputCount;
- (NSString *)nameOfInputAtIndex:(LXInteger)index;
- (LXUInteger)typeOfInputAtIndex:(LXInteger)index;
- (id)connectedNodeForInputAtIndex:(LXInteger)index outputIndexPtr:(LXInteger *)outpIndex;
- (void)disconnectInputAtIndex:(LXInteger)index;
- (void)connectInputAtIndex:(LXInteger)inpIndex toNode:(id)node outputIndex:(LXInteger)outpIndex;

- (LXInteger)parameterCount;

- (BOOL)hasUpstreamConnectionToNode:(id)node;

@end


@protocol EDUINodeGraphConnectableAppearanceMethods

- (NSPoint)centerPoint;
- (void)setCenterPoint:(NSPoint)point;

- (LXFloat)scaleFactor;
- (void)setScaleFactor:(LXFloat)scale;

// the appearance flags are set by the comp UI for misc. persistent state such as whether
// node parameters are collapsed or not
- (LXUInteger)nodeAppearanceFlags;
- (void)setNodeAppearanceFlags:(LXUInteger)flags;

- (BOOL)useBypassedAppearance;

- (BOOL)useCustomConnectorColorsForInputs;
- (BOOL)useCustomConnectorColorsForOutputs;
- (BOOL)useCustomConnectorColorsForParameters;
- (NSColor *)customConnectorColorForInputAtIndex:(LXInteger)index;
- (NSColor *)customConnectorColorForOutputAtIndex:(LXInteger)index;
- (NSColor *)customConnectorColorForParameterAtIndex:(LXInteger)index;

- (BOOL)useWhiteLabelTextWhenSelected:(BOOL)flag;

- (void)setUserConnectorColor:(NSColor *)color forInputAtIndex:(LXInteger)index;
- (void)setUserConnectorColor:(NSColor *)color forOutputAtIndex:(LXInteger)index;

- (NSString *)connectorNoteForInputAtIndex:(LXInteger)index positionPtr:(LXFloat *)pPos;
- (NSString *)connectorNoteForParameterInputAtIndex:(LXInteger)index positionPtr:(LXFloat *)pPos;
- (void)setConnectorNote:(NSString *)note forInputAtIndex:(LXInteger)index;
- (void)setConnectorNote:(NSString *)note forParameterInputAtIndex:(LXInteger)index;
- (void)setConnectorNotePosition:(LXFloat)pos forInputAtIndex:(LXInteger)index;
- (void)setConnectorNotePosition:(LXFloat)pos forParameterInputAtIndex:(LXInteger)index;

@end


@protocol EDUINodeGraphConnectableParameterMethods

- (NSString *)nameOfParameterAtIndex:(LXInteger)index;

- (BOOL)parameterHasInputAtIndex:(LXInteger)index;
- (LXUInteger)typeOfParameterInputAtIndex:(LXInteger)index;

- (id)connectedNodeForParameterAtIndex:(LXInteger)index outputIndexPtr:(LXInteger *)outpIndex;
- (void)disconnectParameterAtIndex:(LXInteger)index;
- (void)connectParameterAtIndex:(LXInteger)inpIndex toNode:(id)node outputIndex:(LXInteger)outpIndex;

@end
