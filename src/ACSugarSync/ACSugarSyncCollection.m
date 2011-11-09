//
//  ACSugarSyncCollection.m
//  ACConnect
//
//  Created by Jason Kichline on 9/6/11.
//  Copyright (c) 2011 andCulture. All rights reserved.
//

#import "ACSugarSyncCollection.h"
#import "ACSugarSyncFile.h"

@interface ACSugarSyncCollection (Private)

-(NSMutableArray*)createCollections:(NSArray*)array;
-(NSMutableArray*)createFiles:(NSArray*)array;

@end

@implementation ACSugarSyncCollection

@synthesize displayName, type, ref;

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

+(ACSugarSyncCollection*)collectionWithDictionary:(NSDictionary*)_dictionary andClient:(ACSugarSyncClient*)client {
	return [[[self alloc] initWithDictionary:_dictionary andClient:client] autorelease];
}

#pragma mark - Properties

-(NSString*)displayName {
	return [dictionary objectForKey:@"displayName"];
}

-(NSString*)type {
	return [dictionary objectForKey:@"type"];
}

-(NSString*)description {
	return self.displayName;
}

-(NSURL*)ref {
	NSString* url = nil;
	if([dictionary objectForKey:@"ref"] != nil) {
		url = [dictionary objectForKey:@"ref"];
	} else {
		url = [dictionary objectForKey:@"contents"];
		url = [url substringToIndex:url.length - 9];
	}
	return [NSURL URLWithString:url];
}

#pragma mark - Methods

-(void)createFolderNamed:(NSString*)folderName {
	[self createFolderNamed:folderName target:nil selector:nil];
}

-(void)createFolderNamed:(NSString*)folderName target:(id)target selector:(SEL)selector {
	NSLog(@"Ref: %@", self.ref);
	NSDictionary* d = [NSDictionary dictionaryWithObject:[NSDictionary dictionaryWithObject:folderName forKey:@"displayName"] forKey:@"folder"];
	ACHTTPRequest* request = [client createRequest:self.ref method:ACHTTPRequestMethodPost data:d target:self selector:@selector(handleCreateFolderNamed:)];
	request.payload = [NSDictionary dictionaryWithObjectsAndKeys:target, @"target", NSStringFromSelector(selector), @"selector", nil];
	[client sendRequest:request];	
}

-(void)handleCreateFolderNamed:(ACHTTPRequest*)request {
	NSLog(@"Created Folder: %@", request.result);
	if([request isKindOfClass:[ACHTTPRequest class]] && request.response.statusCode == 200) {
		id target = [request.payload objectForKey:@"target"];
		SEL selector = NSSelectorFromString([request.payload objectForKey:@"selector"]);
		if(target != nil && [target respondsToSelector:selector]) {
		}
	}
}

-(void)contents:(id)target selector:(SEL)selector {
	ACHTTPRequest* request = [client createRequest:[NSURL URLWithString:[dictionary objectForKey:@"contents"]] method:ACHTTPRequestMethodGet data:nil target:self selector:@selector(handleContents:)];
	request.payload = [NSDictionary dictionaryWithObjectsAndKeys:target, @"target", NSStringFromSelector(selector), @"selector", nil];
	[client sendRequest:request];
}

-(void)handleContents:(ACHTTPRequest*)request {
	if([request isKindOfClass:[ACHTTPRequest class]] && request.response.statusCode == 200) {
		id target = [request.payload objectForKey:@"target"];
		SEL selector = NSSelectorFromString([request.payload objectForKey:@"selector"]);
		if(target != nil && [target respondsToSelector:selector]) {
			NSMutableArray* a = [NSMutableArray array];
			[a addObjectsFromArray:[ACSugarSyncCollection collectionsFromArray:[[request.result objectForKey:@"collectionContents"] objectForKey:@"collection"] withClient:client]];
			[a addObjectsFromArray:[ACSugarSyncFile filesFromArray:[[request.result objectForKey:@"collectionContents"] objectForKey:@"file"] withClient:client]];
			[target performSelector:selector withObject:a];
		}
	}
}

+(NSMutableArray*)collectionsFromArray:(NSArray*)array withClient:(ACSugarSyncClient*)client {
	NSMutableArray* a = [NSMutableArray array];
	if(array == nil) { return a; }
	if([array isKindOfClass:[NSArray class]]) {
		for(NSDictionary* item in array) {
			ACSugarSyncCollection* collection = [ACSugarSyncCollection collectionWithDictionary:item andClient:client];
			if(collection != nil) {
				[a addObject:collection];
			}
		}
	}
	
	else if([array isKindOfClass:[NSDictionary class]]) {
		ACSugarSyncCollection* collection = [ACSugarSyncCollection collectionWithDictionary:(NSDictionary*)array andClient:client];
		if(collection != nil) {
			[a addObject:collection];
		}
	}
	return a;
}

#pragma mark - Memory Management

-(void)dealloc {
	[client release];
	[dictionary release];
	[super dealloc];
}

@end
