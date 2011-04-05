//
//  FTPClient.m
//  OnSong
//
//  Created by Jason Kichline on 3/23/11.
//  Copyright 2011 andCulture. All rights reserved.
//

#import "ACFTPClient.h"


@implementation ACFTPClient

@synthesize location, delegate;

#pragma mark -
#pragma mark Initialization

-(id)initWithHost:(id)host username:(NSString*)username password:(NSString*)password {
	return [self initWithLocation:[ACFTPLocation locationWithHost:host href:nil username:username password:password]];
}

-(id)initWithLocation:(ACFTPLocation*)_location {
	self = [self init];
	if(self) {
		self.location = _location;
	}
	return self;
}

-(id)init {
	self = [super init];
	if(self) {
		requests = [[NSMutableArray alloc] init];
	}
	return self;
}

+(ACFTPClient*)clientWithLocation:(ACFTPLocation *)location {
	return [[[self alloc] initWithLocation:location] autorelease];
}

+(ACFTPClient*)clientWithHost:(id)host username:(NSString *)username password:(NSString *)password {
	return [[[self alloc] initWithHost:host username:username password:password] autorelease];
}

#pragma mark -
#pragma mark Actions

-(void)list:(NSString*)path {
	ACFTPListRequest* request = [ACFTPListRequest requestWithLocation:[ACFTPLocation locationWithHost:self.location.host href:path username:self.location.username password:self.location.password]];
	request.delegate = self;
	[requests addObject:request];
	[request start];
}

-(void)get:(NSString*)sourcePath toDestination:(NSString*)destinationPath {
	ACFTPGetRequest* request = [ACFTPGetRequest requestWithSource:[ACFTPLocation locationWithHost:self.location.host href:sourcePath username:self.location.username password:self.location.password] toDestination:destinationPath];
	request.delegate = self;
	[requests addObject:request];
	[request start];
}

-(void)put:(NSString*)sourcePath toDestination:(NSString*)destinationPath {
	ACFTPPutRequest* request = [ACFTPPutRequest requestWithSource:sourcePath toDestination:[ACFTPLocation locationWithHost:self.location.host href:destinationPath username:self.location.username password:self.location.password]];
	request.delegate = self;
	[requests addObject:request];
	[request start];
}

-(void)makeDirectory:(NSString*)name inParentDirectory:(NSString*)parentDirectory {
	ACFTPMakeDirectoryRequest* request = [ACFTPMakeDirectoryRequest requestWithDirectoryNamed:name inParentDirectory:[ACFTPLocation locationWithHost:self.location.host href:parentDirectory username:self.location.username password:self.location.password]];
	request.delegate = self;
	[requests addObject:request];
	[request start];
}

-(void)deleteFile:(NSString *)filePath {
	ACFTPDeleteFileRequest* request = [ACFTPDeleteFileRequest requestWithLocation:[ACFTPLocation locationWithHost:self.location.host href:filePath username:self.location.username password:self.location.password]];
	request.delegate = self;
	[requests addObject:request];
	[request start];	
}
						
#pragma mark -
#pragma mark Handle delegate

-(void)request:(id)request didListEntries:(NSArray*)entries {
	if(self.delegate && [(NSObject*)self.delegate respondsToSelector:@selector(client:request:didListEntries:)]) {
		[self.delegate client:self request:request didListEntries:entries];
	}
	[requests removeObject:request];
}

-(void)request:(ACFTPGetRequest*)request didUpdateProgress:(float)progress {
	if(self.delegate && [(NSObject*)self.delegate respondsToSelector:@selector(client:request:didUpdateProgress:)]) {
		[self.delegate client:self request:request didUpdateProgress:progress];
	}
}

-(void)request:(ACFTPGetRequest*)request didDownloadFile:(NSURL*)sourceURL toDestination:(NSString*)destinationPath {
	if(self.delegate && [(NSObject*)self.delegate respondsToSelector:@selector(client:request:didDownloadFile:toDestination:)]) {
		[self.delegate client:self request:request didDownloadFile:sourceURL toDestination:destinationPath];
	}
	[requests removeObject:request];
}

-(void)request:(ACFTPPutRequest*)request didUploadFile:(NSString*)sourcePath toDestination:(NSURL*)destination {
	if(self.delegate && [(NSObject*)self.delegate respondsToSelector:@selector(client:request:didUploadFile:toDestination:)]) {
		[self.delegate client:self request:request didUploadFile:sourcePath toDestination:destination];
	}
	[requests removeObject:request];
}

-(void)request:(ACFTPMakeDirectoryRequest*)request didMakeDirectory:(NSURL*)directory {
	if(self.delegate && [(NSObject*)self.delegate respondsToSelector:@selector(client:request:didMakeDirectory:)]) {
		[self.delegate client:self request:request didMakeDirectory:directory];
	}
	[requests removeObject:request];
}

-(void)request:(ACFTPDeleteFileRequest*)request didDeleteFile:(NSURL*)filePath {
	if(self.delegate && [(NSObject*)self.delegate respondsToSelector:@selector(client:request:didDeleteFile:)]) {
		[self.delegate client:self request:request didDeleteFile:filePath];
	}
	[requests removeObject:request];
}

-(void)request:(id)request didFailWithError:(NSError*)error {
	if(self.delegate && [(NSObject*)self.delegate respondsToSelector:@selector(client:request:didFailWithError:)]) {
		[self.delegate client:self request:request didFailWithError:error];
	}
	[requests removeObject:request];
}

-(void)request:(id)request didUpdateStatus:(NSString*)status {
	if(self.delegate && [(NSObject*)self.delegate respondsToSelector:@selector(client:request:didUpdateStatus:)]) {
		[self.delegate client:self request:request didUpdateStatus:status];
	}
}

-(void)requestDidCancel:(id)request {
	if(self.delegate && [(NSObject*)self.delegate respondsToSelector:@selector(client:request:requestDidCancel:)]) {
		[self.delegate client:self requestDidCancel:request];
	}
	[requests removeObject:request];
}

#pragma mark -
#pragma mark Memory management

-(void)dealloc {
	[requests release];
	[location release];
	[(NSObject*)delegate release];
	[super dealloc];
}

@end
