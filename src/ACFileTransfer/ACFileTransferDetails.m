//
//  ACFileTransferDetails.m
//  OnSong
//
//  Created by Jason Kichline on 8/19/11.
//  Copyright (c) 2011 Jason Kichline. All rights reserved.
//

#import "ACFileTransferDetails.h"

@implementation ACFileTransferDetails

@synthesize peer, digest, UUID, filename, bytes, data, total, start, length;

-(id)initWithDictionary:(NSDictionary *)dictionary {
	self = [self init];
	if(self) {
		self.peer = [dictionary objectForKey:@"peer"];
		self.digest = [dictionary objectForKey:@"peer"];
		self.UUID = [dictionary objectForKey:@"uuid"];
		self.filename = [dictionary objectForKey:@"filename"];
		self.data = [dictionary objectForKey:@"data"];
		
		self.bytes = [[dictionary objectForKey:@"bytes"] intValue];
		self.total = [[dictionary objectForKey:@"total"] intValue];
		self.start = [[dictionary objectForKey:@"start"] intValue];
		self.length = [[dictionary objectForKey:@"length"] intValue];
	}
	return self;
}

+(ACFileTransferDetails*)detailsWithDictionary:(NSDictionary*)dictionary {
	return [[[self alloc] initWithDictionary:dictionary] autorelease];
}

@end
