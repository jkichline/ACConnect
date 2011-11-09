//
//  ACWebDAVDeleteRequest.h
//  ACWebDAVTest
//
//  Created by Jason Kichline on 8/19/10.
//  Copyright 2010 Jason Kichline. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ACWebDAV.h"

@class ACWebDAVDeleteRequest;

@protocol ACWebDAVDeleteRequestDelegate

@optional

-(void)request:(ACWebDAVDeleteRequest*)request didDeleteItem:(ACWebDAVItem*)item;
-(void)request:(ACWebDAVDeleteRequest*)request didFailWithErrorCode:(int)errorCode;
-(void)request:(ACWebDAVDeleteRequest*)request didFailWithError:(NSError*)error;

@end

@interface ACWebDAVDeleteRequest : NSObject {
	ACWebDAVLocation* location;
	id<ACWebDAVDeleteRequestDelegate> delegate;
}

@property (nonatomic, retain) id<ACWebDAVDeleteRequestDelegate> delegate;
@property (nonatomic, retain) ACWebDAVLocation* location;

-(void)start;
+(ACWebDAVDeleteRequest*)requestToDeleteItem:(ACWebDAVItem*)item delegate:(id<ACWebDAVDeleteRequestDelegate>) delegate;

@end
