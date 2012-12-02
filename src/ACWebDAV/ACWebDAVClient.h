//
//  ACWebDAVClient.h
//  ACWebDAVTest
//
//  Created by Jason Kichline on 8/19/10.
//  Copyright 2010 Jason Kichline. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ACWebDAV.h"

@protocol ACWebDAVClientDelegate;

@interface ACWebDAVClient : NSObject <ACWebDAVPropertyRequestDelegate, ACWebDAVDownloadRequestDelegate, ACWebDAVUploadRequestDelegate, ACWebDAVMakeCollectionRequestDelegate, ACWebDAVDeleteRequestDelegate, ACWebDAVMoveRequestDelegate, ACWebDAVCopyRequestDelegate, ACWebDAVLockRequestDelegate, ACWebDAVUnlockRequestDelegate> {
	NSString* username;
	NSString* password;
	NSString* host;
    id<ACWebDAVClientDelegate> delegate;
}

@property (nonatomic, retain) NSString* username;
@property (nonatomic, retain) NSString* password;
@property (nonatomic, retain) NSString* host;
@property (nonatomic, retain) id<ACWebDAVClientDelegate> delegate;

/* Loads metadata for the object at the given root/path and returns the results to a delegate */
-(void)loadMetadata:(NSString*)href;

/* Loads the file and return the data */
-(void)downloadFileData:(NSString*)href;

/* Loads the file contents at the given root/path and stores the result into destinationPath */
-(void)downloadFile:(NSString*)href intoPath:(NSString *)destinationPath;

/* Uploads a file that will be named filename to the given path on the server. It will upload the contents of the file at sourcePath */
-(void)uploadFile:(NSString*)filename toPath:(NSString*)href fromPath:(NSString*)sourcePath;

/* Creates a folder at the given path */
-(void)createCollection:(NSString*)href;

/* Deletes the item at the given path */
-(void)deletePath:(NSString*)href;

/* Copies an item from the one path to the other */
-(void)copyFrom:(NSString*)fromHref toPath:(NSString *)toHref;
-(void)copyFrom:(NSString*)fromHref toPath:(NSString *)toHref overwrite:(BOOL)overwrite;

/* Moves an item from the one path to the other */
-(void)moveFrom:(NSString*)fromHref toPath:(NSString *)toHref;
-(void)moveFrom:(NSString*)fromHref toPath:(NSString *)toHref overwrite:(BOOL)overwrite;

/* Locks the collection or file at the given path */
-(void)lockPath:(NSString*)href;

/* Unlocks the collection or file at the given path */
-(void)unlockPath:(NSString*)href token:(NSString*)token;

/* Initializes the client */
-(id)initWithHost:(id)host;
-(id)initWithHost:(id)host username:(NSString*)username password:(NSString*)password;

/* Class methods */
+(ACWebDAVClient*)clientWithHost:(id)host;
+(ACWebDAVClient*)clientWithHost:(id)host username:(NSString*)username password:(NSString*)password;
+(ACWebDAVClient*)clientForMobileMeWithUsername:(NSString*)username password:(NSString*)password;

@end

/* Protocol declaration */

@protocol ACWebDAVClientDelegate <NSObject>

@optional

- (void)client:(ACWebDAVClient*)client failedWithError:(NSError*)error;
- (void)client:(ACWebDAVClient*)client failedWithErrorCode:(int)errorCode;

- (void)client:(ACWebDAVClient*)client loadedMetadata:(ACWebDAVItem*)item;
- (void)client:(ACWebDAVClient*)client loadMetadataFailedWithError:(NSError*)error;
- (void)client:(ACWebDAVClient*)client loadMetadataFailedWithErrorCode:(int)errorCode;

- (void)client:(ACWebDAVClient*)client downloadedFile:(NSString*)destPath;
- (void)client:(ACWebDAVClient*)client downloadedFileData:(NSData*)data;
//- (void)client:(ACWebDAVClient*)client downloadedFile:(NSString*)destPath contentType:(NSString*)contentType;
- (void)client:(ACWebDAVClient*)client downloadProgress:(CGFloat)progress forFile:(NSString*)destPath;
- (void)client:(ACWebDAVClient*)client downloadFileFailedWithError:(NSError*)error;

- (void)client:(ACWebDAVClient*)client uploadedFile:(NSString*)srcPath;
- (void)client:(ACWebDAVClient*)client uploadProgress:(CGFloat)progress forFile:(NSString*)srcPath;
- (void)client:(ACWebDAVClient*)client uploadFileFailedWithError:(NSError*)error;
- (void)client:(ACWebDAVClient*)client uploadFileFailedWithErrorCode:(int)errorCode;

- (void)client:(ACWebDAVClient*)client createdCollection:(ACWebDAVCollection*)collection;
- (void)client:(ACWebDAVClient*)client createCollectionFailedWithError:(NSError*)error;
- (void)client:(ACWebDAVClient*)client createCollectionFailedWithErrorCode:(int)errorCode;

- (void)client:(ACWebDAVClient*)client deletedPath:(NSString *)path;
- (void)client:(ACWebDAVClient*)client deletePathFailedWithError:(NSError*)error;
- (void)client:(ACWebDAVClient*)client deletePathFailedWithErrorCode:(int)errorCode;

- (void)client:(ACWebDAVClient*)client copiedPath:(NSString*)fromPath toPath:(NSString*)toPath;
- (void)client:(ACWebDAVClient*)client copyPathFailedWithError:(NSError*)error;
- (void)client:(ACWebDAVClient*)client copyPathFailedWithErrorCode:(int)errorCode;

- (void)client:(ACWebDAVClient*)client movedPath:(NSString*)fromPath toPath:(NSString*)toPath;
- (void)client:(ACWebDAVClient*)client movePathFailedWithError:(NSError*)error;
- (void)client:(ACWebDAVClient*)client movePathFailedWithErrorCode:(int)errorCode;

- (void)client:(ACWebDAVClient*)client lockPath:(NSString*)path;
- (void)client:(ACWebDAVClient*)client lockPathFailedWithError:(NSError*)error;
- (void)client:(ACWebDAVClient*)client lockPathFailedWithErrorCode:(int)errorCode;

- (void)client:(ACWebDAVClient*)client unlockPath:(NSString*)path;
- (void)client:(ACWebDAVClient*)client unlockPathFailedWithError:(NSError*)error;
- (void)client:(ACWebDAVClient*)client unlockPathFailedWithErrorCode:(int)errorCode;

@end