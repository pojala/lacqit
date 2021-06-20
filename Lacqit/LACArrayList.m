//
//  LACArrayList.m
//  Lacqit
//
//  Created by Pauli Ojala on 5.1.2009.
//  Copyright 2009 Lacquer oy/ltd. All rights reserved.
//

#import "LACArrayList.h"
#import <Lacefx/LXMutexAtomic.h>


static LACArrayList g_emptyList = { 0, nil, NULL, 1000*1000 };

LACArrayList * const LACEmptyArrayList = &g_emptyList;


LXInteger LACArrayListCount(const LACArrayListPtr list)
{
    if ( !list) return 0;
    
    LXInteger total = list->count;
    
    LACArrayListPtr nextList = list->next;
    while (nextList) {
        total += nextList->count;
        nextList = nextList->next;
    }
    return total;
}

NSArray *LACArrayListAsNSArray(const LACArrayListPtr list)
{
    if ( !list || list->count < 1) return nil;
    
    if (list->count == 1)
        return [NSArray arrayWithObject:list->nsObj];
    
    else if ([list->nsObj isKindOfClass:[NSArray class]] && !list->next)
        return [[list->nsObj retain] autorelease];
    
    else {
        // TODO: create nsarray of all objects in list
        printf("** %s: should create nsarray containing all objects (count %ld, total is %ld)\n", __func__, (long)[list->nsObj count], (long)LACArrayListCount(list));
        return [[list->nsObj retain] autorelease];
    }
}

id LACArrayListFirstObject(const LACArrayListPtr list)
{
    if ( !list || list->count < 1) return nil;
    return LACArrayListObjectAt(list, 0);
}

id LACArrayListLastObject(const LACArrayListPtr list)
{
    if ( !list || list->count < 1) return nil;
    
    LACArrayListPtr lastNode = (list->next) ? LACArrayListLastNode(list, NULL) : list;
    
    if (lastNode->count == 1)
        return lastNode->nsObj;
    else
        return [(NSArray *)lastNode->nsObj lastObject];
}

id LACArrayListObjectAt(const LACArrayListPtr list, LXInteger index)
{
    if ( !list) return nil;
    
    if (index < list->count) {
        if (list->count == 1) {
            return list->nsObj;
        } else {
            NSCAssert1([list->nsObj isKindOfClass:[NSArray class]], @"invalid object for multi-obj list node, expected array (%@)", [list->nsObj class]);
            NSCAssert2([list->nsObj count] > index, @"index out of bounds (count is %i, index %i)", [list->nsObj count], index);
            
            return [list->nsObj objectAtIndex:index];
        }
    } else if (list->next) {
        return LACArrayListObjectAt(list->next, index - list->count);
    } else {
        NSLog(@"** %s: index out of bounds (%ld, %p, %ld)", __func__, index, list, list->count);
        return nil;
    }
}

LACArrayListPtr LACArrayListLastNode(const LACArrayListPtr list, LXInteger *outNodeCount)
{
    if ( !list) return 0;
    LXInteger nodeCount = 1;
    LACArrayListPtr last = list;
    
    LACArrayListPtr nextList;
    while ((nextList = list->next)) {
        nodeCount++;
        last = list;
    }
    if (outNodeCount) *outNodeCount = nodeCount;
    return last;
}


LACArrayListPtr LACArrayListCreateWithObject(id nsObj)
{
    if ( !nsObj) return LACEmptyArrayList;

    ///NSLog(@"%s: obj is %@", __func__, nsObj);

    LACArrayList *newList = _lx_calloc(sizeof(LACArrayList), 1);
    newList->count = 1;
    newList->nsObj = [nsObj retain];
    newList->next = NULL;
    newList->refCount = 1;
    return newList;
}

LACArrayListPtr LACArrayListCreateWithArray(NSArray *array)
{
    if ( !array) return LACEmptyArrayList;
    
    if ([array count] == 1) {
        return LACArrayListCreateWithObject([array objectAtIndex:0]);
    }

    LACArrayList *newList = _lx_calloc(sizeof(LACArrayList), 1);
    newList->count = [array count];
    newList->nsObj = (newList->count > 0) ? [array retain] : NULL;
    newList->next = NULL;
    newList->refCount = 1;
    return newList;
}

LACArrayListPtr LACArrayListCreateWithDictionary(NSDictionary *dict)
{
    if ( !dict) return LACEmptyArrayList;
    
    NSArray *keys = [dict allKeys];
    NSMutableArray *newArr = [NSMutableArray arrayWithCapacity:[keys count]];
    NSMutableDictionary *indexNames = [NSMutableDictionary dictionary];
    
    NSEnumerator *keyEnum = [keys objectEnumerator];
    id key;
    long n = 0;
    while (key = [keyEnum nextObject]) {
        [newArr addObject:[dict objectForKey:key]];
        
        if ([key isKindOfClass:[NSString class]]) {  // only strings are allowed as index names
            [indexNames setObject:key forKey:[NSNumber numberWithLong:n]];
        }
        n++;
    }

    LACArrayList *newList = _lx_calloc(sizeof(LACArrayList), 1);
    newList->count = [newArr count];
    newList->nsObj = (newList->count == 0) ? NULL : ((newList->count > 1) ? [newArr retain] : [[newArr objectAtIndex:0] retain]);  // single-object list stores the object directly here
    newList->next = NULL;
    newList->refCount = 1;
    newList->indexNames = ([indexNames count] > 0) ? [indexNames retain] : nil;
    return newList;
}

LACArrayListPtr LACArrayListCreateLinkedListWithObjectsAndCount(id *objects, LXInteger count)
{
    if (count < 1) return NULL;
    
    LACArrayList *newList = _lx_calloc(sizeof(LACArrayList), 1);
    
    newList->count = 1;
    newList->nsObj = [objects[0] retain];
    newList->next = (count > 1) ? LACArrayListCreateLinkedListWithObjectsAndCount(objects+1, count-1)
                                : NULL;
    newList->refCount = 1;
    return newList;
}

LACArrayListPtr LACArrayListCreateWithObjectsAndCount(id *objects, LXInteger count)
{
    // if there's only a handful of objects, create a linked list instead of an NSArray
    if (count < 4) {
        return LACArrayListCreateLinkedListWithObjectsAndCount(objects, count);
    }
    else {
        LACArrayList *newList = _lx_calloc(sizeof(LACArrayList), 1);

        NSArray *newArr = [NSArray arrayWithObjects:objects count:count];
    
        newList->count = count;
        newList->nsObj = [newArr retain];
        newList->next = NULL;
        newList->refCount = 1;
        return newList;
    }
}

LACArrayListPtr LACArrayListCreateWithObjects(id first, ...)
{
    va_list vargs;
    LXInteger count = 1;
    
    va_start(vargs, first);
    {
        while (va_arg(vargs, id) != nil) {
            count++;
        }
    }
    va_end(vargs);
    
    id objects[count];
    objects[0] = first;
    
    va_start(vargs, first);
    {
        LXInteger i;
        for (i = 1; i < count; i++) {
            objects[i] = va_arg(vargs, id);
        }
    }
    va_end(vargs);
    
    return LACArrayListCreateWithObjectsAndCount(objects, count);
}


LACArrayListPtr LACArrayListCopy(const LACArrayListPtr oldList)
{
    if ( !oldList) return NULL;
    if (oldList == LACEmptyArrayList) return oldList;

    LACArrayList *newList = _lx_calloc(sizeof(LACArrayList), 1);
    
    newList->count = oldList->count;
    newList->nsObj = [oldList->nsObj retain];
    newList->next = (oldList->next) ? LACArrayListCopy(oldList->next) : NULL;
    newList->refCount = 1;
    
    if (oldList->indexNames) {
        newList->indexNames = [oldList->indexNames mutableCopy];
    }
    
    return newList;
}


LACArrayListPtr LACArrayListRetain(LACArrayListPtr list)
{
    if ( !list) return NULL;
    if (list == LACEmptyArrayList) return list;
    
    ///list->refCount++;
    LXAtomicInc_int32(&(list->refCount));
    
    if (list->next) LACArrayListRetain(list->next);
    
    return list;
}

void LACArrayListRelease(LACArrayListPtr list)
{
    if ( !list) return;
    if (list == LACEmptyArrayList) return;
    
    ///list->refCount--;
    int32_t refCount = LXAtomicDec_int32(&(list->refCount));

    LACArrayListPtr next = list->next;
    
    if (refCount == 0) {
        ///NSLog(@"%s: obj is %@", __func__, list->nsObj);    
    
        [list->nsObj release];
        list->nsObj = nil;
        list->next = NULL;
        if (list->indexNames) [list->indexNames release];
        
        _lx_free(list);
    }
        
    if (next) LACArrayListRelease(next);
}

NSString *LACArrayListDescribe(LACArrayListPtr list)
{
    if ( !list) return @"(null)";
    if (list == LACEmptyArrayList) return @"(emptyArrayList)";
    
    if (list->count < 1) return @"(empty, not const)";
    
    if ( !list->next) {
        if (list->count == 1) return [NSString stringWithFormat:@"(1-list: %@ / %@)", [list->nsObj class], [list->nsObj description]];
    
        else return [NSString stringWithFormat:@"(%i-list: %p, first is %@)", [list->nsObj count], list->nsObj, [[list->nsObj objectAtIndex:0] class]];
    }
    else {
        LXInteger totalCount = LACArrayListCount(list);
        if (totalCount > 8) {
            return [NSString stringWithFormat:@"(%i-list: first is %@ / %@)", totalCount, [list->nsObj class], [list->nsObj description]];
        } else {
            return [NSString stringWithFormat:@"(%i-list: %@, next is: %@)", totalCount, [list->nsObj class], LACArrayListDescribe(list->next)];
        }
    }
}

NSString *LACArrayListIndexNameAt(const LACArrayListPtr list, LXInteger index)
{
    if ( !list || !list->indexNames) return nil;
    
    if (index >= list->count) {
        if (list->next) {
            return LACArrayListIndexNameAt(list->next, index - list->count);
        }
        return nil;
    }
    
    id key = [NSNumber numberWithLong:index];
    return [list->indexNames objectForKey:key];
}

void LACArrayListSetIndexName(LACArrayListPtr list, LXInteger index, NSString *name)
{
    if ( !list || index < 0) return;
    if (index >= list->count) {
        if (list->next) {
            LACArrayListSetIndexName(list->next, index - list->count, name);
        }
        return;
    }
    
    if ( !list->indexNames && name) {
        list->indexNames = [[NSMutableDictionary alloc] init];
    }
    id key = [NSNumber numberWithLong:index];
    if (name) {
        [list->indexNames setObject:name forKey:key];
    } else {
        [list->indexNames removeObjectForKey:key];
    }
}

void LACArrayListSetIndexNamesFromArray(LACArrayListPtr list, NSArray *array)
{
    if ( !list) return;
    [list->indexNames removeAllObjects];
    
    LXUInteger n = [array count];
    LXUInteger i;
    for (i = 0; i < n; i++) {
        LACArrayListSetIndexName(list, i, [[array objectAtIndex:i] description]);
    }
}

LXInteger LACArrayListFindIndexByName(const LACArrayListPtr list, NSString *name)
{
    if ( !list || !list->indexNames || !name) return kLXNotFound;
    
    NSEnumerator *keyEnum = [list->indexNames keyEnumerator];
    id key;
    while (key = [keyEnum nextObject]) {
        if ([name isEqualToString:[list->indexNames objectForKey:key]]) {
            break;
        }
    }
    
    return (key) ? [key longValue] : kLXNotFound;
}

static void appendIndexNamesToDict(const LACArrayListPtr list, NSMutableDictionary *dict)
{
    if (list->indexNames) {
        [dict addEntriesFromDictionary:list->indexNames];
    }
    if (list->next)
        appendIndexNamesToDict(list->next, dict);
}

NSDictionary *LACArrayListCopyIndexNamesDictionary(const LACArrayListPtr list)
{
    if ( !list || !list->indexNames) return nil;
    
    NSDictionary *dict = [list->indexNames copy];
    
    if (list->next) {
        dict = [[NSMutableDictionary alloc] initWithDictionary:[dict autorelease]];
        appendIndexNamesToDict(list->next, (NSMutableDictionary *)dict);
    }
    return dict;
}

NSArray *LACArrayListCopyIndexNamesArray(const LACArrayListPtr list)
{
    if ( !list || !list->indexNames) return nil;
    
    const LXInteger n = LACArrayListCount(list);
    NSMutableArray *arr = [[NSMutableArray alloc] initWithCapacity:n];
    LXInteger i;
    for (i = 0; i < n; i++) {
        NSString *name = LACArrayListIndexNameAt(list, i);
        
        [arr addObject:(name) ? name : @""];
    }
    return arr;
}

BOOL LACArrayListIndexNamesAreUnique(const LACArrayListPtr list)
{
    if ( !list || !list->indexNames || list->count < 1) return NO;
    
    // shortcut: look for empty names first
    const LXInteger n = LACArrayListCount(list);
    LXInteger i;
    for (i = 0; i < n; i++) {
        NSString *name = LACArrayListIndexNameAt(list, i);
        if ( !name || [name length] < 1)
            return NO;
    }

    // no empty names, so must check for real matches
    NSMutableSet *set = [NSMutableSet setWithCapacity:n];
    for (i = 0; i < n; i++) {
        NSString *name = LACArrayListIndexNameAt(list, i);
        if ([set containsObject:name])
            return NO;
        else
            [set addObject:name];
    }
    return YES;
}

