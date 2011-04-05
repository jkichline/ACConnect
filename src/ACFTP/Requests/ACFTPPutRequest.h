//
//  FTPPutRequest.h
//  OnSong
//
//  Created by Jason Kichline on 3/23/11.
//  Copyright 2011 andCulture. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ACFTPEntry.h"
#include <CFNetwork/CFNetwork.h>

enum {
    kSendBufferSize = 32768
};

@class ACFTPPutRequest;

@protocol ACFTPPutRequestDelegate

@optional

-(void)request:(ACFTPPutRequest*)request didUploadFile:(NSString*)sourcePath toDestination:(NSURL*)destination;
-(void)request:(ACFTPPutRequest*)request didFailWithError:(NSError*)error;
-(void)request:(ACFTPPutRequest*)request didUpdateStatus:(NSString*)status;
-(void)request:(ACFTPPutRequest*)request didUpdateProgress:(float)progress;
-(void)requestDidCancel:(ACFTPPutRequest*)request;

@end

@interface ACFTPPutRequest : NSObject <NSStreamDelegate> {
	id<ACFTPPutRequestDelegate> delegate;
	
	NSOutputStream*	networkStream;
    NSInputStream* fileStream;
    uint8_t buffer[kSendBufferSize];
    size_t bufferOffset;
    size_t bufferLimit;
	int bytesUploaded;
	int bytesTotal;
	
	NSString* sourcePath;
	id destination;
	NSURL* destinationURL;
}


@property (nonatomic, retain) id<ACFTPPutRequestDelegate> delegate;
@property (nonatomic, retain) NSString* sourcePath;
@property (nonatomic, retain) id destination;

@property (nonatomic, retain) NSOutputStream* networkStream;
@property (nonatomic, retain) NSInputStream* fileStream;
@property (nonatomic, readonly) uint8_t* buffer;
@property size_t bufferOffset;
@property size_t bufferLimit;
@property (nonatomic, retain) NSURL* destinationURL;

-(void)start;
-(void)cancel;
-(id)initWithSource:(NSString*)sourcePath toDestination:(id)destination;
+(ACFTPPutRequest*)requestWithSource:(NSString*)sourcePath toDestination:(id)destination;

@end
