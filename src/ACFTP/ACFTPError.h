//
//  ACFTPError.h
//  OnSong
//
//  Created by Jason Kichline on 4/5/11.
//  Copyright 2011 andCulture. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface ACFTPError : NSError {

}

+(ACFTPError*)errorWithCode:(int)errorCode;
+(NSString*)errorMessageFromCode:(int)errorCode;

@end
