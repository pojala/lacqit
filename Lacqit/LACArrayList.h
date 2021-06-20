//
//  LACArrayList.h
//  Lacqit
//
//  Created by Pauli Ojala on 5.1.2009.
//  Copyright 2009 Lacquer oy/ltd. All rights reserved.
//

#ifndef _LACARRAYLIST_H_
#define _LACARRAYLIST_H_

#import "LQBaseFrameworkHeader.h"
#import <stdarg.h>
#import "LacqitExport.h"

/*
An unrolled linked list for NSObjects
*/

typedef struct _LACArrayList {
    LXInteger count;        // count of objects in nsObj
    id nsObj;               // if count > 1, this is an NSArray
    struct _LACArrayList *next;
    volatile int32_t refCount;
    id indexNames;
} LACArrayList;

typedef LACArrayList *LACArrayListPtr;


// the empty list. it is not affected by retain/release
LACQIT_EXPORT_VAR LACArrayListPtr const LACEmptyArrayList;


#ifdef __cplusplus
extern "C" {
#endif

LACQIT_EXPORT LXInteger LACArrayListCount(const LACArrayListPtr list);

LACQIT_EXPORT id LACArrayListFirstObject(const LACArrayListPtr list);
LACQIT_EXPORT id LACArrayListLastObject(const LACArrayListPtr list);
LACQIT_EXPORT id LACArrayListObjectAt(const LACArrayListPtr list, LXInteger index);

LACQIT_EXPORT LACArrayListPtr LACArrayListLastNode(const LACArrayListPtr list, LXInteger *outNodeCount);

// created lists have a refCount of 1; use the release function to destroy the entire list.
// creation functions decide internally whether to use a multi-node list or a single-node list containing an NSArray
LACQIT_EXPORT LACArrayListPtr LACArrayListCreateWithObject(id nsObj);
LACQIT_EXPORT LACArrayListPtr LACArrayListCreateWithObjects(id first, ...);
LACQIT_EXPORT LACArrayListPtr LACArrayListCreateWithObjectsAndCount(id *objects, LXInteger count);

LACQIT_EXPORT LACArrayListPtr LACArrayListCreateWithArray(NSArray *array);
LACQIT_EXPORT LACArrayListPtr LACArrayListCreateWithDictionary(NSDictionary *dict);  // sets index names for dict keys that are strings

// this copy function is shallow (doesn't copy the NSObjects in the list)
LACQIT_EXPORT LACArrayListPtr LACArrayListCopy(const LACArrayListPtr list);

// retain/release are not thread-safe
LACQIT_EXPORT LACArrayListPtr LACArrayListRetain(LACArrayListPtr list);
LACQIT_EXPORT void LACArrayListRelease(LACArrayListPtr list);

LACQIT_EXPORT NSString *LACArrayListDescribe(LACArrayListPtr list);

LACQIT_EXPORT NSArray *LACArrayListAsNSArray(const LACArrayListPtr list);

// named indexes.
// in this slightly hackish manner, lists can be used as ordered dictionaries.
// this might be too slow for large lists, but works fine for the short lists passed between nodes in CL2
LACQIT_EXPORT NSString *LACArrayListIndexNameAt(const LACArrayListPtr list, LXInteger index);
LACQIT_EXPORT void LACArrayListSetIndexName(LACArrayListPtr list, LXInteger index, NSString *name);
LACQIT_EXPORT void LACArrayListSetIndexNamesFromArray(LACArrayListPtr list, NSArray *array);

LACQIT_EXPORT LXInteger LACArrayListFindIndexByName(const LACArrayListPtr list, NSString *name);

LACQIT_EXPORT NSDictionary *LACArrayListCopyIndexNamesDictionary(const LACArrayListPtr list);
LACQIT_EXPORT NSArray *LACArrayListCopyIndexNamesArray(const LACArrayListPtr list);  // array contains empty string for indexes without name

LACQIT_EXPORT BOOL LACArrayListIndexNamesAreUnique(const LACArrayListPtr list);  // returns YES only if all indexes have a unique, non-empty name

#ifdef __cplusplus
}
#endif

#endif
