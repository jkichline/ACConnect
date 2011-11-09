//
//  ACSugarSyncClient.h
//  ACConnect
//
//  Created by Jason Kichline on 9/3/11.
//  Copyright (c) 2011 andCulture. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ACHTTPRequestModifier.h"
#import "ACHTTPRequest.h"
#import "ACSugarSyncUser.h"
#import "ACSugarSyncFolder.h"

extern NSString* const ACSugarSyncAuthorizationCompleteNotification;
extern NSString* const ACSugarSyncRetrievedUserNotification;

typedef enum {
	ACSugarSyncClientNoOptions = 0,
	ACSugarSyncClientShowHiddenFiles = 1
} ACSugarSyncClientOptions;

@interface ACSugarSyncClient : NSObject <ACHTTPRequestDelegate, ACHTTPRequestModifier> {
	NSString* authorizationToken;
	NSDate* authorizationExpiration;
	NSDictionary* authorizationPackage;
	NSURL* userURL;
	NSMutableArray* requestQueue;
	ACSugarSyncClientOptions options;
}

@property (nonatomic) ACSugarSyncClientOptions options;
@property (nonatomic, readonly) NSString* authorizationToken;
@property (nonatomic, readonly) NSURL* userURL;

-(id)initWithUsername:(NSString*)username password:(NSString*)password accessKey:(NSString*)accessKey privateAccessKey:(NSString*)privateAccessKey;
+(ACSugarSyncClient*)clientWithUsername:(NSString*)username password:(NSString*)password accessKey:(NSString*)accessKey privateAccessKey:(NSString*)privateAccessKey;

-(void)authorize;
-(void)authorize:(id)target selector:(SEL)selector;

-(void)user;
-(void)user:(id)target selector:(SEL)selector;

-(void)invoke:(NSURL*)url method:(ACHTTPRequestMethod)method data:(NSDictionary*)data target:(id)target selector:(SEL)selector;
-(ACHTTPRequest*)createRequest:(NSURL*)url method:(ACHTTPRequestMethod)method data:(NSDictionary*)data target:(id)target selector:(SEL)selector;
-(void)sendRequest:(ACHTTPRequest*)request;

@end
