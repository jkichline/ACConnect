//
//  FTPListRequest.h
//  OnSong
//
//  Created by Jason Kichline on 3/23/11.
//  Copyright 2011 andCulture. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ACFTPLocation.h"

@class ACFTPListRequest;

@protocol ACFTPListRequestDelegate

@optional

-(void)request:(ACFTPListRequest*)request didListEntries:(NSArray*)entries;
-(void)request:(ACFTPListRequest*)request didFailWithError:(NSError*)error;
-(void)request:(ACFTPListRequest*)request didUpdateStatus:(NSString*)status;
-(void)requestDidCancel:(ACFTPListRequest*)request;

@end

@interface ACFTPListRequest : NSObject <NSStreamDelegate> {
	id<ACFTPListRequestDelegate> delegate;
	id location;
	NSMutableData* listData;
	NSMutableArray* listEntries;
	NSInputStream* networkStream;
	BOOL showHiddenEntries;
	NSURL* directoryURL;
}

@property (nonatomic, retain) NSMutableData* listData;
@property (nonatomic, retain) NSMutableArray* listEntries;
@property (nonatomic, retain) NSInputStream* networkStream;
@property (nonatomic, retain) id<ACFTPListRequestDelegate> delegate;
@property (nonatomic, retain) id location;
@property BOOL showHiddenEntries;
@property (nonatomic, retain) NSURL* directoryURL;

-(void)start;
-(void)cancel;
-(id)initWithLocation:(id)location;
+(ACFTPListRequest*)requestWithLocation:(id)location;

@end
