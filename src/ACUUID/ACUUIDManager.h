//
//  ACUUIDManager.h
//  OnSong
//
//  Created by Jason Kichline on 3/25/12.
//  Copyright (c) 2012 OnSong LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ACKeychain.h"

@interface ACUUIDManager : NSObject {
	ACKeychain* keychain;
}

+(ACUUIDManager*)sharedManager;
-(NSString*)uniqueIdentifier;

@end
