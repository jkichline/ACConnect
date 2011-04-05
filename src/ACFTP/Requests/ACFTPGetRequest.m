//
//  FTPGetRequest.m
//  OnSong
//
//  Created by Jason Kichline on 3/23/11.
//  Copyright 2011 andCulture. All rights reserved.
//

#import "ACFTPGetRequest.h"
#import "ACFTPHelper.h"
#import "ACFTPError.h"

@interface ACFTPGetRequest (Private)

-(void)didFinish;
-(void)didUpdateProgress;
-(void)didUpdateStatus:(NSString*)status;
-(void)didFail:(id)reason;
-(void)stop;

@end


@implementation ACFTPGetRequest

@synthesize source, delegate, fileStream, networkStream, destinationPath, sourceURL;

#pragma mark -
#pragma mark Initialization

-(id)initWithSource:(id)_source toDestination:(NSString*)_destinationPath {
	if(self = [self init]) {
		self.source = _source;
		self.destinationPath = _destinationPath;
	}
	return self;
}

+(ACFTPGetRequest*)requestWithSource:(id)_source toDestination:(NSString*)_destinationPath {
	return [[[self alloc] initWithSource:_source toDestination:_destinationPath] autorelease];
}


#pragma mark -
#pragma mark Actions

-(void)start {
	
	// Don't restart the process if it's already running
	if(self.networkStream != nil) { return; }
	
	// Create our working variables
	NSURL* url;
	BOOL success;
	CFReadStreamRef ftpStream;
	
	// Retrieve and check the URL
	if([self.source isKindOfClass:[NSURL class]]) {
		url = self.source;
	} else if([self.source respondsToSelector:@selector(urlWithCredentials)]) {
		url = [self.source urlWithCredentials];
	}
	success = (url != nil);
	if(success == NO) {
		[self didFail:@"Invalid FTP location"]; return;
	}
	self.sourceURL = url;
	
	// Determine download bytes
	bytesDownloaded = 0;
	bytesTotal = 0;
	if([source isKindOfClass:[ACFTPEntry class]]) {
		bytesTotal = [(ACFTPEntry*)source size];
	}

	// Output the URL we are getting
	[self didUpdateStatus:[NSString stringWithFormat:@"Get %@", [[ACFTPHelper urlByRemovingCredentials: url] absoluteString]]];
	
	// Create a place to put our data
	self.fileStream = [NSOutputStream outputStreamToFileAtPath:self.destinationPath append:NO];
	assert(self.fileStream != nil);
	
	// Open the file stream
	[self.fileStream open];
	
	// Create the FTP stream
	ftpStream = CFReadStreamCreateWithFTPURL(NULL, (CFURLRef)url);
	assert(ftpStream != NULL);
	
	// Set it to the network stream and hook up some delegates
	NSRunLoop* runLoop = [NSRunLoop currentRunLoop];
	self.networkStream = (NSInputStream*)ftpStream;
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
	if(self.fileStream != nil) {
		[self.fileStream close];
		self.fileStream = nil;
	}
}

#pragma mark -
#pragma mark Handle the stream

- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode {
	
	// An NSStream delegate callback that's called when events happen on our 
	// network stream.
    assert(aStream == self.networkStream);
	
    switch (eventCode) {
        case NSStreamEventOpenCompleted: {
            [self didUpdateStatus:@"Opened connection"];
        } break;
        case NSStreamEventHasBytesAvailable: {
            NSInteger       bytesRead;
            uint8_t         buffer[32768];
			
            [self didUpdateProgress];
            
            // Pull some data off the network.
            bytesRead = [self.networkStream read:buffer maxLength:sizeof(buffer)];
            if (bytesRead == -1) {
                [self didFail:@"Network read error"];
            } else if (bytesRead == 0) {
                [self didFinish];
            } else {
                NSInteger   bytesWritten;
                NSInteger   bytesWrittenSoFar;
				bytesDownloaded += bytesRead;
                
                // Write to the file.
                
                bytesWrittenSoFar = 0;
                do {
                    bytesWritten = [self.fileStream write:&buffer[bytesWrittenSoFar] maxLength:bytesRead - bytesWrittenSoFar];
                    assert(bytesWritten != 0);
                    if (bytesWritten == -1) {
                        [self didFail:@"File write error"];
                        break;
                    } else {
                        bytesWrittenSoFar += bytesWritten;
                    }
                } while (bytesWrittenSoFar != bytesRead);
            }
        } break;
        case NSStreamEventHasSpaceAvailable: {
            assert(NO);     // should never happen for the output stream
        } break;
        case NSStreamEventErrorOccurred: {
            CFStreamError err;
            err = CFReadStreamGetError((CFReadStreamRef) self.networkStream);
            if (err.domain == kCFStreamErrorDomainFTP) {
                [self didFail:[ACFTPError errorWithCode: (int)err.error]];
            } else {
                [self didFail:[aStream streamError]];
            }
        } break;
        case NSStreamEventEndEncountered: {
            // ignore
        } break;
        default: {
            assert(NO);
        } break;
    }
}

#pragma mark -
#pragma mark Delegate methods

-(void)didUpdateProgress {
	if(bytesTotal <= 0) { return; }
	float progress = (float)((float)bytesDownloaded/(float)bytesTotal);
	if(self.delegate != nil && [(NSObject*)self.delegate respondsToSelector:@selector(request:didUpdateProgress:)]) {
		[self.delegate request:self didUpdateProgress:progress];
	} else {
		NSLog(@"FTPGetRequest Progress: %f", progress);
	}
}

-(void)didFinish {
	[self stop];
	if(self.delegate != nil && [(NSObject*)self.delegate respondsToSelector:@selector(request:didDownloadFile:toDestination:)]) {
		[self.delegate request:self didDownloadFile:[ACFTPHelper urlByRemovingCredentials:self.sourceURL] toDestination:self.destinationPath];
	} else {
		NSLog(@"FTPGetRequest Downloaded: %@ to %@", [ACFTPHelper urlByRemovingCredentials:self.sourceURL], self.destinationPath);
	}
}

-(void)didUpdateStatus:(NSString*)status {
	if(self.delegate != nil && [(NSObject*)self.delegate respondsToSelector:@selector(request:didUpdateStatus:)]) {
		[(NSObject*)self.delegate performSelector:@selector(request:didUpdateStatus:) withObject:self withObject:status];
	} else {
		NSLog(@"FTPGetRequest Status: %@", status);
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
		NSLog(@"FTPGetRequest Fail: %@", reason);
	}
}

#pragma mark -
#pragma mark Memory management

-(void)dealloc {
	[(NSObject*)delegate release];
	[source release];
	[networkStream release];
	[fileStream release];
	[destinationPath release];
	[sourceURL release];
	[super dealloc];
}

@end
