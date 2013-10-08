//
//  SocketServer.h
//  rdap
//
//  Created by Furkan Mustafa on 10/5/13.
//  Copyright (c) 2013 fume. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AsyncSocket.h"

@class SocketConnection;
@protocol SocketServer <NSObject>
- (void)connectionDone:(SocketConnection*)connection;
- (void)connectionDone:(SocketConnection*)connection withError:(NSError*)error;
@end

@interface SocketServer : NSObject <AsyncSocketDelegate, SocketServer> {
	AsyncSocket* _socket;
	NSRunLoop* _runloop;
	UInt16 _port;
	NSMutableArray* _connections;
	
	BOOL done;
}

- (void)start;	// creates the runloop
- (void)stop;	// destroys the runloop
+ (Class)connectionHandlerClass;

@property (nonatomic, readwrite) UInt16 port;
@property (nonatomic, retain) NSMutableArray* connections;
@property (nonatomic,retain) AsyncSocket* socket;

@end

@interface SocketConnection : NSObject <AsyncSocketDelegate> {
	AsyncSocket* _socket;
}

+ (instancetype)connectionWithSocket:(AsyncSocket*)socket;

@property (nonatomic,retain) AsyncSocket* socket;
@property (nonatomic,assign) id<SocketServer> server;

@end

