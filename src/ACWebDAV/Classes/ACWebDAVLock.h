//
//  ACWebDAVLock.h
//  ACWebDAVTest
//
//  Created by Jason Kichline on 8/20/10.
//  Copyright 2010 Jason Kichline. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TouchXML.h"

@interface ACWebDAVLock : NSObject {
	BOOL exclusive;
	BOOL recursive;
	NSUInteger timeout;
	NSString* owner;
	NSString* token;
}

@property BOOL exclusive;
@property BOOL recursive;
@property NSUInteger timeout;
@property (nonatomic, retain) NSString* owner;
@property (nonatomic, retain) NSString* token;

+(ACWebDAVLock*)lockWithData:(NSData*)data;
+(ACWebDAVLock*)lockWithNode:(CXMLNode*)node;
+(ACWebDAVLock*)lockWithToken:(NSString*)token;

@end
