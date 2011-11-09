//
//  NSData+ACOAuth.h
//  OnSong
//
//  Created by Jason Kichline on 11/8/11.
//  Copyright (c) 2011 andCulture. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSData (ACOAuth)

+(id)dataWithBase64EncodedString:(NSString*)string;
-(NSString*)base64Encoding;

@end