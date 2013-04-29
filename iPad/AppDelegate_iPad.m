//
//  AppDelegate_iPad.m
//  ACConnect
//
//  Created by Jason Kichline on 7/29/11.
//  Copyright 2011 andCulture. All rights reserved.
//

#import "AppDelegate_iPad.h"
#import "ACSugarSync.h"

@implementation AppDelegate_iPad

@synthesize window;


#pragma mark -
#pragma mark Application lifecycle

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    // Override point for customization after application launch.
	ACSugarSyncClient* client = [ACSugarSyncClient clientWithUsername:@"jkichline@gmail.com" password:@"spoon!08" accessKey:@"MTY0OTE1ODEzMTM1MzU1NTYxNjg" privateAccessKey:@"MmFhYzljN2RlOGQ0NDA5YWE1NDNlYTA0Yzk2MDk5N2Q"];
	[client authorize:self selector:@selector(authorized:)];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleAuthorization:) name:ACSugarSyncAuthorizationCompleteNotification object:client];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleRetrieveUser:) name:ACSugarSyncRetrievedUserNotification object:client];
    [self.window makeKeyAndVisible];
    
    return YES;
}

-(void)authorized:(ACSugarSyncClient*)client {
	[client user:self selector:@selector(handleUser:)];
}

-(void)handleUser:(ACSugarSyncUser*)user {
	[user retrieveCollection:ACSugarSyncWorkspacesCollection target:self selector:@selector(test:)];
}

-(void)test:(id)value {
	if([value isKindOfClass:[NSArray class]]) {
		for(id item in value) {
			if([item isKindOfClass:[ACSugarSyncCollection class]]) {
				NSLog(@"Collection: %@", item);
				ACSugarSyncCollection* collection = (ACSugarSyncCollection*)item;
				[collection createFolderNamed:@"Test 123" target:self selector:@selector(log:)];
				if([collection.displayName isEqualToString:@"Inserting"]) {
					[collection contents:self selector:@selector(test:)];
				}
			} else if([item isKindOfClass:[ACSugarSyncFile class]]) {
				ACSugarSyncFile* file = (ACSugarSyncFile*)item;
				NSLog(@"File: %@ - %d bytes", file, file.size);
				if(file.size > 0) {
                    //					[file downloadFile];
                    //					break;
				}
			}
		}
	} else {
		NSLog(@"%@", value);
	}
}

-(void)log:(id)value {
	NSLog(@"%@", value);
}

- (void)applicationWillResignActive:(UIApplication *)application {
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive.
     */
}


- (void)applicationWillTerminate:(UIApplication *)application {
    /*
     Called when the application is about to terminate.
     */
}


#pragma mark -
#pragma mark Memory management

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application {
    /*
     Free up as much memory as possible by purging cached data objects that can be recreated (or reloaded from disk) later.
     */
}


- (void)dealloc {
    [window release];
    [super dealloc];
}


@end
