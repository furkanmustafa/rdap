//
//  LDAPRequest.m
//  rdap
//
//  Created by Furkan Mustafa on 10/9/13.
//  Copyright (c) 2013 fume. All rights reserved.
//

#import "LDAPRequest.h"

NSString* const kLDAPBindRequest = @"bindRequest";
NSString* const kLDAPUnindRequest = @"unbindRequest";
NSString* const kLDAPSearchRequest = @"searchRequest";
NSString* const kLDAPModifyRequest = @"modifyRequest";
NSString* const kLDAPAddRequest = @"addRequest";
NSString* const kLDAPDelRequest = @"delRequest";
NSString* const kLDAPModDNRequest = @"modDNRequest";
NSString* const kLDAPCompareRequest = @"compareRequest";
NSString* const kLDAPAbandonRequest = @"abandonRequest";
NSString* const kLDAPExtendedRequest = @"extendedRequest";

@implementation LDAPRequest

+(void)load {
	[LDAPOperation registerClass:LDAPBindRequest.class];
	[LDAPOperation registerClass:LDAPSearchRequest.class];
	[LDAPOperation registerClass:LDAPUnbindRequest.class];
	[LDAPOperation registerClass:LDAPExtendedRequest.class];
}

@end

@implementation LDAPBindRequest

- (void)dealloc {
	self.dn = nil;
	self.simpleAuthentication = nil;
	self.saslAuthentication = nil;
	[super dealloc];
}
+ (uint8_t)ldapOperationType { return LDAP_BindRequest; }
+ (NSString *)ldapOperationTypeName { return kLDAPBindRequest; }
- (void)setPayloadObjects:(NSMutableArray *)payloadObjects {
	self.protocolVersion = payloadObjects.count ? [payloadObjects[0] integerValue] : 0;
	self.dn = payloadObjects.count > 1 ? payloadObjects[1] : nil;
	NSData* authentication = payloadObjects.count > 2 ? payloadObjects[2] : nil;
	NSUInteger choice = authentication.berType & ~BER_Context;
	
	self.simpleAuthentication = nil;
	self.saslAuthentication = nil;
	if (choice == 0) {
		self.simpleAuthentication = [NSString.alloc initWithData:authentication encoding:NSASCIIStringEncoding].autorelease;
	} else if (choice == 3) {
		self.saslAuthentication = [SaslCredentials withBERData:authentication];
	}
}

@end

@implementation LDAPSearchRequest
+ (uint8_t)ldapOperationType { return LDAP_SearchRequest; }
+ (NSString *)ldapOperationTypeName { return kLDAPSearchRequest; }

@end

@implementation LDAPUnbindRequest
+ (uint8_t)ldapOperationType { return LDAP_UnbindRequest; }
+ (NSString *)ldapOperationTypeName { return kLDAPUnindRequest; }

@end

@implementation LDAPExtendedRequest

- (void)dealloc {
	self.name = nil;
	self.value = nil;
	[super dealloc];
}
+ (uint8_t)ldapOperationType { return LDAP_ExtendedRequest; }
+ (NSString *)ldapOperationTypeName { return kLDAPExtendedRequest; }
- (void)setPayloadObjects:(NSMutableArray *)payloadObjects {
	self.name = payloadObjects.count ? [NSString.alloc initWithData:payloadObjects[0] encoding:NSASCIIStringEncoding].autorelease : nil;
	self.value = payloadObjects.count > 1 ? [NSString.alloc initWithData:payloadObjects[1] encoding:NSASCIIStringEncoding].autorelease : nil;
}

@end
