//
//  LDAP.m
//  rdap
//
//  Created by Furkan Mustafa on 10/6/13.
//  Copyright (c) 2013 fume. All rights reserved.
//

#import "LDAP.h"
#import "ber.h"
#import <objc/runtime.h>
#import "LDAPRequest.h"
#import "LDAPResponse.h"

// http://tools.ietf.org/html/rfc4512#section-5.1
// commented ones are response objects, defined in : http://tools.ietf.org/html/rfc4517
NSString* const LDAPControl_altServer = @"1.3.6.1.4.1.1466.101.120.6"; // 1.3.6.1.4.1.1466.115.121.1.26 IA5String
NSString* const LDAPControl_namingContexts = @"1.3.6.1.4.1.1466.101.120.5"; // 1.3.6.1.4.1.1466.115.121.1.12 DistinguishedName
NSString* const LDAPControl_supportedControl = @"1.3.6.1.4.1.1466.101.120.13"; // 1.3.6.1.4.1.1466.115.121.1.38 OBJECT IDENTIFIER
NSString* const LDAPControl_supportedExtension = @"1.3.6.1.4.1.1466.101.120.7"; // 1.3.6.1.4.1.1466.115.121.1.38 OBJECT IDENTIFIER
NSString* const LDAPControl_supportedFeatures = @"1.3.6.1.4.1.4203.1.3.5"; // 1.3.6.1.4.1.1466.115.121.1.38 OBJECT IDENTIFIER
NSString* const LDAPControl_supportedLDAPVersion = @"1.3.6.1.4.1.1466.101.120.15"; // 1.3.6.1.4.1.1466.115.121.1.27 INTEGER
NSString* const LDAPControl_supportedSASLMechanisms = @"1.3.6.1.4.1.1466.101.120.14"; // 1.3.6.1.4.1.1466.115.121.1.15 Directory String

@implementation LDAPOID
@end

@implementation LDAPDN
@end

@implementation LDAPReferral
@end

extern NSString* const LDAPControl_altServer;
extern NSString* const LDAPControl_namingContexts;
extern NSString* const LDAPControl_supportedControl;
extern NSString* const LDAPControl_supportedExtension;
extern NSString* const LDAPControl_supportedFeatures;
extern NSString* const LDAPControl_supportedLDAPVersion;
extern NSString* const LDAPControl_supportedSASLMechanisms;

@implementation LDAPControl

+ (BOOL)matchesBERType:(uint8_t)type {
	return NO;
}
- (void)dealloc {
    self.controlType = nil;
	self.controlValue = nil;
	[super dealloc];
}
+ (id)withBERData:(NSData *)data { return nil; }
- (void)setBERData:(NSData *)BERData {}
- (NSData *)berData { return 5; }

@end

@implementation LDAPMessageEnvelope

- (void)dealloc {
	self.controls = nil;
	self.operation = nil;
	[self setBERData:nil];
	[super dealloc];
}
- (NSMutableArray *)controls {
	if (!_controls)
		_controls = NSMutableArray.new;
	return _controls;
}
+ (id)withBERData:(NSData *)data {
	LDAPMessageEnvelope* new = LDAPMessageEnvelope.new;
	new.BERData = data;
	return [new autorelease];
}
+ (instancetype)envelopeWithOperation:(LDAPOperation*)operation {
	return operation.envelope;
}

- (void)loadObjects {
	self.messageID = UINT32_MAX;
	self.operation = nil;
	self.controls = nil;
	if (!_data) return;
	
	NSArray* payloadObjects = [_data berExtract];
	
	if (!payloadObjects.count || ![payloadObjects[0] isKindOfClass:NSNumber.class]) {
		NSLog(@"ERROR: Broken Message: LDAPMessage didn't start with messageID!");
		return;
	}
	self.messageID = [(NSNumber*)payloadObjects[0] integerValue];
	
	if (payloadObjects.count == 1) return;
	
	NSData* operationData = payloadObjects[1];
	if (!operationData || ![operationData isKindOfClass:NSData.class] || !operationData.berType) {
		NSLog(@"ERROR: Broken Message: LDAPMessage doesn't have a request/response object");
		return;
	}
	self.operation = [LDAPOperation withBERData:operationData];
	
	if (payloadObjects.count > 2) {
		self.controls = [[payloadObjects subarrayWithRange:NSMakeRange(2, payloadObjects.count - 2)].mutableCopy autorelease];
	}
}

- (void)setBERData:(NSData *)BERData {
	[_data autorelease]; _data = [BERData retain];
	[self loadObjects];
}
- (NSData *)berData {
	if (!_operation || _messageID == 0 || _messageID == UINT32_MAX) return nil;
	NSMutableArray* objects = NSMutableArray.array;
	[objects addObject:@(_messageID)];
	[objects addObject:_operation];
	[objects addObjectsFromArray:self.controls];
	NSData* berData = [NSData berCombine:objects];
	berData.berType = self.berType;
	return berData;
}
+ (BOOL)matchesBERType:(uint8_t)type {
	return type == (BER_Sequence | BER_Struct);
}
- (uint8_t)berType {
	return BER_Sequence | BER_Struct;
}

@end

@implementation LDAPResult

- (void)dealloc {
    self.matchedDN = nil;
	self.diagnosticMessage = nil;
	self.referral = nil;
	[super dealloc];
}

- (NSArray *)payloadObjects {
	NSNumber* resultCode = @(_resultCode);
	resultCode.berType = BER_Enumeration;
	NSString* matchedDN = self.matchedDN ? self.matchedDN : @"";
	NSString* diagMessage = self.diagnosticMessage ? self.diagnosticMessage : @"";
	return @[ resultCode, matchedDN, diagMessage, _referral ];
}

@end

NSMutableArray* ldapOperations;
@implementation LDAPOperation

+ (void)load {
	ldapOperations = NSMutableArray.new;
}
+ (void)registerClass:(Class)class {
	[ldapOperations addObject:class];
}
+(uint8_t)ldapOperationType {
	NSAssert(NO, @"Override this");
	return 0xFF;
}
+(NSString *)ldapOperationTypeName {
	NSAssert(NO, @"Override this");
	return nil;
}
+(Class)classWithType:(uint8_t)type {
	type &= ~(BER_Application | BER_Struct);
	for (Class aClass in ldapOperations) {
		if ([aClass ldapOperationType]==type) {
			return aClass;
		}
	}
	return nil;
}

- (void)dealloc {
	self.payloadObjects = nil;
    [super dealloc];
}
- (NSMutableArray *)payloadObjects {
	if (!_payloadObjects) {
		_payloadObjects = NSMutableArray.new;
	}
	return _payloadObjects;
}
- (BOOL)isRequest {
	return [self isKindOfClass:LDAPRequest.class];
}
- (LDAPProtocolOperation)type {
	return self.class.ldapOperationType;
}
+ (id)operationWithType:(LDAPProtocolOperation)type {
	Class operationClass = [self classWithType:type];
	NSAssert(operationClass, @"Unsupported operation : %02x", type);
	
	LDAPOperation* new = [operationClass new];
	NSLog(@"\tNew Operation With Type:%02x %@ and Objects:", type, NSStringFromClass(operationClass));
	return [new autorelease];
}
+ (id)operationWithType:(LDAPProtocolOperation)type data:(NSData*)data {
	LDAPOperation* new = [self operationWithType:type];
	new.payloadObjects = [[data.berExtract mutableCopy] autorelease];
	NSLog(@"\t---- %lu objects", new.payloadObjects.count);
	return new;
}
- (LDAPMessageEnvelope*)envelope {
	LDAPMessageEnvelope* newEnvelope = [LDAPMessageEnvelope.new autorelease];
	newEnvelope.operation = self;
	return newEnvelope;
}
+ (id)withBERData:(NSData *)data {
	return [self operationWithType:data.berType & ~(BER_Application | BER_Struct) data:data];
}
+ (BOOL)matchesBERType:(uint8_t)type {
	return (type & BER_Application);
}
- (NSData *)berData {
	NSData* combined = [NSData berCombine:self.payloadObjects];
	combined.berType = self.berType;
	return combined;
}
- (uint8_t)berType {
	if (self.type == LDAP_BindRequest || self.type == LDAP_BindResponse || self.type == LDAP_ExtendedResponse)
		return self.type | BER_Constructor | BER_Application;
	return self.type | BER_Application;
}

@end

@implementation LDAPNode

- (void)dealloc {
	self.dn = nil;
	[super dealloc];
}

@end

@implementation SaslCredentials

- (void)dealloc {
	self.mechanism = nil;
	self.credentials = nil;
    [super dealloc];
}
+ (id)withBERData:(NSData *)data {
	NSArray* objects = data.berExtract;
	if (!objects || objects.count==0)
		return nil;
	SaslCredentials* new = SaslCredentials.new;
	new.mechanism = objects[0];
	new.credentials = objects.count > 1 ? objects[1] : nil;
	return [new autorelease];
}
- (uint8_t)berType {
	// TODO
	return 0x00;
}
- (NSData *)berData {
	NSData* berData = [NSData berCombine:@[ _mechanism, _credentials ]];
	berData.berType = self.berType;
	return berData;
}
+ (BOOL)matchesBERType:(uint8_t)type {
	// TODO
	return NO;
}

@end
