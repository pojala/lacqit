//
//  LQLXBasicFunctions.h
//  Lacqit
//
//  Created by Pauli Ojala on 7.10.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Lacefx/LXBasicTypeFunctions.h>
#import <Lacefx/LXRefTypes.h>
#import "LacqitExport.h"


#ifdef __cplusplus
extern "C" {
#endif


//#define LXRectFromNSRect(_r_)  LXMakeRect(_r_.origin.x, _r_.origin.y,  _r_.size.width, _r_.size.height)
//#define NSRectFromLXRect(_r_)  NSMakeRect(_r_.x, _r_.y, _r_.w, _r_.h)


LXINLINE LXSize LXSizeFromNSSize(NSSize nss) {
    return LXMakeSize(nss.width, nss.height); }
    
LXINLINE NSSize NSSizeFromLXSize(LXSize s) {
    return NSMakeSize(s.w, s.h); }


LXINLINE LXPoint LXPointFromNSPoint(NSPoint nsp) {
    return (*(LXPoint *)&(nsp)); }

LXINLINE NSPoint NSPointFromLXPoint(LXPoint lxp) {
    return (*(NSPoint *)&(lxp)); }


LXINLINE LXRect LXRectFromNSRect(NSRect nsr) {
    LXRect r;
    r.x = nsr.origin.x;
    r.y = nsr.origin.y;
    r.w = nsr.size.width;
    r.h = nsr.size.height;
    return r;
}

LXINLINE NSRect NSRectFromLXRect(LXRect r) {
    return NSMakeRect(r.x, r.y, r.w, r.h);
}

// --- transform utils ---

LACQIT_EXPORT NSAffineTransform *NSAffineTransformFromLXTransform3D(LXTransform3DRef trs);

LACQIT_EXPORT LXTransform3DRef LXTransform3DCreateFromNSAffineTransform(NSAffineTransform *trs);


// --- lacefx <-> NSString utils ---

LXINLINE NSString *NSStringFromLXUnibuffer(LXUnibuffer uni)
{
    return [NSString stringWithCharacters:(unichar *)uni.unistr length:uni.numOfChar16];
}

// if nsstr is nil or has zero length, dstUnibuffer is set to {0, NULL}.
// otherwise it is filled with a _lx_malloc'ed string.
// it's preferred to use LXStrUnibufferDestroy() to free the string.
LACQIT_EXPORT size_t LXStrCopyUTF16FromNSString(LXUnibuffer *dstUnibuffer, NSString *nsstr);

LXINLINE LXUnibuffer LXUnibufferCreateFromNSString(NSString *nsstr)
{
    LXUnibuffer uni = { 0, NULL };
    LXStrCopyUTF16FromNSString(&uni, nsstr);
    return uni;
}


LXINLINE NSString *NSStringFromLXRGBA(LXRGBA rgba)
{
    return [NSString stringWithFormat:@"{ %.6f, %.6f, %.6f, %.6f }", rgba.r, rgba.g, rgba.b, rgba.a];
}

LACQIT_EXPORT LXRGBA LXRGBAFromNSString(NSString *str);


// --- NS-compatible toString utils ---
    
LXINLINE NSString *NSStringFromLXRect(LXRect r) {
    return NSStringFromRect(NSRectFromLXRect(r));
}

LXINLINE NSString *NSStringFromLXSize(LXSize s) {
    return NSStringFromSize(NSSizeFromLXSize(s));
}

LXINLINE NSString *NSStringFromLXPoint(LXPoint p) {
    return NSStringFromPoint(NSPointFromLXPoint(p));
}


// --- LXMap <-> NSDictionary ---

LACQIT_EXPORT NSDictionary *NSDictionaryFromLXMap(LXMapPtr lxMap);  // returned dict is autoreleased
LACQIT_EXPORT LXMapPtr LXMapCreateFromNSDictionary(NSDictionary *dict);


#ifdef __cplusplus
}
#endif

