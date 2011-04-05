//
//  ACHTTPRequest.h
//  Strine
//
//  Created by Jason Kichline on 10/20/09.
//  Copyright 2009 andCulture. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ACHTTPRequest;

@protocol ACHTTPRequestDelegate

@optional
-(void)httpRequestCompleted:(ACHTTPRequest*)httpRequest;
-(void)httpRequest:(ACHTTPRequest*)httpRequest completedWithValue:(id)value;
-(void)httpRequest:(ACHTTPRequest*)httpRequest completedWithData:(NSData*)data;
-(void)httpRequest:(ACHTTPRequest*)httpRequest failedWithError:(NSError*)error;
-(void)httpRequest:(ACHTTPRequest*)httpRequest updatedProgress:(NSNumber*)percentComplete;

@end

@interface ACHTTPRequest : NSObject {
	NSURL* url;
	id<ACHTTPRequestDelegate> delegate;
	NSString* username;
	NSString* password;
	id body;
	NSMutableData* receivedData;
	NSHTTPURLResponse* response;
	NSURLConnection* conn;
	id payload;
	id result;
	SEL action;
}

@property (nonatomic, retain) NSURL* url;
@property (nonatomic, retain) NSString* username;
@property (nonatomic, retain) NSString* password;
@property (nonatomic, retain) NSURLConnection* connection;
@property (nonatomic, retain) NSHTTPURLResponse* response;
@property (nonatomic, retain) NSMutableData* receivedData;
@property (nonatomic, retain) id<ACHTTPRequestDelegate> delegate;
@property (nonatomic, retain) id payload;
@property (nonatomic, retain) id result;
@property (nonatomic, retain) id body;
@property SEL action;

-(BOOL)cancel;
-(void)getUrl:(id)value;
-(void)handleError:(NSError *)error;
+(id)get:(id)url;
+(void)get:(id)url delegate: (id<ACHTTPRequestDelegate>) delegate;
+(void)get:(id)url delegate: (id) delegate action:(SEL)action;
+(void)post:(id)url data:(id)data delegate: (id<ACHTTPRequestDelegate>) delegate;
+(void)post:(id)url data:(id)data delegate: (id) delegate action:(SEL)action;

+(NSString*)convertDictionaryToParameters:(NSDictionary*)d;
+(NSString*)convertDictionaryToParameters:(NSDictionary*)d separator:(NSString*)separator;

@end