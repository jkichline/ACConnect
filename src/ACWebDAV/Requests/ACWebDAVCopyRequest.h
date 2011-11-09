//
//  ACWebDAVCopyRequest.h
//  ACWebDAVTest
//
//  Created by Jason Kichline on 8/19/10.
//  Copyright 2010 Jason Kichline. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ACWebDAV.h"


@class ACWebDAVCopyRequest;

@protocol ACWebDAVCopyRequestDelegate

@optional

-(void)request:(ACWebDAVCopyRequest*)request didCopyItem:(ACWebDAVItem*)item;
-(void)request:(ACWebDAVCopyRequest*)request didFailWithErrorCode:(int)errorCode;
-(void)request:(ACWebDAVCopyRequest*)request didFailWithError:(NSError*)error;

@end

@interface ACWebDAVCopyRequest : NSObject {
	ACWebDAVLocation* location;
	id<ACWebDAVCopyRequestDelegate> delegate;
	ACWebDAVLocation* destination;
	BOOL overwrite;
}

@property (nonatomic, retain) id<ACWebDAVCopyRequestDelegate> delegate;
@property (nonatomic, retain) ACWebDAVLocation* location;
@property (nonatomic, retain) ACWebDAVLocation* destination;
@property BOOL overwrite;

-(void)start;

+(ACWebDAVCopyRequest*)requestToCopyItem:(ACWebDAVItem*)item toURL:(NSURL*)destination delegate:(id<ACWebDAVCopyRequestDelegate>) delegate;
+(ACWebDAVCopyRequest*)requestToCopyItem:(ACWebDAVItem*)item toLocation:(ACWebDAVLocation*)location delegate:(id<ACWebDAVCopyRequestDelegate>) delegate;

@end
