//
//  ACHTTPRequest.h
//  Strine
//
//  Created by Jason Kichline on 10/20/09.
//  Copyright 2009 Jason Kichline. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ACHTTPRequestModifier.h"

@class ACHTTPRequest;

@protocol ACHTTPRequestDelegate

@optional
-(void)httpRequestCompleted:(ACHTTPRequest*)httpRequest;
-(void)httpRequest:(ACHTTPRequest*)httpRequest completedWithValue:(id)value;
-(void)httpRequest:(ACHTTPRequest*)httpRequest completedWithData:(NSData*)data;
-(void)httpRequest:(ACHTTPRequest*)httpRequest failedWithError:(NSError*)error;
-(void)httpRequest:(ACHTTPRequest*)httpRequest updatedProgress:(NSNumber*)percentComplete;

@end

typedef enum {
	ACHTTPPostFormURLEncoded,
//	ACHTTPPostFormMultipart,
	ACHTTPPostXML,
	ACHTTPPostJSON
} ACHTTPPostContentType;

typedef enum {
	ACHTTPRequestMethodAutomatic,
	ACHTTPRequestMethodGet,
	ACHTTPRequestMethodPost,
	ACHTTPRequestMethodHead,
	ACHTTPRequestMethodPut,
	ACHTTPRequestMethodDelete,
	ACHTTPRequestMethodTrace,
	ACHTTPRequestMethodCreate
} ACHTTPRequestMethod;

@interface ACHTTPRequest : NSObject {
	NSURL* url;
	id<ACHTTPRequestDelegate> delegate;
	NSString* username;
	NSString* password;
	ACHTTPRequestMethod method;
	id body;
	NSString* bodyContentType;
	NSMutableData* receivedData;
	NSHTTPURLResponse* response;
	NSURLConnection* conn;
	id payload;
	id result;
	SEL action;
	NSArray* modifiers;
	BOOL cacheless;
}

@property (nonatomic, retain) NSURL* url;
@property (nonatomic, retain) NSString* username;
@property (nonatomic, retain) NSString* password;
@property ACHTTPRequestMethod method;
@property (nonatomic, retain) NSURLConnection* connection;
@property (nonatomic, retain) NSHTTPURLResponse* response;
@property (nonatomic, retain) NSMutableData* receivedData;
@property (nonatomic, retain) id<ACHTTPRequestDelegate> delegate;
@property (nonatomic, retain) id payload;
@property (nonatomic, retain) id result;
@property (nonatomic, retain) id body;
@property ACHTTPPostContentType contentType;
@property (nonatomic, retain) NSArray* modifiers;
@property SEL action;
@property (nonatomic) BOOL cacheless;

-(BOOL)cancel;
-(void)send;
-(void)getUrl:(id)value;
-(void)handleError:(NSError *)error;
+(id)get:(id)url;
+(ACHTTPRequest*)get:(id)url delegate: (id<ACHTTPRequestDelegate>) delegate;
+(ACHTTPRequest*)get:(id)url delegate: (id<ACHTTPRequestDelegate>) delegate modifiers:(NSArray*)modifiers;
+(ACHTTPRequest*)get:(id)url delegate: (id) delegate action:(SEL)action;
+(ACHTTPRequest*)get:(id)url delegate: (id) delegate action:(SEL)action modifiers:(NSArray*)modifiers;
+(ACHTTPRequest*)post:(id)url data:(id)data delegate: (id<ACHTTPRequestDelegate>) delegate;
+(ACHTTPRequest*)post:(id)url data:(id)data contentType:(ACHTTPPostContentType)contentType delegate: (id<ACHTTPRequestDelegate>) delegate;
+(ACHTTPRequest*)post:(id)url data:(id)data delegate: (id<ACHTTPRequestDelegate>) delegate modifiers:(NSArray*)modifiers;
+(ACHTTPRequest*)post:(id)url data:(id)data contentType:(ACHTTPPostContentType)contentType delegate: (id<ACHTTPRequestDelegate>) delegate modifiers:(NSArray*)modifiers;
+(ACHTTPRequest*)post:(id)url data:(id)data delegate: (id) delegate action:(SEL)action;
+(ACHTTPRequest*)post:(id)url data:(id)data contentType:(ACHTTPPostContentType)contentType delegate: (id) delegate action:(SEL)action;
+(ACHTTPRequest*)post:(id)url data:(id)data delegate: (id) delegate action:(SEL)action modifiers:(NSArray*)modifiers;
+(ACHTTPRequest*)post:(id)url data:(id)data contentType:(ACHTTPPostContentType)contentType delegate: (id) delegate action:(SEL)action modifiers:(NSArray*)modifiers;
-(void)call:(NSURLRequest*)request;

+(ACHTTPRequest*)request;
+(ACHTTPRequest*)requestWithDelegate:(id)delegate;
+(ACHTTPRequest*)requestWithDelegate:(id)delegate action:(SEL)action;

+(NSString*)encodeString:(NSString*)string withEncoding:(NSStringEncoding)encoding;
+(NSString*)convertDictionaryToJSON:(NSDictionary*)d;
+(NSString*)convertDictionaryToXML:(NSDictionary*)d;
+(NSString*)convertDictionaryToURLEncoded:(NSDictionary*)d;
+(NSString*)convertDictionaryToURLEncoded:(NSDictionary*)d separator:(NSString*)separator;

+(int)networkActivity;
+(void)incrementNetworkActivity;
+(void)decrementNetworkActivity;
+(void)resetNetworkActivity;

+(id)resultsWithData:(NSData*)data usingMimeType:(NSString*)mimetype;
+(NSURL*)appendQueryString:(NSString*)queryString toURL:(NSURL*)url;

@end