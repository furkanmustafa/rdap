//
//  RuntimeHacks.h
//  rdap
//
//  Created by Furkan Mustafa on 10/9/13.
//  Copyright (c) 2013 fume. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDictionary (FMNilInsertableDictionary)

@end

@interface NSArray (FMNilInsertableArray)

@end

void ClassMethodSwizzle(Class aClass, SEL orig_sel, SEL alt_sel);
void MethodSwizzle(Class aClass, SEL orig_sel, SEL alt_sel);
