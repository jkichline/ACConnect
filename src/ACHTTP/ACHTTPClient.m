//
//  ACHTTPClient.m
//  ACConnect
//
//  Created by Jason Kichline on 4/5/11.
//  Copyright 2011 Jason Kichline. All rights reserved.
//

#import "ACHTTPClient.h"


@implementation ACHTTPClient

@synthesize	username, password, modifiers, delegate;

-(id)initWithDelegate:(id)_delegate {
	self = [self init];
	if(self) {
		self.delegate = _delegate;
	}
	return self;
}

+(ACHTTPClient*)clientWithDelegate:(id)delegate {
	return [[[self alloc] initWithDelegate:delegate] autorelease];
}

-(ACHTTPRequest*)load:(id)url {
	return [self load:url data:nil];
}

-(ACHTTPRequest*)load:(id)url data:(id)data {
	return [self load:url method:ACHTTPRequestMethodAutomatic data:data];
}

-(ACHTTPRequest*)load:(id)url method:(ACHTTPRequestMethod)method data:(id)data {
	return [self load:url method:method data:data action:nil];
}

-(ACHTTPRequest*)load:(id)url action:(SEL)action {
	return [self load:url data:nil action:action];
}

-(ACHTTPRequest*)load:(id)url data:(id)data action:(SEL)action {
	return [self load:url method:ACHTTPRequestMethodAutomatic data:data action:action];
}

-(ACHTTPRequest*)load:(id)url method:(ACHTTPRequestMethod)method data:(id)data action:(SEL)action {
	ACHTTPRequest* request = [ACHTTPRequest requestWithDelegate:self.delegate];
	request.username = self.username;
	request.password = self.password;
	request.modifiers = self.modifiers;
	request.method = method;
	request.body = data;
	request.action = action;
	[request getUrl:url];
	return request;
}

@end
