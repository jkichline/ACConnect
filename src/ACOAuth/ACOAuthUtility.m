//
//  ACOAuthUtility.m
//  ACOAuth
//
//  Created by Jason Kichline on 7/28/11.
//  Copyright 2011 Jason Kichline. All rights reserved.
//

#import "ACOAuthUtility.h"
#import "NSData+ACOAuth.h"
#import <CommonCrypto/CommonDigest.h>
#import <CommonCrypto/CommonHMAC.h>

@implementation ACOAuthUtility

+(NSString*)MD5:(NSString*)data {
    const char *cStr = [data UTF8String];
    unsigned char result[16];
    CC_MD5( cStr, strlen(cStr), result); // This is the md5 call
    return [NSString stringWithFormat:
			@"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
			result[0], result[1], result[2], result[3], 
			result[4], result[5], result[6], result[7],
			result[8], result[9], result[10], result[11],
			result[12], result[13], result[14], result[15]
			];
}

+(NSString*)HMAC_SHA1:(NSString*)data withKey:(NSString*)key {
	const char *cKey  = [key cStringUsingEncoding:NSASCIIStringEncoding];
	const char *cData = [data cStringUsingEncoding:NSASCIIStringEncoding];
	unsigned char cHMAC[CC_SHA1_DIGEST_LENGTH];
	CCHmac(kCCHmacAlgSHA1, cKey, strlen(cKey), cData, strlen(cData), cHMAC);
	NSData *HMAC = [[NSData alloc] initWithBytes:cHMAC length:sizeof(cHMAC)];
	NSString *hash = [HMAC base64Encoding];
	[HMAC release];
	return hash;
}

+(NSString*)webEncode:(id)input {
	NSString* unencodedString = [NSString stringWithFormat:@"%@", input];
	NSString* encodedString = (NSString *)CFURLCreateStringByAddingPercentEscapes(NULL, (CFStringRef)unencodedString, (CFStringRef)@"-._~", (CFStringRef)@"!*'();:@&=+$,/?%#[]", kCFStringEncodingUTF8);
	return [encodedString autorelease];
}

+(NSString*)webDecode:(id)input {
	NSString* encodedString = [NSString stringWithFormat:@"%@", input];
	NSString* unencodedString = [encodedString stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
	return unencodedString;
}

+(NSMutableDictionary*)dictionaryFromQueryString:(NSString*)query {
	
	// Create the output dictionary
	NSMutableDictionary* o = [NSMutableDictionary dictionary];
	
	// Loop through each name/value pair
	for (NSString* nameValuePair in [query componentsSeparatedByString:@"&"]) {
		NSRange equals = [nameValuePair rangeOfString:@"="];
		if(equals.length > 0) {
			
			// Parse the name and value
			NSString* name = [self webDecode: [nameValuePair substringToIndex:equals.location]];
			NSString* value = [self webDecode: [nameValuePair substringFromIndex:equals.location + equals.length]];
			
			// Check if we have an existing value
			NSString* existingValue = [o objectForKey:name];
			
			// If we do, then let's make this an array of values
			if(existingValue != nil) {
				if([existingValue isKindOfClass:[NSMutableArray class]] == NO) {
					existingValue = [NSMutableArray arrayWithObject:existingValue];
				}
				[(NSMutableArray*)existingValue addObject:value];
			} else {
				existingValue = value;
			}
			
			// Add the value
			[o setObject:existingValue forKey:name];
		}
	}
	
	// Return the dictionary
	return o;
}

@end
