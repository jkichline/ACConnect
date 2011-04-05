//
//  FTPDeleteFileRequest.m
//  OnSong
//
//  Created by Jason Kichline on 3/24/11.
//  Copyright 2011 andCulture. All rights reserved.
//

#import "ACFTPDeleteFileRequest.h"
#import "ACFTPHelper.h"
#import <CFNetwork/CFNetwork.h>

@interface ACFTPDeleteFileRequest (Private)

-(void)didFinish:(NSURL*)url;
-(void)didFail:(int)errorCode;

@end


@implementation ACFTPDeleteFileRequest

@synthesize location, delegate;

#pragma mark -
#pragma mark Initialization

-(id)initWithLocation:(id)_location {
	if(self = [self init]) {
		self.location = _location;
	}
	return self;
}

+(ACFTPDeleteFileRequest*)requestWithLocation:(id)_location {
	return [[[self alloc] initWithLocation:_location] autorelease];
}

#pragma mark -
#pragma mark Actions

-(void)start {
	SInt32 status = 0;
	NSURL* url = nil;
	
	if([self.location isKindOfClass:[NSURL class]]) {
		url = self.location;
	} else if([self.location respondsToSelector:@selector(urlWithCredentials)]) {
		url = [self.location performSelector:@selector(urlWithCredentials)];
	}
	
	BOOL success = CFURLDestroyResource((CFURLRef)url, &status);
	if(success) {
		[self didFinish:url];
	} else {
		[self didFail:status];
	}
}


#pragma mark -
#pragma mark Delegate methods

-(void)didFinish:(NSURL*)fileURL {
	if(self.delegate != nil && [(NSObject*)self.delegate respondsToSelector:@selector(request:didDeleteFile:)]) {
		[(NSObject*)self.delegate performSelector:@selector(request:didDeleteFile:) withObject:self withObject:fileURL];
	} else {
		NSLog(@"FTPDeleteFileRequest Deleted: %@", [[ACFTPHelper urlByRemovingCredentials:fileURL] absoluteString]);
	}
}

-(void)didFail:(int)errorCode {
	NSError* error = [NSError errorWithDomain:@"com.mobilu.onsong" code:errorCode userInfo:nil];
	if(self.delegate != nil && [(NSObject*)self.delegate respondsToSelector:@selector(request:didFailWithError:)]) {
		[(NSObject*)self.delegate performSelector:@selector(request:didFailWithError:) withObject:self withObject:error];
	} else {
		NSLog(@"FTPDeleteRequest Fail: %d", errorCode);
	}
}

@end
