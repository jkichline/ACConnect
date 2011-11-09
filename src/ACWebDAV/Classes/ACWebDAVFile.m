//
//  ACWebDAVFile.m
//  ACWebDAVTest
//
//  Created by Jason Kichline on 8/19/10.
//  Copyright 2010 Jason Kichline. All rights reserved.
//

#import "ACWebDAVFile.h"


@implementation ACWebDAVFile

@synthesize contentType, contentLength;

-(id)init {
	return [super init];
}

-(id)initWithDictionary:(NSDictionary *)d {
	if(self = [super initWithDictionary:d]) {
		contentType = [[d objectForKey:@"getcontenttype"] retain];
		contentLength = [[d objectForKey:@"getcontentlength"] longLongValue];
	}
	return self;
}

-(void)dealloc {
	[contentType release];
	[super dealloc];
}

@end
