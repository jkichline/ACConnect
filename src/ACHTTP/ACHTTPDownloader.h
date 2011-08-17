//
//  ACHTTPDownloader.h
//  Vocollect
//
//  Created by Jason Kichline on 8/17/11.
//  Copyright (c) 2011 andCulture. All rights reserved.
//

@class ACHTTPDownloader;

@protocol ACHTTPDownloaderDelegate

@optional
-(void)httpDownloader:(ACHTTPDownloader*)httpDownloader downloadedToPath:(NSString*)path;
-(void)httpDownloader:(ACHTTPDownloader*)httpDownloader failedWithError:(NSError*)error;
-(void)httpDownloader:(ACHTTPDownloader*)httpDownloader updatedProgress:(NSNumber*)percentComplete;

@end

@interface ACHTTPDownloader : NSObject {
	NSURL* url;
	id delegate;
	NSString* username;
	NSString* password;
	NSHTTPURLResponse* response;
	NSURLConnection* conn;
	id payload;
	SEL action;
	NSArray* modifiers;
	int receivedBytes;
	NSString* downloadPath;
	NSFileHandle* handle;
}

@property (nonatomic, retain) NSURL* url;
@property (nonatomic, retain) NSString* username;
@property (nonatomic, retain) NSString* password;
@property (nonatomic, retain) NSString* downloadPath;
@property (nonatomic, retain) NSURLConnection* connection;
@property (nonatomic, retain) NSHTTPURLResponse* response;
@property (nonatomic, retain) NSArray* modifiers;
@property (nonatomic, retain) id payload;
@property (nonatomic, retain) id delegate;
@property SEL action;

@property (readonly) NSString* tempPath;
@property (readonly) NSString* finalPath;

-(BOOL)cancel;
-(void)download;
-(void)download:(id)url;
-(void)download:(id)url toPath:(NSString*)path;

+(ACHTTPDownloader*)download:(id)url toPath:(NSString*)path delegate:(id<ACHTTPDownloaderDelegate>) delegate;
+(ACHTTPDownloader*)download:(id)url toPath:(NSString*)path delegate:(id<ACHTTPDownloaderDelegate>) delegate modifiers:(NSArray*)modifiers;
+(ACHTTPDownloader*)download:(id)url toPath:(NSString*)path delegate:(id) delegate action:(SEL)action;
+(ACHTTPDownloader*)download:(id)url toPath:(NSString*)path delegate:(id) delegate action:(SEL)action modifiers:(NSArray*)modifiers;

+(ACHTTPDownloader*)downloader;
+(ACHTTPDownloader*)downloaderWithDelegate:(id<ACHTTPDownloaderDelegate>)delegate;
+(ACHTTPDownloader*)downloaderWithDelegate:(id)delegate action:(SEL)action;

@end
