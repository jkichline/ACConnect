//
//  FTPMakeDirectoryRequest.h
//  OnSong
//
//  Created by Jason Kichline on 3/24/11.
//  Copyright 2011 andCulture. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ACFTPMakeDirectoryRequest;

@protocol ACFTPMakeDirectoryRequestDelegate

@optional

-(void)request:(ACFTPMakeDirectoryRequest*)request didMakeDirectory:(NSURL*)directoryURL;
-(void)request:(ACFTPMakeDirectoryRequest*)request didFailWithError:(NSError*)error;
-(void)request:(ACFTPMakeDirectoryRequest*)request didUpdateStatus:(NSString*)status;
-(void)requestDidCancel:(ACFTPMakeDirectoryRequest*)request;

@end

@interface ACFTPMakeDirectoryRequest : NSObject <NSStreamDelegate> {
	NSOutputStream* networkStream;
	NSURL* directoryURL;
	NSString* name;
	id parentDirectory;
	id<ACFTPMakeDirectoryRequestDelegate> delegate;
}

@property (nonatomic, retain) NSOutputStream* networkStream;
@property (nonatomic, retain) id<ACFTPMakeDirectoryRequestDelegate> delegate;
@property (nonatomic, retain) NSString* name;
@property (nonatomic, retain) NSURL* directoryURL;
@property (nonatomic, retain) id parentDirectory;

-(void)start;
-(void)cancel;
-(id)initWithDirectoryNamed:(NSString*)name inParentDirectory:(id)parentDirectory;
+(ACFTPMakeDirectoryRequest*)requestWithDirectoryNamed:(NSString*)name inParentDirectory:(id)parentDirectory;

@end
