//
//  CXMLNode+ACWebDAV.m
//  ACWebDAVTest
//
//  Created by Jason Kichline on 8/20/10.
//  Copyright 2010 Jason Kichline. All rights reserved.
//

#import "CXMLNode+ACWebDAV.h"


@implementation CXMLNode (ACWebDAV)

-(NSMutableArray*)elementsNamed:(NSString*)localName withPrefix:(NSString*)prefix recursive:(BOOL)recursive {
	NSMutableArray* a = [NSMutableArray array];
	for(CXMLNode* child in [self children]) {
		if((prefix == nil && [[child localName] isEqualToString:localName]) || 
		   (prefix != nil && [[child name] isEqualToString:[NSString stringWithFormat:@"%@:%@", prefix, localName]])) 
		{
			[a addObject:child];
		}
		if(recursive) {
			[a addObjectsFromArray:[child elementsNamed:localName withPrefix:prefix recursive:recursive]];
		}
	}
	return a;
}

-(CXMLNode*)elementNamed:(NSString*)localName withPrefix:(NSString*)prefix {
	NSMutableArray* a = [self elementsNamed:localName withPrefix:prefix recursive:YES];
	if(a.count > 0) {
		return [a objectAtIndex:0];
	}
	return nil;
}

@end
