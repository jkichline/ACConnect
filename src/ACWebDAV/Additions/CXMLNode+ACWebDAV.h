//
//  CXMLNode+ACWebDAV.h
//  ACWebDAVTest
//
//  Created by Jason Kichline on 8/20/10.
//  Copyright 2010 Jason Kichline. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TouchXML.h"

@interface CXMLNode (ACWebDAV)

-(NSMutableArray*)elementsNamed:(NSString*)localName withPrefix:(NSString*)prefix recursive:(BOOL)recursive;
-(CXMLNode*)elementNamed:(NSString*)localName withPrefix:(NSString*)prefix;

@end
