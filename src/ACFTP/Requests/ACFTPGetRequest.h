//
//  FTPGetRequest.h
//  OnSong
//
//  Created by Jason Kichline on 3/23/11.
//  Copyright 2011 andCulture. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ACFTPLocation.h"
#import "ACFTPEntry.h"

@class ACFTPGetRequest;

@protocol ACFTPGetRequestDelegate

@optional

-(void)request:(ACFTPGetRequest*)request didDownloadFile:(NSURL*)sourceURL toDestination:(NSString*)destinationPath;
-(void)request:(ACFTPGetRequest*)request didFailWithError:(NSError*)error;
-(void)request:(ACFTPGetRequest*)request didUpdateStatus:(NSString*)status;
-(void)request:(ACFTPGetRequest*)request didUpdateProgress:(float)progress;
-(void)requestDidCancel:(ACFTPGetRequest*)request;

@end

@interface ACFTPGetRequest : NSObject <NSStreamDelegate> {
	id<ACFTPGetRequestDelegate> delegate;
	id source;
	NSString* destinationPath;
	int bytesDownloaded;
	int bytesTotal;
	NSInputStream* networkStream;
	NSOutputStream* fileStream;
	NSURL* sourceURL;
}

@property (nonatomic, retain) id<ACFTPGetRequestDelegate> delegate;
@property (nonatomic, retain) id source;
@property (nonatomic, retain) NSString* destinationPath;
@property (nonatomic, retain) NSInputStream* networkStream;
@property (nonatomic, retain) NSOutputStream* fileStream;
@property (nonatomic, retain) NSURL* sourceURL;

-(void)start;
-(void)cancel;
-(id)initWithSource:(id)source toDestination:(NSString*)destinationPath;
+(ACFTPGetRequest*)requestWithSource:(id)source toDestination:(NSString*)destinationPath;

@end
