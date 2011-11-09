//
//  ACWebDAVLockRequest.m
//  ACWebDAVTest
//
//  Created by Jason Kichline on 8/20/10.
//  Copyright 2010 Jason Kichline. All rights reserved.
//

#import "ACWebDAVLockRequest.h"


@implementation ACWebDAVLockRequest

@synthesize delegate, location, recursive, exclusive, item, timeout;

-(id)init {
	if(self = [super init]) {
		self.recursive = NO;
		self.exclusive = YES;
		self.timeout = 0;
	}
	return self;
}

-(id)initWithLocation:(ACWebDAVLocation*)_location {
	if(self = [self init]) {
		self.location = _location;
	}
	return self;
}

+(ACWebDAVLockRequest*)requestWithLocation:(ACWebDAVLocation*)_location {
	return [[[self alloc] initWithLocation:_location] autorelease];
}

+(ACWebDAVLockRequest*)requestToLockItem:(ACWebDAVItem*)_item delegate:(id<ACWebDAVLockRequestDelegate>) _delegate {
	ACWebDAVLockRequest* request = [self requestWithLocation:_item.location];
	request.item = _item;
	request.delegate = _delegate;
	return request;
}

-(NSData*)body {
	NSMutableString* o = [NSMutableString string];
	[o appendString:@"<?xml version=\"1.0\" encoding=\"utf-8\"?>\n"];
	[o appendString:@"<D:lockinfo xmlns:D=\"DAV:\">\n"];
	[o appendString:@"	<D:lockscope>\n"];
	[o appendFormat:@"		<D:%@/>\n", (self.exclusive) ? @"exclusive" : @"shared"];
	[o appendString:@"	</D:lockscope>\n"];
	[o appendString:@"	<D:locktype>\n"];
	[o appendString:@"		<D:write/>\n"];
	[o appendString:@"	</D:locktype>\n"];
	[o appendString:@"	<D:owner>\n"];
	[o appendString:@"		<D:href>http://www.mobilu.com/ACWebDAV/</D:href>\n"];
	[o appendString:@"	</D:owner>\n"];
	[o appendString:@"</D:lockinfo>"];
	return [o dataUsingEncoding:NSUTF8StringEncoding];
}

-(void)start {
	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
	NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:self.location.url];
	[request setHTTPMethod:@"LOCK"];
	[request setHTTPBody:[self body]];
	[request setValue:@"text/xml" forHTTPHeaderField:@"Content-Type"];
	if(self.timeout == 0) {
		[request setValue:@"Infinite, Second-4100000000" forHTTPHeaderField:@"Timeout"];
	} else {
		[request setValue:[NSString stringWithFormat:@"Second-%d", self.timeout] forHTTPHeaderField:@"Timeout"];
	}
	[request setValue:(self.recursive) ? @"Infinity" : @"0" forHTTPHeaderField:@"Depth"];
	if(self.item != nil && self.item.lock != nil && self.item.lock.token != nil && self.item.lock.token.length > 0) {
		[request setValue:[NSString stringWithFormat:@"(<%@>)", self.item.lock.token] forHTTPHeaderField:@"If"];
	}
	statusCode = 0;
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
	data = nil;
	[data release];
	data = [[NSMutableData alloc] init];
    [data setLength:0];
	statusCode = [response statusCode];
	if(statusCode != 200 && statusCode != 423) {
		if(self.delegate != nil && [(NSObject*)self.delegate respondsToSelector:@selector(request:didFailWithErrorCode:)]) {
			[self.delegate request:self didFailWithErrorCode:statusCode];
		}
		[connection cancel];
		[connection release];
	}
}

-(void)connection:(NSURLConnection*)connection didReceiveData:(NSData*)d {
    [data appendData:d];
}

-(void)connectionDidFinishLoading:(NSURLConnection *)connection {
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

	// Release the connection, we are done with it.
	[connection release];
	
	// Set the lock on the item
	self.item.lock = [ACWebDAVLock lockWithData:data];
	
	if(statusCode == 423) {
		if(self.delegate != nil && [(NSObject*)self.delegate respondsToSelector:@selector(request:itemAlreadyLocked:)]) {
			[self.delegate request:self itemAlreadyLocked:self.item];
		}
	} else {
		if(self.delegate != nil && [(NSObject*)self.delegate respondsToSelector:@selector(request:itemWasLocked:)]) {
			[self.delegate request:self itemWasLocked:self.item];
		}
	}
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
	[data release];
	[item release];
	[super dealloc];
}


@end
