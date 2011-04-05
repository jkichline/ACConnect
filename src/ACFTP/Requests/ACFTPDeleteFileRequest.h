//
//  FTPDeleteFileRequest.h
//  OnSong
//
//  Created by Jason Kichline on 3/24/11.
//  Copyright 2011 andCulture. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ACFTPDeleteFileRequest;

@protocol ACFTPDeleteFileRequestDelegate

@optional

-(void)request:(ACFTPDeleteFileRequest*)request didDeleteFile:(NSURL*)fileURL;
-(void)request:(ACFTPDeleteFileRequest*)request didFailWithError:(NSError*)error;

@end

@interface ACFTPDeleteFileRequest : NSObject {
	id<ACFTPDeleteFileRequestDelegate> delegate;
	id location;
}

@property (nonatomic, retain) id<ACFTPDeleteFileRequestDelegate> delegate;
@property (nonatomic, retain) id location;

-(void)start;
-(id)initWithLocation:(id)location;
+(ACFTPDeleteFileRequest*)requestWithLocation:(id)location;

@end
