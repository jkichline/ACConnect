//
//  ACWebDAVPropertyRequest.m
//  ACWebDAVTest
//
//  Created by Jason Kichline on 8/19/10.
//  Copyright 2010 Jason Kichline. All rights reserved.
//

#import "ACWebDAVPropertyRequest.h"
#import "TouchXML.h"
#import "ACWebDAV.h"

@implementation ACWebDAVPropertyRequest

@synthesize properties, receivedData, depth, delegate, location;

-(id)init {
	if(self = [super init]) {
		depth = 0;
		self.receivedData = [NSMutableData data];
		self.properties = ACWebDAVPropertyAllProperties;
	}
	return self;
}

-(id)initWithLocation:(ACWebDAVLocation*)_location {
	if(self = [self init]) {
		self.location = _location;
	}
	return self;
}

+(ACWebDAVPropertyRequest*)requestWithLocation:(ACWebDAVLocation*)_location {
	return [[[self alloc] initWithLocation:_location] autorelease];
}

+(ACWebDAVPropertyRequest*)requestForItem:(ACWebDAVItem*)_item delegate:(id<ACWebDAVPropertyRequestDelegate>)_delegate {
	ACWebDAVPropertyRequest* request = [self requestWithLocation:_item.location];
	request.delegate = _delegate;
	return request;
}

-(void)start {
	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
	NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:self.location.url];
	[request setHTTPMethod:@"PROPFIND"];
	[request setValue:@"text/xml" forHTTPHeaderField:@"Content-Type"];
	if(self.depth == ACWebDAVInfinityDepth) {
		[request setValue:@"Infinity" forHTTPHeaderField:@"Depth"];
	} else {
		[request setValue:[NSString stringWithFormat:@"%d", self.depth] forHTTPHeaderField:@"Depth"];
	}
	[request setHTTPBody:self.body];
	NSURLConnection* conn = [[NSURLConnection alloc] initWithRequest:request delegate:self];
	[conn start];
}

-(NSData*)body {
	NSMutableString* o = [NSMutableString string];
	[o appendString:@"<?xml version=\"1.0\" encoding=\"utf-8\"?>\n"];
	[o appendString:@"<D:propfind xmlns:D=\"DAV:\">\n"];
	[o appendString:@"	<D:prop>"];
	[o appendString:@"		<D:resourcetype/>\n"];
	
	if((self.properties & ACWebDAVPropertyCreationDate) == ACWebDAVPropertyCreationDate) {
		[o appendString:@"		<D:creationdate/>\n"];
	}
	
	if((self.properties & ACWebDAVPropertyLastModifiedDate) == ACWebDAVPropertyLastModifiedDate) {
		[o appendString:@"		<D:getlastmodified/>\n"];
	}
	
	if((self.properties & ACWebDAVPropertyDisplayName) == ACWebDAVPropertyDisplayName) {
		[o appendString:@"		<D:displayname/>\n"];
	}
	
	if((self.properties & ACWebDAVPropertyContentLength) == ACWebDAVPropertyContentLength) {
		[o appendString:@"		<D:getcontentlength/>\n"];
	}
	
	if((self.properties & ACWebDAVPropertyContentType) == ACWebDAVPropertyContentType) {
		[o appendString:@"		<D:getcontenttype/>\n"];
	}
	
	if((self.properties & ACWebDAVPropertyLockDiscovery) == ACWebDAVPropertyLockDiscovery) {
		[o appendString:@"		<D:lockdiscovery/>\n"];
	}
	
	if((self.properties & ACWebDAVPropertySupportedLock) == ACWebDAVPropertySupportedLock) {
		[o appendString:@"		<D:supportedlock/>\n"];
	}
	
	[o appendString:@"	</D:prop>"];
	[o appendString:@"</D:propfind>"];
	
	return [o dataUsingEncoding:NSUTF8StringEncoding];
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

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSHTTPURLResponse *)response {
    [self.receivedData setLength:0];
	if([response statusCode] != 200 && [response statusCode] != 207) {
		if(self.delegate != nil && [(NSObject*)self.delegate respondsToSelector:@selector(request:didFailWithErrorCode:)]) {
			[self.delegate request:self didFailWithErrorCode:[response statusCode]];
		}
		[connection cancel];
		[connection release];
		return;
	}
}

-(void)connection:(NSURLConnection*)connection didReceiveData:(NSData*)data {
    [self.receivedData appendData:data];
}

-(void)connectionDidFinishLoading:(NSURLConnection *)connection {
	
	// Stop the network activity
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	
	// Create the XML
	NSError* error = nil;
	CXMLDocument* xml = [[CXMLDocument alloc] initWithData:self.receivedData options:0 error:&error];
	self.receivedData = [NSMutableData data];
	
	// If we have an error, then handle it
	if(error != nil) {
		if(self.delegate != nil && [(NSObject*)self.delegate respondsToSelector:@selector(request:didFailWithError:)]) {
			[self.delegate request:self didFailWithError:error];
		}
		[connection release];
		[xml release];
		return;
	}
	
	// Get each resource
	NSMutableArray* items = [NSMutableArray array];
	NSMutableArray* p = [NSMutableArray array];
	
	// Store a dictionary so we can add subitems
	ACWebDAVLock* lock = nil;
	NSMutableDictionary* collections = [NSMutableDictionary dictionary];
	
	for(CXMLNode* response in [[xml rootElement] children]) {
		if([response kind] == CXMLElementKind && [[response localName] isEqualToString:@"response"]) {
			
			// Create a dictionary
			NSMutableDictionary* d = [NSMutableDictionary dictionary];
			for(CXMLNode* child in [response children]) {
				if([[child localName] isEqualToString:@"href"]) {
					[d setObject:[child stringValue] forKey:@"href"];
				} else if([[child name] isEqualToString:@"propstat"]) {
					for(CXMLNode* propstat in [child children]) {
						if([[propstat localName] isEqualToString:@"prop"]) {
							for(CXMLNode* prop in [propstat children]) {
								if([prop kind] == CXMLElementKind) {
									if([[prop localName] isEqualToString:@"resourcetype"]) {
										for (CXMLNode* node in [prop children]) {
											if ([node kind] == CXMLElementKind) {
												[d setObject:[node localName] forKey:@"resourcetype"];
											}
										}
									} else if([[prop localName] isEqualToString:@"lockdiscovery"]) {
										lock = [ACWebDAVLock lockWithNode:prop];
									} else {
										NSString* value = [prop stringValue];
										if(value != nil) {
											[d setObject:value forKey:[prop localName]];
										}
									}
								}
							}
						}
					}
				}
			}
			
			// Create the type of object based on that
			ACWebDAVItem* item;
			if([[d objectForKey:@"resourcetype"] isEqualToString:@"collection"]) {
				item = [[ACWebDAVCollection alloc] initWithDictionary:d];
				item.lock = lock;
/*
				NSString* href = item.href;
				if([href hasSuffix:@"/"] == NO) {
					href = [NSString stringWithFormat:@"%@/", href];
				}
				if([item.parentHref hasPrefix:self.location.host] && [href hasPrefix:self.location.host] == NO) {
					href = [NSString stringWithFormat:@"%@%@", self.location.host, href];
				}
				NSLog(@"href: %@; parentHref: %@", href, item.parentHref);
*/
				[collections setObject:item forKey:item.href];
			} else {
				item = [[ACWebDAVFile alloc] initWithDictionary:d];
				item.lock = lock;
			}
			
			// Set the host of the item for further requests
			item.location = [ACWebDAVLocation locationWithHost:self.location.host href:item.href username:self.location.username password:self.location.password];
			
			// If this item's parent is in the collections list, then add it as a subitem
			ACWebDAVCollection* parent = [collections objectForKey:item.parentHref];
			if(parent != nil) {
				[parent.contents addObject:item];
				
			// Otherwise, just add it to the root
			} else {
				[items addObject:item];
			}
			
			// Release the item
			[p addObject:item];
			[item release];
		}
	}
	[xml release];
	
	// Fire the received properties delegate
	if(self.delegate != nil && [(NSObject*)self.delegate respondsToSelector:@selector(request:didReceiveProperties:)]) {
		[self.delegate request:self didReceiveProperties:p];
	}

	// Fire the returned items delegate
	if(self.delegate != nil && [(NSObject*)self.delegate respondsToSelector:@selector(request:didReturnItems:)]) {
		[self.delegate request:self didReturnItems:items];
	}
	
	[connection release];
}

-(void)connection:(NSURLConnection*)connection didFailWithError:(NSError*)error {
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	[connection release];
}


@end
