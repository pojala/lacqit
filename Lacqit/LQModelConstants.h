//
//  LQFileConstants.h
//  Lacqit
//
//  Created by Pauli Ojala on 20.8.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#import "LQBaseFrameworkHeader.h"
#import "LacqitExport.h"

LACQIT_EXPORT_VAR NSString * const kLQErrorDomain;

// standard metadata keys
LACQIT_EXPORT_VAR NSString * const kLQMetadata_Name;
LACQIT_EXPORT_VAR NSString * const kLQMetadata_SystemTypeName;
LACQIT_EXPORT_VAR NSString * const kLQMetadata_Description;
LACQIT_EXPORT_VAR NSString * const kLQMetadata_Author;
LACQIT_EXPORT_VAR NSString * const kLQMetadata_Version_Int;
LACQIT_EXPORT_VAR NSString * const kLQMetadata_Version_Str;
LACQIT_EXPORT_VAR NSString * const kLQMetadata_Namespace;

// standard plugin category names
LACQIT_EXPORT_VAR NSString * const kLQPluginCategory_Composite;
LACQIT_EXPORT_VAR NSString * const kLQPluginCategory_Distortion;
LACQIT_EXPORT_VAR NSString * const kLQPluginCategory_Generator;
LACQIT_EXPORT_VAR NSString * const kLQPluginCategory_Motion;
LACQIT_EXPORT_VAR NSString * const kLQPluginCategory_Space;
LACQIT_EXPORT_VAR NSString * const kLQPluginCategory_Stylize;
LACQIT_EXPORT_VAR NSString * const kLQPluginCategory_Time;
LACQIT_EXPORT_VAR NSString * const kLQPluginCategory_Video;

// standard file extensions
LACQIT_EXPORT_VAR NSString * const kLQFileExt_JSON_ShapesArray;
LACQIT_EXPORT_VAR NSString * const kLQFileExt_JSON_Fcurve;

// script-related notifs and keys (moved from LQStreamPatch.h)
LACQIT_EXPORT_VAR NSString * const kLQPatchJSTraceNotification;
LACQIT_EXPORT_VAR NSString * const kLQPatchTraceStringKey;
LACQIT_EXPORT_VAR NSString * const kLQPatchTraceIsErrorKey;

// used for the eval contents overlay in CL2
LACQIT_EXPORT_VAR NSString * const kLQPatchEvalLogNotification;

