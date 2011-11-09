//
//  ACHTTPDownloader.m
//  Vocollect
//
//  Created by Jason Kichline on 8/17/11.
//  Copyright (c) 2011 Jason Kichline. All rights reserved.
//

#import "ACHTTPDownloader.h"
#import "ACHTTPRequest.h"
#import "ACHTTPReachability.h"
#import "ACHTTPRequestModifier.h"

@interface ACHTTPDownloader (Private)

-(void)handleError:(NSError*)error;

@end

@implementation ACHTTPDownloader

@synthesize action, response, payload, url, delegate, username, password, connection = conn, modifiers, downloadPath, filename;

#pragma mark - Initialization

-(id)init{
	if((self = [super init])) {
		conn = nil;
	}
	return self;
}

+(ACHTTPDownloader*)downloader {
	return [[[self alloc] init] autorelease];
}

+(ACHTTPDownloader*)downloaderWithDelegate:(id)_delegate {
	ACHTTPDownloader* downloader = [[self alloc] init];
	downloader.delegate = _delegate;
	return [downloader autorelease];
}

+(ACHTTPDownloader*)downloaderWithDelegate:(id)_delegate action:(SEL)_action {
	ACHTTPDownloader* downloader = [[self alloc] init];
	downloader.delegate = _delegate;
	downloader.action = _action;
	return [downloader autorelease];
}

#pragma mark -
#pragma mark Properties

-(NSString*)downloadPath {
	if(downloadPath == nil) {
		return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
	}
	return downloadPath;
}

-(NSString*)tempPath {
	NSAssert(self.response != nil, @"Response must not be null");
	return [self.downloadPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.download", [self.response suggestedFilename]]];
}

-(NSString*)filename {
	if(filename == nil) {
		NSAssert(self.response != nil, @"Response must not be null");
		return [self.response suggestedFilename];
	} else {
		return filename;
	}
}

-(NSString*)finalPath {
	NSAssert(self.response != nil, @"Response must not be null");
	return [self.downloadPath stringByAppendingPathComponent: [self.response suggestedFilename]];
}

#pragma mark -
#pragma mark Download Methods

-(void)download:(id)value toPath:(NSString*)path {
	self.downloadPath = path;
	[self download:value];
}

-(void)download:(id)value {
	
	// Make it a URL if it's not one
	if(value != nil) {
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
	}
	[self download];
}

-(void)download {
	// Make sure the network is available
	if([[ACHTTPReachability reachabilityForInternetConnection] currentReachabilityStatus] == NotReachable) {
		NSError* error = [NSError errorWithDomain:@"ACHTTPDownloader" code:400 userInfo:[NSDictionary dictionaryWithObject:@"The network is not available" forKey:NSLocalizedDescriptionKey]];
		[self handleError: error];
		return;
	} else {
		// Make sure we can reach the host
		if([[ACHTTPReachability reachabilityWithHostName:self.url.host] currentReachabilityStatus] == NotReachable) {
			NSError* error = [NSError errorWithDomain:@"ACHTTPDownloader" code:410 userInfo:[NSDictionary dictionaryWithObject:@"The host is not available" forKey:NSLocalizedDescriptionKey]];
			[self handleError: error];
			return;
		}
	}
	
	// Create the request
	NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:self.url cachePolicy:NSURLRequestReturnCacheDataElseLoad timeoutInterval:30];
	
	// If we have any modifiers specified, run them
	if(self.modifiers != nil) {
		for(id modifier in self.modifiers) {
			if([modifier conformsToProtocol:@protocol(ACHTTPRequestModifier)]) {
				[modifier modifyRequest:request];
			}
		}
	}
	
	// Create the connection
	self.connection = [[[NSURLConnection alloc] initWithRequest:request delegate: self] autorelease];
	[ACHTTPRequest incrementNetworkActivity];
	if(self.connection) {
		receivedBytes = 0;
	} else {
		NSError* error = [NSError errorWithDomain:@"ACHTTPDownloader" code:404 userInfo: [NSDictionary dictionaryWithObjectsAndKeys: @"Could not create connection", NSLocalizedDescriptionKey,nil]];
		[self handleError: error];
	}
}

+(ACHTTPDownloader*)download:(id)url toPath:(NSString*)path delegate:(id<ACHTTPDownloaderDelegate>) delegate {
	return [self download:url toPath:path delegate:delegate action:nil];
}

+(ACHTTPDownloader*)download:(id)url toPath:(NSString*)path delegate:(id<ACHTTPDownloaderDelegate>) delegate modifiers:(NSArray*)modifiers {
	return [self download:url toPath:path delegate:delegate action:nil modifiers:modifiers];
}

+(ACHTTPDownloader*)download:(id)url toPath:(NSString*)path delegate:(id) delegate action:(SEL)action {
	return [self download:url toPath:path delegate:delegate action:action modifiers:nil];
}

+(ACHTTPDownloader*)download:(id)url toPath:(NSString*)path delegate:(id) delegate action:(SEL)action modifiers:(NSArray*)modifiers {
	ACHTTPDownloader* downloader = [ACHTTPDownloader downloaderWithDelegate:delegate action:action];
	downloader.modifiers = modifiers;
	[downloader download:url toPath:path];
	return downloader;
}

#pragma mark -
#pragma mark Connection Delegates

// Called when the HTTP socket gets a response.
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)r {
	self.response = (NSHTTPURLResponse*)r;

	// Initialize the file handler
	[[NSFileManager defaultManager] removeItemAtPath:self.tempPath error:nil];
	[[NSFileManager defaultManager] createFileAtPath:self.tempPath contents:nil attributes:nil];
	
	handle = [[NSFileHandle fileHandleForWritingAtPath:self.tempPath] retain];
	[handle truncateFileAtOffset:0];
	
	// Notify the delegate of progress
	if(self.delegate != nil && [(NSObject*)self.delegate respondsToSelector:@selector(httpDownloader:updatedProgress:)]) {
		[(NSObject*)self.delegate performSelector:@selector(httpDownloader:updatedProgress:) withObject:self withObject:[NSNumber numberWithFloat:0]];
	}
}

// Called when the HTTP socket received data.
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)value {
	
	// Update the received bytes
	receivedBytes += value.length;

	// Save the data to the file
	[handle writeData:value];
	
	if(self.delegate != nil && [(NSObject*)self.delegate respondsToSelector:@selector(httpDownloader:updatedProgress:)]) {
		[(NSObject*)self.delegate performSelector:@selector(httpDownloader:updatedProgress:) withObject:self withObject:[NSNumber numberWithFloat:(float)receivedBytes/(float)self.response.expectedContentLength]];
	}
}

// Called when the HTTP request fails.
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
	
	// Close the file
	[handle synchronizeFile];
	[handle closeFile];
	[handle release];
	handle = nil;
	
	// Stop the network activity
	[ACHTTPRequest decrementNetworkActivity];
	
	// Delete the file
	[[NSFileManager defaultManager] removeItemAtPath:self.tempPath error:nil];
	[self handleError:error];
}

-(void)handleError:(NSError*)error {
	SEL a = @selector(httpRequest:failedWithError:);
	
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
	
	// Synchronize and close the file
	[handle synchronizeFile];
	[handle closeFile];
	[handle release];
	handle = nil;
	
	// Move the temp file to the actual file
	NSError* error = nil;
	if([[NSFileManager defaultManager] fileExistsAtPath:self.tempPath]) {
		[[NSFileManager defaultManager] removeItemAtPath:self.finalPath error:nil];
		[[NSFileManager defaultManager] moveItemAtPath:self.tempPath toPath:self.finalPath error:&error];
	} else {
		error = [NSError errorWithDomain:@"ACHTTPDownloader" code:501 userInfo: [NSDictionary dictionaryWithObjectsAndKeys: @"No file was downloaded", NSLocalizedDescriptionKey,nil]];
	}
	
	// Stop the network activity
	[ACHTTPRequest decrementNetworkActivity];
	
	// If we have an error, then handle it
	if(error != nil) {
		[self handleError:error];
		return;
	}
	
	if(!self.delegate) { return; }
	
	if (self.action != nil && [(NSObject*)self.delegate respondsToSelector:self.action]) {
		[(NSObject*)self.delegate performSelector:self.action withObject:self];
		return;
	}
	
	if ([(NSObject*)self.delegate respondsToSelector:@selector(httpDownloader:downloadedToPath:)]) {
		[self.delegate httpDownloader:self downloadedToPath:self.finalPath];
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
		NSError* error = [NSError errorWithDomain:@"ACHTTPDownloader" code:403 userInfo: [NSDictionary dictionaryWithObjectsAndKeys: @"Could not authenticate this request", NSLocalizedDescriptionKey,nil]];
		[self handleError:error];
    }
}

// Cancels the HTTP request.
-(BOOL)cancel{
	if(self.connection == nil) { return NO; }
	[self.connection cancel];
	return YES;
}

-(void)dealloc{
	[url release];
	[(NSObject*)delegate release];
	[username release];
	[password release];
	[response release];
	[conn release];
	[payload release];
	[modifiers release];
	[handle release];
	[super dealloc];
}

@end
