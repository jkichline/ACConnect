//
//  ACHTTPClient.h
//  ACConnect
//
//  Created by Jason Kichline on 4/5/11.
//  Copyright 2011 andCulture. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ACHTTPRequest.h"

@interface ACHTTPClient : NSObject {
	NSString* username;
	NSString* password;
	NSArray* modifiers;
	id<ACHTTPRequestDelegate> delegate;
}

@property (nonatomic, retain) NSString* username;
@property (nonatomic, retain) NSString* password;
@property (nonatomic, retain) id<ACHTTPRequestDelegate> delegate;
@property (nonatomic, retain) NSArray* modifiers;

-(id)initWithDelegate:(id<ACHTTPRequestDelegate>)delegate;
+(ACHTTPClient*)clientWithDelegate:(id<ACHTTPRequestDelegate>)delegate;

-(ACHTTPRequest*)load:(id)url;
-(ACHTTPRequest*)load:(id)url data:(id)data;
-(ACHTTPRequest*)load:(id)url method:(ACHTTPRequestMethod)method data:(id)data;

-(ACHTTPRequest*)load:(id)url action:(SEL)action;
-(ACHTTPRequest*)load:(id)url data:(id)data action:(SEL)action;
-(ACHTTPRequest*)load:(id)url method:(ACHTTPRequestMethod)method data:(id)data action:(SEL)action;

@end
