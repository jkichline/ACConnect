//
//  FTPEntry.h
//  OnSong
//
//  Created by Jason Kichline on 3/23/11.
//  Copyright 2011 andCulture. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ACFTPLocation.h"

typedef enum {
	FTPEntryUnknown = 0,
	FTPEntryTypeFIFO = 1,
	FTPEntryTypeCharacterDevice = 2,
	FTPEntryTypeDirectory = 4,
	FTPEntryTypeBLL = 6,
	FTPEntryTypeFile = 8,
	FTPEntryTypeLink = 10,
	FTPEntryTypeSocket = 12,
	FTPEntryTypeWHT = 14
} FTPEntryType;

@interface ACFTPEntry : NSObject {
	NSDate* modified;
	NSString* owner;
	NSString* group;
	NSString* link;
	NSString* name;
	int size;
	FTPEntryType type;
	int mode;
	NSString* permissions;
	ACFTPLocation* parent;
}

@property (nonatomic, retain) NSDate* modified;
@property (nonatomic, retain) NSString* owner;
@property (nonatomic, retain) NSString* group;
@property (nonatomic, retain) NSString* link;
@property (nonatomic, retain) NSString* name;
@property (nonatomic, retain) ACFTPLocation* parent;
@property (readonly) NSString* permissions;
@property int size;
@property FTPEntryType type;
@property int mode;

@property (readonly) NSURL* url;
@property (readonly) NSURL* urlWithCredentials;

-(id)initWithDictionary:(NSDictionary*)entry;
+(ACFTPEntry*)entryWithDictionary:(NSDictionary*)entry;

@end
