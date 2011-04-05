//
//  FTPListRequest.m
//  OnSong
//
//  Created by Jason Kichline on 3/23/11.
//  Copyright 2011 andCulture. All rights reserved.
//

#import "ACFTPListRequest.h"
#import "ACFTPEntry.h"
#import "ACFTPError.h"
#include <sys/socket.h>
#include <sys/dirent.h>
#include <CFNetwork/CFNetwork.h>

@interface ACFTPListRequest (Private)

-(void)didListItems;
-(void)didUpdateStatus:(NSString*)status;
-(void)didFail:(id)reason;
-(void)parseListData;
-(NSDictionary*)_entryByReencodingNameInEntry:(NSDictionary *)entry encoding:(NSStringEncoding)newEncoding;
-(void)stop;

@end


@implementation ACFTPListRequest

@synthesize location, delegate, listData, listEntries, networkStream, showHiddenEntries, directoryURL;

#pragma mark -
#pragma mark Initialization

-(id)initWithLocation:(id)_location {
	if(self = [self init]) {
		self.location = _location;
	}
	return self;
}

+(ACFTPListRequest*)requestWithLocation:(id)_location {
	return [[[self alloc] initWithLocation:_location] autorelease];
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
	success = (url != nil);
	if(success == NO) {
		[self didFail:@"Invalid FTP location"]; return;
	}
	
	// Determine the URL dynamically
	if([self.location isKindOfClass:[NSURL class]]) {
		url = self.location;
	} else if([self.location respondsToSelector:@selector(urlWithCredentials)]) {
		url = [self.location performSelector:@selector(urlWithCredentials)];
	}
	
	if([[url absoluteString] hasSuffix:@"/"] == NO) {
		url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/", [url absoluteString]]];
	}
	
	// Set the directory URL
	self.directoryURL = url;
	
	// Output the URL we are getting
	[self didUpdateStatus:[NSString stringWithFormat:@"List %@", [url absoluteString]]];
	
	// Create a place to put our data
	self.listData = [NSMutableData data];
	assert(self.listData != nil);
	
	// Clear out the entries
	self.listEntries = [NSMutableArray array];
	
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

-(void)cancel {
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
    self.listData = nil;
}

#pragma mark -
#pragma mark Handle stream events

- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode {
    assert(aStream == self.networkStream);
	
    switch (eventCode) {
        case NSStreamEventOpenCompleted: {
            [self didUpdateStatus:@"Opened connection"];
        } break;
        case NSStreamEventHasBytesAvailable: {
            NSInteger bytesRead;
            uint8_t buffer[32768];
            [self didUpdateStatus:@"Receiving"];
            
            // Pull some data off the network.
            bytesRead = [self.networkStream read:buffer maxLength:sizeof(buffer)];
            if (bytesRead == -1) {
                [self didFail:@"Could not read the listing from the remote server"];
            } else if (bytesRead == 0) {
				[self didListItems];
            } else {
                assert(self.listData != nil);
                
                // Append the data to our listing buffer.
                [self.listData appendBytes:buffer length:bytesRead];

				// Parse the results
                [self parseListData];
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
			// Do nothing
        } break;
        default: {
            assert(NO);
        } break;
    }
}

- (void)parseListData {
    NSMutableArray* newEntries;
    NSUInteger offset;
    
	// Create a new array
    newEntries = [NSMutableArray array];
    assert(newEntries != nil);
    
    offset = 0;
    do {
        CFIndex         bytesConsumed;
        CFDictionaryRef thisEntry;
        
        thisEntry = NULL;
        assert(offset <= self.listData.length);

        bytesConsumed = CFFTPCreateParsedResourceListing(NULL, &((const uint8_t *) self.listData.bytes)[offset], self.listData.length - offset, &thisEntry);
        if (bytesConsumed > 0) {
			
            // It is possible for CFFTPCreateParsedResourceListing to return a 
            // positive number but not create a parse dictionary.  For example, 
            // if the end of the listing text contains stuff that can't be parsed, 
            // CFFTPCreateParsedResourceListing returns a positive number (to tell 
            // the caller that it has consumed the data), but doesn't create a parse 
            // dictionary (because it couldn't make sense of the data).  So, it's 
            // important that we check for NULL.
			
            if (thisEntry != NULL) {
                NSDictionary *  entryToAdd;
                
                // Try to interpret the name as UTF-8, which makes things work properly 
                // with many UNIX-like systems, including the Mac OS X built-in FTP 
                // server.  If you have some idea what type of text your target system 
                // is going to return, you could tweak this encoding.  For example, 
                // if you know that the target system is running Windows, then 
                // NSWindowsCP1252StringEncoding would be a good choice here.
                // 
                // Alternatively you could let the user choose the encoding up 
                // front, or reencode the listing after they've seen it and decided 
                // it's wrong.
                //
                // Ain't FTP a wonderful protocol!
				
                entryToAdd = [self _entryByReencodingNameInEntry:(NSDictionary *) thisEntry encoding:NSUTF8StringEncoding];
                ACFTPEntry* ftpEntry = [ACFTPEntry entryWithDictionary:entryToAdd];
				if([self.location isKindOfClass:[ACFTPLocation class]]) {
					ftpEntry.parent = self.location;
				} else {
					ftpEntry.parent = [ACFTPLocation locationWithURL:self.directoryURL];
				}
				if([ftpEntry.name hasPrefix:@"."] == NO) {
					[newEntries addObject:ftpEntry];
				}
            }
            
            // We consume the bytes regardless of whether we get an entry.
            
            offset += bytesConsumed;
        }
        
        if (thisEntry != NULL) {
            CFRelease(thisEntry);
        }
        
        if (bytesConsumed == 0) {
            // We haven't yet got enough data to parse an entry.  Wait for more data 
            // to arrive.
            break;
        } else if (bytesConsumed < 0) {
            // We totally failed to parse the listing.  Fail.
            [self didFail:@"Listing parse failed"];
            break;
        }
    } while (YES);
	
    if (newEntries.count != 0) {
		[self.listEntries addObjectsFromArray:newEntries];
    }
    if (offset != 0) {
        [self.listData replaceBytesInRange:NSMakeRange(0, offset) withBytes:NULL length:0];
    }
}

- (NSDictionary*)_entryByReencodingNameInEntry:(NSDictionary *)entry encoding:(NSStringEncoding)newEncoding {
	
	// CFFTPCreateParsedResourceListing always interprets the file name as MacRoman, 
	// which is clearly bogus <rdar://problem/7420589>.  This code attempts to fix 
	// that by converting the Unicode name back to MacRoman (to get the original bytes; 
	// this works because there's a lossless round trip between MacRoman and Unicode) 
	// and then reconverting those bytes to Unicode using the encoding provided. 
	
    NSDictionary *  result;
    NSString *      name;
    NSData *        nameData;
    NSString *      newName;
    
    newName = nil;
    
    // Try to get the name, convert it back to MacRoman, and then reconvert it 
    // with the preferred encoding.
    
    name = [entry objectForKey:(id) kCFFTPResourceName];
    if (name != nil) {
        assert([name isKindOfClass:[NSString class]]);
        
        nameData = [name dataUsingEncoding:NSMacOSRomanStringEncoding];
        if (nameData != nil) {
            newName = [[[NSString alloc] initWithData:nameData encoding:newEncoding] autorelease];
        }
    }
    
    // If the above failed, just return the entry unmodified.  If it succeeded, 
    // make a copy of the entry and replace the name with the new name that we 
    // calculated.
    
    if (newName == nil) {
        assert(NO); // in the debug builds, if this fails, we should investigate why
        result = (NSDictionary *) entry;
    } else {
        NSMutableDictionary *   newEntry;
        
        newEntry = [[entry mutableCopy] autorelease];
        assert(newEntry != nil);
        
        [newEntry setObject:newName forKey:(id) kCFFTPResourceName];
        
        result = newEntry;
    }
    
    return result;
}

#pragma mark -
#pragma mark Delegate methods

-(void)didListItems {
	[self stop];
	if(self.delegate != nil && [(NSObject*)self.delegate respondsToSelector:@selector(request:didListEntries:)]) {
		[(NSObject*)self.delegate performSelector:@selector(request:didListEntries:) withObject:self withObject:self.listEntries];
	} else {
		for(NSDictionary* entry in self.listEntries) {
			NSLog(@"FTPListRequest Entry: %@", entry);
		}
	}
}

-(void)didUpdateStatus:(NSString*)status {
	if(self.delegate != nil && [(NSObject*)self.delegate respondsToSelector:@selector(request:didUpdateStatus:)]) {
		[(NSObject*)self.delegate performSelector:@selector(request:didUpdateStatus:) withObject:self withObject:status];
	} else {
		NSLog(@"FTPListRequest Status: %@", status);
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
		NSLog(@"FTPListRequest Fail: %@", reason);
	}
}

#pragma mark -
#pragma mark Memory management

-(void)dealloc {
	[(NSObject*)delegate release];
	[location release];
	[listData release];
	[listEntries release];
	[networkStream release];
	[super dealloc];
}

@end
