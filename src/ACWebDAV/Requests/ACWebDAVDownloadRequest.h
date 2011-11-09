//
//  ACWebDAVDownloadRequest.h
//  ACWebDAVTest
//
//  Created by Jason Kichline on 8/20/10.
//  Copyright 2010 Jason Kichline. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ACWebDAVLocation.h"
#import "ACWebDAVItem.h"

@class ACWebDAVDownloadRequest;

@protocol ACWebDAVDownloadRequestDelegate

@optional

-(void)requestDidStartDownload:(ACWebDAVDownloadRequest*)request;
-(void)request:(ACWebDAVDownloadRequest*)request didUpdateDownloadProgress:(float)percent;
-(void)request:(ACWebDAVDownloadRequest*)request didCompleteDownload:(NSData*)data;
-(void)request:(ACWebDAVDownloadRequest*)request didFailWithError:(NSError*)error;
-(void)request:(ACWebDAVDownloadRequest*)request didFailWithErrorCode:(int)errorCode;

@end


@interface ACWebDAVDownloadRequest : NSObject {
	long long contentLength;
	ACWebDAVLocation* location;
	id<ACWebDAVDownloadRequestDelegate> delegate;
	NSMutableData* data;
	NSDictionary* userInfo;
}

@property (nonatomic, retain) id<ACWebDAVDownloadRequestDelegate> delegate;
@property (nonatomic, retain) ACWebDAVLocation* location;
@property (nonatomic, retain) NSDictionary* userInfo;

-(void)start;
+(ACWebDAVDownloadRequest*)requestToDownloadItem:(ACWebDAVItem*)item delegate:(id<ACWebDAVDownloadRequestDelegate>) delegate;

@end
