//
//  LDAPServer.m
//  rdap
//
//  Created by Furkan Mustafa on 10/5/13.
//  Copyright (c) 2013 fume. All rights reserved.
//

#import "LDAPServer.h"
#import "ber.h"

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
	if (message.operation.type == LDAP_BindRequest) {
		LDAPOperation* response = [self responseForBindRequest:message.operation inMessage:message];
		[connection sendMessage:response.envelope];
	}
}
- (void)connection:(LDAPConnection *)connection didRaiseError:(NSError *)error {
	[self connectionDone:connection withError:error];
}

#pragma mark - 
#pragma mark LDAP Application Level Functions
#pragma mark -

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
- (LDAPOperation*)responseWithOperationType:(LDAPProtocolOperation)type withResult:(LDAPResult*)result {
	LDAPOperation* response = [LDAPOperation.new autorelease];
	response.type = LDAP_BindResponse;
	[response.payloadObjects addObjectsFromArray:result.payloadObjects];
	// also add sasl result, to the objects, when you start supporting it.
	return response;
}
- (LDAPOperation*)responseForBindRequest:(LDAPOperation*)bindRequest inMessage:(LDAPMessageEnvelope*)message {
	NSUInteger ldapVersion = [bindRequest.payloadObjects[0] integerValue];
	LDAPResult* result = [LDAPResult.new autorelease];
	result.diagnosticMessage = @"Hepiniz topsunuz";
	if (ldapVersion != 3 || bindRequest.payloadObjects.count < 3) {
		// rfc4511 - 4.2. Bind Operation
		// If the server does not
		// support the specified version, it MUST respond with a BindResponse
		// where the resultCode is set to protocolError.
		result.resultCode = LDAPResult_protocolError;
		return [self responseWithOperationType:LDAP_BindResponse withResult:result];
	}
	// rfc4513 - 5. Bind Operation
	// The server
	// MUST reject the Bind operation with an `invalidCredentials` resultCode
	// in the Bind response if the client is not so authorized.
	
	// rfc4513	5.1.1, no DN #1 and no Authentication #2, Anonymous bind.
	// rfc4513  5.1.2, only DN, no authentication ( The value is not to be
	//			used (directly or indirectly) for authorization purposes.)
	
	NSString* dn = bindRequest.payloadObjects[1];  // rfc4514 String Representation of Distinguished Names
	if (!dn || dn.length == 0 || ![self validateDN:dn]) {
		result.resultCode = LDAPResult_invalidDNSyntax;
		return [self responseWithOperationType:LDAP_BindResponse withResult:result];
	}
	LDAPNode* node = [self getDN:dn];
	// maybe check existence of dn, and return `noSuchObject` even before checking auth.
	if (!node) {
		result.resultCode = LDAPResult_noSuchObject;
		return [self responseWithOperationType:LDAP_BindResponse withResult:result];
	}

	result.matchedDN = dn;

	NSData* authentication = bindRequest.payloadObjects[2];
	
	if (authentication.berType & BER_Context) {
		NSUInteger choice = authentication.berType & ~BER_Context;
		if (choice == 0) { // OCTET STRING
			// widely used
			NSString* password = [NSString.alloc initWithData:authentication encoding:NSASCIIStringEncoding].autorelease;
			
			if ([self authenticateUsingDN:dn andPassword:password]) {
				self.bindedDN = dn;
				// result = `success`
				result.resultCode = LDAPResult_success;
				return [self responseWithOperationType:LDAP_BindResponse withResult:result];
			} else {
				// result = `invalidCredentials`
				result.resultCode = LDAPResult_invalidCredentials;
				return [self responseWithOperationType:LDAP_BindResponse withResult:result];
			}
			
		} else if (choice == 3) { // SASL
			// not used at all
			result.resultCode = LDAPResult_authMethodNotSupported;
			return [self responseWithOperationType:LDAP_BindResponse withResult:result];
		}
	}
	
	result.matchedDN = nil;
	result.resultCode = LDAPResult_protocolError;
	return [self responseWithOperationType:LDAP_BindResponse withResult:result];

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

@end

#define LDAPIdleTimeout					60.0

#define LDAP_WaitingMessage				16
#define LDAP_WaitingMessageResize		17
#define LDAP_ReadingMessagePayload		32
#define LDAP_WritingMessage				15

@implementation LDAPConnection

- (void)protocolError:(NSError*)error {
	// just close.
	[self.socket disconnect];
	self.socket = nil;
	[self.delegate connection:self didRaiseError:error];
}
- (void)idleListen {
	[self.socket readDataToLength:2 withTimeout:LDAPIdleTimeout tag:LDAP_WaitingMessage];;
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
- (BOOL)sendMessage:(LDAPMessageEnvelope*)message {
	if (!message.messageID || message.messageID == UINT32_MAX) {
		message.messageID = ++_sentMessageCount;
	}
	NSData* data = message.berData.berTransmissionData;
	if (!data) return NO;
	NSLog(@"Sending Message With Data : %@", data);
	[self.socket writeData:data withTimeout:LDAPIdleTimeout tag:LDAP_WritingMessage];
	return YES;
}
- (void)onSocket:(AsyncSocket *)sock didWriteDataWithTag:(long)tag {
	if (tag==LDAP_WritingMessage) {
		[self idleListen];
	}
}

- (void)setServer:(id<SocketServer>)server {
	if ([server conformsToProtocol:@protocol(LDAPConnectionDelegate)])
		self.delegate = (id<LDAPConnectionDelegate>)server;
	[super setServer:server];
}

@end
