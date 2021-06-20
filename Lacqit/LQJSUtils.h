//
//  LQJSUtils.h
//  Lacqit
//
//  Created by Pauli Ojala on 29.12.2009.
//  Copyright 2009 Lacquer oy/ltd. All rights reserved.
//

#import "LQBaseFrameworkHeader.h"
#import "LacqitExport.h"


LACQIT_EXPORT NSString *LQValidateJSVariableName(NSString *str, NSString *prefixForConflict);


// conversion util for arrays that originate from JavaScript.
// calls LQJSConvertKeyedItemsRecursively for any array objects that are not NSDictionaries but implement -keyEnumerator
LACQIT_EXPORT NSArray *LQArrayByConvertingKeyedItemsToDictionariesInArray(NSArray *inArr);


// any items that are not NSDictionaries but respond to -keyEnumerator (in practice, LQJSKitObjects)
// are converted to real NSDictionaries by copying the keys.
LACQIT_EXPORT id LQJSConvertKeyedItemsRecursively(id inObj);

