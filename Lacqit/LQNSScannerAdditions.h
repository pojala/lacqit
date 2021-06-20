//
//  LQNSScannerAdditions.h
//  Lacqit
//
//  Created by Pauli Ojala on 2.9.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSScanner (LQParsingAdditions)

- (BOOL)incrementLocation;
- (BOOL)decrementLocation;

- (BOOL)scanQuotedLiteralIntoString:(NSString **)outStr;


// following two methods omit any preceding whitespace

- (BOOL)scanPossiblyQuotedLiteralIntoString:(NSString **)outStr;

- (BOOL)scanPossiblyNestedListOfLiteralsIntoArray:(NSArray **)arr
            listStartCharacter:(unichar)lstartCh
            listEndCharacter:(unichar)lendCh
            separatorCharacter:(unichar)sepCh;
            
@end
