//
//  ACWebDAVMoveRequest.m
//  ACWebDAVTest
//
//  Created by Jason Kichline on 8/19/10.
//  Copyright 2010 Jason Kichline. All rights reserved.
//

#import "ACWebDAVMoveRequest.h"
#import "ACWebDAVLocation.h"

@implementation ACWebDAVMoveRequest

@synthesize delegate, location, overwrite, destination;

-(id)initWithLocation:(ACWebDAVLocation*)_location {
	if(self = [self init]) {
		self.location = _location;
	}
	return self;
}

+(ACWebDAVMoveRequest*)requestWithLocation:(ACWebDAVLocation*)_location {
	return [[[self alloc] initWithLocation:_location] autorelease];
}

+(ACWebDAVMoveRequest*)requestToMoveItem:(ACWebDAVItem*)item toURL:(NSURL*)_destination delegate:(id<ACWebDAVMoveRequestDelegate>) _delegate {
	return [self requestToMoveItem:item toLocation:[ACWebDAVLocation locationWithURL:_destination] delegate:_delegate];
}

+(ACWebDAVMoveRequest*)requestToMoveItem:(ACWebDAVItem*)item toLocation:(ACWebDAVLocation*)_destination delegate:(id<ACWebDAVMoveRequestDelegate>) _delegate {
	ACWebDAVMoveRequest* request = [self requestWithLocation:item.location];
	request.overwrite = NO;
	request.destination = _destination;
	request.delegate = _delegate;
	return request;
}

-(void)start {
	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
	NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:self.location.url];
	[request setHTTPMethod:@"MOVE"];
	[request setValue:(self.overwrite) ? @"T" : @"F" forHTTPHeaderField:@"Overwrite"];
	[request setValue:[self.destination.url absoluteString] forHTTPHeaderField:@"Destination"];
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
		if(self.delegate != nil && [(NSObject*)self.delegate respondsToSelector:@selector(ACWebDAVMoveRequest:didMoveItem:)]) {
			ACWebDAVLocation* newLocation = [ACWebDAVLocation locationWithURL:[response URL] username:self.location.username password:self.location.password];
			ACWebDAVItem* item = [[ACWebDAVItem alloc] initWithLocation:newLocation];
			[self.delegate request:self didMoveItem:item];
			[item release];
		}
	} else {
		if(self.delegate != nil && [(NSObject*)self.delegate respondsToSelector:@selector(ACWebDAVMoveRequest:didFailWithErrorCode:)]) {
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
	if(self.delegate != nil && [(NSObject*)self.delegate respondsToSelector:@selector(ACWebDAVMoveRequest:didFailWithError:)]) {
		[self.delegate request:self didFailWithError:error];
	}
	[connection release];
}


@end
