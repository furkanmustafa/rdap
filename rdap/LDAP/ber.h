//
//  ber.h
//  rdap
//
//  Created by Furkan Mustafa on 10/6/13.
//  Copyright (c) 2013 fume. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
	BER_Universal		= 0x00,
	BER_Application		= 0x40,
	BER_Context			= 0x80,
	BER_Private			= 0xC0,
	
	BER_Primitive		= 0x00,
	BER_Struct			= 0x20,	// BER_Constructor
	BER_Constructor		= 0x20, // Naming convention
	
	BER_TypeMask		= 0x1F,		// types below;
	
	BER_String			= 0x04,
	BER_UTF8String		= 0x0C,	// means also a String
	BER_Sequence		= 0x10,
	BER_Integer			= 0x02,
	BER_Boolean			= 0x01,
	BER_Enumeration		= 0x0A, // means also a BER_Integer
	BER_NumericString	= 0x12,	// means also an Integer Sequence? :/
	BER_BitString		= 0x03,
	BER_NULL			= 0x05,
	BER_OID				= 0x06,
	BER_ObjectDescriptor= 0x07,
	BER_External		= 0x08,
	BER_Real			= 0x09,
	BER_PDV				= 0x0B,
	BER_RelativeOID		= 0x0D,
	BER_Set				= 0x11,
	BER_PrintableString	= 0x13,
	BER_T61String		= 0x14,
	BER_VideotexString	= 0x15,
	BER_IA5String		= 0x16,
	BER_UTCTime			= 0x17,
	BER_GeneralizedTime	= 0x18,
	BER_GraphicString	= 0x19,
	BER_VisibleString	= 0x1A,
	BER_GeneralString	= 0x1C,
	BER_UniversalString	= 0x1D,
	BER_CharacterString	= 0x1E,
	BER_BMPString		= 0x1F
	
} BERType;

@protocol BEREncoding <NSObject>
@required
+ (id)withBERData:(NSData*)data;
+ (BOOL)matchesBERType:(uint8_t)type;
@property (nonatomic,readonly) NSData* berData;
- (uint8_t)berType;
@end

@interface NSData (BERData)
@property (nonatomic,readwrite) uint8_t berType;
- (NSArray*)berExtract;
+ (NSData*)berCombine:(NSArray*)payloadObjects;
- (NSData*)berTransmissionData;
@end

@interface NSNumber (BERData) <BEREncoding>
@property (nonatomic,readwrite) uint8_t berType;
@end

@interface NSString (BERData) <BEREncoding>
@property (nonatomic,readwrite) uint8_t berType;
@end
