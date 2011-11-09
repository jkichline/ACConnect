//
//  ACWebDAVCollection.m
//  ACWebDAVTest
//
//  Created by Jason Kichline on 8/19/10.
//  Copyright 2010 Jason Kichline. All rights reserved.
//

#import "ACWebDAVCollection.h"

@implementation ACWebDAVCollection

@synthesize contents;

-(id)initWithLocation:(ACWebDAVLocation*)_location {
	if(self = [self init]) {
		type = ACWebDAVItemTypeCollection;
		NSString* host = _location.host;
		href = [[[_location.url absoluteString] substringFromIndex:host.length] retain];
		creationDate = [[NSDate date] retain];
		lastModifiedDate = [[NSDate date] retain];
		displayName = nil;
		self.location = _location;
	}
	return self;
}

-(NSMutableArray*)contents {
	if(contents == nil) {
		contents = [[NSMutableArray alloc] init];
	}
	return contents;
}

-(void)dealloc {
	[contents release];
	[super dealloc];
}

@end
