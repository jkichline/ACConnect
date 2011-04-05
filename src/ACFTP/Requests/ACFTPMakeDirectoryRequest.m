//
//  FTPMakeDirectoryRequest.m
//  OnSong
//
//  Created by Jason Kichline on 3/24/11.
//  Copyright 2011 andCulture. All rights reserved.
//

#import "ACFTPMakeDirectoryRequest.h"
#import "ACFTPHelper.h"
#import "ACFTPError.h"

@interface ACFTPMakeDirectoryRequest (Private)

-(void)didFinish;
-(void)didUpdateStatus:(NSString*)status;
-(void)didFail:(id)reason;
-(void)stop;

@end

@implementation ACFTPMakeDirectoryRequest

@synthesize networkStream, directoryURL, name, parentDirectory, delegate;

#pragma mark -
#pragma mark Initialization

-(id)initWithDirectoryNamed:(NSString*)_name inParentDirectory:(id)_parentDirectory {
	if(self = [self init]) {
		self.name = _name;
		self.parentDirectory = _parentDirectory;
	}
	return self;
}

+(ACFTPMakeDirectoryRequest*)requestWithDirectoryNamed:(NSString*)_name inParentDirectory:(id)_parentDirectory {
	return [[[self alloc] initWithDirectoryNamed:_name inParentDirectory:_parentDirectory] autorelease];
}


#pragma mark -
#pragma mark Actions

-(void)start {
	
	// Don't restart the process if it's already running
	if(self.networkStream != nil) { return; }
	
	// Create our working variables
	NSURL* url;
	BOOL success;
	CFWriteStreamRef ftpStream;
	
	// Retrieve and check the URL
	if([self.parentDirectory isKindOfClass:[NSURL class]]) {
		url = self.parentDirectory;
	} else if([self.parentDirectory respondsToSelector:@selector(urlWithCredentials)]) {
		url = [self.parentDirectory performSelector:@selector(urlWithCredentials)];
	}
	success = (url != nil);
	if(success == NO) {
		[self didFail:@"Invalid FTP location"]; return;
	}
	NSString* strUrl = [url absoluteString];
	self.directoryURL = [NSURL URLWithString: [NSString stringWithFormat:@"%@%@%@/", strUrl, (([strUrl hasSuffix:@"/"]) ? @"" : @"/"), [self.name stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
	
	// Output the URL we are getting
	[self didUpdateStatus:[NSString stringWithFormat:@"Make %@", [[ACFTPHelper urlByRemovingCredentials:self.directoryURL] absoluteString]]];
	
	// Create the FTP stream
	ftpStream = CFWriteStreamCreateWithFTPURL(NULL, (CFURLRef)self.directoryURL);
	assert(ftpStream != NULL);
	
	// Set it to the network stream and hook up some delegates
	NSRunLoop* runLoop = [NSRunLoop currentRunLoop];
	self.networkStream = (NSOutputStream*)ftpStream;
	self.networkStream.delegate = self;
	[self.networkStream scheduleInRunLoop:runLoop forMode:NSDefaultRunLoopMode];
	[self.networkStream open];
	
	// Release the FTP stream since it's not retained by networkStream
	CFRelease(ftpStream);
}

-(void)cancel	 {
	[self stop];
	if(self.delegate != nil && [(NSObject*)self.delegate respondsToSelector:@selector(requestDidCancel:)]) {
		[(NSObject*)self.delegate performSelector:@selector(requestDidCancel:) withObject:self];
	}
}

-(void)stop {
	if (self.networkStream != nil) {
        [self.networkStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        self.networkStream.delegate = nil;
        [self.networkStream close];
        self.networkStream = nil;
    }
}

#pragma mark -
#pragma mark Stream handling

- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode {
    assert(aStream == self.networkStream);

    switch (eventCode) {
        case NSStreamEventOpenCompleted: {
            [self didUpdateStatus:@"Opened connection"];
        } break;
        case NSStreamEventHasBytesAvailable: {
            assert(NO);
        } break;
        case NSStreamEventHasSpaceAvailable: {
            assert(NO);
        } break;
        case NSStreamEventErrorOccurred: {
            CFStreamError err;
            err = CFWriteStreamGetError((CFWriteStreamRef) self.networkStream);
            if (err.domain == kCFStreamErrorDomainFTP) {
                [self didFail:[ACFTPError errorWithCode: (int)err.error]];
            } else {
                [self didFail:[aStream streamError]];
            }
        } break;
        case NSStreamEventEndEncountered: {
            [self didFinish];
        } break;
        default: {
            assert(NO);
        } break;
    }
}

#pragma mark -
#pragma mark Delegate methods

-(void)didFinish {
	[self stop];
	if(self.delegate != nil && [(NSObject*)self.delegate respondsToSelector:@selector(request:didMakeDirectory:)]) {
		[self.delegate request:self didMakeDirectory:[ACFTPHelper urlByRemovingCredentials:self.directoryURL]];
	} else {
		NSLog(@"FTPMakeDirectoryRequest Created: %@", [ACFTPHelper urlByRemovingCredentials:self.directoryURL]);
	}
}

-(void)didUpdateStatus:(NSString*)status {
	if(self.delegate != nil && [(NSObject*)self.delegate respondsToSelector:@selector(request:didUpdateStatus:)]) {
		[(NSObject*)self.delegate performSelector:@selector(request:didUpdateStatus:) withObject:self withObject:status];
	} else {
		NSLog(@"FTPMakeDirectoryRequest Status: %@", status);
	}
}

-(void)didFail:(id)reason {
	[self stop];
	NSError* error;
	if([reason isKindOfClass:[NSError class]]) {
		error = (NSError*)reason;
	} else {
		error = [NSError errorWithDomain:@"com.mobilu.onsong" code:502 userInfo:[NSDictionary dictionaryWithObject:reason forKey:@"reason"]];
	}
	if(self.delegate != nil && [(NSObject*)self.delegate respondsToSelector:@selector(request:didFailWithError:)]) {
		[(NSObject*)self.delegate performSelector:@selector(request:didFailWithError:) withObject:self withObject:error];
	} else {
		NSLog(@"FTPMakeDirectoryRequest Fail: %@", reason);
	}
}

#pragma mark -
#pragma mark Memory management

-(void)dealloc {
	[networkStream release];
	[directoryURL release];
	[name release];
	[parentDirectory release];
	[(NSObject*)delegate release];
	[super dealloc];
}

@end
