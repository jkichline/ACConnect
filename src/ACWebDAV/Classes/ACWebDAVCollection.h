//
//  ACWebDAVCollection.h
//  ACWebDAVTest
//
//  Created by Jason Kichline on 8/19/10.
//  Copyright 2010 Jason Kichline. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ACWebDAVItem.h"
#import "ACWebDAVLocation.h"

@interface ACWebDAVCollection : ACWebDAVItem {
	NSMutableArray* contents;
}

@property (readonly) NSMutableArray* contents;

-(id)initWithLocation:(ACWebDAVLocation*)location;

@end
