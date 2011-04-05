//
//  FTPClient.h
//  OnSong
//
//  Created by Jason Kichline on 3/23/11.
//  Copyright 2011 andCulture. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ACFTPLocation.h"
#import "ACFTPListRequest.h"
#import "ACFTPGetRequest.h"
#import "ACFTPPutRequest.h"
#import "ACFTPMakeDirectoryRequest.h"
#import "ACFTPDeleteFileRequest.h"

@class ACFTPClient;

@protocol ACFTPClientDelegate

@optional

-(void)client:(ACFTPClient*)client request:(id)request didListEntries:(NSArray*)entries;
-(void)client:(ACFTPClient*)client request:(id)request didUpdateProgress:(float)progress;
-(void)client:(ACFTPClient*)client request:(id)request didDownloadFile:(NSURL*)sourceURL toDestination:(NSString*)destinationPath;
-(void)client:(ACFTPClient*)client request:(id)request didUploadFile:(NSString*)sourcePath toDestination:(NSURL*)destination;
-(void)client:(ACFTPClient*)client request:(id)request didMakeDirectory:(NSURL*)destination;
-(void)client:(ACFTPClient*)client request:(id)request didDeleteFile:(NSURL*)fileURL;

-(void)client:(ACFTPClient*)client request:(id)request didFailWithError:(NSError*)error;
-(void)client:(ACFTPClient*)client request:(id)request didUpdateStatus:(NSString*)status;
-(void)client:(ACFTPClient*)client requestDidCancel:(id)request;

@end


@interface ACFTPClient : NSObject <ACFTPListRequestDelegate, ACFTPGetRequestDelegate, ACFTPPutRequestDelegate, ACFTPMakeDirectoryRequestDelegate, ACFTPDeleteFileRequestDelegate> {
	NSMutableArray* requests;
	ACFTPLocation* location;
	id<ACFTPClientDelegate> delegate;
}

@property (nonatomic, retain) ACFTPLocation* location;
@property (nonatomic, retain) id<ACFTPClientDelegate> delegate;

-(id)initWithHost:(id)host username:(NSString*)username password:(NSString*)password;
-(id)initWithLocation:(ACFTPLocation*)location;

+(ACFTPClient*)clientWithHost:(id)host username:(NSString*)username password:(NSString*)password;
+(ACFTPClient*)clientWithLocation:(ACFTPLocation*)location;

-(void)list:(NSString*)path;
-(void)get:(NSString*)sourcePath toDestination:(NSString*)destinationPath;
-(void)put:(NSString*)sourcePath toDestination:(NSString*)destinationPath;
-(void)makeDirectory:(NSString*)named inParentDirectory:(NSString*)parentDirectory;
-(void)deleteFile:(NSString*)filePath;

@end
