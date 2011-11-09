//
//  ACWebDAVLocation.h
//  ACWebDAVTest
//
//  Created by Jason Kichline on 8/19/10.
//  Copyright 2010 Jason Kichline. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ACWebDAVLocation : NSObject {
	NSString* username;
	NSString* password;
	NSURL* url;
}

@property (nonatomic, retain) NSString* username;
@property (nonatomic, retain) NSString* password;
@property (nonatomic, retain) NSURL* url;
@property (readonly) NSString* host;
@property (readonly) NSString* href;

-(id)initWithURL:(NSURL*)url;
-(id)initWithURL:(NSURL*)url username:(NSString*)username password:(NSString*)password;
-(id)initWithHost:(NSString*)host href:(NSString*)href username:(NSString*)username password:(NSString*)password;

+(ACWebDAVLocation*)locationWithURL:(NSURL*)url;
+(ACWebDAVLocation*)locationWithURL:(NSURL*)url username:(NSString*)username password:(NSString*)password;
+(ACWebDAVLocation*)locationWithHost:(NSString*)host href:(NSString*)href username:(NSString*)username password:(NSString*)password;

@end
