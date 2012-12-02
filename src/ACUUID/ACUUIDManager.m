//
//  ACUUIDManager.m
//  OnSong
//
//  Created by Jason Kichline on 3/25/12.
//  Copyright (c) 2012 OnSong LLC. All rights reserved.
//

#import "ACUUIDManager.h"

@implementation ACUUIDManager

-(id)init {
	self = [super init];
	if(self) {
		keychain = [[ACKeychain alloc] initWithIdentifier:@"ACUUID"];
	}
	return self;
}

static ACUUIDManager* _sharedManager;
+(ACUUIDManager*)sharedManager {
	if(_sharedManager == nil) {
		_sharedManager = [[ACUUIDManager alloc] init];
	}
	return _sharedManager;
}

-(NSString*)uniqueIdentifier {
	NSString* uuid = [keychain objectForKey:kSecAttrAccount];
	if(uuid == nil || uuid.length == 0) {
		CFUUIDRef uuidRef = CFUUIDCreate(nil);
		uuid = [(NSString*)CFUUIDCreateString(nil, uuidRef) autorelease];
		CFRelease(uuidRef);
		[keychain setObject:uuid forKey:(id)kSecAttrAccount];
	}
	return uuid;
}

@end
