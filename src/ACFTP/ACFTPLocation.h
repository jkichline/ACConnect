//
//  FTPLocation.h
//  OnSong
//
//  Created by Jason Kichline on 3/23/11.
//  Copyright 2011 andCulture. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ACFTPLocation : NSObject {
	NSString* username;
	NSString* password;
	NSURL* url;
}

@property (nonatomic, retain) NSString* username;
@property (nonatomic, retain) NSString* password;
@property (nonatomic, retain) NSURL* url;
@property (readonly) NSString* host;
@property (readonly) NSString* href;
@property (readonly) NSURL* urlWithCredentials;

-(id)initWithURL:(id)url;
-(id)initWithURL:(id)url username:(NSString*)username password:(NSString*)password;
-(id)initWithHost:(NSString*)host href:(id)href username:(NSString*)username password:(NSString*)password;

+(ACFTPLocation*)locationWithURL:(id)url;
+(ACFTPLocation*)locationWithURL:(id)url username:(NSString*)username password:(NSString*)password;
+(ACFTPLocation*)locationWithHost:(NSString*)host href:(id)href username:(NSString*)username password:(NSString*)password;

@end