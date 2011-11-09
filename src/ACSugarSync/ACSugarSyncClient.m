//
//  ACSugarSyncClient.m
//  ACConnect
//
//  Created by Jason Kichline on 9/3/11.
//  Copyright (c) 2011 andCulture. All rights reserved.
//

#import "ACSugarSyncClient.h"

#define SUGARSYNC_API_ENDPOINT @"https://api.sugarsync.com"

NSString* const ACSugarSyncAuthorizationCompleteNotification = @"ACSugarSyncAuthorizationCompleteNotification";
NSString* const ACSugarSyncRetrievedUserNotification = @"ACSugarSyncRetrievedUserNotification";

@interface ACSugarSyncClient (Private)

-(NSURL*)URLWithFragment:(NSString*)fragment;

@end

@implementation ACSugarSyncClient

@synthesize authorizationToken, userURL, options;

#pragma mark - Initialization

-(id)init {
	self = [super init];
	if(self) {
		self.options = ACSugarSyncClientNoOptions;
		requestQueue = [[NSMutableArray alloc] init];
	}
	return self;
}

-(id)initWithUsername:(NSString*)_username password:(NSString*)_password accessKey:(NSString*)_accessKey privateAccessKey:(NSString*)_privateAccessKey {
	self = [self init];
	if(self) {
		authorizationPackage = [[NSDictionary alloc] initWithObjectsAndKeys:
								[NSDictionary dictionaryWithObjectsAndKeys:
								 _username, @"username", 
								 _password, @"password",
								 _accessKey, @"accessKeyId", 
								 _privateAccessKey, @"privateAccessKey",
								 nil], @"authRequest", nil];
	}
	return self;
}

+(ACSugarSyncClient*)clientWithUsername:(NSString*)_username password:(NSString*)_password accessKey:(NSString*)_accessKey privateAccessKey:(NSString*)_privateAccessKey {
	return [[[self alloc] initWithUsername:_username password:_password accessKey:_accessKey privateAccessKey:_privateAccessKey] autorelease];
}

#pragma mark - Authorization

-(void)authorize {
	[self authorize:nil selector:nil];
}

-(void)authorize:(id)target selector:(SEL)selector {
	NSString* url = [NSString stringWithFormat:@"%@/authorization", SUGARSYNC_API_ENDPOINT];
	ACHTTPRequest* request = [ACHTTPRequest requestWithDelegate:self action:@selector(handleAuthorization:)];
	request.url = [NSURL URLWithString:url];
	request.method = ACHTTPRequestMethodPost;
	request.contentType = ACHTTPPostXML;
	request.body = authorizationPackage;
	if(target != nil) {
		request.payload = [NSDictionary dictionaryWithObjectsAndKeys:target, @"target", NSStringFromSelector(selector), @"selector", nil];
	}
	[request send];
}

-(void)handleAuthorization:(ACHTTPRequest*)request {
	
	// Store the authorization token
	authorizationToken = nil;
	[authorizationToken release];
	authorizationToken = [[request.response.allHeaderFields objectForKey:@"Location"] retain];
	
	NSLog(@"%@", request.result);
	
	// Store the expiration date
	authorizationExpiration = nil;
	[authorizationExpiration release];
	authorizationExpiration = [[request.result objectForKey:@"authorization"] objectForKey:@"expiration"];
	[authorizationExpiration retain];
	
	// Store the user URL
	userURL = nil;
	[userURL release];
	userURL = [[request.result objectForKey:@"authorization"] objectForKey:@"user"];
	[userURL retain];
	
	// Process any queued requests
	for(ACHTTPRequest* request in requestQueue) {
		[request send];
	}
	
	// Post a notification that we have authorized
	if(request.payload != nil) {
		id target = [request.payload objectForKey:@"target"];
		SEL selector = NSSelectorFromString([request.payload objectForKey:@"selector"]);
		if(target != nil && [target respondsToSelector:selector]) {
			[target performSelector:selector withObject:self];
			return;
		}
	}
	[[NSNotificationCenter defaultCenter] postNotificationName:ACSugarSyncAuthorizationCompleteNotification object:self userInfo:request.result];
}

#pragma mark - Main Methods

-(void)user {
	[self user:nil selector:nil];
}

-(void)user:(id)target selector:(SEL)selector {
	NSAssert(self.userURL != nil, @"You must be authorized to retrieve user information");
	ACHTTPRequest* request = [self createRequest:self.userURL method:ACHTTPRequestMethodGet data:nil target:self selector:@selector(handleUser:)];
	if(target != nil) {
		request.payload = [NSDictionary dictionaryWithObjectsAndKeys:target, @"target", NSStringFromSelector(selector), @"selector", nil];
	}
	[self sendRequest:request];
}

-(void)handleUser:(ACHTTPRequest*)request {
	if([request isKindOfClass:[ACHTTPRequest class]] && request.response.statusCode == 200) {
		ACSugarSyncUser* user = [ACSugarSyncUser userWithDictionary:[request.result objectForKey:@"user"] andClient:self];
		if(request.payload != nil) {
			id target = [request.payload objectForKey:@"target"];
			SEL selector = NSSelectorFromString([request.payload objectForKey:@"selector"]);
			if(target != nil && [target respondsToSelector:selector]) {
				[target performSelector:selector withObject:user];
				return;
			}
		}
		[[NSNotificationCenter defaultCenter] postNotificationName:ACSugarSyncRetrievedUserNotification object:self userInfo:[NSDictionary dictionaryWithObject:user forKey:@"user"]];
	}
}

/*
-(void)retrieveFolder:(NSString *)fragment {
	NSString* path = [@"/folder" stringByAppendingPathComponent:fragment];
	if([path hasSuffix:@"/"] == NO) {
		path = [path stringByAppendingString:@"/"];
	}
	NSURL* url = [self URLWithFragment:path];
	[self invoke:url method:ACHTTPRequestMethodGet data:nil target:self selector:@selector(handleRetrieveFolder:)];
}

-(void)handleRetrieveFolder:(ACHTTPRequest*)request {
	if([request isKindOfClass:[ACHTTPRequest class]]) {
		if(request.response.statusCode == 200) {
			ACSugarSyncFolder* folder = [ACSugarSyncFolder folderWithDictionary:request.result andClient:self];
			NSLog(@"Folder:%@", request.result);
		}
	}
}
*/

#pragma mark - Connection Management

-(NSURL*)URLWithFragment:(NSString*)fragment {
	if([fragment hasPrefix:@"/"] == NO) {
		fragment = [@"/" stringByAppendingString:fragment];
	}
	NSString* url = [NSString stringWithFormat:@"%@%@", SUGARSYNC_API_ENDPOINT, fragment];
	return [NSURL URLWithString:url];
}

-(ACHTTPRequest*)createRequest:(NSURL*)url method:(ACHTTPRequestMethod)method data:(NSDictionary*)data target:(id)target selector:(SEL)selector {
	ACHTTPRequest* request = [ACHTTPRequest request];
	request.url = url;
	request.contentType = ACHTTPPostXML;
	request.delegate = target;
	request.method = method;
	request.action = selector;
	request.modifiers = [NSArray arrayWithObject:self];
	return request;
}

-(void)invoke:(NSURL*)url method:(ACHTTPRequestMethod)method data:(NSDictionary*)data target:(id)target selector:(SEL)selector {
	ACHTTPRequest* request = [self createRequest:url method:method data:data target:target selector:selector];
	[self sendRequest:request];
}

-(void)sendRequest:(ACHTTPRequest *)request {
	if(authorizationToken == nil || [authorizationExpiration compare:[NSDate date]] == NSOrderedAscending) {
		[requestQueue addObject:request];
		[self authorize];
	} else {
		[request send];
	}
}

-(BOOL)modifyRequest:(NSMutableURLRequest*)request {
	if(authorizationToken == nil || [authorizationExpiration compare:[NSDate date]] == NSOrderedAscending) {
		return NO;
	} else {
		[request setValue:authorizationToken forHTTPHeaderField:@"Authorization"];
		return YES;
	}
}

#pragma mark - Memory Management

-(void)dealloc {
	[requestQueue release];
	[authorizationPackage release];
	[authorizationToken release];
	[userURL release];
	[super dealloc];
}

@end
