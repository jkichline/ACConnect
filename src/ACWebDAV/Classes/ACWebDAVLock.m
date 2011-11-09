//
//  ACWebDAVLock.m
//  ACWebDAVTest
//
//  Created by Jason Kichline on 8/20/10.
//  Copyright 2010 Jason Kichline. All rights reserved.
//

#import "ACWebDAVLock.h"
#import "CXMLNode+ACWebDAV.h"

@implementation ACWebDAVLock

@synthesize exclusive, recursive, timeout, owner, token;

-(id)init {
	if(self = [super init]) {
		exclusive = YES;
		recursive = NO;
		self.owner = @"http://www.mobilu.com/ACWebDAV/";
	}
	return self;
}

+(ACWebDAVLock*)lockWithData:(NSData*)data {
	NSError* error = nil;
	CXMLDocument* xml = [[CXMLDocument alloc] initWithData:data options:0 error:&error];
	if(error != nil) {
		[xml release];
		return nil;
	}
	ACWebDAVLock* lock = [self lockWithNode:xml];
	[xml release];
	return lock;
}

+(ACWebDAVLock*)lockWithNode:(CXMLNode*)node {
	ACWebDAVLock* lock = [[[ACWebDAVLock alloc] init] autorelease];
	lock.exclusive = ([node elementNamed:@"exclusive" withPrefix:nil] != nil);
	lock.recursive = ([[[node elementNamed:@"depth" withPrefix:nil] stringValue] isEqualToString:@"Infinity"]);
	lock.timeout = [[[[[node elementNamed:@"timeout" withPrefix:nil] stringValue] componentsSeparatedByString:@"-"] lastObject] intValue];
	lock.owner = [[[node elementNamed:@"owner" withPrefix:nil] stringValue] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@" \t\n"]];
	lock.token = [[[node elementNamed:@"locktoken" withPrefix:nil] stringValue] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@" \t\n"]];
	return lock;
}

+(ACWebDAVLock*)lockWithToken:(NSString*)_token {
	ACWebDAVLock* lock = [[[ACWebDAVLock alloc] init] autorelease];
	lock.token = _token;
	return lock;
}

@end
