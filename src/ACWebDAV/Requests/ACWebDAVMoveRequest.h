//
//  ACWebDAVMoveRequest.h
//  ACWebDAVTest
//
//  Created by Jason Kichline on 8/19/10.
//  Copyright 2010 Jason Kichline. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ACWebDAV.h"

@class ACWebDAVMoveRequest;

@protocol ACWebDAVMoveRequestDelegate

@optional

-(void)request:(ACWebDAVMoveRequest*)request didMoveItem:(ACWebDAVItem*)item;
-(void)request:(ACWebDAVMoveRequest*)request didFailWithErrorCode:(int)errorCode;
-(void)request:(ACWebDAVMoveRequest*)request didFailWithError:(NSError*)error;

@end

@interface ACWebDAVMoveRequest : NSObject {
	ACWebDAVLocation* location;
	id<ACWebDAVMoveRequestDelegate> delegate;
	ACWebDAVLocation* destination;
	BOOL overwrite;
}

@property (nonatomic, retain) id<ACWebDAVMoveRequestDelegate> delegate;
@property (nonatomic, retain) ACWebDAVLocation* location;
@property (nonatomic, retain) ACWebDAVLocation* destination;
@property BOOL overwrite;

-(void)start;

+(ACWebDAVMoveRequest*)requestToMoveItem:(ACWebDAVItem*)item toURL:(NSURL*)destination delegate:(id<ACWebDAVMoveRequestDelegate>) delegate;
+(ACWebDAVMoveRequest*)requestToMoveItem:(ACWebDAVItem*)item toLocation:(ACWebDAVLocation*)location delegate:(id<ACWebDAVMoveRequestDelegate>) delegate;

@end
