//
//  FTPHelper.h
//  OnSong
//
//  Created by Jason Kichline on 3/24/11.
//  Copyright 2011 andCulture. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface ACFTPHelper : NSObject {

}

+(NSURL*)urlByRemovingCredentials:(NSURL*)input;
+(NSURL*)urlByAddingCredentials:(NSURL*)input username:(NSString*)username password:(NSString*)password;

@end
