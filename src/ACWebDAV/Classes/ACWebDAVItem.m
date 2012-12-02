//
//  ACWebDAVItem.m
//  ACWebDAVTest
//
//  Created by Jason Kichline on 8/19/10.
//  Copyright 2010 Jason Kichline. All rights reserved.
//

#import "ACWebDAVItem.h"
#import "ACWebDAV.h"

@implementation ACWebDAVItem

@synthesize type, href, displayName, creationDate, lastModifiedDate, location, delegate, lock;

-(id)initWithDictionary:(NSDictionary*)d {
	if((self = [super init])) {
		
		// Set the type
		if([[d objectForKey:@"resourcetype"] isEqualToString:@"collection"]) {
			type = ACWebDAVItemTypeCollection;
		} else {
			type = ACWebDAVItemTypeFile;
		}
		
		// Set the href
		href = [[d objectForKey:@"href"] retain];
		
		static NSDateFormatter* dateFormatter;
		if(dateFormatter == nil) {
			dateFormatter = [[NSDateFormatter alloc] init];
			[dateFormatter setDateFormat:@"EEE, dd MMM yyyy HH:mm:ss Z"];
		}
		
		// Set the creation date
		if([d objectForKey:@"creationdate"] != nil) {
			creationDate = [[dateFormatter dateFromString:[d objectForKey:@"creationdate"]] retain];
		}
		
		// Set the last modified date
		if([d objectForKey:@"getlastmodified"] != nil) {
			lastModifiedDate = [[dateFormatter dateFromString:[d objectForKey:@"getlastmodified"]] retain];
		}
		
		// Set the display name
		displayName = [[d objectForKey:@"displayname"] retain];
		
	}
	return self;
}

+(ACWebDAVItem*)itemWithLocation:(ACWebDAVLocation *)_location {
	return [[[self alloc] initWithLocation:_location] autorelease];
}

-(id)initWithLocation:(ACWebDAVLocation *)_location {
	if(self = [self init]) {
		self.location = _location;
		self.lock = nil;
		href = [[[_location.url absoluteString] substringFromIndex:_location.host.length] retain];
		if([[href lastPathComponent] isEqualToString:@""]) {
			type = ACWebDAVItemTypeCollection;
		} else {
			type = ACWebDAVItemTypeFile;
		}
	}
	return self;
}

-(NSString*)displayName {
	if(displayName == nil || displayName.length == 0) {
		return [[href lastPathComponent] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
	} else {
		return displayName;
	}
}

-(NSString*)parentHref {
	NSString* parentHref = href;
	if([parentHref hasSuffix:@"/"]) {
		parentHref = [parentHref substringToIndex:parentHref.length-1];
	}
	parentHref = [parentHref substringToIndex:parentHref.length-[parentHref lastPathComponent].length];
	if([parentHref rangeOfString:@"://"].length > 0) {
		parentHref = [[NSURL URLWithString:parentHref] relativePath];
	}
	return parentHref;
}

-(NSString*)href {
	if(href == nil) {
		href = [[[self.location.url absoluteString] substringFromIndex:self.location.host.length] retain];
	}
	if([href rangeOfString:@"://"].length > 0) {
		NSString* newHref = [[NSURL URLWithString:href] relativePath];
		[href release];
		href = [newHref retain];
	}
	return href;
}

-(NSString*)absoluteHref {
	return [[self.location.url absoluteString] stringByAppendingPathComponent:self.href];
}

-(NSString*)absoluteParentHref {
	return [[self.location.url absoluteString] stringByAppendingPathComponent:self.parentHref];
}

-(NSURL*)url {
	NSString* s = [self.location.host stringByAppendingString:self.href];
	return [NSURL URLWithString:s];
}

-(void)getProperties {
	ACWebDAVLocation* l = [ACWebDAVLocation locationWithHost:self.location.host href:self.href username:self.location.username password:self.location.password];
	ACWebDAVPropertyRequest* request = [ACWebDAVPropertyRequest requestWithLocation:l];
	request.depth = 0;
	request.properties = ACWebDAVPropertyAllProperties;
	request.delegate = (id<ACWebDAVPropertyRequestDelegate>)self;
	[request start];
}

-(void)request:(ACWebDAVPropertyRequest *)request didReceiveProperties:(NSArray*)properties {
	if(self.delegate != nil && [(NSObject*)self.delegate respondsToSelector:@selector(ACWebDAVItem:didReceiveProperties:)]) {
		[self.delegate ACWebDAVItem:self didReceiveProperties:[properties objectAtIndex:0]];
	}
}

-(void)dealloc {
 	[href release];
	[displayName release];
	[creationDate release];
	[lastModifiedDate release];
	[location release];
	[delegate release];
	[super dealloc];
}

@end
