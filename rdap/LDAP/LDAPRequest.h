//
//  LDAPRequest.h
//  rdap
//
//  Created by Furkan Mustafa on 10/9/13.
//  Copyright (c) 2013 fume. All rights reserved.
//

#import "LDAP.h"

extern NSString* const kLDAPBindRequest;
extern NSString* const kLDAPUnindRequest;
extern NSString* const kLDAPSearchRequest;
extern NSString* const kLDAPModifyRequest;
extern NSString* const kLDAPAddRequest;
extern NSString* const kLDAPDelRequest;
extern NSString* const kLDAPModDNRequest;
extern NSString* const kLDAPCompareRequest;
extern NSString* const kLDAPAbandonRequest;
extern NSString* const kLDAPExtendedRequest;

@interface LDAPRequest : LDAPOperation
@end

@interface LDAPBindRequest : LDAPRequest
@property (nonatomic,readwrite) NSUInteger protocolVersion;
@property (nonatomic,retain) NSString* dn;
@property (nonatomic,retain) NSString* simpleAuthentication;
@property (nonatomic,retain) SaslCredentials* saslAuthentication;
@end

@interface LDAPUnbindRequest : LDAPRequest
@end

@interface LDAPSearchRequest : LDAPRequest

@end

@interface LDAPExtendedRequest : LDAPRequest
@property (nonatomic,retain) NSString* name;
@property (nonatomic,retain) NSString* value;
@end
