//
//  LDAPServer.m
//  rdap
//
//  Created by Furkan Mustafa on 10/5/13.
//  Copyright (c) 2013 fume. All rights reserved.
//

#import "LDAPServer.h"
#import "ber.h"
#import "LDAPRequest.h"
#import "LDAPResponse.h"

@implementation LDAPServer

- (void)dealloc {
	self.bindedDN = nil;
	[super dealloc];
}
+ (Class)connectionHandlerClass {
	return LDAPConnection.class;
}

+ (LDAPServer *)sharedServer {
	if (!ldapServer) {
		static dispatch_once_t onceToken;
		dispatch_once(&onceToken, ^{
			ldapServer = LDAPServer.new;
		});
	}
	return ldapServer;
}

- (void)connection:(LDAPConnection*)connection didReceiveMessage:(LDAPMessageEnvelope *)message {
	NSLog(@" # # # RECEIVED A MESSAGE : !!! %@", message);
	
	message.operation.application = self;
	message.operation.connection = connection;
	
	[self processRequest:(LDAPRequest*)message.operation];
}

- (void)connection:(LDAPConnection *)connection didRaiseError:(NSError *)error {
	[self connectionDone:connection withError:error];
}

#pragma mark - LDAP Application Level Functions
#pragma mark -

- (void)processRequest:(LDAPRequest*)request {
	if (request.type == LDAP_BindRequest) {
		[self processBindRequest:(LDAPBindRequest*)request];
		return;
	}
	
	if (request.type == LDAP_ExtendedRequest) {
		[self processExtendedRequest:(LDAPExtendedRequest*)request];
		return;
	}
	
	//	if (!self.bindedDN) {
	//		// NOT AUTHENTICATED, REFUSE FOR REQUESTS BELOW
	//	}
	
	if (request.type == LDAP_SearchRequest) {
		[self processSearchRequest:(LDAPSearchRequest*)request];
		return;
	}
}

#pragma mark Bind

- (BOOL)authenticateUsingDN:(NSString*)dn andPassword:(NSString*)password {
	return YES;
	return ([dn isEqualToString:@"cn=root"] && [password isEqualToString:@"secret"]);
}
- (BOOL)validateDN:(NSString*)dn {
	return YES;
}
- (LDAPNode*)getDN:(NSString*)dn {
	LDAPNode* node = LDAPNode.new;
	node.dn = dn;
	return [node autorelease];
}

- (void)processBindRequest:(LDAPBindRequest*)bindRequest {
	LDAPBindResponse* response = [LDAPBindResponse.new autorelease];
	
	if (bindRequest.protocolVersion != 3 || !bindRequest.dn) {
		// rfc4511 - 4.2. Bind Operation
		// If the server does not
		// support the specified version, it MUST respond with a BindResponse
		// where the resultCode is set to protocolError.
		response.result.resultCode = LDAPResult_protocolError;
		response.result.diagnosticMessage = @"Error";
		[bindRequest.connection sendMessage:response.envelope];
		return;
	}
	// rfc4513 - 5. Bind Operation
	// The server
	// MUST reject the Bind operation with an `invalidCredentials` resultCode
	// in the Bind response if the client is not so authorized.
	
	// rfc4513	5.1.1, no DN #1 and no Authentication #2, Anonymous bind.
	// rfc4513  5.1.2, only DN, no authentication ( The value is not to be
	//			used (directly or indirectly) for authorization purposes.)
	
	if (![self validateDN:bindRequest.dn]) {
		response.result.resultCode = LDAPResult_invalidDNSyntax;
		response.result.diagnosticMessage = @"Error";
		[bindRequest.connection sendMessage:response.envelope];
		return;
	}
	LDAPNode* node = [self getDN:bindRequest.dn];
	// maybe check existence of dn, and return `noSuchObject` even before checking auth.
	if (!node) {
		response.result.resultCode = LDAPResult_noSuchObject;
		response.result.diagnosticMessage = @"Error";
		[bindRequest.connection sendMessage:response.envelope];
		return;
	}

	response.result.matchedDN = bindRequest.dn;
	
	if (bindRequest.simpleAuthentication) {
		if ([self authenticateUsingDN:bindRequest.dn andPassword:bindRequest.simpleAuthentication]) {
			self.bindedDN = bindRequest.dn;
			response.result.resultCode = LDAPResult_success;
			[bindRequest.connection sendMessage:response.envelope];
			return;
		} else {
			response.result.resultCode = LDAPResult_invalidCredentials;
			response.result.diagnosticMessage = @"UserError";
			[bindRequest.connection sendMessage:response.envelope];
			return;
		}
	} else { //if (bindRequest.saslAuthentication) {
		response.result.resultCode = LDAPResult_authMethodNotSupported;
		response.result.diagnosticMessage = @"Error";
		[bindRequest.connection sendMessage:response.envelope];
		return;
	}
	
	response.result.matchedDN = nil;
	response.result.resultCode = LDAPResult_protocolError;
	[bindRequest.connection sendMessage:response.envelope];

	/*
	 A resultCode of `invalidDNSyntax` indicates that the DN sent in the
	 name value is syntactically invalid.  A resultCode of
	 `invalidCredentials` indicates that the DN is syntactically correct but
	 not valid for purposes of authentication, that the password is not
	 valid for the DN, or that the server otherwise considers the
	 credentials invalid.  A resultCode of `success` indicates that the
	 credentials are valid and that the server is willing to provide
	 service to the entity these credentials identify.
	 */
}

#pragma mark Extended

NSString* const ExtendedRequest_StartTLS = @"1.3.6.1.4.1.1466.20037";
- (void)processExtendedRequest:(LDAPExtendedRequest*)request {
	LDAPExtendedResponse* response = [LDAPExtendedResponse.new autorelease];
	response.request = request;
	
	// START TLS
	if ([request.name isEqualToString:ExtendedRequest_StartTLS]) {
		// OK
		response.name = [ExtendedRequest_StartTLS.copy autorelease];
		response.result.resultCode = LDAPResult_success;

//		__block LDAPExtendedRequest* connRequest = [[request retain] retain];
		[request.connection sendMessage:response.envelope completionBlock:^(BOOL wrote) {
			NSLog(@"Starting TLS Negotiation");
//			[request.connection.socket startTLS:nil];
		}];
		[request.connection.socket startTLS:@{
											  (NSString*)kCFStreamSSLAllowsExpiredCertificates: @(YES),
											  (NSString*)kCFStreamSSLAllowsAnyRoot: @(YES),
											  (NSString*)kCFStreamSSLValidatesCertificateChain: @(NO),
											  (NSString*)kCFStreamSSLIsServer: @(YES),
											  (NSString*)kCFStreamSSLPeerName: @"10.0.76.20",
											  (NSString*)kCFStreamSSLLevel: (NSString*)kCFStreamSocketSecurityLevelNegotiatedSSL //kCFStreamSocketSecurityLevelTLSv1
											  }];
		
		[request.connection.socket writeString:@"secure top"];
		
		return;
	}
	response.result.resultCode = LDAPResult_unwillingToPerform;
//	response.result.diagnosticMessage = @"Error";
	[request.connection sendMessage:response.envelope];
	return;
}

- (void)processSearchRequest:(LDAPSearchRequest*)request {
	
}

@end

#define LDAPIdleTimeout					60.0

#define LDAP_WaitingMessage				16
#define LDAP_WaitingMessageResize		17
#define LDAP_ReadingMessagePayload		32
#define LDAP_WritingMessage				15

@implementation LDAPConnection

- (void)dealloc {
	self.writeCompletionBlock = nil;
	self.requestPayload = nil;
	[super dealloc];
}
- (void)protocolError:(NSError*)error {
	// just close.
	[self.socket disconnect];
	self.socket = nil;
	[self.delegate connection:self didRaiseError:error];
}
- (void)idleListen {
	[self.socket readDataToLength:2 withTimeout:LDAPIdleTimeout tag:LDAP_WaitingMessage];;
}
- (void)onSocketDidSecure:(AsyncSocket *)sock {
	NSLog(@"Secured Connection, listening");
	[self.socket writeString:@"hey ssl, naber dostum??"];
//	[self idleListen];
}
- (void)onSocketDidConnect:(AsyncSocket *)sock {
	NSLog(@"New Connection");
	[self idleListen];
}
- (void)onSocket:(AsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
	uint8_t * bytes = (uint8_t *)data.bytes;
	if (tag==LDAP_WaitingMessage) {
		if (bytes[0]!=0x30) {
			[self protocolError:[NSError errorWithDomain:@"ldap" code:LDAPResult_protocolError
												userInfo:@{ NSLocalizedDescriptionKey: @"Invalid start signature" }]];
			return;
		}
		NSUInteger restLength = 0;
		if ((bytes[1] & 0x80) == 0x80) {
			restLength = bytes[1] & ~0x80;
			if (restLength > 4) {
				[self protocolError:[NSError errorWithDomain:@"ldap" code:LDAPResult_protocolError
													userInfo:@{ NSLocalizedDescriptionKey: @"Payload size too big :/" }]];
				return;
			}
			self.expectedLength = restLength;
			[sock readDataToLength:restLength withTimeout:LDAPIdleTimeout tag:LDAP_WaitingMessageResize];
			return;
		}
		restLength = bytes[1];
		self.expectedLength = restLength;
		self.requestPayload = [NSMutableData data];
		[sock readDataToLength:restLength withTimeout:LDAPIdleTimeout tag:LDAP_ReadingMessagePayload];
		return;
	}
	if (tag == LDAP_WaitingMessageResize) {
		if (data.length!=self.expectedLength) {
			[self protocolError:[NSError errorWithDomain:@"ldap" code:LDAPResult_protocolError
												userInfo:@{ NSLocalizedDescriptionKey: @"Payload size mismatch :/" }]];
			return;
		}
		uint8_t* sizePtr = (uint8_t*)data.bytes;
		uint32_t size = 0;
		NSUInteger i = data.length;
		do {
			size |= (*sizePtr & 0xFF);
			sizePtr++;
			i--;
			if ( i > 0 ) {
				size = size << 8;
			}
		} while (i > 0);
		// DONT KNOW IF THIS IS GOING TO WORK
		self.expectedLength = size;
		[sock readDataToLength:self.expectedLength withTimeout:LDAPIdleTimeout tag:LDAP_ReadingMessagePayload];
	}
	if (tag == LDAP_ReadingMessagePayload) {
		[self.requestPayload appendData:data];
		if (self.requestPayload.length == self.expectedLength) {
			NSLog(@"Received another Package : %@", self.requestPayload);
			LDAPMessageEnvelope* message = [LDAPMessageEnvelope withBERData:self.requestPayload];
			[self.delegate connection:self didReceiveMessage:message];
			self.requestPayload = nil;
		}
	}
}
//- (void)onSocket:(AsyncSocket *)sock didReadPartialDataOfLength:(NSUInteger)partialLength tag:(long)tag {}
- (BOOL)sendMessageWith:(id)messageObj {
	LDAPMessageEnvelope* envelope = nil;
	if ([messageObj isKindOfClass:NSData.class])
		envelope = [LDAPMessageEnvelope withBERData:messageObj];
	else if ([messageObj respondsToSelector:@selector(envelope)])
		envelope = [messageObj performSelector:@selector(envelope)];
	
	if (!envelope) return NO;
	
	return [self sendMessage:envelope];
}
- (BOOL)sendMessage:(LDAPMessageEnvelope*)message completionBlock:(void(^)(BOOL wrote))onComplete {
	if (!message.messageID || message.messageID == UINT32_MAX) {
		message.messageID = ++_sentMessageCount;
	}
	NSData* data = message.berData.berTransmissionData;
	if (!data) return NO;
	NSLog(@"Sending Message With Data : %@", data);
	[self.socket writeData:data withTimeout:LDAPIdleTimeout tag:LDAP_WritingMessage];
	self.writeCompletionBlock = onComplete;
	return YES;
}
- (BOOL)sendMessage:(LDAPMessageEnvelope*)message {
	return [self sendMessage:message completionBlock:nil];
}
- (void)onSocket:(AsyncSocket *)sock didWriteDataWithTag:(long)tag {
	if (tag==LDAP_WritingMessage) {
		if (self.writeCompletionBlock) {
			self.writeCompletionBlock(true);
			self.writeCompletionBlock = nil;
		} else {
			[self idleListen];
		}
	}
}

- (void)setServer:(id<SocketServer>)server {
	if ([server conformsToProtocol:@protocol(LDAPConnectionDelegate)])
		self.delegate = (id<LDAPConnectionDelegate>)server;
	[super setServer:server];
}

@end
