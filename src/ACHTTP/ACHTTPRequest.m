//
//  ACHTTPRequest.m
//  Strine
//
//  Created by Jason Kichline on 10/20/09.
//  Copyright 2009 //  Copyright 2009 Jason Kichline. All rights reserved.. All rights reserved.
//

#import "ACHTTPRequest.h"
#import "ACHTTPReachability.h"
#import "JSONKit.h"
#import "ACHTTPAdditions.h"
#import "XMLReader.h"
#import "RegexKitLite.h"

static int _networkActivity = 0;

@protocol ACHTTPRequestDelegate;

@interface ACHTTPRequest (Private)

+(id)standardizeDictionaryTypes:(id)input;
+(id)convertType:(id)value;

@end

@implementation ACHTTPRequest

@synthesize action, response, result, body, payload, url, receivedData, delegate, username, password, method, connection = conn, modifiers, contentType, cacheless;

#pragma mark - Initialization

-(id)init{
	if((self = [super init])) {
		conn = nil;
		method = ACHTTPRequestMethodAutomatic;
	}
	return self;
}

+(ACHTTPRequest*)request {
	return [[[self alloc] init] autorelease];
}

+(ACHTTPRequest*)requestWithDelegate:(id)_delegate {
	ACHTTPRequest* request = [[self alloc] init];
	request.delegate = _delegate;
	return [request autorelease];
}

+(ACHTTPRequest*)requestWithDelegate:(id)_delegate action:(SEL)_action {
	ACHTTPRequest* request = [[self alloc] init];
	request.delegate = _delegate;
	request.action = _action;
	return [request autorelease];
}

+(int)networkActivity {
	return _networkActivity;
}

+(void)incrementNetworkActivity {
	_networkActivity++;
	if(_networkActivity > 0) {
		[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
	}
}

+(void)decrementNetworkActivity {
	_networkActivity--;
	if(_networkActivity <= 0) {
		[self resetNetworkActivity];
	}
}

+(void)resetNetworkActivity {
	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
	_networkActivity = 0;
}

// Sends the request via HTTP.
-(void)send {
	[self getUrl:self.url];
}

- (void) getUrl:(id)value {
	
	// Make it a URL if it's not one
	NSURL* newUrl = nil;
	if([value isKindOfClass:[NSURL class]]) {
		newUrl = [value retain];
	} else if([value isKindOfClass:[NSString class]]) {
		newUrl = [[NSURL alloc] initWithString: value];
		if(newUrl == nil) {
			NSLog(@"The URL %@ could not be parsed.", value);
		}
	}
	if([newUrl isKindOfClass:[NSURL class]]) {
		self.url = newUrl;
	}
	if([value isKindOfClass:[NSURLRequest class]]) {
		self.url = [(NSURLRequest*)value URL];
	}
	[newUrl release];

	
	// Make sure the network is available
/*
	if([[ACHTTPReachability reachabilityForInternetConnection] currentReachabilityStatus] == NotReachable) {
		NSError* error = [NSError errorWithDomain:@"ACHTTPRequest" code:400 userInfo:[NSDictionary dictionaryWithObject:@"The network is not available" forKey:NSLocalizedDescriptionKey]];
		[self handleError: error];
		return;
	}
	if([[ACHTTPReachability reachabilityWithHostName:url.host] currentReachabilityStatus] == NotReachable) {
		NSError* error = [NSError errorWithDomain:@"ACHTTPRequest" code:410 userInfo:[NSDictionary dictionaryWithObject:@"The host is not available" forKey:NSLocalizedDescriptionKey]];
		[self handleError: error];
		return;
	}
*/

	// Create the request
	NSMutableURLRequest* request = nil;
	if([value isKindOfClass:[NSURLRequest class]]) {
		request = value;
	} else {
		request = [NSMutableURLRequest requestWithURL:self.url cachePolicy:(self.cacheless) ? NSURLRequestReloadIgnoringCacheData : NSURLRequestReturnCacheDataElseLoad timeoutInterval:30];
	
		// Determine the method of the request
		NSString* httpMethod = @"GET";
		switch (method) {
			case ACHTTPRequestMethodGet:
				httpMethod = @"GET"; break;
			case ACHTTPRequestMethodPost:
				httpMethod = @"POST"; break;
			case ACHTTPRequestMethodPut:
				httpMethod = @"PUT"; break;
			case ACHTTPRequestMethodHead:
				httpMethod = @"HEAD"; break;
			case ACHTTPRequestMethodDelete:
				httpMethod = @"DELETE"; break;
			case ACHTTPRequestMethodTrace:
				httpMethod = @"TRACE"; break;
			case ACHTTPRequestMethodCreate:
				httpMethod = @"CREATE"; break;
			default:
				if(self.body != nil) {
					httpMethod = @"POST";
				} else {
					httpMethod = @"GET";
				}
				break;
		}
		[request setHTTPMethod:httpMethod];
	}

	// Set body parameters
	if(self.body != nil) {
		if(self.method == ACHTTPRequestMethodPost) {
			if([self.body isKindOfClass:[NSData class]]) {
				[request setHTTPBody:(NSData*)body];
			} else if([self.body isKindOfClass:[NSDictionary class]]) {
				switch (self.contentType) {
	/*
					case ACHTTPPostFormMultipart:
						[request setHTTPBody:[[ACHTTPRequest convertDictionaryToMultipart:(NSDictionary*)self.body] dataUsingEncoding:NSUTF8StringEncoding]];
						break;
	*/
					case ACHTTPPostXML:
						[request setHTTPBody:[[ACHTTPRequest convertDictionaryToXML:(NSDictionary*)self.body] dataUsingEncoding:NSUTF8StringEncoding]];
						break;
					case ACHTTPPostJSON:
						[request setHTTPBody:[[ACHTTPRequest convertDictionaryToJSON:(NSDictionary*)self.body] dataUsingEncoding:NSUTF8StringEncoding]];
						break;
					default:
						[request setHTTPBody:[[ACHTTPRequest convertDictionaryToURLEncoded:(NSDictionary*)self.body] dataUsingEncoding:NSUTF8StringEncoding]];
						break;
				}
			} else {
				[request setHTTPBody:[[NSString stringWithFormat:@"%@", self.body] dataUsingEncoding:NSUTF8StringEncoding]];
			}
		} else {
			if([self.body isKindOfClass:[NSDictionary class]]) {
				self.url = [ACHTTPRequest appendQueryString:[ACHTTPRequest convertDictionaryToURLEncoded:(NSDictionary*)self.body] toURL:self.url];
			}
		}
	}
	
	// Set the content type
	switch (self.contentType) {
/*
		case ACHTTPPostFormMultipart:
			[request addValue:@"multipart/form-data" forHTTPHeaderField:@"Content-Type"];
			break;
*/
		case ACHTTPPostXML:
			[request addValue:@"text/xml; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
			break;
		case ACHTTPPostJSON:
			[request addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
			break;
		default:
			[request addValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
			break;
	}
	
	// If we have any modifiers specified, run them
	if(self.modifiers != nil) {
		for(id modifier in self.modifiers) {
			if([modifier conformsToProtocol:@protocol(ACHTTPRequestModifier)]) {
				if([modifier modifyRequest:request] == NO) {
					return;
				}
			}
		}
	}
	[self call:request];
}

-(void)call:(NSURLRequest*)request {
	// Create the connection
	self.connection = [[[NSURLConnection alloc] initWithRequest: request delegate: self] autorelease];
	[ACHTTPRequest incrementNetworkActivity];
	if(self.connection) {
		self.receivedData = [[[NSMutableData alloc] init] autorelease];
	} else {
		NSError* error = [NSError errorWithDomain:@"ACHTTPRequest" code:404 userInfo: [NSDictionary dictionaryWithObjectsAndKeys: @"Could not create connection", NSLocalizedDescriptionKey,nil]];
		[self handleError: error];
	}
}

// Called when the HTTP socket gets a response.
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)r {
	self.response = (NSHTTPURLResponse*)r;
    [self.receivedData setLength:0];
	
	// Check to see if we should continue
	BOOL shouldContinue = YES;
	for(id<ACHTTPRequestModifier> modifier in self.modifiers) {
		if([modifier respondsToSelector:@selector(approveResponse:)] && [modifier approveResponse:r] == NO) {
			shouldContinue = NO;
		}
	}
	
	// If we should stop, then stop here
	if(shouldContinue == NO) {
		[connection cancel];
		return;
	}
	
	// Notify the delegate of progress
	if(self.delegate != nil && [(NSObject*)self.delegate respondsToSelector:@selector(httpRequest:updatedProgress:)]) {
		[(NSObject*)self.delegate performSelector:@selector(httpRequest:updatedProgress:) withObject:self withObject:[NSNumber numberWithFloat:0]];
	}
}

// Called when the HTTP socket received data.
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)value {
    [self.receivedData appendData:value];
	if(self.delegate != nil && [(NSObject*)self.delegate respondsToSelector:@selector(httpRequest:updatedProgress:)]) {
		[(NSObject*)self.delegate performSelector:@selector(httpRequest:updatedProgress:) withObject:self withObject:[NSNumber numberWithFloat:(float)self.receivedData.length/(float)self.response.expectedContentLength]];
	}
}

// Called when the HTTP request fails.
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
	[ACHTTPRequest decrementNetworkActivity];
	self.receivedData = nil;
	[self handleError:error];
}

-(void)handleError:(NSError*)error{
	SEL a = @selector(httpRequest:failedWithError:);
	
	if (self.action != nil && [(NSObject*)self.delegate respondsToSelector:self.action]) {
		[(NSObject*)self.delegate performSelector:self.action withObject:error];
	}
	
	if(self.delegate != nil && [(NSObject*)self.delegate respondsToSelector:a]) {
		[(NSObject*)self.delegate performSelector:action withObject: self withObject: error];
	}
	NSLog(@"%@", error);
}

-(NSString*)description {
	return [NSString stringWithFormat:@"%@", self.result];
}

-(id)result {
	self.result = [ACHTTPRequest resultsWithData:self.receivedData usingMimeType:[self.response MIMEType]];
	return result;
}

// Called when the connection has finished loading.
- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
	[ACHTTPRequest decrementNetworkActivity];
	if(!self.delegate) { return; }
	
	if (self.action != nil && [(NSObject*)self.delegate respondsToSelector:self.action]) {
		[(NSObject*)self.delegate performSelector:self.action withObject:self];
		return;
	}
	
	if ([(NSObject*)self.delegate respondsToSelector:@selector(httpRequestCompleted)]) {
		[(NSObject*)self.delegate performSelector:@selector(httpRequestCompleted:) withObject: self];
	}

	if(self.delegate && [(NSObject*)self.delegate respondsToSelector:@selector(httpRequest:completedWithData:)]) {
		[(NSObject*)self.delegate performSelector:@selector(httpRequest:completedWithData:) withObject:self withObject:self.receivedData];
	}

	if(self.delegate && [(NSObject*)self.delegate respondsToSelector:@selector(httpRequest:completedWithValue:)]) {
		[(NSObject*)self.delegate performSelector:@selector(httpRequest:completedWithValue:) withObject:self withObject:self.result];
	}
}

// Called if the HTTP request receives an authentication challenge.
-(void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
	if([challenge previousFailureCount] == 0) {
		NSURLCredential *newCredential;
        newCredential=[NSURLCredential credentialWithUser:self.username password:self.password persistence:NSURLCredentialPersistenceNone];
        [[challenge sender] useCredential:newCredential forAuthenticationChallenge:challenge];
    } else {
        [[challenge sender] cancelAuthenticationChallenge:challenge];
		NSError* error = [NSError errorWithDomain:@"ACHTTPRequest" code:403 userInfo: [NSDictionary dictionaryWithObjectsAndKeys: @"Could not authenticate this request", NSLocalizedDescriptionKey,nil]];
		[self handleError:error];
    }
}

+(id)resultsWithData:(NSData*)data usingMimeType:(NSString*)mimetype {
	NSString* r = @"";
	id output = nil;
	
	if([mimetype hasPrefix:@"text/"] || [mimetype isEqualToString:@"application/json"]) {
		r = [self contentsFromData:data];
	}
	
	if([r rangeOfString:@"http://www.apple.com/DTDs/PropertyList-1.0.dtd"].length > 0) {
		output = [r propertyList];
	} else {
		if([mimetype hasPrefix:@"application/json"]) {
			output = [r mutableObjectFromJSONString];
		} else if([mimetype hasPrefix:@"application/xml"] || [mimetype hasPrefix:@"text/xml"]) {
			output = [self standardizeDictionaryTypes:[XMLReader dictionaryForXMLData:data error:nil]];
		} else if([mimetype hasPrefix:@"text/"]) {
			output = r;
		} else if ([mimetype hasPrefix:@"image/"]) {
			output = [UIImage imageWithData:data];
		} else {
			output = data;
		}
	}
	return output;
	
}

+(id)standardizeDictionaryTypes:(id)input {
	
	// Handle if it is a dictionary
	if([input isKindOfClass:[NSDictionary class]]) {
		if([[input allKeys] count] == 1 && [[[input allKeys] lastObject] isEqualToString:@"text"]) {
			return [self convertType:[input objectForKey:@"text"]];
		} else {
			NSMutableDictionary* d = [NSMutableDictionary dictionary];
			for(id key in [input allKeys]) {
				[d setObject:[self standardizeDictionaryTypes:[input objectForKey:key]] forKey:key];
			}
			return d;
		}
	}
	
	// Handle arrays
	else if([input isKindOfClass:[NSArray class]]) {
		NSMutableArray* a = [NSMutableArray array];
		for(id item in input) {
			[a addObject:[self standardizeDictionaryTypes:item]];
		}
		return a;
	}
	
	// Otherwise, just return the value
	else {
		return [self convertType:input];
	}
}

+(id)convertType:(id)value {
	if([value isKindOfClass:[NSString class]]) {
		static NSDateFormatter* df = nil;
		if(df == nil) {
			df = [[NSDateFormatter alloc] init];
			df.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss'.'SSSZZ";
		}
		NSDate* date = nil;
		if([df getObjectValue:&date forString:value range:nil error:nil] && date != nil) {
			return date;
		}
/*
		double number = 0;
		NSScanner* scanner = [NSScanner scannerWithString:value];
		if([scanner scanDouble:&number] && [scanner isAtEnd]) {
			return [NSNumber numberWithDouble:number];
		}
*/
	}
	return value;
}

+(id)get:(id)url{
	if([url isKindOfClass:[NSString class]]) {
		url = [NSURL URLWithString:url];
	}
	if([url isKindOfClass:[NSURL class]] == NO) {
		return nil;
	}

	if([[ACHTTPReachability reachabilityForInternetConnection] currentReachabilityStatus] == NotReachable) {
		return nil;
	}
	
	// Make sure we can reach the host
	if([ACHTTPReachability reachabilityWithHostName:[(NSURL*)url host]] == NotReachable) {
		return nil;
	}
	
	NSError* error;
	NSHTTPURLResponse* response;
	[ACHTTPRequest incrementNetworkActivity];
	NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:url];
	NSData* resultData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
	
//	NSString* resultString = [[[NSString alloc] initWithData:resultData encoding:NSUTF8StringEncoding] autorelease];
	[ACHTTPRequest decrementNetworkActivity];
	return [ACHTTPRequest resultsWithData:resultData usingMimeType:[response MIMEType]];
}

+(ACHTTPRequest*)get:(id)url delegate: (id<ACHTTPRequestDelegate>) delegate {
	return [self get:url delegate:delegate modifiers:nil];
}

+(ACHTTPRequest*)get:(id)url delegate: (id<ACHTTPRequestDelegate>) delegate modifiers:(NSArray*)modifiers {
	ACHTTPRequest* wd = [[ACHTTPRequest alloc] init];
	wd.delegate = delegate;
	wd.modifiers = modifiers;
	[wd getUrl:url];
	return [wd autorelease];
}

+(ACHTTPRequest*)get:(id)url delegate: (id<ACHTTPRequestDelegate>) delegate action:(SEL)action {
	return [self get:url delegate:delegate action:action modifiers:nil];
}

+(ACHTTPRequest*)get:(id)url delegate: (id<ACHTTPRequestDelegate>) delegate action:(SEL)action modifiers:(NSArray*)modifiers {
	ACHTTPRequest* wd = [[ACHTTPRequest alloc] init];
	wd.delegate = delegate;
	wd.action = action;
	wd.modifiers = modifiers;
	[wd getUrl:url];
	return [wd autorelease];
}

+(ACHTTPRequest*)post:(id)url data:(id)data delegate:(id <ACHTTPRequestDelegate>)delegate {
	return [self post:url data:data delegate:delegate modifiers:nil];
}

+(ACHTTPRequest*)post:(id)url data:(id)data contentType:(ACHTTPPostContentType)contentType delegate:(id <ACHTTPRequestDelegate>)delegate {
	return [self post:url data:data contentType:contentType delegate:delegate modifiers:nil];
}

+(ACHTTPRequest*)post:(id)url data:(id)data delegate:(id <ACHTTPRequestDelegate>)delegate modifiers:(NSArray*)modifiers {
	return [self post:url data:data contentType:ACHTTPPostFormURLEncoded delegate:delegate modifiers:modifiers];
}

+(ACHTTPRequest*)post:(id)url data:(id)data contentType:(ACHTTPPostContentType)_contentType delegate:(id <ACHTTPRequestDelegate>)delegate modifiers:(NSArray*)modifiers {
	ACHTTPRequest* wd = [[ACHTTPRequest alloc] init];
	wd.delegate = delegate;
	wd.body = data;
	wd.modifiers = modifiers;
	wd.contentType = _contentType;
	[wd getUrl:url];
	return [wd autorelease];
}

+(ACHTTPRequest*)post:(id)url data:(id)data delegate:(id <ACHTTPRequestDelegate>)delegate action:(SEL)action {
	return [self post:url data:data delegate:delegate action:action modifiers:nil];
}

+(ACHTTPRequest*)post:(id)url data:(id)data contentType:(ACHTTPPostContentType)_contentType delegate:(id <ACHTTPRequestDelegate>)delegate action:(SEL)action {
	return [self post:url data:data contentType:_contentType delegate:delegate action:action modifiers:nil];
}

+(ACHTTPRequest*)post:(id)url data:(id)data delegate:(id <ACHTTPRequestDelegate>)delegate action:(SEL)action modifiers:(NSArray*)modifiers {
	return [self post:url data:data contentType:ACHTTPPostFormURLEncoded delegate:delegate action:action modifiers:modifiers];
}

+(ACHTTPRequest*)post:(id)url data:(id)data contentType:(ACHTTPPostContentType)_contentType delegate:(id <ACHTTPRequestDelegate>)delegate action:(SEL)action modifiers:(NSArray*)modifiers {
	ACHTTPRequest* wd = [[ACHTTPRequest alloc] init];
	wd.delegate = delegate;
	wd.action = action;
	wd.modifiers = modifiers;
	wd.method = ACHTTPRequestMethodPost;
	wd.body = data;
	wd.contentType = _contentType;
	[wd getUrl:url];
	return [wd autorelease];
}

// Cancels the HTTP request.
-(BOOL)cancel{
	if(self.connection == nil) { return NO; }
	[self.connection cancel];
	return YES;
}

#pragma mark - Conversion Methods

+(NSString*)encodeString:(NSString*)string withEncoding:(NSStringEncoding)encoding {
	return [(NSString *) CFURLCreateStringByAddingPercentEscapes(NULL, (CFStringRef)string, NULL, (CFStringRef)@";/?:@&=$+{}<>,", CFStringConvertNSStringEncodingToEncoding(encoding)) autorelease];
}

+(NSString*)convertDictionaryToXML:(NSDictionary*)d {
	return [d xmlDocument];
}

+(NSString*)convertDictionaryToJSON:(NSDictionary*)d {
	return [d JSONString];
}

+(NSString*)convertDictionaryToMultipart:(NSDictionary*)d {
	return nil;
}

+(NSString*)convertDictionaryToURLEncoded:(NSDictionary*)d {
	return [self convertDictionaryToURLEncoded:d separator:nil];
}

+(NSString*)convertDictionaryToURLEncoded:(NSDictionary*)d separator:(NSString*)separator {
//	if(separator == nil) { separator = @"."; }
	NSMutableString* s = [NSMutableString string];
	for(id key in [d allKeys]) {
		NSString* value = [NSString stringWithFormat:@"%@", [d objectForKey:key]];
		if(s.length > 0) {
			[s appendString:@"&"];
		}
		[s appendFormat:@"%@=%@", [self encodeString:key withEncoding:NSUTF8StringEncoding], [self encodeString:value withEncoding:NSUTF8StringEncoding]];
	}
	return s;
}

+(NSURL*)appendQueryString:(NSString*)queryString toURL:(NSURL*)url {
	NSMutableString* newUrl = [NSMutableString stringWithString:[NSString stringWithFormat:@"%@", url]];
	if(url.query != nil && url.query.length > 0) {
		[newUrl appendString:@"&"];
	} else {
		[newUrl appendString:@"?"];
	}
	[newUrl appendString:queryString];
	return [NSURL URLWithString:newUrl];
}

+(NSString*)contentsFromData:(NSData*)data {
	
	// Set up the encoding
	NSString* contents = nil;
	NSString* encodingString = nil;
	NSStringEncoding encoding = 0;
	
	// Attempt to detect via XML header
	NSString* text = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
	NSArray* matches = [text arrayOfCaptureComponentsMatchedByRegex:@"(?<=encoding=\")(.+?)(?=\")"];
	if (matches.count > 0) {
		NSString* o = [[[matches objectAtIndex:0] objectAtIndex:1] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
		if(o.length != 0) {
			encodingString = o;
		}
	}
	
	// Use a default encoding if it's set
	if(encodingString == nil) {
		encodingString = [[NSUserDefaults standardUserDefaults] objectForKey:@"defaultEncoding"];
	}
	
	// If we know the encoding, let's use it
	if(encodingString != nil) {
		encodingString = [encodingString uppercaseString];
		
		// Auto detect the encoding
		if([encodingString isEqualToString:@"AUTO"]) {
			contents = nil;
		} else {
			// UTF-8
			if([encodingString isEqualToString:@"UTF-8"]) {
				encoding = NSUTF8StringEncoding;
			}
			// ASCII
			else if([encodingString isEqualToString:@"US-ASCII"]) {
				encoding = NSASCIIStringEncoding;
			}
			// UTF-16
			else if([encodingString isEqualToString:@"UTF-16"]) {
				encoding = NSUTF16StringEncoding;
			}
			// UTF-32
			else if([encodingString isEqualToString:@"UTF-32"]) {
				encoding = NSUTF32StringEncoding;
			}
			// ISO Latin
			else if([encodingString hasPrefix:@"ISO-8859"]) {
				encoding = NSISOLatin1StringEncoding;
			}
			
			// Return if we have something
			contents = [[[NSString alloc] initWithData:data encoding:encoding] autorelease];
		}
	}
	
	// Return the contents if we have some
	if(contents != nil) { return contents; }
	
	// Otherwise, detect the encoding
	contents = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
	if(contents != nil) { return contents; }
	
	contents = [[[NSString alloc] initWithData:data encoding:NSISOLatin1StringEncoding] autorelease];
	if(contents != nil) { return contents; }
	
	contents = [[[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding] autorelease];
	if(contents != nil) { return contents; }
	
	contents = [[[NSString alloc] initWithData:data encoding:NSUTF16StringEncoding] autorelease];
	if(contents != nil) { return contents; }
	
	contents = [[[NSString alloc] initWithData:data encoding:NSUTF32StringEncoding] autorelease];
	if(contents != nil) { return contents; }
	
	return contents;
}


-(void)dealloc{
	[body release];
	[result release];
	[payload release];
	[(NSObject*)delegate release];
	[response release];
	[username release];
	[password release];
	[receivedData release];
	[url release];
	[conn release];
	[modifiers release];
	[super dealloc];
}

@end

