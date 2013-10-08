//
//  FMConsole.h
//  rdap
//
//  Created by Furkan Mustafa on 10/6/13.
//  Copyright (c) 2013 fume. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FMConsole : NSObject

@end

@protocol FMSocket <NSObject>

- (NSString*)readline;
- (NSData*)read;
- (NSData*)readBytes:(UInt32)bytes;

@end

@interface FMFileSource : NSObject <FMSocket>

@end

@interface FMNetSourceSource : NSObject <FMSocket>

@end
