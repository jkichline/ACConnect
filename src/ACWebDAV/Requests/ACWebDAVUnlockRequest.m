//Unlock
//  ACWebDAVUnlockRequest.m
//  ACWebDAVTest
//
//  Created by Jason Kichline on 8/20/10.
//  Copyright 2010 Jason Kichline. All rights reserved.
//

#import "ACWebDAVUnlockRequest.h"


@implementation ACWebDAVUnlockRequest

@synthesize delegate, location, item;

-(id)initWithLocation:(ACWebDAVLocation*)_location {
	if(self = [self init]) {
		self.location = _location;
	}
	return self;
}

+(ACWebDAVUnlockRequest*)requestWithLocation:(ACWebDAVLocation*)_location {
	return [[[self alloc] initWithLocation:_location] autorelease];
}

+(ACWebDAVUnlockRequest*)requestToUnlockItem:(ACWebDAVItem*)_item delegate:(id<ACWebDAVUnlockRequestDelegate>) _delegate {
	ACWebDAVUnlockRequest* request = [self requestWithLocation:_item.location];
	request.item = _item;
	request.delegate = _delegate;
	return request;
}

-(void)start {
	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
	NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:self.location.url];
	[request setHTTPMethod:@"UNLOCK"];
	[request setValue:@"text/xml" forHTTPHeaderField:@"Content-Type"];
	[request setValue:[NSString stringWithFormat:@"<%@>", self.item.lock.token] forHTTPHeaderField:@"Lock-Token"];
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
	if([response statusCode] == 204) {
		if(self.delegate != nil && [(NSObject*)self.delegate respondsToSelector:@selector(request:didUnlockItem:)]) {
			self.item.lock = nil;
			[self.delegate request:self didUnlockItem:self.item];
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

-(void)dealloc {
	[location release];
	[(NSObject*)delegate release];
	[item release];
	[super dealloc];
}


@end
