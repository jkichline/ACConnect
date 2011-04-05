//
//  ACHTTPClient.m
//  Strine
//
//  Created by Jason Kichline on 10/20/09.
//  Copyright 2009 andCulture. All rights reserved.
//

#import "ACHTTPClient.h"
#import "ACHTTPReachability.h"

@protocol ACHTTPClientDelegate;

@implementation ACHTTPClient

@synthesize action, response, result, body, payload, url, receivedData, delegate, username, password, connection = conn;

-(id)init{
	if((self = [super init])) {
		conn = nil;
	}
	return self;
}

// Sends the request via HTTP.
- (void) getUrl:(id)value {
	
	// Make it a URL if it's not one
	NSURL* newUrl = nil;
	if([value isKindOfClass:[NSURL class]]) {
		newUrl = [value retain];
	} else {
		newUrl = [[NSURL alloc] initWithString: value];
	}
	if(newUrl == nil) {
		NSLog(@"The URL %@ could not be parsed.", value);
	}
	self.url = newUrl;
	[newUrl release];
	
	// Make sure the network is available
	if([[ACHTTPReachability reachabilityForInternetConnection] currentReachabilityStatus] == NotReachable) {
		NSError* error = [NSError errorWithDomain:@"ACHTTPClient" code:400 userInfo:[NSDictionary dictionaryWithObject:@"The network is not available" forKey:NSLocalizedDescriptionKey]];
		[self handleError: error];
		return;
	} else {
		// Make sure we can reach the host
		if([[ACHTTPReachability reachabilityWithHostName:url.host] currentReachabilityStatus] == NotReachable) {
			NSError* error = [NSError errorWithDomain:@"ACHTTPClient" code:410 userInfo:[NSDictionary dictionaryWithObject:@"The host is not available" forKey:NSLocalizedDescriptionKey]];
			[self handleError: error];
			return;
		}
	}

	// Create the request
	NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:self.url cachePolicy:NSURLRequestReturnCacheDataElseLoad timeoutInterval:30];
	if(self.body != nil) {
		[request setHTTPMethod:@"POST"];
		if([self.body isKindOfClass:[NSData class]]) {
			[request setHTTPBody:(NSData*)body];
		} else if([self.body isKindOfClass:[NSDictionary class]]) {
			[request setHTTPBody:[[ACHTTPClient convertDictionaryToParameters:(NSDictionary*)self.body] dataUsingEncoding:NSUTF8StringEncoding]];
		} else {
			[request setHTTPBody:[[NSString stringWithFormat:@"%@", self.body] dataUsingEncoding:NSUTF8StringEncoding]];
		}
	}
	
	// Create the connection
	self.connection = [[NSURLConnection alloc] initWithRequest: request delegate: self];
	if(self.connection) {
		self.receivedData = [[NSMutableData alloc] init];
	} else {
		NSError* error = [NSError errorWithDomain:@"ACHTTPClient" code:404 userInfo: [NSDictionary dictionaryWithObjectsAndKeys: @"Could not create connection", NSLocalizedDescriptionKey,nil]];
		[self handleError: error];
	}
}

// Called when the HTTP socket gets a response.
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)r {
	self.response = (NSHTTPURLResponse*)r;
    [self.receivedData setLength:0];
	if(self.delegate != nil && [(NSObject*)self.delegate respondsToSelector:@selector(httpClient:updatedProgress:)]) {
		[(NSObject*)self.delegate performSelector:@selector(httpClient:updatedProgress:) withObject:self withObject:[NSNumber numberWithFloat:0]];
	}
}

// Called when the HTTP socket received data.
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)value {
    [self.receivedData appendData:value];
	if(self.delegate != nil && [(NSObject*)self.delegate respondsToSelector:@selector(httpClient:updatedProgress:)]) {
		[(NSObject*)self.delegate performSelector:@selector(httpClient:updatedProgress:) withObject:self withObject:[NSNumber numberWithFloat:(float)self.receivedData.length/(float)self.response.expectedContentLength]];
	}
}

// Called when the HTTP request fails.
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
	[self.receivedData release];
	[self handleError:error];
}

-(void)handleError:(NSError*)error{
	SEL a = @selector(httpClient:failedWithError:);
	
	if (self.action != nil && [(NSObject*)self.delegate respondsToSelector:self.action]) {
		[(NSObject*)self.delegate performSelector:self.action withObject:error];
	}
	
	if(self.delegate != nil && [(NSObject*)self.delegate respondsToSelector:a]) {
		[(NSObject*)self.delegate performSelector:action withObject: self withObject: error];
	}
	NSLog(@"%@", error);
}

// Called when the connection has finished loading.
- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
	if(!self.delegate) { return; }
	
	NSString* mimetype = [self.response MIMEType];
	if([mimetype hasPrefix:@"text/"]) {
		NSString* r = [[NSString alloc] initWithData: self.receivedData encoding: NSUTF8StringEncoding];
		if([r rangeOfString:@"http://www.apple.com/DTDs/PropertyList-1.0.dtd"].length > 0) {
			self.result = [r propertyList];
		} else {
			self.result = r;
		}
		[r release];
	} else if ([mimetype hasPrefix:@"image/"]) {
		self.result = [UIImage imageWithData:self.receivedData];
	} else {
		self.result = self.receivedData;
	}
	
	if (self.action != nil && [(NSObject*)self.delegate respondsToSelector:self.action]) {
		[(NSObject*)self.delegate performSelector:self.action withObject:self];
		return;
	}
	
	if ([(NSObject*)self.delegate respondsToSelector:@selector(httpClientCompleted)]) {
		[(NSObject*)self.delegate performSelector:@selector(httpClientCompleted:) withObject: self];
	}

	if(self.delegate && [(NSObject*)self.delegate respondsToSelector:@selector(httpClient:completedWithData:)]) {
		[(NSObject*)self.delegate performSelector:@selector(httpClient:completedWithData:) withObject:self withObject:self.receivedData];
	}

	if(self.delegate && [(NSObject*)self.delegate respondsToSelector:@selector(httpClient:completedWithValue:)]) {
		[(NSObject*)self.delegate performSelector:@selector(httpClient:completedWithValue:) withObject:self withObject:self.result];
	}
}

// Called if the HTTP request receives an authentication challenge.
-(void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
	if([challenge previousFailureCount] == 0) {
		NSURLCredential *newCredential;
        newCredential=[NSURLCredential credentialWithUser:self.username password:self.password persistence:NSURLCredentialPersistenceNone];
        [[challenge sender] useCredential:newCredential forAuthenticationChallenge:challenge];
    } else {
        [[challenge sender] cancelAuthenticationChallenge:challenge];
		NSError* error = [NSError errorWithDomain:@"ACHTTPClient" code:403 userInfo: [NSDictionary dictionaryWithObjectsAndKeys: @"Could not authenticate this request", NSLocalizedDescriptionKey,nil]];
		[self handleError:error];
    }
}

+(id)get:(id)url{
	if([url isKindOfClass:[NSString class]]) {
		url = [NSURL URLWithString:url];
	}
	if([url isKindOfClass:[NSURL class]] == NO) {
		return nil;
	}

	if([[ACHTTPReachability reachabilityForInternetConnection] currentReachabilityStatus] == NotReachable) {
		return nil;
	}
	
	// Make sure we can reach the host
	if([ACHTTPReachability reachabilityWithHostName:[(NSURL*)url host]] == NotReachable) {
		return nil;
	}
	
	NSError* error;
	NSHTTPURLResponse* response;
	NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:url];
	NSData* resultData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
	
	NSString* resultString = [[[NSString alloc] initWithData:resultData encoding:NSUTF8StringEncoding] autorelease];
	NSLog(@"Received Data: %@", resultString);
	id resultOutput;
	@try {
		resultOutput = [resultString propertyList];
	}
	@catch (NSException * e) {
		resultOutput = resultString;
	}
	@finally {
	}
	return resultOutput;
}

+(void)get:(id)url delegate: (id<ACHTTPClientDelegate>) delegate{
	ACHTTPClient* wd = [[ACHTTPClient alloc] init];
	wd.delegate = delegate;
	[wd getUrl:url];
	[wd release];
}

+(void)get:(id)url delegate: (id<ACHTTPClientDelegate>) delegate action:(SEL)action{
	ACHTTPClient* wd = [[ACHTTPClient alloc] init];
	wd.delegate = delegate;
	wd.action = action;
	[wd getUrl:url];
	[wd release];
}

+(void)post:(id)url data:(id)data delegate:(id <ACHTTPClientDelegate>)delegate {
	ACHTTPClient* wd = [[ACHTTPClient alloc] init];
	wd.delegate = delegate;
	wd.body = data;
	[wd getUrl:url];
	[wd release];
}

+(void)post:(id)url data:(id)data delegate:(id <ACHTTPClientDelegate>)delegate action:(SEL)action {
	ACHTTPClient* wd = [[ACHTTPClient alloc] init];
	wd.delegate = delegate;
	wd.action = action;
	wd.body = data;
	[wd getUrl:url];
	[wd release];
}

// Cancels the HTTP request.
-(BOOL)cancel{
	if(self.connection == nil) { return NO; }
	[self.connection cancel];
	return YES;
}

+(NSString*)convertDictionaryToParameters:(NSDictionary*)d {
	return [self convertDictionaryToParameters:d separator:nil];
}

+(NSString*)convertDictionaryToParameters:(NSDictionary*)d separator:(NSString*)separator {
	if(separator == nil) { separator = @"."; }
	NSMutableString* s = [NSMutableString string];
	for(id key in [d allKeys]) {
		NSString* value = [NSString stringWithFormat:@"%@", [d objectForKey:key]];
		if(s.length > 0) {
			[s appendString:@"&"];
		}
		[s appendFormat:@"%@=%@", [key stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding], [value stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
	}
	return s;
}

-(void)dealloc{
	[receivedData release];
	[url release];
	[conn release];
	[super dealloc];
}

@end
