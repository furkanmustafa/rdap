//
//  main.m
//  rdap
//
//  Created by Furkan Mustafa on 10/5/13.
//  Copyright (c) 2013 fume. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LDAPServer.h"

void InterruptHandler(int signal);

int main(int argc, const char * argv[]) {

	@autoreleasepool {
	
		NSRunLoop* runloop = [NSRunLoop currentRunLoop];
		
		signal(SIGINT, &InterruptHandler);
		signal(SIGTERM, &InterruptHandler);
		signal(SIGKILL, &InterruptHandler);
		
		LDAPServer.sharedServer.port = 1389;
		[LDAPServer.sharedServer start];
		
		[runloop run];
		
	}
    return 0;
}

void InterruptHandler(int signal) {

	static BOOL gotSignal = NO;
	if (gotSignal) return;
	gotSignal = YES;

	NSLog(@"received signal");

	[LDAPServer.sharedServer stop];
	
}
