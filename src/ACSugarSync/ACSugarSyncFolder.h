//
//  ACSugarSyncFolder.h
//  ACConnect
//
//  Created by Jason Kichline on 9/5/11.
//  Copyright (c) 2011 andCulture. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ACSugarSyncClient.h"

@class ACSugarSyncClient;

@interface ACSugarSyncFolder : NSObject {
	NSDictionary* dictionary;
	ACSugarSyncClient* client;
}

@property (nonatomic, readonly) NSString* displayName;
@property (nonatomic, readonly) NSDate* timeCreated;

-(id)initWithDictionary:(NSDictionary*)dictionary andClient:(ACSugarSyncClient*)client;
+(ACSugarSyncFolder*)folderWithDictionary:(NSDictionary*)dictionary andClient:(ACSugarSyncClient*)client;

@end
