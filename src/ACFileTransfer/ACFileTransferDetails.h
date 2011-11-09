//
//  ACFileTransferDetails.h
//  OnSong
//
//  Created by Jason Kichline on 8/19/11.
//  Copyright (c) 2011 Jason Kichline. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ACFileTransferDetails : NSObject

@property (nonatomic, retain) NSString* peer;
@property (nonatomic, retain) NSString* digest;
@property (nonatomic, retain) NSString* UUID;
@property (nonatomic, retain) NSString* filename;
@property (nonatomic) int bytes;
@property (nonatomic) int total;
@property (nonatomic) int start;
@property (nonatomic) int length;
@property (nonatomic, retain) NSData* data;

-(id)initWithDictionary:(NSDictionary*)dictionary;
+(ACFileTransferDetails*)detailsWithDictionary:(NSDictionary*)dictionary;

@end
