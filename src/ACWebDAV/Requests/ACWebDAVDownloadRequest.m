//
//  ACWebDAVDownloadRequest.m
//  ACWebDAVTest
//
//  Created by Jason Kichline on 8/20/10.
//  Copyright 2010 Jason Kichline. All rights reserved.
//

#import "ACWebDAVDownloadRequest.h"


@implementation ACWebDAVDownloadRequest

@synthesize delegate, location, userInfo;

-(id)initWithLocation:(ACWebDAVLocation*)_location {
	if(self = [self init]) {
		self.location = _location;
	}
	return self;
}

+(ACWebDAVDownloadRequest*)requestWithLocation:(ACWebDAVLocation*)_location {
	return [[[self alloc] initWithLocation:_location] autorelease];
}

+(ACWebDAVDownloadRequest*)requestToDownloadItem:(ACWebDAVItem*)item delegate:(id<ACWebDAVDownloadRequestDelegate>) _delegate {
	ACWebDAVDownloadRequest* request = [self requestWithLocation:item.location];
	request.delegate = _delegate;
	return request;
}

-(void)start {
	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
	NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:self.location.url];
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

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSHTTPURLResponse *)response {
	if([response statusCode] != 200) {
		if(self.delegate != nil && [(NSObject*)self.delegate respondsToSelector:@selector(request:didFailWithErrorCode:)]) {
			[self.delegate request:self didFailWithErrorCode:[response statusCode]];
		}
		[connection cancel];
		[connection release];
		return;
	}
	
	data = nil;
	[data release];
	data = [[NSMutableData alloc] init];
    [data setLength:0];
	contentLength = [response expectedContentLength];
	
	if(self.delegate != nil && [(NSObject*)self.delegate respondsToSelector:@selector(requestDidStartDownload:)]) {
		[self.delegate requestDidStartDownload:self];
	}
}

-(void)connection:(NSURLConnection*)connection didReceiveData:(NSData*)d {
    [data appendData:d];
	if(self.delegate != nil && [(NSObject*)self.delegate respondsToSelector:@selector(request:didUpdateDownloadProgress:)]) {
		[self.delegate request:self didUpdateDownloadProgress:(float)data.length/contentLength];
	}
}

-(void)connectionDidFinishLoading:(NSURLConnection *)connection {
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	if(self.delegate != nil && [(NSObject*)self.delegate respondsToSelector:@selector(request:didCompleteDownload:)]) {
		[self.delegate request:self didCompleteDownload:data];
	}
	[connection release];
}

-(void)connection:(NSURLConnection*)connection didFailWithError:(NSError*)error {
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	if(self.delegate != nil && [(NSObject*)self.delegate respondsToSelector:@selector(request:didFailWithError:)]) {
		[self.delegate request:self didFailWithError:error];
	}
	[connection release];
}

-(void)dealloc {
	[userInfo release];
	[location release];
	[(NSObject*)delegate release];
	[data release];
	[super dealloc];
}

@end
