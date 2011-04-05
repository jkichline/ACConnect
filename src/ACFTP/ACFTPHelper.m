//
//  FTPHelper.m
//  OnSong
//
//  Created by Jason Kichline on 3/24/11.
//  Copyright 2011 andCulture. All rights reserved.
//

#import "ACFTPHelper.h"

@implementation ACFTPHelper

+(NSURL*)urlByRemovingCredentials:(NSURL*)input {
	if(input == nil) { return nil; }
	NSString* str = nil;
	if([input isKindOfClass:[NSURL class]]) {
		str = [input absoluteString];
	} else {
		str = [NSString stringWithFormat:@"%@", str];
	}
	NSRange from = [str rangeOfString:@"://"];
	NSRange to = [str rangeOfString:@"@"];
	str = [NSString stringWithFormat:@"%@%@", [str substringToIndex:from.location + from.length], [str substringFromIndex:to.location + to.length]];
	return [NSURL URLWithString:str];
}

+(NSURL*)urlByAddingCredentials:(NSURL*)input username:(NSString*)username password:(NSString*)password {
	if(input == nil) { return nil; }
	NSString* str = nil;
	if([input isKindOfClass:[NSURL class]]) {
		str = [input absoluteString];
	} else {
		str = [NSString stringWithFormat:@"%@", str];
	}
	
	// If we already have credentials, send it out
	if(username == nil || [str rangeOfString:@"@"].length > 0) { 
		return input;
	}
	
	// Insert the username/password
	NSMutableString* o = [NSMutableString stringWithString:str];
	NSRange at = [str rangeOfString:@"://"];
	NSString* pwd = @"";
	if(password != nil) {
		pwd = [NSString stringWithFormat:@":%@", password];
	}
	[o insertString:[NSString stringWithFormat:@"%@%@@", username, pwd] atIndex:at.location + at.length];
	return [NSURL URLWithString:o];
}

@end
