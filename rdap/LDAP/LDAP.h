//
//  LDAP.h
//  rdap
//
//  Created by Furkan Mustafa on 10/6/13.
//  Copyright (c) 2013 fume. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ber.h"

typedef enum {
	
	LDAPResult_success				= 0,
	LDAPResult_operationsError,
	LDAPResult_protocolError,
	LDAPResult_timeLimitExceeded,
	LDAPResult_sizeLimitExceeded,
	LDAPResult_compareFalse,
	LDAPResult_compareTrue,
	LDAPResult_authMethodNotSupported,
	LDAPResult_strongerAuthRequired,
	LDAPResult_Reserved9,
	LDAPResult_referral,
	LDAPResult_adminLimitExceeded,
	LDAPResult_unavailableCriticalExtension,
	LDAPResult_confidentialityRequired,
	LDAPResult_saslBindInProgress,
	LDAPResult_NA15,
	LDAPResult_noSuchAttribute,
	LDAPResult_undefinedAttributeType,
	LDAPResult_inappropriateMatching,
	LDAPResult_constraintViolation,
	LDAPResult_attributeOrValueExists,
	LDAPResult_invalidAttributeSyntax,
	/* 22-31 unused */
	LDAPResult_noSuchObject = 32,
	LDAPResult_aliasProblem,
	LDAPResult_invalidDNSyntax,
	LDAPResult_NA35, // -- 35 reserved for undefined isLeaf --
	LDAPResult_aliasDereferencingProblem,
	/* 37-47 unused */
	LDAPResult_inappropriateAuthentication = 48,
	LDAPResult_invalidCredentials,
	LDAPResult_insufficientAccessRights,
	LDAPResult_busy,
	LDAPResult_unavailable,
	LDAPResult_unwillingToPerform,
	LDAPResult_loopDetect,
	/* 55-63 unused */
	LDAPResult_namingViolation = 64,
	LDAPResult_objectClassViolation,
	LDAPResult_notAllowedOnNonLeaf,
	LDAPResult_notAllowedOnRDN,
	LDAPResult_entryAlreadyExists,
	LDAPResult_objectClassModsProhibited,
	LDAPResult_Reserved70, // -- 70 reserved for CLDAP --
	LDAPResult_affectsMultipleDSAs,
	/* 72-79 unused */
	LDAPResult_other = 80
	
} LDAPResultCode;

typedef enum {
	LDAP_BindRequest		= 0,
	LDAP_BindResponse		= 1,
	LDAP_UnbindRequest		= 2,
	LDAP_SearchRequest		= 3,
	
	LDAP_SearchResultEntry	= 4,
	LDAP_SearchResultDone	= 5,
	LDAP_SearchResultRef	= 19,
	
	LDAP_ModifyRequest		= 6,
	LDAP_ModifyResponse		= 7,
	LDAP_AddRequest			= 8,
	LDAP_AddResponse		= 9,
	LDAP_DelRequest			= 10,
	LDAP_DelResponse		= 11,
	LDAP_ModifyRDNRequest	= 12,
	LDAP_ModifyRDNResponse	= 13,
	LDAP_CompareRequest		= 14,
	LDAP_CompareResponse	= 15,
	LDAP_AbandonRequest		= 16,
	
	LDAP_ExtendedRequest	= 23,
	LDAP_ExtendedResponse	= 24,
	
	LDAP_IntermediateResponse	= 25

} LDAPProtocolOperation;


@class LDAPRequest, LDAPResponse, LDAPOperation;

@interface LDAPOID : NSString
@end

@interface LDAPDN : NSString
@end

@interface LDAPReferral : NSString <BEREncoding>
@end

extern NSString* const LDAPControl_altServer;
extern NSString* const LDAPControl_namingContexts;
extern NSString* const LDAPControl_supportedControl;
extern NSString* const LDAPControl_supportedExtension;
extern NSString* const LDAPControl_supportedFeatures;
extern NSString* const LDAPControl_supportedLDAPVersion;
extern NSString* const LDAPControl_supportedSASLMechanisms;

@interface LDAPControl : NSObject <BEREncoding>
@property (nonatomic,retain) LDAPOID* controlType;
@property (nonatomic,readwrite) BOOL criticality;
@property (nonatomic,copy) NSString* controlValue; // integer sequence
@end

@interface LDAPMessageEnvelope : NSObject <BEREncoding> {
	NSData* _data;
}

+ (instancetype)envelopeWithOperation:(LDAPOperation*)operation;

@property (nonatomic,readwrite) UInt32 messageID;
@property (nonatomic,retain) LDAPOperation* operation;
@property (nonatomic,retain) NSMutableArray* controls; // LDAPControl (optional)

@end

@interface LDAPResult : NSObject {
	
}

@property (nonatomic,readwrite) LDAPResultCode resultCode;
@property (nonatomic,retain) NSString* matchedDN;
@property (nonatomic,copy) NSString* diagnosticMessage;
@property (nonatomic,retain) LDAPReferral* referral;
@property (nonatomic,readonly) NSArray* payloadObjects;

@end

@class LDAPConnection;
@interface LDAPOperation : NSObject <BEREncoding>

+ (void)registerClass:(Class)class;
+ (id)operationWithType:(LDAPProtocolOperation)type;
+ (id)operationWithType:(LDAPProtocolOperation)type data:(NSData*)data;
- (LDAPMessageEnvelope*)envelope;

@property (nonatomic,readwrite) LDAPProtocolOperation type;
@property (nonatomic,retain) NSMutableArray* payloadObjects;
@property (nonatomic,readonly) BOOL isRequest;
@property (nonatomic,assign) id application;
@property (nonatomic,assign) LDAPConnection* connection;

@end

@interface LDAPNode : NSObject

@property (nonatomic,retain) NSString *dn;

@end

@interface SaslCredentials : NSObject <BEREncoding>
@property (nonatomic,retain) NSString* mechanism;
@property (nonatomic,retain) NSString* credentials;
@end
