//
//  ACKeychain.h
//  ACOAuth
//
//  Created by Jason Kichline on 8/3/11.
//  Copyright 2011 andCulture. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Security/Security.h>

@interface ACKeychain : NSObject {
    NSMutableDictionary* keychainData;
    NSMutableDictionary* genericPasswordQuery;
	NSString* identifier;
}

@property (nonatomic, retain) NSMutableDictionary* keychainData;
@property (nonatomic, retain) NSMutableDictionary* genericPasswordQuery;

- (id)initWithIdentifier:(NSString*)_identifier;
- (void)setObject:(id)inObject forKey:(id)key;
- (id)objectForKey:(id)key;
- (void)reset;

@end