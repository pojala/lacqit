/*
 *  LMODrawing.h
 *  Lacqit
 *
 *  Created by Pauli Ojala on 5.5.2008.
 *  Copyright 2008 Lacquer oy/ltd. All rights reserved.
 *
 */


@protocol LQLacefxPreviewDrawing

- (void)drawPreviewInSurface:(LXSurfaceRef)surface bounds:(LXRect)bounds context:(NSDictionary *)context;

- (void)drawOverlayWithID:(NSString *)overlayID
                inSurface:(LXSurfaceRef)surface bounds:(LXRect)bounds context:(NSDictionary *)context;

- (double)previewAspectRatioInContext:(NSDictionary *)context;

@end
