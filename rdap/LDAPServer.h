//
//  LDAPServer.h
//  rdap
//
//  Created by Furkan Mustafa on 10/5/13.
//  Copyright (c) 2013 fume. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SocketServer.h"
#import "LDAP/LDAP.h"



@class LDAPConnection;
@protocol LDAPConnectionDelegate <NSObject>

- (void)connection:(LDAPConnection*)connection didReceiveMessage:(LDAPMessageEnvelope*)message;
- (void)connection:(LDAPConnection*)connection didRaiseError:(NSError*)error;

@end

@interface LDAPServer : SocketServer <LDAPConnectionDelegate>

+ (LDAPServer*)sharedServer;

@property (nonatomic,retain) NSString* bindedDN;

@end

@interface LDAPConnection : SocketConnection

- (void)idleListen;
- (BOOL)sendMessageWith:(id)messageObj;
- (BOOL)sendMessage:(LDAPMessageEnvelope*)message;

@property (nonatomic,retain) NSMutableData* requestPayload;
@property (nonatomic,readwrite) NSInteger expectedLength;
@property (nonatomic,assign) id<LDAPConnectionDelegate> delegate;
@property (nonatomic,readwrite) NSUInteger sentMessageCount;

@end

LDAPServer* ldapServer;
