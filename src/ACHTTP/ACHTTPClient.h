//
//  ACHTTPClient.h
//  Strine
//
//  Created by Jason Kichline on 10/20/09.
//  Copyright 2009 andCulture. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ACHTTPClient;

@protocol ACHTTPClientDelegate

@optional
-(void)httpClientCompleted:(ACHTTPClient*)httpClient;
-(void)httpClient:(ACHTTPClient*)httpClient completedWithValue:(id)value;
-(void)httpClient:(ACHTTPClient*)httpClient completedWithData:(NSData*)data;
-(void)httpClient:(ACHTTPClient*)httpClient failedWithError:(NSError*)error;
-(void)httpClient:(ACHTTPClient*)httpClient updatedProgress:(NSNumber*)percentComplete;

@end

@interface ACHTTPClient : NSObject {
	NSURL* url;
	id<ACHTTPClientDelegate> delegate;
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
@property (nonatomic, retain) id<ACHTTPClientDelegate> delegate;
@property (nonatomic, retain) id payload;
@property (nonatomic, retain) id result;
@property (nonatomic, retain) id body;
@property SEL action;

-(BOOL)cancel;
-(void)getUrl:(id)value;
-(void)handleError:(NSError *)error;
+(id)get:(id)url;
+(void)get:(id)url delegate: (id<ACHTTPClientDelegate>) delegate;
+(void)get:(id)url delegate: (id) delegate action:(SEL)action;
+(void)post:(id)url data:(id)data delegate: (id<ACHTTPClientDelegate>) delegate;
+(void)post:(id)url data:(id)data delegate: (id) delegate action:(SEL)action;

+(NSString*)convertDictionaryToParameters:(NSDictionary*)d;
+(NSString*)convertDictionaryToParameters:(NSDictionary*)d separator:(NSString*)separator;

@end