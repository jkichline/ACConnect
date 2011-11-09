//
//  ACSugarSyncFile.h
//  ACConnect
//
//  Created by Jason Kichline on 9/6/11.
//  Copyright (c) 2011 andCulture. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ACSugarSyncClient.h"

@class ACSugarSyncClient;

@interface ACSugarSyncFile : NSObject {
	NSDictionary* dictionary;
	ACSugarSyncClient* client;
}

@property (nonatomic, readonly) NSString* displayName;
@property (nonatomic, readonly) NSString* mediaType;
@property (nonatomic, readonly) NSDate* lastModified;
@property (nonatomic, readonly) NSDate* timeCreated;
@property (nonatomic, readonly) BOOL presentOnServer;
@property (nonatomic, readonly) int size;

-(id)initWithDictionary:(NSDictionary*)dictionary andClient:(ACSugarSyncClient*)client;
+(ACSugarSyncFile*)fileWithDictionary:(NSDictionary*)dictionary andClient:(ACSugarSyncClient*)client;

-(void)fileData:(id)target selector:(SEL)selector;
-(void)versions:(id)target selector:(SEL)selector;

-(void)downloadFile;
-(void)downloadFileTo:(NSString*)filepath;
-(void)downloadFileTo:(NSString*)filepath target:(id)target selector:(SEL)selector;

+(NSMutableArray*)filesFromArray:(NSArray*)array withClient:(ACSugarSyncClient*)client;

@end
