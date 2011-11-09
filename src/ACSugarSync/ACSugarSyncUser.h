//
//  ACSugarSyncUser.h
//  ACConnect
//
//  Created by Jason Kichline on 9/4/11.
//  Copyright (c) 2011 andCulture. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ACSugarSyncClient.h"

typedef enum {
	ACSugarSyncAlbumsCollection,
	ACSugarSyncDeletedCollection,
	ACSugarSyncMagicBriefcaseCollection,
	ACSugarSyncMobilePhotosCollection,
	ACSugarSyncPublicLinksCollection,
	ACSugarSyncReceivedSharesCollection,
	ACSugarSyncRecentActivitiesCollection,
	ACSugarSyncSyncFoldersCollection,
	ACSugarSyncWebArchiveCollection,
	ACSugarSyncWorkspacesCollection
} ACSugarSyncCollectionType;

@class ACSugarSyncClient;

@interface ACSugarSyncUser : NSObject {
	NSDictionary* dictionary;
	ACSugarSyncClient* client;
}

@property (nonatomic, readonly) NSString* username;
@property (nonatomic, readonly) NSString* nickname;
@property (readonly) int quota;
@property (readonly) int usage;

-(id)initWithDictionary:(NSDictionary*)dictionary andClient:(ACSugarSyncClient*)client;
+(ACSugarSyncUser*)userWithDictionary:(NSDictionary*)dictionary andClient:(ACSugarSyncClient*)client;

-(void)retrieveCollection:(ACSugarSyncCollectionType)type target:(id)target selector:(SEL)selector;
-(void)retrieveCollection:(ACSugarSyncCollectionType)type target:(id)target selector:(SEL)selector range:(NSRange)range;

@end
