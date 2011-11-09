//
//  ACWebDAVUnlockRequest.h
//  ACWebDAVTest
//
//  Created by Jason Kichline on 8/20/10.
//  Copyright 2010 Jason Kichline. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ACWebDAV.h"

@class ACWebDAVUnlockRequest;

@protocol ACWebDAVUnlockRequestDelegate

@optional

-(void)request:(ACWebDAVUnlockRequest*)request didUnlockItem:(ACWebDAVItem*)item;
-(void)request:(ACWebDAVUnlockRequest*)request didFailWithErrorCode:(int)errorCode;
-(void)request:(ACWebDAVUnlockRequest*)request didFailWithError:(NSError*)error;

@end

@interface ACWebDAVUnlockRequest : NSObject {
	ACWebDAVLocation* location;
	id<ACWebDAVUnlockRequestDelegate> delegate;
	ACWebDAVItem* item;
}

@property (nonatomic, retain) id<ACWebDAVUnlockRequestDelegate> delegate;
@property (nonatomic, retain) ACWebDAVLocation* location;
@property (nonatomic, retain) ACWebDAVItem* item;

-(void)start;
+(ACWebDAVUnlockRequest*)requestToUnlockItem:(ACWebDAVItem*)item delegate:(id<ACWebDAVUnlockRequestDelegate>) delegate;

@end
