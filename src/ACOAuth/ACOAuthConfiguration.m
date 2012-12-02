//
//  ACOAuthConfiguration.m
//  ACOAuth
//
//  Created by Jason Kichline on 7/29/11.
//  Copyright 2011 Jason Kichline. All rights reserved.
//

#import "ACOAuthConfiguration.h"
#import "ACOAuthUtility.h"

@implementation ACOAuthConfiguration

@synthesize baseURL, requestTokenURL, accessTokenURL, authorizationURL, callbackURL;
@synthesize accessTokenMethod, requestTokenMethod, authorizationMethod, authorizeExternally;
@synthesize consumerKey, consumerSecret, token, tokenSecret, verifier, signatureMethod, useAuthorizationHeader;
@synthesize identifier, tintColor, parentViewController, parameters, css, javascript, authenticateImmediately;

#pragma mark -
#pragma mark Initialization

-(id)init {
	self = [super init];
	if(self) {
		self.accessTokenMethod = @"POST";
		self.requestTokenMethod = @"POST";
		self.authorizationMethod = @"GET";
		self.useAuthorizationHeader = YES;
		self.signatureMethod = ACOAuthSignatureMethodHMAC_SHA1;
	}
	return self;
}

-(id)initWithConsumerKey:(NSString*)_consumerKey andSecret:(NSString*)_consumerSecret forBaseURL:(NSURL*)_baseURL {
	self = [self init];
	if(self) {
		self.baseURL = _baseURL;
		self.consumerKey = _consumerKey;
		self.consumerSecret = _consumerSecret;
	}
	return self;
}

+(ACOAuthConfiguration*)configurationWithConsumerKey:(NSString*)consumerKey andSecret:(NSString*)consumerSecret forBaseURL:(NSURL*)baseURL {
	return [[[ACOAuthConfiguration alloc] initWithConsumerKey:consumerKey andSecret:consumerSecret forBaseURL:baseURL] autorelease];
}

#pragma mark -
#pragma mark Properties

-(BOOL)isValid {
	return (self.consumerKey != nil && self.consumerSecret != nil && self.requestTokenURL != nil && self.accessTokenURL != nil);
}

-(BOOL)isAuthenticated {
	return (self.consumerKey != nil && self.consumerSecret != nil && self.token != nil && self.tokenSecret != nil);
}

-(NSURL*)requestTokenURL {
	if(requestTokenURL == nil && baseURL != nil) {
		self.requestTokenURL = [baseURL URLByAppendingPathComponent:@"request_token"];
	}
	return requestTokenURL;
}

-(NSURL*)accessTokenURL {
	if(accessTokenURL == nil && baseURL != nil) {
		self.accessTokenURL = [baseURL URLByAppendingPathComponent:@"access_token"];
	}
	return accessTokenURL;
}

-(NSURL*)authorizationURL {
	if(authorizationURL == nil && baseURL != nil) {
		self.authorizationURL = [baseURL URLByAppendingPathComponent:@"authorize"];
	}
	return authorizationURL;
}

-(NSURL*)callbackURL {
	
	// Return a callback URL if we have one
	if(callbackURL != nil) { return callbackURL; }
	
	// If we don't, create one
	NSString* scheme = nil;
	NSArray* urlTypes = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleURLTypes"];
	if(urlTypes != nil && urlTypes.count > 0) {
		NSDictionary* urlType = [urlTypes objectAtIndex:0];
		NSArray* urlSchemes = [urlType objectForKey:@"CFBundleURLSchemes"];
		if(urlSchemes != nil && urlSchemes.count > 0) {
			scheme = [urlSchemes objectAtIndex:0];
		}
	}
	
	// If we have no scheme, fail
	NSAssert((scheme != nil), NSLocalizedString(@"Please add a URL scheme to your application info.plist", @""));
	return [NSURL URLWithString:[NSString stringWithFormat:@"%@://GetSatisfactionAuthorized", scheme]];
}

-(NSString*)signatureKey {
	return [NSString stringWithFormat:@"%@&%@", 
			[ACOAuthUtility webEncode:self.consumerSecret],
			(self.tokenSecret) ? [ACOAuthUtility webEncode:self.tokenSecret] : @""];
}

-(void)setConsumerKey:(NSString*)value {
	if(value != consumerKey) {
		[consumerKey release];
		[value retain];
		consumerKey = value;
	}
	
	// Set the keychain
	keychain = nil;
	[keychain release];
	keychain = [[ACKeychain alloc] initWithIdentifier:consumerKey];
	
	// Load the keychain values
	id temp = [keychain objectForKey:(id)kSecAttrAccount];
	if([temp length] > 0) {
		self.token = temp;
	}
	
	temp = [keychain objectForKey:(id)kSecValueData];
	if([temp length] > 0) {
		self.tokenSecret = temp;
	}
}

#pragma mark -
#pragma mark Keychain Methods

-(void)saveToKeychain {
	if(keychain != nil) {
		[keychain setObject:self.token forKey:(id)kSecAttrAccount];
		[keychain setObject:self.tokenSecret forKey:(id)kSecValueData];
		[keychain setObject:self.consumerKey forKey:(id)kSecAttrLabel];
		[keychain setObject:[self.baseURL absoluteString] forKey:(id)kSecAttrService];
	}
}

-(void)removeFromKeychain {
	[keychain reset];
	self.token = nil;
	self.tokenSecret = nil;
}

#pragma mark -
#pragma mark Memory Management

-(void)dealloc {
	[baseURL release];
	[requestTokenURL release];
	[accessTokenURL release];
	[authorizationURL release];
	[callbackURL release];
	[consumerKey release];
	[consumerSecret release];
	[token release];
	[tokenSecret release];
	[verifier release];
	[identifier release];
	[parameters release];
	[tintColor release];
	[parentViewController release];
	[keychain release];
	[super dealloc];
}

@end
