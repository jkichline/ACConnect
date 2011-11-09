//
//  ACWebDAVUploadRequest.h
//  ACWebDAVTest
//
//  Created by Jason Kichline on 8/19/10.
//  Copyright 2010 Jason Kichline. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ACWebDAV.h"

@class ACWebDAVUploadRequest;

@protocol ACWebDAVUploadRequestDelegate

@optional

-(void)request:(ACWebDAVUploadRequest*)request didUpdateUploadProgress:(float)percent;
-(void)request:(ACWebDAVUploadRequest*)request didUploadItem:(ACWebDAVItem*)item;
-(void)request:(ACWebDAVUploadRequest*)request didFailWithErrorCode:(int)errorCode;
-(void)request:(ACWebDAVUploadRequest*)request didFailWithError:(NSError*)error;

@end


@interface ACWebDAVUploadRequest : NSObject {
	NSString* filepath;
	ACWebDAVLocation* location;
	id<ACWebDAVUploadRequestDelegate> delegate;
}

@property (nonatomic, retain) NSString* filepath;
@property (nonatomic, retain) id<ACWebDAVUploadRequestDelegate> delegate;
@property (nonatomic, retain) ACWebDAVLocation* location;

-(void)start;
-(NSString*)mimetypeForFile:(NSString*)filepath;
+(ACWebDAVUploadRequest*)requestToUploadFile:(NSString*)filepath toCollection:(ACWebDAVCollection*)collection delegate:(id<ACWebDAVUploadRequestDelegate>) delegate;

@end
