//
//  LQJSON.h
//  Lacqit
//
//  Created by Pauli Ojala on 24.1.2009.
//  Copyright 2009 Lacquer oy/ltd. All rights reserved.
//

/*
-- LICENSING INFO --
Based on SBJSON (modified BSD license),
modified by P.O. to match project code style (ivar names, etc.)
and to add 10.4 compatibility (original code used Leopard-only ObjC 2.0 features).

SBJSON license follows:
--
Copyright (C) 2008 Stig Brautaset. All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

  Redistributions of source code must retain the above copyright notice, this
  list of conditions and the following disclaimer.

  Redistributions in binary form must reproduce the above copyright notice,
  this list of conditions and the following disclaimer in the documentation
  and/or other materials provided with the distribution.

  Neither the name of the author nor the names of its contributors may be used
  to endorse or promote products derived from this software without specific
  prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/


#import "LQBaseFrameworkHeader.h"
#import "LacqitExport.h"
#import "LQJSONNSAdditions.h"

LACQIT_EXPORT_VAR NSString * const kLQJSONErrorDomain;


/**
@brief A strict JSON parser and generator

This is the parser and generator underlying the categories added to
NSString and various other objects.

Objective-C types are mapped to JSON types and back in the following way:

@li NSNull -> Null -> NSNull
@li NSString -> String -> NSMutableString
@li NSArray -> Array -> NSMutableArray
@li NSDictionary -> Object -> NSMutableDictionary
@li NSNumber (-initWithBool:) -> Boolean -> NSNumber -initWithBool:
@li NSNumber -> Number -> NSDecimalNumber
// --- 2009.09.26 -- decimal behaviour removed for Lacqit version, now uses plain doubles ---

In JSON the keys of an object must be strings. NSDictionary keys need
not be, but attempting to convert an NSDictionary with non-string keys
into JSON will throw an exception.

NSNumber instances created with the +numberWithBool: method are
converted into the JSON boolean "true" and "false" values, and vice
versa. Any other NSNumber instances are converted to a JSON number the
way you would expect. JSON numbers turn into NSDecimalNumber instances,
as we can thus avoid any loss of precision.

Strictly speaking correctly formed JSON text must have <strong>exactly
one top-level container</strong>. (Either an Array or an Object.) Scalars,
i.e. nulls, numbers, booleans and strings, are not valid JSON on their own.
It can be quite convenient to pretend that such fragments are valid
JSON however, and this class lets you do so.

This class does its best to be as strict as possible, both in what it
accepts and what it generates. (Other than the above mentioned support
for JSON fragments.) For example, it does not support trailing commas
in arrays or objects. Nor does it support embedded comments, or
anything else not in the JSON specification.
 
*/
@interface LQJSON : NSObject {
    BOOL _humanReadable;
    BOOL _sortsKeys;
    BOOL _includeUnknownObjects;
    LXUInteger _maxDepth;

@private
    // Used temporarily during scanning/generation
    LXUInteger _depth;
    const char *_ch;
}

+ (id)parseObjectFromString:(NSString *)jsonrep error:(NSError **)error;


/// Whether we are generating human-readable (multiline) JSON
/**
 Set whether or not to generate human-readable JSON. The default is NO, which produces
 JSON without any whitespace. (Except inside strings.) If set to YES, generates human-readable
 JSON with linebreaks after each array value and dictionary key/value pair, indented two
 spaces per nesting level.
 */
- (BOOL)humanReadable;
- (void)setHumanReadable:(BOOL)f;

/// Whether or not to sort the dictionary keys in the output
/** The default is to not sort the keys. */
- (BOOL)sortsKeys;
- (void)setSortsKeys:(BOOL)f;

// added by Pauli Ojala.
// when enabled, unrecognized objects will be serialized with their Obj-C class name and pointer.
// this is of course completely non-standard (but can be useful for debug or display purposes).
- (BOOL)allowsUnknownObjects;
- (void)setAllowsUnknownObjects:(BOOL)f;

/// The maximum depth the parser will go to
/** Defaults to 512. */
- (LXUInteger)maxDepth;
- (void)setMaxDepth:(LXUInteger)maxDepth;

/// Return JSON representation of an array or dictionary
- (NSString *)stringWithObject:(id)value error:(NSError **)error;

/// Return JSON representation of any legal JSON value
- (NSString *)stringWithFragment:(id)value error:(NSError **)error;

/// Return the object represented by the given string
- (id)objectWithString:(NSString *)jsonrep error:(NSError **)error;

/// Return the fragment represented by the given string
- (id)fragmentWithString:(NSString *)jsonrep error:(NSError **)error;

/// Return JSON representation (or fragment) for the given object
- (NSString *)stringWithObject:(id)value
                  allowScalar:(BOOL)x
    					error:(NSError **)error;

/// Parse the string and return the represented object (or scalar)
- (id)objectWithString:(id)value
           allowScalar:(BOOL)x
    			 error:(NSError **)error;

@end
