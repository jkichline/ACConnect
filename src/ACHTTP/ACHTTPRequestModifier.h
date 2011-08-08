//
//  ACHTTPRequestModifier.h
//  ACOAuth
//
//  Created by Jason Kichline on 7/29/11.
//  Copyright 2011 andCulture. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol ACHTTPRequestModifier

-(void)modifyRequest:(NSMutableURLRequest*)request;

@end
