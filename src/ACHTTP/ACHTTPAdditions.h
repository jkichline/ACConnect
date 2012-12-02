//
//  ACHTTPAdditions.h
//  ACConnect
//
//  Created by Jason Kichline on 9/3/11.
//  Copyright (c) 2011 Jason Kichline. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (ACHTTPAdditions)

-(NSString*)xmlString;

@end

@interface NSNumber (ACHTTPAdditions)

-(NSString*)xmlString;

@end

@interface NSDate (ACHTTPAdditions)

-(NSString*)xmlString;

@end


@interface NSDictionary (ACHTTPAdditions)

-(NSString*)xmlString;
-(NSString*)xmlDocument;

@end

@interface NSArray (ACHTTPAdditions)

-(NSString*)xmlString;

@end

@interface NSData (ACHTTPAdditions)

-(NSString*)xmlString;

@end