//
//  ACSugarSyncCollection.h
//  ACConnect
//
//  Created by Jason Kichline on 9/6/11.
//  Copyright (c) 2011 andCulture. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ACSugarSyncClient.h"

@class ACSugarSyncClient;

@interface ACSugarSyncCollection : NSObject {
	NSDictionary* dictionary;
	ACSugarSyncClient* client;
}

@property (nonatomic, readonly) NSURL* ref;
@property (nonatomic, readonly) NSString* displayName;
@property (nonatomic, readonly) NSString* type;

-(id)initWithDictionary:(NSDictionary*)dictionary andClient:(ACSugarSyncClient*)client;
+(ACSugarSyncCollection*)collectionWithDictionary:(NSDictionary*)dictionary andClient:(ACSugarSyncClient*)client;

-(void)contents:(id)target selector:(SEL)selector;

-(void)createFolderNamed:(NSString*)folderName;
-(void)createFolderNamed:(NSString*)folderName target:(id)target selector:(SEL)selector;

+(NSMutableArray*)collectionsFromArray:(NSArray*)array withClient:(ACSugarSyncClient*)client;

@end
