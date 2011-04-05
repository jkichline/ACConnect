//
//  ACS3Client.h
//  OnSong
//
//  Created by Jason Kichline on 3/28/11.
//  Copyright 2011 andCulture. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ASINetworkQueue.h"

@class ACS3Client;

@protocol ACS3ClientDelegate

@optional

-(void)client:(ACS3Client*)client didCreateBucket:(NSString*)name;
-(void)client:(ACS3Client*)client didDeleteBucket:(NSString*)name;

-(void)client:(ACS3Client*)client didListBuckets:(NSArray*)buckets;
-(void)client:(ACS3Client*)client didListObjects:(NSArray*)objects;
-(void)client:(ACS3Client*)client didDownloadFile:(NSString*)key toPath:(NSString*)filePath;
-(void)client:(ACS3Client*)client didUploadFile:(NSString*)sourcePath toDestination:(NSString*)key;
-(void)client:(ACS3Client*)client didDeleteFile:(NSString*)key;
-(void)client:(ACS3Client*)client didCopyFile:(NSString*)key toDestination:(NSString*)destination;

-(void)client:(ACS3Client*)client didMakeDirectory:(NSString*)directoryPath;
-(void)client:(ACS3Client*)client didRemoveDirectory:(NSString*)directoryPath;

-(void)client:(ACS3Client*)client didFailWithError:(NSError*)error;
-(void)client:(ACS3Client*)clientDidCancel:(id)request;

@end

@interface ACS3Client : NSObject {
	id<ACS3ClientDelegate> delegate;
	NSString* bucket;
	BOOL secure;
	NSString* accessKey;
	NSString* secretKey;
	NSMutableDictionary* savePaths;
	ASINetworkQueue* queue;
}

@property (nonatomic, retain) id<ACS3ClientDelegate> delegate;
@property (nonatomic, retain) NSString* accessKey;
@property (nonatomic, retain) NSString* secretKey;
@property (nonatomic, retain) NSString* bucket;
@property BOOL secure;

-(id)initWithAccessKey:(NSString*)accessKey secretKey:(NSString*)secretKey;
-(id)initWithBucket:(NSString*)host accessKey:(NSString*)accessKey secretKey:(NSString*)secretKey;

+(ACS3Client*)clientWithAccessKey:(NSString*)accessKey secretKey:(NSString*)secretKey;
+(ACS3Client*)clientWithBucket:(NSString*)host accessKey:(NSString*)accessKey secretKey:(NSString*)secretKey;

-(void)listBuckets;
-(void)createBucket:(NSString*)name;
-(void)deleteBucket:(NSString*)name;

-(void)listObjects;
-(void)listObjectsInBucket:(NSString*)bucket;
-(void)listObjectsInBucket:(NSString*)bucket inDirectory:(NSString*)directory;

-(void)downloadFile:(NSString*)_sourcePath toDestination:(NSString*)_destinationPath;
-(void)downloadFile:(NSString*)sourcePath toDestination:(NSString*)destinationPath fromBucket:(NSString*)bucket;

-(void)uploadFile:(NSString*)_sourcePath;
-(void)uploadFile:(NSString*)_sourcePath toDestination:(NSString*)_destinationPath;
-(void)uploadFile:(NSString*)sourcePath toDestination:(NSString*)destinationPath inBucket:(NSString*)bucket;

-(void)makeDirectory:(NSString*)named;
-(void)makeDirectory:(NSString*)named inParentDirectory:(NSString*)parentDirectory;
-(void)makeDirectory:(NSString*)named inParentDirectory:(NSString*)parentDirectory inBucket:(NSString*)bucket;

-(void)removeDirectory:(NSString*)path;
-(void)removeDirectory:(NSString*)path inBucket:(NSString*)bucket;

-(void)deleteFile:(NSString*)filePath inBucket:(NSString*)bucket;

-(void)copyFile:(NSString*)sourcePath toDestination:(NSString*)destinationPath;
-(void)copyFile:(NSString*)sourcePath inBucket:(NSString*)bucket toDestination:(NSString*)destinationPath;
-(void)copyFile:(NSString*)sourcePath inBucket:(NSString*)sourceBucket toDestination:(NSString*)destinationPath bucket:(NSString*)destinationBucket;

@end
