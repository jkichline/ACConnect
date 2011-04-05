//
//  ACWebDAVClient.m
//  ACWebDAVTest
//
//  Created by Jason Kichline on 8/19/10.
//  Copyright 2010 andCulture. All rights reserved.
//

#import "ACWebDAVClient.h"


@implementation ACWebDAVClient

@synthesize username, password, host, delegate;

#pragma mark -
#pragma mark Contructors

-(id)initWithHost:(id)_host {
	return [self initWithHost:_host username:nil password:nil];
}

+(ACWebDAVClient*)clientWithHost:(id)host {
	return [[[self alloc] initWithHost:host] autorelease];
}

-(id)initWithHost:(id)_host username:(NSString*)_username password:(NSString*)_password {
	if(self = [super init]) {
		self.host = _host;
		self.username = _username;
		self.password = _password;
	}
	return self;
}

+(ACWebDAVClient*)clientWithHost:(id)host username:(NSString*)username password:(NSString*)password {
	return [[[self alloc] initWithHost:host username:username password:password] autorelease];
}

+(ACWebDAVClient*)clientForMobileMeWithUsername:(NSString *)_username password:(NSString *)_password {
	_username = [[_username componentsSeparatedByString:@"@"] objectAtIndex:0];
	return [self clientWithHost:[@"http://idisk.mac.com/" stringByAppendingString:_username] username:_username password:_password];
}

#pragma mark -
#pragma mark Properties

-(void)setHost:(NSString*)value {
	if([value isKindOfClass:[NSURL class]]) {
		value = [(NSURL*)value absoluteString];
	}
	value = [value stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"\t\n /"]];
	if(value != host) {
		[value retain];
		[host release];
		host = value;
	}
}

#pragma mark -
#pragma mark Client Methods

-(void)loadMetadata:(NSString*)href {
	ACWebDAVLocation* location = [ACWebDAVLocation locationWithHost:self.host href:href username:self.username password:self.password];
	ACWebDAVPropertyRequest* request = [ACWebDAVPropertyRequest requestWithLocation:location];
	request.depth = 1;
	request.delegate = self;
	[request start];
}

-(void)downloadFile:(NSString*)href intoPath:(NSString*)destinationPath {
	ACWebDAVLocation* location = [ACWebDAVLocation locationWithHost:self.host href:href username:self.username password:self.password];
	ACWebDAVDownloadRequest* request = [ACWebDAVDownloadRequest requestToDownloadItem:[ACWebDAVItem itemWithLocation:location] delegate:self];
	request.userInfo = [NSDictionary dictionaryWithObject:destinationPath forKey:@"destinationPath"];
	[request start];	
}

-(void)downloadFileData:(NSString*)href {
	ACWebDAVLocation* location = [ACWebDAVLocation locationWithHost:self.host href:href username:self.username password:self.password];
	ACWebDAVDownloadRequest* request = [ACWebDAVDownloadRequest requestToDownloadItem:[ACWebDAVItem itemWithLocation:location] delegate:self];
	[request start];
}

-(void)uploadFile:(NSString*)filename toPath:(NSString*)href fromPath:(NSString*)sourcePath {
	ACWebDAVLocation* location = [ACWebDAVLocation locationWithHost:self.host href:href username:self.username password:self.password];
	ACWebDAVUploadRequest* request = [ACWebDAVUploadRequest requestToUploadFile:filename toCollection:(ACWebDAVCollection*)[ACWebDAVItem itemWithLocation:location] delegate:self];
	request.filepath = sourcePath;
	request.delegate = self;
	[request start];
}

-(void)createCollection:(NSString*)href {
	if([href hasSuffix:@"/"]) {
		href = [href substringToIndex:href.length-1];
	}
	ACWebDAVLocation* location = [ACWebDAVLocation locationWithHost:self.host href:href username:self.username password:self.password];
	ACWebDAVMakeCollectionRequest* request = [ACWebDAVMakeCollectionRequest requestWithLocation:location];
	request.delegate = self;
	[request start];
}

-(void)deletePath:(NSString*)href {
	ACWebDAVLocation* location = [ACWebDAVLocation locationWithHost:self.host href:href username:self.username password:self.password];
	ACWebDAVDeleteRequest* request = [ACWebDAVDeleteRequest requestToDeleteItem:[ACWebDAVItem itemWithLocation:location] delegate:self];
	[request start];
}

-(void)copyFrom:(NSString*)fromHref toPath:(NSString*)toHref {
	return [self copyFrom:fromHref toPath:toHref overwrite:NO];
}

-(void)copyFrom:(NSString*)fromHref toPath:(NSString*)toHref overwrite:(BOOL)overwrite {
	ACWebDAVLocation* location = [ACWebDAVLocation locationWithHost:self.host href:fromHref username:self.username password:self.password];
	ACWebDAVLocation* destination = [ACWebDAVLocation locationWithHost:self.host href:toHref username:self.username password:self.password];
	ACWebDAVCopyRequest* request = [ACWebDAVCopyRequest requestToCopyItem:[ACWebDAVItem itemWithLocation:location] toLocation:destination delegate:self];
	[request start];
}

-(void)moveFrom:(NSString*)fromHref toPath:(NSString*)toHref {
	return [self moveFrom:fromHref toPath:toHref overwrite:NO];
}

-(void)moveFrom:(NSString*)fromHref toPath:(NSString*)toHref overwrite:(BOOL)overwrite {
	ACWebDAVLocation* location = [ACWebDAVLocation locationWithHost:self.host href:fromHref username:self.username password:self.password];
	ACWebDAVLocation* destination = [ACWebDAVLocation locationWithHost:self.host href:toHref username:self.username password:self.password];
	ACWebDAVMoveRequest* request = [ACWebDAVMoveRequest requestToMoveItem:[ACWebDAVItem itemWithLocation:location] toLocation:destination delegate:self];
	[request start];
}

-(void)lockPath:(NSString *)href {
	ACWebDAVLocation* location = [ACWebDAVLocation locationWithHost:self.host href:href username:self.username password:self.password];
	ACWebDAVItem* item = [ACWebDAVItem itemWithLocation:location];
	ACWebDAVLockRequest* request = [ACWebDAVLockRequest requestToLockItem:item delegate:self];
	[request start];
}

-(void)unlockPath:(NSString *)href token:(NSString*)token {
	ACWebDAVLocation* location = [ACWebDAVLocation locationWithHost:self.host href:href username:self.username password:self.password];
	ACWebDAVItem* item = [ACWebDAVItem itemWithLocation:location];
	item.lock = [ACWebDAVLock lockWithToken:token];
	ACWebDAVUnlockRequest* request = [ACWebDAVUnlockRequest requestToUnlockItem:item delegate:self];
	[request start];
}

#pragma mark -
#pragma mark Delegate Handlers

-(void)request:(ACWebDAVPropertyRequest*)request didReturnItems:(NSArray*)items {
	if([self.delegate respondsToSelector:@selector(client:loadedMetadata:)]) {
		if(items == nil || items.count < 1) {
			[self.delegate client:self loadedMetadata:nil];
		} else {
			[self.delegate client:self loadedMetadata:[items objectAtIndex:0]];
		}
	}
}

-(void)request:(ACWebDAVDownloadRequest*)request didUpdateDownloadProgress:(float)percent {
	if([self.delegate respondsToSelector:@selector(client:downloadProgress:forFile:)]) {
		[self.delegate client:self downloadProgress:percent forFile:[request.userInfo objectForKey:@"destinationPath"]];
	}
}

-(void)request:(ACWebDAVDownloadRequest*)request didCompleteDownload:(NSData*)data {
	NSString* path = [request.userInfo objectForKey:@"destinationPath"];
	if(path == nil) {
		if([self.delegate respondsToSelector:@selector(client:downloadedFileData:)]) {
			[self.delegate client:self downloadedFileData:data];
		}
	} else {
		[data writeToFile:path atomically:YES];
		if([self.delegate respondsToSelector:@selector(client:downloadedFile:)]) {
			[self.delegate client:self downloadedFile:path];
		}
	}
}

-(void)request:(ACWebDAVUploadRequest*)request didUpdateUploadProgress:(float)percent {
	if([self.delegate respondsToSelector:@selector(client:uploadProgress:forFile:)]) {
		[self.delegate client:self uploadProgress:percent forFile:request.filepath];
	}
}

-(void)request:(ACWebDAVUploadRequest*)request didUploadItem:(ACWebDAVItem*)item {
	if([self.delegate respondsToSelector:@selector(client:uploadedFile:)]) {
		[self.delegate client:self uploadedFile:request.filepath];
	}
}

-(void)request:(ACWebDAVMakeCollectionRequest*)request didCreateCollection:(ACWebDAVCollection*)subcollection {
	if([self.delegate respondsToSelector:@selector(client:createdCollection:)]) {
		[self.delegate client:self createdCollection:subcollection];
	}
}

-(void)request:(ACWebDAVDeleteRequest*)request didDeleteItem:(ACWebDAVItem*)item {
	if([self.delegate respondsToSelector:@selector(client:deletedPath:)]) {
		[self.delegate client:self deletedPath:item.href];
	}
}

-(void)request:(ACWebDAVMoveRequest*)request didMoveItem:(ACWebDAVItem*)item {
	if([self.delegate respondsToSelector:@selector(client:movedPath:toPath:)]) {
		[self.delegate client:self movedPath:request.location.href toPath:request.destination.href];
	}
}

-(void)request:(ACWebDAVCopyRequest*)request didCopyItem:(ACWebDAVItem*)item {
	if([self.delegate respondsToSelector:@selector(client:copiedPath:toPath:)]) {
		[self.delegate client:self copiedPath:request.location.href toPath:request.destination.href];
	}
}

-(void)request:(id)request didFailWithErrorCode:(int)errorCode {
	NSLog(@"Error encountered in ACWebDAV client: %d", errorCode);
	
	if([self.delegate respondsToSelector:@selector(client:failedWithErrorCode:)]) {
		[self.delegate client:self failedWithErrorCode:errorCode];
	}

	if([request isKindOfClass:[ACWebDAVPropertyRequest class]]) {
		if([self.delegate respondsToSelector:@selector(client:loadMetadataFailedWithErrorCode:)]) {
			[self.delegate client:self loadMetadataFailedWithErrorCode:errorCode];
		}
		return;
	}
	if([request isKindOfClass:[ACWebDAVUploadRequest class]]) {
		if([self.delegate respondsToSelector:@selector(client:uploadFileFailedWithErrorCode:)]) {
			[self.delegate client:self uploadFileFailedWithErrorCode:errorCode];
		}
		return;
	}
	if([request isKindOfClass:[ACWebDAVMakeCollectionRequest class]]) {
		if([self.delegate respondsToSelector:@selector(client:createCollectionFailedWithErrorCode:)]) {
			[self.delegate client:self createCollectionFailedWithErrorCode:errorCode];
		}
		return;
	}
	if([request isKindOfClass:[ACWebDAVDeleteRequest class]]) {
		if([self.delegate respondsToSelector:@selector(client:deletePathFailedWithErrorCode:)]) {
			[self.delegate client:self deletePathFailedWithErrorCode:errorCode];
		}
		return;
	}
	if([request isKindOfClass:[ACWebDAVMoveRequest class]]) {
		if([self.delegate respondsToSelector:@selector(client:movePathFailedWithErrorCode:)]) {
			[self.delegate client:self movePathFailedWithErrorCode:errorCode];
		}
		return;
	}
	if([request isKindOfClass:[ACWebDAVCopyRequest class]]) {
		if([self.delegate respondsToSelector:@selector(client:copyPathFailedWithErrorCode:)]) {
			[self.delegate client:self copyPathFailedWithErrorCode:errorCode];
		}
		return;
	}
}

-(void)request:(id)request didFailWithError:(NSError*)error {
	NSLog(@"Error encountered in ACWebDAV client: %@", [error localizedDescription]);
	
	if([self.delegate respondsToSelector:@selector(client:failedWithError:)]) {
		[self.delegate client:self failedWithError:error];
	}
	
	if([request isKindOfClass:[ACWebDAVPropertyRequest class]]) {
		if([self.delegate respondsToSelector:@selector(client:loadMetadataFailedWithError:)]) {
			[self.delegate client:self loadMetadataFailedWithError:error];
		}
		return;
	}
	if([request isKindOfClass:[ACWebDAVDownloadRequest class]]) {
		if([self.delegate respondsToSelector:@selector(client:downloadFileFailedWithError:)]) {
			[self.delegate client:self downloadFileFailedWithError:error];
		}
		return;
	}
	if([request isKindOfClass:[ACWebDAVUploadRequest class]]) {
		if([self.delegate respondsToSelector:@selector(client:uploadFileFailedWithError:)]) {
			[self.delegate client:self uploadFileFailedWithError:error];
		}
		return;
	}
	if([request isKindOfClass:[ACWebDAVMakeCollectionRequest class]]) {
		if([self.delegate respondsToSelector:@selector(client:createCollectionFailedWithError:)]) {
			[self.delegate client:self createCollectionFailedWithError:error];
		}
		return;
	}
	if([request isKindOfClass:[ACWebDAVDeleteRequest class]]) {
		if([self.delegate respondsToSelector:@selector(client:deletePathFailedWithError:)]) {
			[self.delegate client:self deletePathFailedWithError:error];
		}
		return;
	}
	if([request isKindOfClass:[ACWebDAVCopyRequest class]]) {
		if([self.delegate respondsToSelector:@selector(client:copyPathFailedWithError:)]) {
			[self.delegate client:self copyPathFailedWithError:error];
		}
		return;
	}
	if([request isKindOfClass:[ACWebDAVMoveRequest class]]) {
		if([self.delegate respondsToSelector:@selector(client:movePathFailedWithError:)]) {
			[self.delegate client:self movePathFailedWithError:error];
		}
		return;
	}
}

@end
