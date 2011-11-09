//
//  ACSugarSyncFile.m
//  ACConnect
//
//  Created by Jason Kichline on 9/6/11.
//  Copyright (c) 2011 andCulture. All rights reserved.
//

#import "ACSugarSyncFile.h"
#import "ACHTTPDownloader.h"

@class ACSugarSyncClient;

@implementation ACSugarSyncFile

@synthesize displayName, timeCreated, lastModified, mediaType, presentOnServer, size;

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

+(ACSugarSyncFile*)fileWithDictionary:(NSDictionary*)_dictionary andClient:(ACSugarSyncClient*)client {
	return [[[self alloc] initWithDictionary:_dictionary andClient:client] autorelease];
}

#pragma mark - Properties

-(NSString*)displayName {
	return [dictionary objectForKey:@"displayName"];
}

-(NSDate*)timeCreated {
	return [dictionary objectForKey:@"timeCreated"];
}

-(NSDate*)lastModified {
	return [dictionary objectForKey:@"lastModified"];
}

-(NSString*)mediaType {
	return [dictionary objectForKey:@"mediaType"];
}

-(BOOL)presentOnServer {
	return [[dictionary objectForKey:@"presentOnServer"] boolValue];
}

-(int)size {
	return [[dictionary objectForKey:@"size"] intValue];
}

-(NSString*)description {
	return self.displayName;
}

#pragma mark - Methods

-(void)fileData:(id)target selector:(SEL)selector {
	ACHTTPRequest* request = [client createRequest:[NSURL URLWithString:[dictionary objectForKey:@"fileData"]] method:ACHTTPRequestMethodGet data:nil target:self selector:@selector(handleFileData:)];
	request.payload = [NSDictionary dictionaryWithObjectsAndKeys:target, @"target", NSStringFromSelector(selector), @"selector", nil];
	[client sendRequest:request];
}

-(void)handleFileData:(ACHTTPRequest*)request {
	if([request isKindOfClass:[ACHTTPRequest class]] && request.response.statusCode == 200) {
		id target = [request.payload objectForKey:@"target"];
		SEL selector = NSSelectorFromString([request.payload objectForKey:@"selector"]);
		if(target != nil && [target respondsToSelector:selector]) {
			[target performSelector:selector withObject:request.result];
		}
	}
}

-(void)versions:(id)target selector:(SEL)selector {
	ACHTTPRequest* request = [client createRequest:[NSURL URLWithString:[dictionary objectForKey:@"versions"]] method:ACHTTPRequestMethodGet data:nil target:self selector:@selector(handleVersions:)];
	request.payload = [NSDictionary dictionaryWithObjectsAndKeys:target, @"target", NSStringFromSelector(selector), @"selector", nil];
	[client sendRequest:request];
}

-(void)handleVersions:(ACHTTPRequest*)request {
	if([request isKindOfClass:[ACHTTPRequest class]] && request.response.statusCode == 200) {
		id target = [request.payload objectForKey:@"target"];
		SEL selector = NSSelectorFromString([request.payload objectForKey:@"selector"]);
		if(target != nil && [target respondsToSelector:selector]) {
			NSArray* a = [ACSugarSyncFile filesFromArray:[[request.result objectForKey:@"fileVersions"] objectForKey:@"fileVersion"] withClient:client];
			[target performSelector:selector withObject:a];
		}
	}
}

-(void)downloadFile {
	[self downloadFileTo:nil];
}

-(void)downloadFileTo:(NSString *)filepath {
	[self downloadFileTo:filepath target:nil selector:nil];
}

-(void)downloadFileTo:(NSString *)filepath target:(id)target selector:(SEL)selector {
	ACHTTPDownloader* downloader = [ACHTTPDownloader downloaderWithDelegate:target action:selector];
	downloader.modifiers = [NSArray arrayWithObject:client];
	downloader.filename = self.displayName;
	[downloader download:[dictionary objectForKey:@"fileData"] toPath:filepath];
}
			 
#pragma mark - Array Creation
			 
+(NSMutableArray*)filesFromArray:(NSArray*)array withClient:(ACSugarSyncClient*)client {
	NSMutableArray* a = [NSMutableArray array];
	if(array == nil) { return a; }

	if([array isKindOfClass:[NSArray class]]) {
		for(NSDictionary* item in array) {
			ACSugarSyncFile* file = [ACSugarSyncFile fileWithDictionary:item andClient:client];
			if(file != nil) {
				if([file.displayName hasPrefix:@"."] == NO || ACSugarSyncClientShowHiddenFiles == (client.options & ACSugarSyncClientShowHiddenFiles)) {
					[a addObject:file];
				}
			}
		}
	}
	
	else if([array isKindOfClass:[NSDictionary class]]) {
		ACSugarSyncFile* file = [ACSugarSyncFile fileWithDictionary:(NSDictionary*)array andClient:client];
		if(file != nil) {
			if([file.displayName hasPrefix:@"."] == NO || ACSugarSyncClientShowHiddenFiles == (client.options & ACSugarSyncClientShowHiddenFiles)) {
				[a addObject:file];
			}
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
