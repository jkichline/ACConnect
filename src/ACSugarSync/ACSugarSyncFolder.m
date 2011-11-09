//
//  ACSugarSyncFolder.m
//  ACConnect
//
//  Created by Jason Kichline on 9/5/11.
//  Copyright (c) 2011 andCulture. All rights reserved.
//

#import "ACSugarSyncFolder.h"

@implementation ACSugarSyncFolder

@synthesize displayName, timeCreated;

#pragma mark - Initialization

-(id)initWithDictionary:(NSDictionary*)_dictionary andClient:(ACSugarSyncClient*)_client {
	self = [self init];
	if(self) {
		dictionary = [_dictionary retain];
		client = [_client retain];
	}
	return self;
}

+(ACSugarSyncFolder*)folderWithDictionary:(NSDictionary*)_dictionary andClient:(ACSugarSyncClient*)client {
	return [[[self alloc] initWithDictionary:_dictionary andClient:client] autorelease];
}

#pragma mark - Properties

-(NSString*)displayName {
	return [dictionary objectForKey:@"displayName"];
}

-(NSDate*)timeCreated {
	return [dictionary objectForKey:@"timeCreated"];
}

-(NSString*)description {
	return self.displayName;
}

#pragma mark - Memory Management

-(void)dealloc {
	[client release];
	[dictionary release];
	[super dealloc];
}

@end
