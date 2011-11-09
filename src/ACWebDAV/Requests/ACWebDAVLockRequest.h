//
//  ACWebDAVLockRequest.h
//  ACWebDAVTest
//
//  Created by Jason Kichline on 8/20/10.
//  Copyright 2010 Jason Kichline. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ACWebDAV.h"

@class ACWebDAVLockRequest;

@protocol ACWebDAVLockRequestDelegate

@optional

-(void)request:(ACWebDAVLockRequest*)request itemWasLocked:(ACWebDAVItem*)item;
-(void)request:(ACWebDAVLockRequest*)request itemAlreadyLocked:(ACWebDAVItem*)item;
-(void)request:(ACWebDAVLockRequest*)request didFailWithErrorCode:(int)errorCode;
-(void)request:(ACWebDAVLockRequest*)request didFailWithError:(NSError*)error;

@end

@interface ACWebDAVLockRequest : NSObject {
	NSMutableData* data;
	ACWebDAVLocation* location;
	id<ACWebDAVLockRequestDelegate> delegate;
	BOOL recursive;
	BOOL exclusive;
	NSUInteger timeout;
	ACWebDAVItem* item;
	int statusCode;
}

@property (nonatomic, retain) id<ACWebDAVLockRequestDelegate> delegate;
@property (nonatomic, retain) ACWebDAVLocation* location;
@property (nonatomic, retain) ACWebDAVItem* item;
@property NSUInteger timeout;
@property BOOL recursive;
@property BOOL exclusive;

-(void)start;
-(NSData*)body;
+(ACWebDAVLockRequest*)requestToLockItem:(ACWebDAVItem*)item delegate:(id<ACWebDAVLockRequestDelegate>) delegate;

@end
