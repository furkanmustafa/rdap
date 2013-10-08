//
//  SocketServer.m
//  rdap
//
//  Created by Furkan Mustafa on 10/5/13.
//  Copyright (c) 2013 fume. All rights reserved.
//

#import "SocketServer.h"

@implementation SocketServer

- (void)dealloc {
    self.connections = nil;
	[self.socket disconnect];
	self.socket = nil;
	[super dealloc];
}
+ (Class)connectionHandlerClass {
	return SocketConnection.class;
}
- (void)start {
	done = NO;
	_runloop = [NSRunLoop currentRunLoop];
	
	NSLog(@"Starting runloop");
	if (![self listenOnPort:self.port]) {
		NSLog(@"Cannot listen on port : %d", self.port);
		return;
	}
    while (!done) {
		
		[_runloop runUntilDate:[NSDate dateWithTimeIntervalSinceNow:.05]];

    }
	NSLog(@"Stopped runloop");
	
}
- (void)stop {
	NSLog(@"Stopping runloop");
	done = YES;
}
- (BOOL)listenOnPort:(UInt16)port {
	AsyncSocket* newSocket = [AsyncSocket.alloc initWithDelegate:self];
	if (![newSocket acceptOnPort:port error:nil]) {
		newSocket.delegate = nil;
		[newSocket release];
		return NO;
	}
	return YES;
}
- (NSMutableArray *)connections {
	if (!_connections) {
		_connections = NSMutableArray.new;
	}
	return _connections;
}
- (void)onSocket:(AsyncSocket *)sock didAcceptNewSocket:(AsyncSocket *)newSocket {
	SocketConnection* newConnection = [self.class.connectionHandlerClass connectionWithSocket:newSocket];
	newConnection.server = self;
	[self.connections addObject:newConnection];
}
- (void)connectionDone:(SocketConnection*)connection {
	[self connectionDone:connection withError:nil];
}
- (void)connectionDone:(SocketConnection*)connection withError:(NSError*)error {
	[self.connections removeObject:connection];
	NSLog(@"A connection done.");
}

@end

@implementation SocketConnection

- (void)dealloc {
	self.socket.delegate = nil;
	[self.socket disconnect];
	self.socket = nil;
	[super dealloc];
}
+ (instancetype)connectionWithSocket:(AsyncSocket *)socket {
	SocketConnection* new = [self.class new];
	new.socket = socket;
	[new onSocketDidConnect:socket];
	return [new autorelease];
}

#pragma mark - Socket Handling

- (void)setSocket:(AsyncSocket *)socket {
	_socket.delegate = nil;
	[_socket autorelease];
	_socket = [socket retain];
	_socket.delegate = self;
}

- (void)sendLine:(NSString*)line {
	[self.socket writeString:[NSString stringWithFormat:@"%@\n", line]];
}
- (void)send:(NSData*)data {
	[self.socket writeData:data withTimeout:60 tag:0];
}
- (void)onSocketDidConnect:(AsyncSocket *)sock {
	NSLog(@"\tSocket Connected");
	[self sendLine:@"Welcome BITCH!"];
	[sock readDataWithTimeout:60.0 tag:0];
}
- (void)onSocket:(AsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
	NSLog(@"\tSocket Read Data: %@", data);
	NSLog(@"\t\tString: %@", [NSString.alloc initWithData:data encoding:NSASCIIStringEncoding].autorelease);
}
- (void)onSocketDidDisconnect:(AsyncSocket *)sock {
	NSLog(@"\tSocket Disconnected");
	self.socket = nil;
	[self.server connectionDone:self];
}

@end
