//
//  FTPEntry.m
//  OnSong
//
//  Created by Jason Kichline on 3/23/11.
//  Copyright 2011 andCulture. All rights reserved.
//

#import "ACFTPEntry.h"
#include <sys/socket.h>
#include <sys/dirent.h>
#include <CFNetwork/CFNetwork.h>

@interface ACFTPEntry (Private)

-(NSString*)padInteger:(int)integer;

@end


@implementation ACFTPEntry

@synthesize modified, owner, group, link, name, size, type, mode, parent;

-(id)initWithDictionary:(NSDictionary*)entry {
	self = [self init];
	if(self) {
		self.group = [entry objectForKey:(id)kCFFTPResourceGroup];
		self.link = [entry objectForKey:(id)kCFFTPResourceLink];
		self.modified = [entry objectForKey:(id)kCFFTPResourceModDate];
		self.mode = [[entry objectForKey:(id)kCFFTPResourceSize] intValue];
		self.name = [entry objectForKey:(id)kCFFTPResourceName];
		self.owner = [entry objectForKey:(id)kCFFTPResourceOwner];
		self.size = [[entry objectForKey:(id)kCFFTPResourceSize] intValue];
		self.type = [[entry objectForKey:(id)kCFFTPResourceType] intValue];
	}
	return self;
}

+(ACFTPEntry*)entryWithDictionary:(NSDictionary*)entry {
	return [[[self alloc] initWithDictionary:entry] autorelease];
}

-(NSString*)permissions {
	char modeCStr[12];
	strmode(self.mode + DTTOIF(type), modeCStr);
	return [NSString stringWithUTF8String:modeCStr];
}

-(NSString*)description {
	static NSDateFormatter* formatter;
	if(formatter == nil) {
		formatter = [[NSDateFormatter alloc] init];
		[formatter setDateFormat:@"MMM dd yyyy hh:mm:ss"];
	}
	
	return [NSString stringWithFormat:@"%@\t%@\t%@\t%@\t%@\t%@", 
			self.permissions,
			self.owner,
			self.group,
			[self padInteger:self.size],
			[formatter stringFromDate:self.modified],
			self.name];
}

-(NSURL*)url {
	if(self.parent == nil) { return nil; }
	NSString* baseUrl = [self.parent.url absoluteString];
	if([baseUrl hasSuffix:@"/"] == NO) {
		baseUrl = [NSString stringWithFormat:@"%@/", baseUrl];
	}
	NSString* str = [NSString stringWithFormat:@"%@%@", baseUrl, [self.name stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
	return [NSURL URLWithString:str];
}

-(NSURL*)urlWithCredentials {
	if(self.parent == nil) { return nil; }
	NSString* baseUrl = [self.parent.urlWithCredentials absoluteString];
	if([baseUrl hasSuffix:@"/"] == NO) {
		baseUrl = [NSString stringWithFormat:@"%@/", baseUrl];
	}
	return [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", baseUrl, [self.name stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
}

-(NSString*)padInteger:(int)integer {
	NSString* o = [NSString stringWithFormat:@"            %d", integer];
	return [o substringFromIndex:o.length - 12];
}

@end
