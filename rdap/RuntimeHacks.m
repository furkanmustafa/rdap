//
//  RuntimeHacks.m
//  rdap
//
//  Created by Furkan Mustafa on 10/9/13.
//  Copyright (c) 2013 fume. All rights reserved.
//

#import "RuntimeHacks.h"
#import <objc/runtime.h>


@implementation NSDictionary (FMNilInsertableDictionary)

+ (void)load {
	ClassMethodSwizzle(NSDictionary.class, @selector(dictionaryWithObjects:forKeys:count:), @selector(_FMNilInsertableDictionary_dictionaryWithObjects:forKeys:count:));
}
+ (instancetype)_FMNilInsertableDictionary_dictionaryWithObjects:(const id [])objects forKeys:(const id<NSCopying> [])keys count:(NSUInteger)cnt {
	NSMutableDictionary* dictionary = NSMutableDictionary.new;
	
	for (int i = 0; i < cnt; i++) {
		if (!objects[i]) continue;	 // nil safe
		[dictionary setObject:objects[i] forKey:keys[i]];
	}
	
	NSDictionary* dict = [dictionary.copy autorelease];
	[dictionary release];
	return dict;
}

@end

@implementation NSArray (FMNilInsertableArray)

+ (void)load {
	ClassMethodSwizzle(NSArray.class, @selector(arrayWithObjects:count:), @selector(_FMNilInsertableArray_arrayWithObjects:count:));
}
+ (instancetype)_FMNilInsertableArray_arrayWithObjects:(const id [])objects count:(NSUInteger)cnt {
	NSMutableArray* mutableArray = NSMutableArray.new;
	
	for (int i = 0; i < cnt; i++) {
		if (!objects[i]) continue;	 // nil safe
		[mutableArray addObject:objects[i]];
	}
	
	NSArray* array = [mutableArray.copy autorelease];
	[mutableArray release];
	return array;
}

@end

void ClassMethodSwizzle(Class aClass, SEL orig_sel, SEL alt_sel) {
	
	Method orig_method = nil, alt_method = nil;
	
	// First, look for the methods
	orig_method = class_getClassMethod(aClass, orig_sel);
	alt_method = class_getClassMethod(aClass, alt_sel);
	
	// If both are found, swizzle them
	if ((orig_method != nil) && (alt_method != nil)) {
		//		char *temp1;
		IMP temp2;
		
		//		temp1 = orig_method->method_types;
		//		orig_method->method_types = alt_method->method_types;
		//		alt_method->method_types = temp1;
		
		temp2 = method_getImplementation(orig_method);// orig_method->method_imp;
		method_setImplementation(orig_method, method_getImplementation(alt_method)); //	orig_method->method_imp = alt_method->method_imp;
		method_setImplementation(alt_method, temp2); // alt_method->method_imp = temp2;
	}
}

void MethodSwizzle(Class aClass, SEL orig_sel, SEL alt_sel) {
	
	Method orig_method = nil, alt_method = nil;
	
	// First, look for the methods
	orig_method = class_getInstanceMethod(aClass, orig_sel);
	alt_method = class_getInstanceMethod(aClass, alt_sel);
	
	// If both are found, swizzle them
	if ((orig_method != nil) && (alt_method != nil)) {
		//		char *temp1;
		IMP temp2;
		
		//		temp1 = orig_method->method_types;
		//		orig_method->method_types = alt_method->method_types;
		//		alt_method->method_types = temp1;
		
		temp2 = method_getImplementation(orig_method);// orig_method->method_imp;
		method_setImplementation(orig_method, method_getImplementation(alt_method)); //	orig_method->method_imp = alt_method->method_imp;
		method_setImplementation(alt_method, temp2); // alt_method->method_imp = temp2;
	}
}
