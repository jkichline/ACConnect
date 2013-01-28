//
//  ACWebDAVItem.m
//  ACWebDAVTest
//
//  Created by Jason Kichline on 8/19/10.
//  Copyright 2010 Jason Kichline. All rights reserved.
//

#import "ACWebDAVItem.h"
#import "ACWebDAV.h"
#import "ISO8601DateFormatter.h"
#import "NSDateRFC1123.h"




@implementation ACWebDAVItem

@synthesize type, href, displayName, creationDate, lastModifiedDate, location, delegate, lock;

-(id)initWithDictionary:(NSDictionary*)d
{
	if((self = [super init]))
    {
		// Set the type
		if([[d objectForKey:@"resourcetype"] isEqualToString:@"collection"]) {
			type = ACWebDAVItemTypeCollection;
		} else {
			type = ACWebDAVItemTypeFile;
		}
		
		// Set the href
		href = [[d objectForKey:@"href"] retain];
		
        // Set the display name
		displayName = [[d objectForKey:@"displayname"] retain];
        
        
        
        //===============================
        //        Date Setting
        //===============================
		// Set the creation date
        NSString *createDateStr = [d objectForKey:@"creationdate"];
        NSString *modifyDateStr = [d objectForKey:@"getlastmodified"];
        
		if(createDateStr != nil)
        {
            ISO8601DateFormatter *formatter = [[ISO8601DateFormatter alloc] init];
			creationDate = [formatter dateFromString:createDateStr];
            [formatter release];
            
            //change the GMT Date to localDate
            NSTimeZone *zone = [NSTimeZone systemTimeZone];
            NSInteger timeInterval = [zone secondsFromGMTForDate:creationDate];
            creationDate = [[creationDate  dateByAddingTimeInterval: timeInterval] retain];
		}
		// Set the last modified date
		if(modifyDateStr != nil)
        {
			lastModifiedDate = [NSDate dateFromRFC1123:modifyDateStr];
            
            //change the GMT Date to localDate
            NSTimeZone *zone = [NSTimeZone systemTimeZone];
            NSInteger timeInterval = [zone secondsFromGMTForDate:lastModifiedDate];
            lastModifiedDate = [[lastModifiedDate  dateByAddingTimeInterval: timeInterval] retain];
		}
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
-(NSString *)description
{
	NSString *typeStr = (self.type==ACWebDAVItemTypeCollection)?@"Collection":@"File";
	return [NSString stringWithFormat:@"=====item=====\n{\ttype:%@\n\tdisplayName:%@\n\thref:%@\n\tabsoluteHref:%@\n\tparentHref:%@\n\tabsoluteParentHref:%@\n\tcreationDate:%@\n\tlastModifiedDate:%@\n\turl:%@\n}",
            typeStr,
			self.displayName,
			self.href,
			self.absoluteHref,
			self.parentHref,
			self.absoluteParentHref,
			self.creationDate,
            self.lastModifiedDate,
            self.url];
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
