//
//  ACWebDAVMakeCollectionRequest.h
//  ACWebDAVTest
//
//  Created by Jason Kichline on 8/19/10.
//  Copyright 2010 Jason Kichline. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ACWebDAVLocation.h"
#import "ACWebDAVCollection.h"

@class ACWebDAVMakeCollectionRequest;

@protocol ACWebDAVMakeCollectionRequestDelegate

@optional

-(void)request:(ACWebDAVMakeCollectionRequest*)request didCreateCollection:(ACWebDAVCollection*)subcollection;
-(void)request:(ACWebDAVMakeCollectionRequest*)request didFailWithErrorCode:(int)errorCode;
-(void)request:(ACWebDAVMakeCollectionRequest*)request didFailWithError:(NSError*)error;

@end


@interface ACWebDAVMakeCollectionRequest : NSObject {
	ACWebDAVLocation* location;
	id<ACWebDAVMakeCollectionRequestDelegate> delegate;
}

@property (nonatomic, retain) id<ACWebDAVMakeCollectionRequestDelegate> delegate;
@property (nonatomic, retain) ACWebDAVLocation* location;

-(void)start;

+(ACWebDAVMakeCollectionRequest*)requestWithLocation:(ACWebDAVLocation *)location;
+(ACWebDAVMakeCollectionRequest*)requestToMakeCollectionNamed:(NSString*)named inParent:(ACWebDAVCollection*)parent delegate:(id) delegate;

@end
