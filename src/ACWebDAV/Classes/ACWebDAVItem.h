//
//  ACWebDAVItem.h
//  ACWebDAVTest
//
//  Created by Jason Kichline on 8/19/10.
//  Copyright 2010 Jason Kichline. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ACWebDAVLock.h"

@class ACWebDAVItem;

@protocol ACWebDAVItemDelegate

@optional

-(void)ACWebDAVItem:(ACWebDAVItem*)item didReceiveProperties:(NSDictionary*)properties;

@end

typedef enum {
	ACWebDAVItemTypeFile,
	ACWebDAVItemTypeCollection
} ACWebDAVItemType;

@class ACWebDAVLocation;

@protocol ACWebDAVPropertyRequestDelegate;

@interface ACWebDAVItem : NSObject {
	ACWebDAVItemType type;
	NSString* href;
	NSString* relativeHref;
	NSString* displayName;
	NSDate* creationDate;
	NSDate* lastModifiedDate;
	ACWebDAVLocation* location;
	id delegate;
	ACWebDAVLock* lock;
}

@property ACWebDAVItemType type;
@property (readonly) NSString* href;
@property (readonly) NSString* absoluteHref;
@property (readonly) NSString* absoluteParentHref;
@property (readonly) NSString* displayName;
@property (readonly) NSDate* creationDate;
@property (readonly) NSDate* lastModifiedDate;
@property (readonly) NSString* parentHref;
@property (nonatomic, retain) ACWebDAVLocation* location;
@property (nonatomic, retain) id delegate;
@property (readonly)  NSURL* url;
@property (nonatomic, retain) ACWebDAVLock* lock;

-(id)initWithDictionary:(NSDictionary*)dictionary;
-(id)initWithLocation:(ACWebDAVLocation*)location;
+(ACWebDAVItem*)itemWithLocation:(ACWebDAVLocation*)location;

-(void)getProperties;

@end
