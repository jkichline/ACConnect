//
//  FTPLocation.m
//  OnSong
//
//  Created by Jason Kichline on 3/23/11.
//  Copyright 2011 andCulture. All rights reserved.
//

#import "ACFTPLocation.h"
#import "ACFTPHelper.h"

@implementation ACFTPLocation

@synthesize url, username, password;

-(id)initWithURL:(id)_url {
	NSURL* newUrl = nil;
	if([_url isKindOfClass:[NSURL class]]) {
		newUrl = _url;
	} else {
		newUrl = [NSURL URLWithString:[NSString stringWithFormat:@"%@", _url]];
	}
	return [self initWithURL:[ACFTPHelper urlByRemovingCredentials:newUrl] username:[_url user] password:[_url password]];
}

+(ACFTPLocation*)locationWithURL:(NSURL *)url {
	return [[[self alloc] initWithURL:url] autorelease];
}

-(id)initWithURL:(id)_url username:(NSString*)_username password:(NSString*)_password {
	if(self = [self init]) {
		NSURL* newUrl = nil;
		if([_url isKindOfClass:[NSURL class]]) {
			newUrl = _url;
		} else {
			newUrl = [NSURL URLWithString:[NSString stringWithFormat:@"%@", _url]];
		}
		self.url = newUrl;
		self.username = _username;
		self.password = _password;
	}
	return self;
}

+(ACFTPLocation*)locationWithURL:(NSURL *)_url username:(NSString*)_username password:(NSString*)_password {
	return [[[self alloc] initWithURL:_url username:_username password:_password] autorelease];
}

-(id)initWithHost:(NSString*)_host href:(id)_href username:(NSString*)_username password:(NSString*)_password {
	if(self = [self init]) {
		// If the host is a NSURL, convert back to string
		if([_host isKindOfClass:[NSURL class]]) {
			_host = [(NSURL*)_host absoluteString];
		}
		
		// If the host doesn't have a scheme, let's add it
		if([_host rangeOfString:@"://"].length == 0) {
			_host = [NSString stringWithFormat:@"ftp://%@", _host];
		}
		
		// If href is a URL, make is a relative string
		if([_href isKindOfClass:[NSURL class]]) {
			_href = [(NSURL*)_href relativePath];
		}
		
		// If we don't have an href, let's make it nothing
		if(_href == nil) { _href = @""; }
		if([_href hasPrefix:@"/"] == NO) { _href = [NSString stringWithFormat:@"/%@", _href]; }
		
		// Other cleanup stuff
		if([_href hasPrefix:[NSString stringWithFormat:@"/%@", [_host lastPathComponent]]]) {
			_href = [_href substringFromIndex:[_host lastPathComponent].length+1];
		}
		if([_href rangeOfString:@"%"].length == 0) {
			_href = [_href stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
		}
		
		// Set the params
		self.url = [NSURL URLWithString:[_host stringByAppendingString:_href]];
		self.username = _username;
		self.password = _password;
	}
	return self;
}

+(ACFTPLocation*)locationWithHost:(NSString *)_host href:(NSString *)_href username:(NSString *)_username password:(NSString *)_password {
	return [[[self alloc] initWithHost:_host href:_href username:_username password:_password] autorelease];
}

-(NSString*)host {
	return [NSString stringWithFormat:@"%@://%@", [self.url scheme], [self.url host]];
}

-(NSString*)href {
	return [[self.url absoluteString] substringFromIndex:self.host.length];
}

-(NSURL*)urlWithCredentials {
	return [ACFTPHelper urlByAddingCredentials:self.url username:self.username password:self.password];
}

@end
