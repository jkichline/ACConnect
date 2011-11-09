//
//  ACWebDAVLocation.m
//  ACWebDAVTest
//
//  Created by Jason Kichline on 8/19/10.
//  Copyright 2010 Jason Kichline. All rights reserved.
//

#import "ACWebDAVLocation.h"


@implementation ACWebDAVLocation

@synthesize url, username, password;

-(id)initWithURL:(NSURL*)_url {
	return [self initWithURL:_url username:nil password:nil];
}

+(ACWebDAVLocation*)locationWithURL:(NSURL *)url {
	return [[[self alloc] initWithURL:url] autorelease];
}

-(id)initWithURL:(NSURL*)_url username:(NSString*)_username password:(NSString*)_password {
	if(self = [self init]) {
		self.url = _url;
		self.username = _username;
		self.password = _password;
	}
	return self;
}

+(ACWebDAVLocation*)locationWithURL:(NSURL *)_url username:(NSString*)_username password:(NSString*)_password {
	return [[[self alloc] initWithURL:_url username:_username password:_password] autorelease];
}

-(id)initWithHost:(NSString*)_host href:(NSString*)_href username:(NSString*)_username password:(NSString*)_password {
	if(self = [self init]) {
		if([_href hasPrefix:[NSString stringWithFormat:@"/%@", [_host lastPathComponent]]]) {
			_href = [_href substringFromIndex:[_host lastPathComponent].length+1];
		}
		if([_href rangeOfString:@"%"].length == 0) {
			_href = [_href stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
		}
		self.url = [NSURL URLWithString:[_host stringByAppendingString:_href]];
		self.username = _username;
		self.password = _password;
	}
	return self;
}

+(ACWebDAVLocation*)locationWithHost:(NSString *)_host href:(NSString *)_href username:(NSString *)_username password:(NSString *)_password {
	return [[[self alloc] initWithHost:_host href:_href username:_username password:_password] autorelease];
}

-(NSString*)host {
	return [NSString stringWithFormat:@"%@://%@", [self.url scheme], [self.url host]];
}

-(NSString*)href {
	return [[self.url absoluteString] substringFromIndex:self.host.length];
}

@end
