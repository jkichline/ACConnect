//
//  ACOAuthSession.m
//  ACOAuth
//
//  Created by Jason Kichline on 7/28/11.
//  Copyright 2011 Jason Kichline. All rights reserved.
//

#import "ACOAuthSession.h"
#import "ACOAuthUtility.h"
#import "ACOAuthLoginScreen.h"

NSString* const ACOAuthSessionRequestTokenReceived = @"ACOAuthSessionRequestTokenReceived";
NSString* const ACOAuthSessionAccessTokenReceived = @"ACOAuthSessionAccessTokenReceived";
NSString* const ACOAuthSessionAuthorizationVerified = @"ACOAuthSessionAuthorizationVerified";
NSString* const ACOAuthSessionAuthorizationCanceled = @"ACOAuthSessionAuthorizationCanceled";

@implementation ACOAuthSession

@synthesize receivedData, response, configuration;

#pragma mark -
#pragma mark Initialization

-(id)init {
	self = [super init];
	if(self) {
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(requestTokenReceived:) name:ACOAuthSessionRequestTokenReceived object:self];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(authorizationVerified:) name:ACOAuthSessionAuthorizationVerified object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(accessTokenReceived:) name:ACOAuthSessionAccessTokenReceived object:self];
	}
	return self;
}

-(id)initWithConfiguration:(ACOAuthConfiguration*)_configuration {
	self = [self init];
	if(self) {
		self.configuration = _configuration;
	}
	return self;
}

+(ACOAuthSession*)sessionWithConfiguration:(ACOAuthConfiguration*)_configuration {
	return [[[ACOAuthSession alloc] initWithConfiguration:_configuration] autorelease];
}

#pragma mark -
#pragma mark Properties

-(void)setConfiguration:(ACOAuthConfiguration *)value {
	if(value != configuration) {
		[value retain];
		[configuration release];
		configuration = value;
	}
	if(configuration.token != nil && configuration.tokenSecret != nil) {
		[self performSelector:@selector(connected) withObject:nil afterDelay:0.1];
	} else if(configuration.authenticateImmediately) {
		[self requestToken];
	}
}

-(void)connected {
	[[NSNotificationCenter defaultCenter] postNotificationName:ACOAuthSessionAccessTokenReceived object:self userInfo:[NSDictionary dictionaryWithObject:self.configuration forKey:@"configuration"]];
}

#pragma mark -
#pragma mark Request Tokens

-(BOOL)requestToken {
	
	// Check to make sure we have a valid configuration
	if(self.configuration == nil || [self.configuration isValid] == NO) { return NO; }

	// Create and sign the request
	NSMutableURLRequest* request = [[[NSMutableURLRequest alloc] initWithURL:self.configuration.requestTokenURL] autorelease];
	[request setHTTPMethod:self.configuration.requestTokenMethod];
	[self signRequest:request];

	// Create the connection and handle it
	NSURLConnection* connection = [[[NSURLConnection alloc] initWithRequest:request delegate:self] autorelease];
	[connection start];
	return YES;
}

-(BOOL)accessToken {
	
	// Check to make sure we have a valid configuration
	if(self.configuration == nil || [self.configuration isValid] == NO) { return NO; }
	
	// Create and sign the request
	NSMutableURLRequest* request = [[[NSMutableURLRequest alloc] initWithURL:self.configuration.accessTokenURL] autorelease];
	[request setHTTPMethod:self.configuration.accessTokenMethod];
	[self signRequest:request];
	
	// Create the connection and handle it
	NSURLConnection* connection = [[[NSURLConnection alloc] initWithRequest:request delegate:self] autorelease];
	[connection start];
	return YES;
}

#pragma mark -
#pragma mark Request Tokens

-(BOOL)authorize {
	
	// Check to make sure we have a valid configuration
	if(self.configuration != nil && self.configuration.authorizationURL != nil && self.configuration.parentViewController != nil) {
		
		// Create the login screen
		ACOAuthLoginScreen* login = [[ACOAuthLoginScreen alloc] initWithConfiguration:self.configuration];
	
		// If we have a navigation controller, push it
		if([self.configuration.parentViewController isKindOfClass:[UINavigationController class]]) {
			[(UINavigationController*)self.configuration.parentViewController pushViewController:login animated:YES];
		}
		
		// Otherwise, create a navigation controller and pop it up modally
		else {
			UINavigationController* nav = [[UINavigationController alloc] initWithRootViewController:login];
			nav.navigationBar.tintColor = self.configuration.tintColor;
			nav.modalPresentationStyle = UIModalPresentationFormSheet;
			[self.configuration.parentViewController presentModalViewController:nav animated:YES];
			[nav release];
		}
		
		// Release the login screen
		[login release];
		return YES;
	}
	return NO;
}

#pragma mark -
#pragma mark Handle Notifications

-(void)requestTokenReceived:(NSNotification*)notification {
	[self authorize];
}

-(void)authorizationVerified:(NSNotification*)notification {
	[self accessToken];
}

-(void)accessTokenReceived:(NSNotification*)notification {
	[self.configuration saveToKeychain];
}

#pragma mark -
#pragma mark - Modifier Methods

-(BOOL)modifyRequest:(NSMutableURLRequest *)request {
	[self signRequest:request];
	return YES;
}

-(BOOL)approveResponse:(NSURLResponse *)r {
	if([r isKindOfClass:[NSHTTPURLResponse class]]) {
		NSHTTPURLResponse* r2 = (NSHTTPURLResponse*)r;
		if(r2.statusCode == 401 || r2.statusCode == 403) {
			[self requestToken];
			return NO;
		}
	}
	return YES;
}

#pragma mark -
#pragma mark Sign Requests

-(void)signRequest:(NSMutableURLRequest*)request {
	return [self signRequest:request useAuthorizationHeader:NO];
}

-(void)signRequest:(NSMutableURLRequest*)request useAuthorizationHeader:(BOOL)useAuthorizationHeader {
	
	// Generate a nonce
	NSString* nonce = [ACOAuthUtility MD5:[NSString stringWithFormat:@"%d", [[NSDate date] timeIntervalSince1970]]];
	
	// Determine the signature method string
	NSString* signatureMethod = @"HMAC-SHA1";
	switch (self.configuration.signatureMethod) {
		case ACOAuthSignatureMethodHMAC_SHA1:
			signatureMethod = @"HMAC-SHA1";
			break;
		case ACOAuthSignatureMethodPlainText:
			signatureMethod = @"PLAINTEXT";
			break;

		default:
			break;
	}

	// Create a parameters dictionary
	NSMutableDictionary* parameters = [NSMutableDictionary dictionary];
	[parameters setObject:self.configuration.consumerKey forKey:@"oauth_consumer_key"];
	[parameters setObject:signatureMethod forKey:@"oauth_signature_method"];
	[parameters setObject:[NSNumber numberWithInt:[[NSDate date] timeIntervalSince1970]] forKey:@"oauth_timestamp"];
	[parameters setObject:nonce forKey:@"oauth_nonce"];
	[parameters setObject:@"1.0" forKey:@"oauth_version"];
	if([request.URL.absoluteString hasSuffix:@"request_token"]) {
		[parameters setObject:self.configuration.consumerSecret forKey:@"oauth_consumer_secret"];
	}
	
	if(self.configuration.token) {
//		NSLog(@"Token: %@", self.configuration.token);
		[parameters setObject:self.configuration.token forKey:@"oauth_token"];
	}
	if(self.configuration.verifier != nil && [[[request URL] absoluteString] isEqualToString:[self.configuration.accessTokenURL absoluteString]]) {
		[parameters setObject:self.configuration.verifier forKey:@"oauth_verifier"];
	}
	
	// Add parameters in the query string, if any...
	NSDictionary* queryStringParams = [ACOAuthUtility dictionaryFromQueryString:[[request URL] query]];
	for(NSString* name in [queryStringParams allKeys]) {
		[parameters setObject:[queryStringParams objectForKey:name] forKey:name];
	}
	
	// Add for POST variables, if applicable
	if([[request HTTPMethod] isEqualToString:@"POST"] && [request HTTPBody] != nil) {
		NSString* postAsString = [[[NSString alloc] initWithData:[request HTTPBody] encoding:NSUTF8StringEncoding] autorelease];
		NSDictionary* postParameters = [ACOAuthUtility dictionaryFromQueryString:postAsString];
		for(NSString* name in [postParameters allKeys]) {
			[parameters setObject:[postParameters objectForKey:name] forKey:name];
		}
	}

	// Create the post for the baseString
	NSMutableString* basePost = [NSMutableString string];
	for(NSString* key in [[parameters allKeys] sortedArrayUsingSelector:@selector(localizedStandardCompare:)]) {
		if(basePost.length > 0) {
			[basePost appendString:@"&"];
		}
		[basePost appendFormat:@"%@=%@", [ACOAuthUtility webEncode:key], [ACOAuthUtility webEncode:[parameters objectForKey:key]]];
	}
	
	// Create the post
	NSString* url = [[[[request URL] absoluteString] componentsSeparatedByString:@"?"] objectAtIndex:0];
	NSString* baseString = [NSString stringWithFormat:@"%@&%@&%@", 
							[[request HTTPMethod] uppercaseString], 
							[ACOAuthUtility webEncode:url], 
							[ACOAuthUtility webEncode:basePost]];
	
	// Generate the signature
	NSString* signature = nil;
	
	switch (self.configuration.signatureMethod) {
		case ACOAuthSignatureMethodHMAC_SHA1:
			signature = [ACOAuthUtility HMAC_SHA1:baseString withKey:self.configuration.signatureKey];
			break;
		case ACOAuthSignatureMethodPlainText:
			signature = self.configuration.signatureKey;
			break;

		default:
			break;
	}
	
	// Add the signature to the request
	[parameters setObject:signature forKey:@"oauth_signature"];

	// Create the authorization header;
	NSMutableString* auth = [NSMutableString stringWithFormat:@"OAuth realm=\"%@://%@/\"", [[request URL] scheme], [[request URL] host]];
	for(NSString* key in [[parameters allKeys] sortedArrayUsingSelector:@selector(localizedStandardCompare:)]) {
		if([key hasPrefix:@"oauth_"]) {
			[auth appendFormat:@",%@=\"%@\"", key, [ACOAuthUtility webEncode:[parameters objectForKey:key]]];
		}
	}

	if(!useAuthorizationHeader) {
		NSMutableString* query = [NSMutableString string];
		if([[request URL] query] != nil) {
			[query appendString:[[request URL] query]];
		}
		for(NSString* key in [[parameters allKeys] sortedArrayUsingSelector:@selector(localizedStandardCompare:)]) {
			if([key hasPrefix:@"oauth_"]) {
				if([query length] > 0) {
					[query appendString:@"&"];
				}
				[query appendFormat:@"%@=%@", [ACOAuthUtility webEncode:key], [ACOAuthUtility webEncode:[parameters objectForKey:key]]];
			}
		}

		if([[request HTTPMethod] isEqualToString:@"GET"]) {
			[request setURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@?%@", url, query]]];
		} else {
			[request addValue:auth forHTTPHeaderField:@"Authorization"];
		}
	} else {
		[request addValue:auth forHTTPHeaderField:@"Authorization"];
	}
	
//	NSLog(@"URL: %@", [request URL]);
}

#pragma mark -
#pragma mark Handle Connection

// Called when the HTTP socket gets a response.
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)r {
	self.response = (NSHTTPURLResponse*)r;
	self.receivedData = [NSMutableData data];
}

// Called when the HTTP socket received data.
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)value {
    [self.receivedData appendData:value];
}

// Called when the HTTP request fails.
-(void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
	NSLog(@"oAuth Error: %@", error);
}

// Called when the HTTP finished.
-(void)connectionDidFinishLoading:(NSURLConnection *)connection {
	
	// Get the content
	NSString* content = [[[NSString alloc] initWithData:self.receivedData encoding:NSUTF8StringEncoding] autorelease];
	
//	NSLog(@"URL: %@\nContent: %@", [self.response URL], content);
	
	// Parse into a dictionary
	NSMutableDictionary* parameters = [ACOAuthUtility dictionaryFromQueryString:content];
	
	// Set the tokens
	self.configuration.token = [parameters objectForKey:@"oauth_token"];
	[parameters removeObjectForKey:@"oauth_token"];

	self.configuration.tokenSecret = [parameters objectForKey:@"oauth_token_secret"];
	[parameters removeObjectForKey:@"oauth_token_secret"];

	self.configuration.parameters = [NSDictionary dictionaryWithDictionary:parameters];
	
	// Post a notification for request token
	NSString* responseURL = [[self.response URL] absoluteString];
	if([responseURL hasPrefix:[self.configuration.requestTokenURL absoluteString]]) {
		[[NSNotificationCenter defaultCenter] postNotificationName:ACOAuthSessionRequestTokenReceived object:self userInfo:[NSDictionary dictionaryWithObject:self.configuration forKey:@"configuration"]];
	}
	
	// Post a notification for access token
	if([responseURL hasPrefix:[self.configuration.accessTokenURL absoluteString]]) {
		[[NSNotificationCenter defaultCenter] postNotificationName:ACOAuthSessionAccessTokenReceived object:self userInfo:[NSDictionary dictionaryWithObject:self.configuration forKey:@"configuration"]];
	}
}

#pragma mark -
#pragma mark Memory Management

-(void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[receivedData release];
	[response release];
	[configuration release];
	
	[super dealloc];
}

@end
