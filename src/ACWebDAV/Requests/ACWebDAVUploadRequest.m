//
//  ACWebDAVUploadRequest.m
//  ACWebDAVTest
//
//  Created by Jason Kichline on 8/19/10.
//  Copyright 2010 Jason Kichline. All rights reserved.
//

#import "ACWebDAVUploadRequest.h"


@implementation ACWebDAVUploadRequest

@synthesize delegate, location, filepath;

-(id)initWithLocation:(ACWebDAVLocation*)_location {
	if(self = [self init]) {
		self.location = _location;
	}
	return self;
}

+(ACWebDAVUploadRequest*)requestWithLocation:(ACWebDAVLocation*)_location {
	return [[[self alloc] initWithLocation:_location] autorelease];
}

+(ACWebDAVUploadRequest*)requestToUploadFile:(NSString*)_filepath toCollection:(ACWebDAVCollection*)_collection delegate:(id<ACWebDAVUploadRequestDelegate>) _delegate {
	
	NSString* filename = [[_filepath lastPathComponent] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
	
	NSString* url = [[_collection.url absoluteString] stringByAppendingPathComponent:filename];
	url = [[url stringByReplacingOccurrencesOfString:@":/" withString:@"://"] stringByReplacingOccurrencesOfString:@":///" withString:@"://"];
	ACWebDAVLocation* newLocation = [ACWebDAVLocation locationWithURL:[NSURL URLWithString:url] username:_collection.location.username password:_collection.location.password];
	
	ACWebDAVUploadRequest* request = [self requestWithLocation:newLocation];
	request.filepath = _filepath;
	request.delegate = _delegate;
	return request;
}

-(void)start {

	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;

	// Set up credentials
	NSURLCredential *userCredentials = [NSURLCredential credentialWithUser:self.location.username password:self.location.password persistence:NSURLCredentialPersistenceForSession];
    NSURLProtectionSpace *space = [[NSURLProtectionSpace alloc] initWithHost:self.location.host
                                                                        port:([self.location.host hasPrefix:@"https://"]) ? 443 : 80
																	protocol:[[self.location.host componentsSeparatedByString:@":"] objectAtIndex:0]
																	   realm:@"Mobilu ACWebDAV"
														authenticationMethod:nil];
    [[NSURLCredentialStorage sharedCredentialStorage] setCredential:userCredentials forProtectionSpace:space];
	[space release];
	
	// Create the request
	NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:self.location.url];
	[request setHTTPMethod:@"PUT"];
	[request setValue:[self mimetypeForFile:self.filepath] forHTTPHeaderField:@"Content-Type"];
	[request setHTTPBody:[NSData dataWithContentsOfFile:self.filepath]];
	
	NSURLConnection* conn = [[NSURLConnection alloc] initWithRequest:request delegate:self];
	[conn start];
}

-(NSURLRequest*)connection:(NSURLConnection*)connection willSendRequest:(NSURLRequest*)request redirectResponse:(NSURLResponse*)redirectResponse {
	return request;
}

-(void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
	if([challenge previousFailureCount] == 0) {
		NSURLCredential *newCredential;
        newCredential=[NSURLCredential credentialWithUser:self.location.username password:self.location.password persistence:NSURLCredentialPersistenceNone];
        [[challenge sender] useCredential:newCredential forAuthenticationChallenge:challenge];
    } else {
        [[challenge sender] cancelAuthenticationChallenge:challenge];
    }
}

-(void)connection:(NSURLConnection *)connection didSendBodyData:(NSInteger)bytesWritten totalBytesWritten:(NSInteger)totalBytesWritten totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite {
	if(self.delegate != nil && [(NSObject*)self.delegate respondsToSelector:@selector(request:didUpdateUploadProgress:)]) {
		[self.delegate request:self didUpdateUploadProgress:(float)totalBytesWritten/totalBytesExpectedToWrite];
	}
}

- (void)connection:(NSURLConnection*)connection didReceiveResponse:(NSHTTPURLResponse*)response {
	if([response statusCode] == 201 || [response statusCode] == 204) {
		if(self.delegate != nil && [(NSObject*)self.delegate respondsToSelector:@selector(request:didUploadItem:)]) {
			ACWebDAVLocation* newLocation = [ACWebDAVLocation locationWithURL:[response URL] username:self.location.username password:self.location.password];
			ACWebDAVItem* item = [[ACWebDAVItem alloc] initWithLocation:newLocation];
			[self.delegate request:self didUploadItem:item];
			[item release];
		}
	} else {
		if(self.delegate != nil && [(NSObject*)self.delegate respondsToSelector:@selector(request:didFailWithErrorCode:)]) {
			[self.delegate request:self didFailWithErrorCode:[response statusCode]];
		}
	}
}

-(void)connectionDidFinishLoading:(NSURLConnection *)connection {
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	[connection release];
}

-(void)connection:(NSURLConnection*)connection didFailWithError:(NSError*)error {
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	if(self.delegate != nil && [(NSObject*)self.delegate respondsToSelector:@selector(request:didFailWithError:)]) {
		[self.delegate request:self didFailWithError:error];
	}
	[connection release];
}

-(NSString*)mimetypeForFile:(NSString*)_filepath {
	NSURL* fileUrl = [NSURL fileURLWithPath:_filepath];
	NSURLRequest* fileUrlRequest = [NSURLRequest requestWithURL:fileUrl];
	NSError* error = nil;
	NSURLResponse* response = nil;
	[NSURLConnection sendSynchronousRequest:fileUrlRequest returningResponse:&response error:&error];
	return [response MIMEType];
}


@end
