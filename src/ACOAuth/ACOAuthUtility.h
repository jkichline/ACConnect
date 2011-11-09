//
//  ACOAuthUtility.h
//  ACOAuth
//
//  Created by Jason Kichline on 7/28/11.
//  Copyright 2011 Jason Kichline. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface ACOAuthUtility : NSObject {

}

+(NSString*)MD5:(NSString*)data;
+(NSString*)HMAC_SHA1:(NSString*)data withKey:(NSString*)key;
+(NSString*)webEncode:(id)unencodedString;
+(NSString*)webDecode:(id)input;
+(NSMutableDictionary*)dictionaryFromQueryString:(NSString*)query;

@end
