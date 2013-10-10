//
//  LDAPResponse.m
//  rdap
//
//  Created by Furkan Mustafa on 10/9/13.
//  Copyright (c) 2013 fume. All rights reserved.
//

#import "LDAPResponse.h"

NSString* const kLDAPBindResponse = @"bindResponse";
NSString* const kLDAPSearchResEntry = @"SearchResultEntry";
NSString* const kLDAPSearchResDone = @"SearchResultDone";
NSString* const kLDAPSearchResRef = @"SearchResultReference";
NSString* const kLDAPModifyResponse = @"modifyResponse";
NSString* const kLDAPAddResponse = @"addResponse";
NSString* const kLDAPDelResponse = @"delResponse";
NSString* const kLDAPModDNResponse = @"modDNResponse";
NSString* const kLDAPCompareResponse = @"compareResponse";
NSString* const kLDAPExtendedResponse = @"extendedResponse";
NSString* const kLDAPIntermediateResponse = @"intermediateResponse";

@implementation LDAPResponse

- (void)dealloc {
	self.result = nil;
	self.request = nil;
	[super dealloc];
}
+ (void)load {
	[LDAPOperation registerClass:LDAPBindResponse.class];
	[LDAPOperation registerClass:LDAPSearchDoneResponse.class];
	[LDAPOperation registerClass:LDAPExtendedResponse.class];
}
- (LDAPResult *)result {
	if (!_result) {
		_result = LDAPResult.new;
	}
	return _result;
}
- (NSMutableArray *)payloadObjects {
	NSMutableArray* new = NSMutableArray.array;
	[new addObjectsFromArray:self.result.payloadObjects];
	return new;
}

@end

@implementation LDAPBindResponse

+ (uint8_t)ldapOperationType { return LDAP_BindResponse; }
+ (NSString *)ldapOperationTypeName { return kLDAPBindResponse; }

@end

@implementation LDAPSearchDoneResponse
+ (uint8_t)ldapOperationType { return LDAP_SearchResultDone; }
+ (NSString *)ldapOperationTypeName { return kLDAPSearchResDone; }
@end

@implementation LDAPExtendedResponse

- (void)dealloc {
	self.name = nil;
	self.value = nil;
	[super dealloc];
}
+ (uint8_t)ldapOperationType { return LDAP_ExtendedResponse ; }
+ (NSString *)ldapOperationTypeName { return kLDAPExtendedResponse; }
//- (void)setPayloadObjects:(NSMutableArray *)payloadObjects {
//	this is only required on client applications
//}
- (NSMutableArray *)payloadObjects {
	NSMutableArray* objects = [super payloadObjects];
	if (_name) {
		_name.berType = BER_Context | BER_Enumeration;
		[objects addObject:_name];
		if (_value) {
			_value.berType = BER_Context | BER_Enumeration;
			[objects addObject:_value];
		}
	}
	return objects;
}

@end

