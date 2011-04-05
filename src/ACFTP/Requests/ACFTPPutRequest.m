//
//  FTPPutRequest.m
//  OnSong
//
//  Created by Jason Kichline on 3/23/11.
//  Copyright 2011 andCulture. All rights reserved.
//

#import "ACFTPPutRequest.h"
#import "ACFTPHelper.h"
#import "ACFTPError.h"

@interface ACFTPPutRequest (Private)

-(void)didFinish;
-(void)didUpdateProgress;
-(void)didUpdateStatus:(NSString*)status;
-(void)didFail:(id)reason;
-(void)stop;

@end


@implementation ACFTPPutRequest

@synthesize delegate, sourcePath, destination, networkStream, fileStream, bufferLimit, bufferOffset, destinationURL;

#pragma mark -
#pragma mark Setters and getters

-(uint8_t *)buffer {
	return self->buffer;
}

#pragma mark -
#pragma mark Initialization

-(id)inti {
	self = [super init];
	if(self) {
		self.bufferLimit = 0;
		self.bufferOffset = 0;
	}
	return self;
}

-(id)initWithSource:(NSString*)_sourcePath toDestination:(id)_destination {
	if(self = [self init]) {
		self.sourcePath = _sourcePath;
		self.destination = _destination;
	}
	return self;
}

+(ACFTPPutRequest*)requestWithSource:(NSString*)_sourcePath toDestination:(id)_destination {
	return [[[self alloc] initWithSource:_sourcePath toDestination:_destination] autorelease];
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
	if([self.destination isKindOfClass:[NSURL class]]) {
		url = self.destination;
	} else if ([self.destination respondsToSelector:@selector(urlWithCredentials)]) {
		url = [self.destination urlWithCredentials];
	}
	success = (url != nil);
	if(success == NO) {
		[self didFail:@"Invalid FTP destination"]; return;
	}
	
	// Create the final URL by appending the file name
	url = [NSMakeCollectable(CFURLCreateCopyAppendingPathComponent(NULL, (CFURLRef) url, (CFStringRef) [self.sourcePath lastPathComponent], false)) autorelease];
	success = (url != nil);
	if(success == NO) {
		[self didFail:@"Invalid FTP filename"]; return;
	}
	self.destinationURL = url;
	
	// Set up the bytes for upload progress
	bytesUploaded = 0;
	bytesTotal = [[[NSFileManager defaultManager] attributesOfItemAtPath:self.sourcePath error:nil] fileSize];
	
	// Output the URL we are getting
	[self didUpdateStatus:[NSString stringWithFormat:@"Put %@", [url absoluteString]]];
	
	// Create a place to put our data
	self.fileStream = [NSInputStream inputStreamWithFileAtPath:self.sourcePath];
	assert(self.fileStream != nil);
	
	// Open the file stream
	[self.fileStream open];
	
	// Create the FTP stream
	ftpStream = CFWriteStreamCreateWithFTPURL(NULL, (CFURLRef)url);
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
	if(self.fileStream != nil) {
		[self.fileStream close];
		self.fileStream = nil;
	}
}


#pragma mark -
#pragma mark Handle the stream

- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode {
    assert(aStream == self.networkStream);
	
    switch (eventCode) {
        case NSStreamEventOpenCompleted: {
            [self didUpdateStatus:@"Opened connection"];
        } break;
        case NSStreamEventHasBytesAvailable: {
            assert(NO);     // should never happen for the output stream
        } break;
        case NSStreamEventHasSpaceAvailable: {
            [self didUpdateStatus:@"Sending"];
            
            // If we don't have any data buffered, go read the next chunk of data.
            
            if (self.bufferOffset == self.bufferLimit) {
                NSInteger bytesRead;
                
                bytesRead = [self.fileStream read:self.buffer maxLength:kSendBufferSize];

                if (bytesRead == -1) {
                    [self didFail:@"Could not read from the local file"];
                } else if (bytesRead == 0) {
					[self didFinish];
					return;
                } else {
                    self.bufferOffset = 0;
                    self.bufferLimit  = bytesRead;
                }
            }
            
            // If we're not out of data completely, send the next chunk.
            if (self.bufferOffset != self.bufferLimit) {
                NSInteger   bytesWritten;
                bytesWritten = [self.networkStream write:&self.buffer[self.bufferOffset] maxLength:self.bufferLimit - self.bufferOffset];
				bytesUploaded += bytesWritten;
                assert(bytesWritten != 0);
                if (bytesWritten == -1) {
                    [self didFail:@"Data transfer with the server has failed"];
                } else {
                    self.bufferOffset += bytesWritten;
					[self didUpdateProgress];
                }
            }
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
	float progress = (float)((float)bytesUploaded/(float)bytesTotal);
	if(self.delegate != nil && [(NSObject*)self.delegate respondsToSelector:@selector(request:didUpdateProgress:)]) {
		[self.delegate request:self didUpdateProgress:progress];
	} else {
		NSLog(@"FTPPutRequest Progress: %f", progress);
	}
}

-(void)didFinish {
	[self stop];
	if(self.delegate != nil && [(NSObject*)self.delegate respondsToSelector:@selector(request:didUploadFile:toDestination:)]) {
		[self.delegate request:self didUploadFile:self.sourcePath toDestination:[ACFTPHelper urlByRemovingCredentials: self.destinationURL]];
	} else {
		NSLog(@"FTPPutRequest Uploaded: %@ to %@", self.sourcePath, [ACFTPHelper urlByRemovingCredentials: self.destinationURL]);
	}
}

-(void)didUpdateStatus:(NSString*)status {
	if(self.delegate != nil && [(NSObject*)self.delegate respondsToSelector:@selector(request:didUpdateStatus:)]) {
		[(NSObject*)self.delegate performSelector:@selector(request:didUpdateStatus:) withObject:self withObject:status];
	} else {
		NSLog(@"FTPPutRequest Status: %@", status);
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
		NSLog(@"FTPPutRequest Fail: %@", reason);
	}
}

#pragma mark -
#pragma mark Memory management

-(void)dealloc {
	[(NSObject*)delegate release];
	[networkStream release];
	[fileStream release];
	[destination release];
	[destinationURL release];
	[sourcePath release];
	[super dealloc];
}

@end
