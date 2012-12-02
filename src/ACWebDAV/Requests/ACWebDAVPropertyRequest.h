//
//  ACWebDAVPropertyRequest.h
//  ACWebDAVTest
//
//  Created by Jason Kichline on 8/19/10.
//  Copyright 2010 Jason Kichline. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ACWebDAV.h"

@class ACWebDAVItem;
@class ACWebDAVPropertyRequest;

@protocol ACWebDAVPropertyRequestDelegate

@optional

-(void)request:(ACWebDAVPropertyRequest*)request didReceiveProperties:(NSArray*)items;
-(void)request:(ACWebDAVPropertyRequest*)request didReturnItems:(NSArray*)items;
-(void)request:(ACWebDAVPropertyRequest*)request didFailWithError:(NSError*)error;
-(void)request:(ACWebDAVPropertyRequest*)request didFailWithErrorCode:(int)errorCode;

@end


typedef enum {
	ACWebDAVPropertyCreationDate = 1,
	ACWebDAVPropertyLastModifiedDate = 2,
	ACWebDAVPropertyDisplayName = 4,
	ACWebDAVPropertyContentLength = 8,
	ACWebDAVPropertyContentType = 16,
	ACWebDAVPropertyCommonProperties = 31,
	ACWebDAVPropertyETag = 32,
	ACWebDAVPropertySupportedLock = 64,
	ACWebDAVPropertyLockDiscovery = 128,
	ACWebDAVPropertyAllProperties = 4095
	
} ACWebDAVProperties;

static const NSUInteger ACWebDAVInfinityDepth = 4294967295;

@class ACWebDAVLocation;
@interface ACWebDAVPropertyRequest : NSObject {
	NSMutableData* receivedData;
	ACWebDAVProperties properties;
	ACWebDAVLocation* location;
	NSUInteger depth;
	id<ACWebDAVPropertyRequestDelegate> delegate;
}

@property ACWebDAVProperties properties;
@property (nonatomic, retain) NSMutableData* receivedData;
@property NSUInteger depth;
@property (nonatomic, retain) id<ACWebDAVPropertyRequestDelegate> delegate;
@property (nonatomic, retain) ACWebDAVLocation* location;

-(id)initWithLocation:(ACWebDAVLocation*)location;

+(ACWebDAVPropertyRequest*)requestWithLocation:(ACWebDAVLocation*)location;
+(ACWebDAVPropertyRequest*)requestForItem:(ACWebDAVItem*)item delegate:(id<ACWebDAVPropertyRequestDelegate>)_delegate;

-(NSData*)body;
-(void)start;

@end