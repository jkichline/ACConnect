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

-(NSString *)description
{
    NSString *typeStr = (self.type==ACWebDAVItemTypeCollection)?@"Collection":@"File";
	return [NSString stringWithFormat:@"\n=====item=====\n{\ttype:%@\n\tdisplayName:%@\n\thref:%@\n\tabsoluteHref:%@\n\tparentHref:%@\n\tabsoluteParentHref:%@\n\tcreationDate:%@\n\tlastModifiedDate:%@\n\turl:%@\n\tcontentType:%@\n\tcontentLength:%lld\n}",
            typeStr,
			self.displayName,
			self.href,
			self.absoluteHref,
			self.parentHref,
			self.absoluteParentHref,
			self.creationDate,
            self.lastModifiedDate,
            self.url,
            self.contentType,
            self.contentLength];
}

-(void)dealloc {
	[contentType release];
	[super dealloc];
}

@end
