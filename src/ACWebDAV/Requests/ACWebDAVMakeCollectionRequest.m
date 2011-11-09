//
//  ACWebDAVMakeCollectionRequest.m
//  ACWebDAVTest
//
//  Created by Jason Kichline on 8/19/10.
//  Copyright 2010 Jason Kichline. All rights reserved.
//

#import "ACWebDAVMakeCollectionRequest.h"


@implementation ACWebDAVMakeCollectionRequest

@synthesize delegate, location;

-(id)initWithLocation:(ACWebDAVLocation*)_location {
	if(self = [self init]) {
		self.location = _location;
	}
	return self;
}

+(ACWebDAVMakeCollectionRequest*)requestWithLocation:(ACWebDAVLocation*)_location {
	return [[[self alloc] initWithLocation:_location] autorelease];
}

+(ACWebDAVMakeCollectionRequest*)requestToMakeCollectionNamed:(NSString*)named inParent:(ACWebDAVCollection*)parent delegate:(id) _delegate {
	NSString* url = [[[parent.url absoluteString] stringByAppendingPathComponent:named] stringByAppendingString:@"/"];
	ACWebDAVLocation* l = [ACWebDAVLocation locationWithURL:[NSURL URLWithString:url] username:parent.location.username password:parent.location.password];
	ACWebDAVMakeCollectionRequest* request = [self requestWithLocation:l];
	request.delegate = _delegate;
	return request;
}

-(void)start {
	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
	NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:self.location.url];
	[request setHTTPMethod:@"MKCOL"];
	[request setValue:@"text/xml" forHTTPHeaderField:@"Content-Type"];
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

- (void)connection:(NSURLConnection*)connection didReceiveResponse:(NSHTTPURLResponse*)response {
	if([response statusCode] == 201) {
		if(self.delegate != nil && [(NSObject*)self.delegate respondsToSelector:@selector(request:didCreateCollection:)]) {
			ACWebDAVLocation* newLocation = [ACWebDAVLocation locationWithURL:[response URL] username:self.location.username password:self.location.password];
			ACWebDAVCollection* collection = [[ACWebDAVCollection alloc] initWithLocation:newLocation];
			[self.delegate request:self didCreateCollection:collection];
			[collection release];
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


@end
