//
//  ACHTTPRequestModifier.h
//  ACOAuth
//
//  Created by Jason Kichline on 7/29/11.
//  Copyright 2011 Jason Kichline. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol ACHTTPRequestModifier <NSObject>
@optional
-(void)modifyRequest:(NSMutableURLRequest*)request;
-(BOOL)approveResponse:(NSURLResponse*)response;

@end
