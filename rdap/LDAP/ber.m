//
//  ber.m
//  rdap
//
//  Created by Furkan Mustafa on 10/6/13.
//  Copyright (c) 2013 fume. All rights reserved.
//

#import "ber.h"
#import <objc/runtime.h>

@implementation NSData (BERData)

- (void)setBerType:(uint8_t)type {
	objc_setAssociatedObject(self, @selector(berType), @(type), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
- (uint8_t)berType {
	return [objc_getAssociatedObject(self, @selector(berType)) integerValue];
}
- (NSData*)berTransmissionData {
	NSMutableData* transmissionData = [NSMutableData dataWithData:self.berPrefix];
	[transmissionData appendData:self];
	return transmissionData;
}
- (NSData*)berPrefix {
	NSMutableData* data = [NSMutableData data];
	
	// TYPE
	uint8_t type = self.berType;
	[data appendBytes:&type length:1];
	
	// SIZE
	if (self.length <= 127) {
		uint8_t newsize = self.length;
		[data appendBytes:&newsize length:1];
	}
	else if (self.length <= 255) {
		uint8_t sizeInd = 0x81;
		[data appendBytes:&sizeInd length:1];
		uint8_t newsize = self.length;
		[data appendBytes:&newsize length:1];
	}
	else if (self.length <= 65535) {
		uint8_t sizeInd = 0x82;
		[data appendBytes:&sizeInd length:1];
		uint16_t newsize = self.length;
		[data appendBytes:&newsize length:2];
	}
	else if (self.length <= 4294967295) {
		uint8_t sizeInd = 0x84;
		[data appendBytes:&sizeInd length:1];
		uint32_t newsize = (uint32_t)self.length;
		[data appendBytes:&newsize length:4];
	}
	
	return data;
}
+ (NSData*)berCombine:(NSArray*)payloadObjects {
	NSMutableData* combinedData = [NSMutableData.new autorelease];
	for (NSObject<BEREncoding>* obj in payloadObjects) {
		if (![obj respondsToSelector:@selector(berData)]) {
			[[NSException exceptionWithName:@"BER Incompatible Object" reason:@"BER Encoding" userInfo:nil] raise];
			return nil;
		}
		
		// TYPE & SIZE
		[combinedData appendData:obj.berData.berPrefix];
		// DATA
		[combinedData appendData:obj.berData];
	}
	return combinedData;
}
- (NSArray *)berExtract {
	NSMutableArray* objects = [NSMutableArray.new autorelease];
	unsigned char * bytes = (unsigned char *)self.bytes;
	int i = 0;
	int start = 0;
	int limit = (int)self.length;
	int payloadStart = 0;
	if (limit < 2) {
		return nil;
	}
	do {
		start = i;
		uint8_t type = bytes[i++];
		uint32_t size = bytes[i++];
		if ((size & 0x80) == 0x80) {
			uint8_t sizeBytes = size & ~0x80;
			size = 0;
			while (sizeBytes-- > 0) {
				size |= bytes[i++] & 0xFF;
				if (sizeBytes > 0)
					size = size << 8;
			};
		}
		payloadStart = i;
		i += size;
		unsigned char * value = (unsigned char *)self.bytes;
		value += payloadStart;
		if (payloadStart + size > limit) {
			// maybe even fail here
			return objects;
		}
		NSData* berData = [NSData dataWithBytes:value length:size];
		berData.berType = type;
		
		if ([NSString matchesBERType:type]) {
			NSString* string = [NSString withBERData:berData];
			NSLog(@"Found String: %@", string);
			[objects addObject:string];
			continue;
		}
		if ([NSNumber matchesBERType:type]) {
			NSNumber* theNumber = [NSNumber withBERData:berData];
			if (theNumber) {
				[objects addObject:theNumber];
				NSLog(@"Found Integer : %@ (size: %d)", theNumber, size);
			}
			continue;
		}
		if (((type & BER_Application) && (type & BER_Struct)) || type == BER_Context) {
			NSData* data = [NSData dataWithBytes:value length:size];
			data.berType = type;
			[objects addObject:data];
			NSLog(@"Found A Struct (%02x) with size : %d", type, size);
			continue;
		}
		
		NSLog(@"Unrecognized Type %02x (len:%d) -- Data : %@", type, size, berData);
		[objects addObject:berData]; // add unrecognized type too.
		// ..
	} while (i<self.length);
	return objects;
}

@end

@implementation NSNumber (BERData)

- (void)setBerType:(uint8_t)type {
	objc_setAssociatedObject(self, @selector(berType), @(type), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
- (uint8_t)berType {
	NSNumber* type = objc_getAssociatedObject(self, @selector(berType));
	if (!type)
		return BER_Integer;
	return [type integerValue];
}
+ (BOOL)matchesBERType:(uint8_t)type {
	// TODO: There should be more
	return (type == BER_Boolean) || (type == BER_Integer) || ( type == (BER_Integer | BER_External)); // BER_External | BER_Integer (enumeration)
}
+ (id)withBERData:(NSData *)data {
	NSNumber* theNumber = nil;
	unsigned char * value = (unsigned char *)data.bytes;
	if (data.berType == BER_Boolean) {
		uint8_t number = (uint8_t)*value;
		if (number == 0x00)
			theNumber = @(NO);
		else if (number == 0xFF)
			theNumber = @(YES);
	}
	else if (data.length==1) {
		uint8_t number = (uint8_t)*value;
		theNumber = [NSNumber.alloc initWithUnsignedChar:number].autorelease;
	} else if (data.length==2) {
		uint16_t number = (uint16_t)*value;
		theNumber = [NSNumber.alloc initWithUnsignedShort:number].autorelease;
	} else if (data.length==4) {
		uint32_t number = (uint32_t)*value;
		theNumber = [NSNumber.alloc initWithUnsignedInt:number].autorelease;
	} else if (data.length==8) {
		uint64_t number = (uint64_t)*value;
		theNumber = [NSNumber.alloc initWithUnsignedLong:number].autorelease;
	} else {
		NSLog(@"Unsupported Integer Size : %lu", data.length);
	}
	theNumber.berType = data.berType;
	return theNumber;
}
- (NSData *)berData {
	unsigned long value = self.unsignedLongValue;
	NSData* result = nil;
	if (self.berType == BER_Boolean) {
		uint8_t newval = ([self boolValue] == YES) ? 0xFF : 0x00;
		result = [NSData dataWithBytes:&newval length:1];
	}
	else if ((value & 0xFF) == value) {
		uint8_t newval = (uint8_t)value;
		result = [NSData dataWithBytes:&newval length:1];
	}
	else if ((value & 0xFFFF) == value) {
		uint16_t newval = (uint16_t)value;
		result = [NSData dataWithBytes:&newval length:2];
	}
	else if ((value & 0xFFFFFFFF) == value) {
		uint32_t newval = (uint32_t)value;
		result = [NSData dataWithBytes:&newval length:4];
	}
	else if ((value & 0xFFFFFFFFFFFFFFFF) == value) {
		uint64_t newval = (uint64_t)value;
		result = [NSData dataWithBytes:&newval length:8];
	}
	result.berType = self.berType;
	return result;
}

@end
@implementation NSString (BERData)

- (void)setBerType:(uint8_t)type {
	objc_setAssociatedObject(self, @selector(berType), @(type), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
- (uint8_t)berType {
	NSNumber* type = objc_getAssociatedObject(self, @selector(berType));
	if (!type)
		return BER_String;
	return [type integerValue];
}
+ (BOOL)matchesBERType:(uint8_t)type {
	// there should be more
	return (type & 0x0F) == BER_String;
}
+ (id)withBERData:(NSData *)data {
	NSString* string = [NSString.alloc initWithData:data encoding:NSASCIIStringEncoding].autorelease;
	string.berType = data.berType;
	return string;
}
- (NSData*)berData {
	NSData* data = [self dataUsingEncoding:NSUTF8StringEncoding]; // NSASCIIStringEncoding ?
	data.berType = self.berType;
	return data; // implement
}

@end
