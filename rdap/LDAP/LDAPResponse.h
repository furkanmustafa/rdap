//
//  LDAPResponse.h
//  rdap
//
//  Created by Furkan Mustafa on 10/9/13.
//  Copyright (c) 2013 fume. All rights reserved.
//

#import "LDAP.h"
#import "LDAPRequest.h"

extern NSString* const kLDAPBindResponse;
extern NSString* const kLDAPSearchResEntry;
extern NSString* const kLDAPSearchResDone;
extern NSString* const kLDAPSearchResRef;
extern NSString* const kLDAPModifyResponse;
extern NSString* const kLDAPAddResponse;
extern NSString* const kLDAPDelResponse;
extern NSString* const kLDAPModDNResponse;
extern NSString* const kLDAPCompareResponse;
extern NSString* const kLDAPExtendedResponse;
extern NSString* const kLDAPIntermediateResponse;

@interface LDAPResponse : LDAPOperation

@property (nonatomic,retain) LDAPRequest* request;
@property (nonatomic,retain) LDAPResult* result;
@end

@interface LDAPBindResponse : LDAPResponse
@end

@interface LDAPSearchDoneResponse : LDAPResponse
@end

@interface LDAPExtendedResponse : LDAPResponse
@property (nonatomic,retain) NSString* name;
@property (nonatomic,retain) NSString* value;
@end
