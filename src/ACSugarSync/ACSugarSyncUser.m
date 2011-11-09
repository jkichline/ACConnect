//
//  ACSugarSyncUser.m
//  ACConnect
//
//  Created by Jason Kichline on 9/4/11.
//  Copyright (c) 2011 andCulture. All rights reserved.
//

#import "ACSugarSyncUser.h"
#import "ACHTTPRequest.h"
#import "ACSugarSyncCollection.h"
#import "ACSugarSyncFile.h"

@class ACSugarSyncCollection;
@class ACSugarSyncFile;

@implementation ACSugarSyncUser

@synthesize username, nickname, quota, usage;

#pragma mark - Initialization

-(id)initWithDictionary:(NSDictionary*)_dictionary andClient:(ACSugarSyncClient*)_client {
	NSAssert(_dictionary != nil, @"Dictionary is required");
	NSAssert(_client != nil, @"Client is required");
	if([_dictionary isKindOfClass:[NSDictionary class]] == NO) {
		NSLog(@"%@", _dictionary);
	}
	NSAssert([_dictionary isKindOfClass:[NSDictionary class]], @"Invalid dictionary type");
	self = [self init];
	if(self) {
		dictionary = [_dictionary retain];
		client = [_client retain];
	}
	return self;
}

+(ACSugarSyncUser*)userWithDictionary:(NSDictionary*)_dictionary andClient:(ACSugarSyncClient*)client {
	return [[[self alloc] initWithDictionary:_dictionary andClient:client] autorelease];
}

#pragma mark - Properties

-(NSString*)username {
	return [dictionary objectForKey:@"username"];
}

-(NSString*)nickname {
	return [dictionary objectForKey:@"nickname"];
}

-(int)quota {
	return [[[dictionary objectForKey:@"quota"] objectForKey:@"limit"] intValue];
}

-(int)usage {
	return [[[dictionary objectForKey:@"quota"] objectForKey:@"usage"] intValue];
}

#pragma mark - Methods

-(void)retrieveCollection:(ACSugarSyncCollectionType)type target:(id)target selector:(SEL)selector {
	[self retrieveCollection:type target:target selector:selector range:NSMakeRange(0, 0)];
}

-(void)retrieveCollection:(ACSugarSyncCollectionType)type target:(id)target selector:(SEL)selector range:(NSRange)range {
	NSString* key = nil;
	switch (type) {
		case ACSugarSyncAlbumsCollection: key = @"albums"; break;
		case ACSugarSyncDeletedCollection: key = @"deleted"; break;
		case ACSugarSyncMagicBriefcaseCollection: key = @"magicBriefcase"; break;
		case ACSugarSyncMobilePhotosCollection: key = @"mobilePhotos"; break;
		case ACSugarSyncPublicLinksCollection: key = @"publicLinks"; break;
		case ACSugarSyncReceivedSharesCollection: key = @"receivedShares"; break;
		case ACSugarSyncRecentActivitiesCollection: key = @"recentActivities"; break;
		case ACSugarSyncSyncFoldersCollection: key = @"syncfolders"; break;
		case ACSugarSyncWebArchiveCollection: key = @"webArchive"; break;
		case ACSugarSyncWorkspacesCollection: key = @"workspaces"; break;
		default: break;
	}
	NSString* url = [dictionary objectForKey:key];
	if(range.length > 0) {
		url = [url stringByAppendingString:[NSString stringWithFormat:@"?start=%d&max=%d", range.location, range.length]];
	}
	ACHTTPRequest* request = [client createRequest:[NSURL URLWithString:url] method:ACHTTPRequestMethodGet data:nil target:self selector:@selector(handleRetrieveCollection:)];
	request.payload = [NSDictionary dictionaryWithObjectsAndKeys:target, @"target", NSStringFromSelector(selector), @"selector", [NSNumber numberWithInt:(int)type], @"type", nil];
	[client sendRequest:request];
}

#pragma mark - Handlers

-(void)handleRetrieveCollection:(ACHTTPRequest*)request {
	id target = [request.payload objectForKey:@"target"];
	SEL selector = NSSelectorFromString([request.payload objectForKey:@"selector"]);
	if([request isKindOfClass:[ACHTTPRequest class]] && request.response.statusCode == 200) {
		if(target != nil && [target respondsToSelector:selector]) {
			NSMutableArray* a = [NSMutableArray array];
			[a addObjectsFromArray:[ACSugarSyncCollection collectionsFromArray:[[request.result objectForKey:@"collectionContents"] objectForKey:@"collection"] withClient:client]];
			[a addObjectsFromArray:[ACSugarSyncFile filesFromArray:[[request.result objectForKey:@"collectionContents"] objectForKey:@"file"] withClient:client]];
			[target performSelector:selector withObject:a];
		}
	}
}

#pragma mark - Memory Management

-(void)dealloc {
	[dictionary release];
	[client release];
	[super dealloc];
}

@end
