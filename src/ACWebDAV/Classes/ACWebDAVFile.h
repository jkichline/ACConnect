//
//  ACWebDAVFile.h
//  ACWebDAVTest
//
//  Created by Jason Kichline on 8/19/10.
//  Copyright 2010 Jason Kichline. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ACWebDAVLocation.h"
#import "ACWebDAVItem.h"

@interface ACWebDAVFile : ACWebDAVItem {
	long long contentLength;
	NSString* contentType;
}

@property (readonly) long long contentLength;
@property (readonly) NSString* contentType;

@end
