//
//  ACS3Client.m
//  OnSong
//
//  Created by Jason Kichline on 3/28/11.
//  Copyright 2011 andCulture. All rights reserved.
//

#import "ACS3Client.h"
#import "ASIS3ServiceRequest.h"
#import "ASIS3BucketRequest.h"
#import "ASIS3ObjectRequest.h"
#import "ASIS3BucketObject.h"

@implementation ACS3Client

@synthesize bucket, secure, accessKey, secretKey, delegate;

#pragma mark -
#pragma mark Initialization

-(id)init {
	self = [super init];
	if(self) {
		savePaths = [[NSMutableDictionary alloc] init];
	}
	return self;
}

-(id)initWithAccessKey:(NSString*)_accessKey secretKey:(NSString*)_secretKey {
	return [self initWithBucket:nil accessKey:_accessKey secretKey:_secretKey];
}

-(id)initWithBucket:(NSString*)_bucket accessKey:(NSString*)_accessKey secretKey:(NSString*)_secretKey {
	self = [self init];
	if(self) {
		self.bucket = _bucket;
		self.accessKey = _accessKey;
		self.secretKey = _secretKey;
	}
	return self;
}

+(ACS3Client*)clientWithAccessKey:(NSString*)_accessKey secretKey:(NSString*)_secretKey {
	return [[[self alloc] initWithAccessKey:_accessKey secretKey:_secretKey] autorelease];
}

+(ACS3Client*)clientWithBucket:(NSString*)_bucket accessKey:(NSString*)_accessKey secretKey:(NSString*)_secretKey {
	return [[[self alloc] initWithBucket:_bucket accessKey:_accessKey secretKey:_secretKey] autorelease];
}

#pragma mark -
#pragma mark Methods

-(void)createBucket:(NSString*)name {
	assert(name);
	ASIS3BucketRequest* request = [ASIS3BucketRequest PUTRequestWithBucket:name];
	request.requestScheme = (self.secure) ? @"https" : @"http";
	[request setAccessKey:self.accessKey];
	[request setSecretAccessKey:self.secretKey];
	[request setDelegate:self];
	[request setDidFinishSelector:@selector(createdBucket:)];
	[request setDidFailSelector:@selector(failed:)];
	[request startAsynchronous];
}

-(void)deleteBucket:(NSString*)name {
	assert(name);
	ASIS3BucketRequest* request = [ASIS3BucketRequest DELETERequestWithBucket:name];
	request.requestScheme = (self.secure) ? @"https" : @"http";
	[request setAccessKey:self.accessKey];
	[request setSecretAccessKey:self.secretKey];
	[request setDelegate:self];
	[request setDidFinishSelector:@selector(deletedBucket:)];
	[request setDidFailSelector:@selector(failed:)];
	[request startAsynchronous];
}

-(void)listObjects {
	[self listObjectsInBucket:nil];
}

-(void)listObjectsInBucket:(NSString*)_bucket {
	[self listObjectsInBucket:_bucket inDirectory:nil];
}

-(void)listObjectsInBucket:(NSString*)_bucket inDirectory:(NSString*)_directory {
	
	// If we have no bucket, use the default
	if(_bucket == nil) { _bucket = self.bucket; }
	assert(_bucket != nil);
	
	// Determine the prefix
	NSString* prefix = _directory;
	if(prefix == nil) { prefix = @""; }
	if([prefix hasPrefix:@"/"]) {
		prefix = [prefix substringFromIndex:1];
	}
	if([prefix hasSuffix:@"/"] == NO) {
		prefix = [NSString stringWithFormat:@"%@/", prefix];
	}
	if([prefix isEqualToString:@"/"]) {
		prefix = @"";
	}

	ASIS3BucketRequest* request = [ASIS3BucketRequest requestWithBucket:_bucket];
	request.requestScheme = (self.secure) ? @"https" : @"http";
	[request setAccessKey:self.accessKey];
	[request setSecretAccessKey:self.secretKey];
	[request setPrefix:prefix];
	[request setDelegate:self];
	[request setDidFinishSelector:@selector(retrievedObjects:)];
	[request setDidFailSelector:@selector(failed:)];
	[request startAsynchronous];
}

-(void)listBuckets {
	ASIS3ServiceRequest *request = [ASIS3ServiceRequest serviceRequest];
	request.requestScheme = (secure) ? @"https" : @"http";
	[request setAccessKey:self.accessKey];
	[request setSecretAccessKey:self.secretKey];
	[request setDelegate:self];
	[request setDidFinishSelector:@selector(retrievedBuckets:)];
	[request setDidFailSelector:@selector(failed:)];
	[request startAsynchronous];
}

-(void)downloadFile:(NSString*)_sourcePath toDestination:(NSString*)_destinationPath {
	[self downloadFile:_sourcePath toDestination:_destinationPath fromBucket:nil];
}

-(void)downloadFile:(NSString*)_sourcePath toDestination:(NSString*)_destinationPath fromBucket:(NSString*)_bucket {
	
	//Use the default bucket if we have one
	if(_bucket == nil) { _bucket = self.bucket; }
	assert(_bucket != nil);
	
	// Get the source path
	assert(_sourcePath != nil);
	if([_sourcePath hasPrefix:@"/"]) { _sourcePath = [_sourcePath substringFromIndex:1]; }
	
	// Append the file name to the destination
	assert(_destinationPath != nil);
	_destinationPath = [_destinationPath stringByAppendingPathComponent:[_sourcePath lastPathComponent]];
	
	// Generate the request and start it
	ASIS3ObjectRequest* request = [ASIS3ObjectRequest requestWithBucket:_bucket key:_sourcePath];
	request.requestScheme = (secure) ? @"https" : @"http";
	request.userInfo = [NSDictionary dictionaryWithObject:_destinationPath forKey:@"destinationPath"];
	[request setAccessKey:self.accessKey];
	[request setSecretAccessKey:self.secretKey];
	[request setDelegate:self];
	[request setDidFailSelector:@selector(failed:)];
	[request setDidFinishSelector:@selector(downloadedFile:)];
	[request startAsynchronous];
}

-(void)uploadFile:(NSString*)_sourcePath {
	[self uploadFile:_sourcePath toDestination:nil];
}

-(void)uploadFile:(NSString*)_sourcePath toDestination:(NSString*)_destinationPath {
	[self uploadFile:_sourcePath toDestination:_destinationPath inBucket:nil];
}

-(void)uploadFile:(NSString*)_sourcePath toDestination:(NSString*)_destinationPath inBucket:(NSString*)_bucket {
	
	// Use the default bucket if we have one
	if(_bucket == nil) { _bucket = self.bucket; }
	assert(_bucket != nil);
	assert(_sourcePath != nil);
	
	// Get the destination path
	if(_destinationPath == nil) { _destinationPath = @""; }
	if([_destinationPath hasPrefix:@"/"]) { _destinationPath = [_destinationPath substringFromIndex:1]; }
	_destinationPath = [_destinationPath stringByAppendingPathComponent:[_sourcePath lastPathComponent]];
	
	// Run the request
	ASIS3ObjectRequest* request = [ASIS3ObjectRequest PUTRequestForFile:_sourcePath withBucket:_bucket key:_destinationPath];
	request.requestScheme = (secure) ? @"https" : @"http";
	request.userInfo = [NSDictionary dictionaryWithObject:_sourcePath forKey:@"source"];
	[request setAccessKey:self.accessKey];
	[request setSecretAccessKey:self.secretKey];
	[request setDelegate:self];
	[request setDidFailSelector:@selector(failed:)];
	[request setDidFinishSelector:@selector(uploadedFile:)];
	[request startAsynchronous];
}

-(void)deleteFile:(NSString*)_filePath inBucket:(NSString*)_bucket {
	
	// Use the default bucket if we have one
	if(_bucket == nil) { _bucket = self.bucket; }
	assert(_bucket != nil);
	
	// Normalize the file path
	assert(_filePath != nil);
	if([_filePath hasPrefix:@"/"]) { _filePath = [_filePath substringFromIndex:1]; }
	
	// Generate the request and run it
	ASIS3ObjectRequest* request = [ASIS3ObjectRequest DELETERequestWithBucket:_bucket key:_filePath];
	request.requestScheme = (secure) ? @"https" : @"http";
	[request setAccessKey:self.accessKey];
	[request setSecretAccessKey:self.secretKey];
	[request setDelegate:self];
	[request setDidFailSelector:@selector(failed:)];
	[request setDidFinishSelector:@selector(deletedFile:)];
	[request startAsynchronous];
}

-(void)copyFile:(NSString*)_sourcePath toDestination:(NSString*)_destinationPath {
	[self copyFile:_sourcePath inBucket:nil toDestination:_destinationPath];
}

-(void)copyFile:(NSString*)_sourcePath inBucket:(NSString*)_sourceBucket toDestination:(NSString*)_destinationPath {
	[self copyFile:_sourcePath inBucket:_sourceBucket toDestination:_destinationPath bucket:_sourceBucket];
}

-(void)copyFile:(NSString*)_sourcePath inBucket:(NSString*)_sourceBucket toDestination:(NSString*)_destinationPath bucket:(NSString*)_destinationBucket {
	
	// Check that we have a source and destination
	assert(_sourcePath);
	assert(_destinationPath);
	
	// Use the default bucket if we have one
	if(_sourceBucket == nil) { _sourceBucket = self.bucket; }
	assert(_sourceBucket != nil);
	
	// If we don't have the destination bucket, use the source
	if(_destinationBucket == nil) { _destinationBucket = _sourceBucket; }

	// Generate the request and run it
	ASIS3ObjectRequest* request = [ASIS3ObjectRequest COPYRequestFromBucket:_sourceBucket key:_sourcePath toBucket:_destinationBucket key:_destinationPath];
	request.requestScheme = (secure) ? @"https" : @"http";
	[request setAccessKey:self.accessKey];
	[request setSecretAccessKey:self.secretKey];
	[request setDelegate:self];
	[request setDidFailSelector:@selector(failed:)];
	[request setDidFinishSelector:@selector(copiedFile:)];
	[request startAsynchronous];
}

-(void)makeDirectory:(NSString*)_named {
	[self makeDirectory:_named inParentDirectory:nil];
}

-(void)makeDirectory:(NSString*)_named inParentDirectory:(NSString*)_parentDirectory {
	[self makeDirectory:_named inParentDirectory:_parentDirectory inBucket:nil];
}

-(void)makeDirectory:(NSString*)_named inParentDirectory:(NSString*)_parentDirectory inBucket:(NSString*)_bucket {
	
	// Use the default bucket if we have one
	if(_bucket == nil) { _bucket = self.bucket; }
	assert(_bucket != nil);
	
	// Make sure we have a directory name
	assert(_named != nil);
	
	// Get the destination path
	if(_parentDirectory == nil) { _parentDirectory = @""; }
	if([_parentDirectory hasPrefix:@"/"]) { _parentDirectory = [_parentDirectory substringFromIndex:1]; }
	_parentDirectory = [_parentDirectory stringByAppendingPathComponent:[_named lastPathComponent]];
	
	// Create the dummy file key
	NSString* key = [_parentDirectory stringByAppendingString:@"_$folder$"];
	
	// Run the request
	ASIS3ObjectRequest* request = [ASIS3ObjectRequest PUTRequestForData:[NSData data] withBucket:_bucket key:key];
//	[ASIS3ObjectRequest PUTRequestForFile:[[NSBundle mainBundle] pathForResource:@"ACS3DummyFile" ofType:@"txt"] withBucket:_bucket key:key];
	request.requestScheme = (secure) ? @"https" : @"http";
	[request setAccessKey:self.accessKey];
	[request setSecretAccessKey:self.secretKey];
	[request setDelegate:self];
	[request setDidFailSelector:@selector(failed:)];
	[request setDidFinishSelector:@selector(createdDirectory:)];
	[request startAsynchronous];
}

-(void)removeDirectory:(NSString*)_path {
	[self removeDirectory:_path inBucket:nil];
}

-(void)removeDirectory:(NSString*)_path inBucket:(NSString*)_bucket {
	
	// If we have no bucket, use the default
	if(_bucket == nil) { _bucket = self.bucket; }
	
	// Determine the prefix
	NSString* prefix = _path;
	if([prefix hasPrefix:@"/"]) {
		prefix = [prefix substringFromIndex:1];
	}
	if([prefix hasSuffix:@"/"] == NO) {
		prefix = [NSString stringWithFormat:@"%@/", prefix];
	}
	if([prefix isEqualToString:@"/"]) {
		prefix = @"";
	}
	
	ASIS3BucketRequest* request = [ASIS3BucketRequest requestWithBucket:_bucket];
	request.userInfo = [NSDictionary dictionaryWithObject:_path forKey:@"path"];
	request.requestScheme = (self.secure) ? @"https" : @"http";
	[request setAccessKey:self.accessKey];
	[request setSecretAccessKey:self.secretKey];
	[request setPrefix:prefix];
	[request setDelegate:self];
	[request setDidFinishSelector:@selector(retrievedObjectsToRemove:)];
	[request setDidFailSelector:@selector(failed:)];
	[request startAsynchronous];
}

-(void)retrievedObjectToRemove:(ASIS3BucketRequest*)request {
	
	// Create the queue
	if(queue != nil) {
		[queue cancelAllOperations];
		[queue release];
	}
	queue = [[ASINetworkQueue queue] retain];
	[queue setUserInfo:[NSDictionary dictionaryWithObject:request.userInfo forKey:@"path"]];
	[queue setRequestDidFinishSelector:@selector(removedDirectory:)];
	[queue setRequestDidFailSelector:@selector(failed:)];
	
	// Delete all the files in the directory
	for(ASIS3BucketObject* object in [request objects]) {
		ASIS3ObjectRequest* request = [object DELETERequest];
		[queue addOperation:request];
	}
	[queue go];
}

#pragma mark -
#pragma mark Delegates

-(void)retrievedBuckets:(ASIS3ServiceRequest*)request {
	if(self.delegate != nil && [(NSObject*)self.delegate respondsToSelector:@selector(client:didListBuckets:)]) {
		[self.delegate client:self didListBuckets:[request buckets]];
	}
}

-(void)retrievedObjects:(ASIS3BucketRequest*)request {
	if(self.delegate != nil && [(NSObject*)self.delegate respondsToSelector:@selector(client:didListObjects:)]) {
		[self.delegate client:self didListObjects:[request objects]];
	}
}

-(void)downloadedFile:(ASIS3ObjectRequest*)request {
	NSString* destination = [request.userInfo objectForKey:@"destinationPath"];
	[[request responseData] writeToFile:destination atomically:YES];
	[savePaths removeObjectForKey:request.key];
	
	if(self.delegate != nil && [(NSObject*)self.delegate respondsToSelector:@selector(client:didDownloadFile:toPath:)]) {
		[self.delegate client:self didDownloadFile:[request key] toPath:destination];
	}
}

-(void)uploadedFile:(ASIS3ObjectRequest*)request {
	NSString* source = [request.userInfo objectForKey:@"source"];
	if(self.delegate != nil && [(NSObject*)self.delegate respondsToSelector:@selector(client:didUploadFile:toDestination:)]) {
		[self.delegate client:self didUploadFile:source toDestination:[request key]];
	}
}

-(void)deletedFile:(ASIS3ObjectRequest*)request {
	if(self.delegate != nil && [(NSObject*)self.delegate respondsToSelector:@selector(client:didDeleteFile:)]) {
		[self.delegate client:self didDeleteFile:[request key]];
	}
}

-(void)copiedFile:(ASIS3ObjectRequest*)request {
	if(self.delegate != nil && [(NSObject*)self.delegate respondsToSelector:@selector(client:didCopyFile:toDestination:)]) {
		[self.delegate client:self didCopyFile:[request sourceKey] toDestination:[request key]];
	}
}

-(void)createdDirectory:(ASIS3ObjectRequest*)request {
	if(self.delegate != nil && [(NSObject*)self.delegate respondsToSelector:@selector(client:didMakeDirectory:)]) {
		[self.delegate client:self didMakeDirectory:[request key]];
	}
}

-(void)removedDirectory:(ASIS3Request*)request {
	if(self.delegate != nil && [(NSObject*)self.delegate respondsToSelector:@selector(client:didRemoveDirectory:)]) {
		[self.delegate client:self didRemoveDirectory:[[queue userInfo] objectForKey:@"path"]];
	}
}

-(void)createdBucket:(ASIS3BucketRequest*)request {
	if(self.delegate != nil && [(NSObject*)self.delegate respondsToSelector:@selector(client:didCreateBucket:)]) {
		[self.delegate client:self didCreateBucket:[request bucket]];
	}
}

-(void)deletedBucket:(ASIS3BucketRequest*)request {
	if(self.delegate != nil && [(NSObject*)self.delegate respondsToSelector:@selector(client:didDeleteBucket:)]) {
		[self.delegate client:self didDeleteBucket:[request bucket]];
	}
}

-(void)failed:(id)request {
	if(self.delegate != nil && [(NSObject*)self.delegate respondsToSelector:@selector(client:didFailWithError:)] && [(NSObject*)request respondsToSelector:@selector(error)]) {
		[self.delegate client:self didFailWithError:[(NSObject*)request performSelector:@selector(error)]];
	} else {
		NSLog(@"%@", [[(NSObject*)request performSelector:@selector(error)] localizedDescription]);
	}
}

#pragma mark -
#pragma mark Memory management

-(void)dealloc {
	[(NSObject*)delegate release];
	[queue release];
	[bucket release];
	[accessKey release];
	[secretKey release];
	[savePaths release];
	[super dealloc];
}

@end
