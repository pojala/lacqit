//
//  LQStreamSource.h
//  Lacqit
//
//  Created by Pauli Ojala on 4.1.2009.
//  Copyright 2009 Lacquer oy/ltd. All rights reserved.
//

#import "LQBufferingStreamNode.h"
#import "LQVideoTypes.h"


enum {
    kLQFrameAccessHint_Playback = 0,
    kLQFrameAccessHint_Sequential,
    kLQFrameAccessHint_Random
};


// stream node attributes (access with LQStreamNode's -attributeForKey: accessors)

LACQIT_EXPORT_VAR NSString * const kLQSourceAttribute_VideoLoops;           // NSNumber / bool
LACQIT_EXPORT_VAR NSString * const kLQSourceAttribute_Deinterlace;          // NSNumber / bool
LACQIT_EXPORT_VAR NSString * const kLQSourceAttribute_ImageCropSettings;    // NSDictionary with contents of LQBitmapCrop struct
LACQIT_EXPORT_VAR NSString * const kLQSourceAttribute_SequenceFrameRate;    // NSNumber / double
LACQIT_EXPORT_VAR NSString * const kLQSourceAttribute_RendersInNativeColorspace;  // NSNumber / bool (this can be used to indicate "raw YUV" output)
LACQIT_EXPORT_VAR NSString * const kLQSourceAttribute_EnableAudio;          // NSNumber / bool

LACQIT_EXPORT NSDictionary *LQBitmapCropToDictionary(LQBitmapCrop crop);
LACQIT_EXPORT LQBitmapCrop LQBitmapCropFromDictionary(NSDictionary *dict);



@interface LQStreamSource : LQBufferingStreamNode {

    double _streamStartRefTime;   // available when the stream is playing
}

- (void)startPlaybackOnThread:(id)threadDict;

- (BOOL)isCapableOfSingleFileCapture;
- (BOOL)isCapableOfImageSequenceCapture;

@end



@interface LQStreamSource (OptionalCaptureMethods)

- (BOOL)enableSingleFileCaptureWithPath:(NSString *)path error:(NSError **)error;
- (BOOL)singleFileCaptureIsEnabled;
- (void)disableSingleFileCapture;

// formatID must be the image UTI, e.g. "public.dpx" or "public.jpeg"
- (BOOL)enableImageSequenceCaptureWithPath:(NSString *)path formatID:(NSString *)formatUTI properties:(NSDictionary *)imageProps error:(NSError **)error;
- (BOOL)imageSequenceCaptureIsEnabled;
- (void)disableImageSequenceCapture;

- (NSString *)captureDeviceName;

@end