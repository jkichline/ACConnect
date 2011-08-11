//
//  ACKeychain.m
//  ACOAuth
//
//  Created by Jason Kichline on 8/3/11.
//  Copyright 2011 andCulture. All rights reserved.
//

#import "ACKeychain.h"


@interface ACKeychain (PrivateMethods)


//The following two methods translate dictionaries between the format used by
// the view controller (NSString *) and the Keychain Services API:
- (NSMutableDictionary *)secItemFormatToDictionary:(NSDictionary *)dictionaryToConvert;
- (NSMutableDictionary *)dictionaryToSecItemFormat:(NSDictionary *)dictionaryToConvert;
// Method used to write data to the keychain:
- (void)writeToKeychain;

@end

@implementation ACKeychain

//Synthesize the getter and setter:
@synthesize keychainData, genericPasswordQuery;

-(id)initWithIdentifier:(NSString*)_identifier {
    if ((self = [super init])) {
		
		// Set the identifier
		identifier = [_identifier retain];
        
        OSStatus keychainErr = noErr;
        // Set up the keychain search dictionary:
        genericPasswordQuery = [[NSMutableDictionary alloc] init];
        // This keychain item is a generic password.
        [genericPasswordQuery setObject:(id)kSecClassGenericPassword
                                 forKey:(id)kSecClass];
        // The kSecAttrGeneric attribute is used to store a unique string that is used
        // to easily identify and find this keychain item. The string is first
        // converted to an NSData object:
        NSData *keychainItemID = [NSData dataWithBytes:[identifier UTF8String]
                                                length:strlen((const char *)[identifier UTF8String])];
        [genericPasswordQuery setObject:keychainItemID forKey:(id)kSecAttrGeneric];
        // Return the attributes of the first match only:
        [genericPasswordQuery setObject:(id)kSecMatchLimitOne forKey:(id)kSecMatchLimit];
        // Return the attributes of the keychain item (the password is
        //  acquired in the secItemFormatToDictionary: method):
        [genericPasswordQuery setObject:(id)kCFBooleanTrue
                                 forKey:(id)kSecReturnAttributes];
        
        //Initialize the dictionary used to hold return data from the keychain:
        NSMutableDictionary *outDictionary = nil;
        // If the keychain item exists, return the attributes of the item: 
        keychainErr = SecItemCopyMatching((CFDictionaryRef)genericPasswordQuery,
                                          (CFTypeRef *)&outDictionary);
        if (keychainErr == noErr) {
            // Convert the data dictionary into the format used by the view controller:
            self.keychainData = [self secItemFormatToDictionary:outDictionary];
        } else if (keychainErr == errSecItemNotFound) {
            // Put default values into the keychain if no matching
            // keychain item is found:
            [self reset];
        } else {
            // Any other error is unexpected.
            NSAssert(NO, @"Serious error.\n");
        }
        [outDictionary release];
    }
    return self;
}

- (void)dealloc
{
	[identifier release];
    [keychainData release];
    [genericPasswordQuery release];
    [super dealloc];
}

// Implement the setObject:forKey method, which writes attributes to the keychain:
- (void)setObject:(id)inObject forKey:(id)key
{
    if (inObject == nil) return;
    id currentObject = [keychainData objectForKey:key];
    if (![currentObject isEqual:inObject])
    {
        [keychainData setObject:inObject forKey:key];
        [self writeToKeychain];
    }
}

// Implement the objectForKey: method, which reads an attribute value from a dictionary:
- (id)objectForKey:(id)key
{
    return [keychainData objectForKey:key];
}

// Reset the values in the keychain item, or create a new item if it
// doesn't already exist:

- (void)reset
{
	OSStatus junk = noErr;
    if (!keychainData) //Allocate the keychainData dictionary if it doesn't exist yet.
    {
        self.keychainData = [[NSMutableDictionary alloc] init];
    }
    else if (keychainData)
    {
        // Format the data in the keychainData dictionary into the format needed for a query
        //  and put it into tmpDictionary:
        NSMutableDictionary *tmpDictionary = [self dictionaryToSecItemFormat:keychainData];
        // Delete the keychain item in preparation for resetting the values:
		junk = SecItemDelete((CFDictionaryRef)tmpDictionary);
		if(junk != noErr && junk != errSecItemNotFound) {
			NSLog(@"Reset Keychain Error: %@", [self fetchStatus:junk]);
		}
//        NSAssert(junk == noErr || junk == errSecItemNotFound, @"Problem deleting current dictionary.");
    }
    
    // Default generic data for Keychain Item:
    [keychainData setObject:@"" forKey:(id)kSecAttrLabel];
    [keychainData setObject:@"" forKey:(id)kSecAttrDescription];
    [keychainData setObject:@"" forKey:(id)kSecAttrAccount];
    [keychainData setObject:@"" forKey:(id)kSecAttrService];
    [keychainData setObject:@"" forKey:(id)kSecAttrComment];
    [keychainData setObject:@"" forKey:(id)kSecValueData];
}

-(NSString*)fetchStatus:(OSStatus)status {
	if(status == 0)
		return @"success";
	else if(status == errSecNotAvailable)
		return @"no trust results available";
	else if(status == errSecItemNotFound)
		return @"the item cannot be found";
	else if(status == errSecParam)
		return @"parameter error";
	else if(status == errSecAllocate)
		return @"memory allocation error";
	else if(status == errSecInteractionNotAllowed)
		return @"user interaction not allowd";
	else if(status == errSecUnimplemented)
		return @"not implemented";
	else if(status == errSecDuplicateItem)
		return @"item already exists";
	else if(status == errSecDecode)
		return @"unable to decode data";
	else
		return [NSString stringWithFormat:@"%d", status];
}

// Implement the dictionaryToSecItemFormat: method, which takes the attributes that
//   you want to add to the keychain item and sets up a dictionary in the format
//  needed by Keychain Services:
- (NSMutableDictionary *)dictionaryToSecItemFormat:(NSDictionary *)dictionaryToConvert
{
    // This method must be called with a properly populated dictionary
    // containing all the right key/value pairs for a keychain item search.
    
    // Create the return dictionary:
    NSMutableDictionary *returnDictionary =
    [NSMutableDictionary dictionaryWithDictionary:dictionaryToConvert];
    
    // Add the keychain item class and the generic attribute:
    NSData *keychainItemID = [NSData dataWithBytes:[identifier UTF8String]
                                            length:strlen((const char *)[identifier UTF8String])];
    [returnDictionary setObject:keychainItemID forKey:(id)kSecAttrGeneric];
    [returnDictionary setObject:(id)kSecClassGenericPassword forKey:(id)kSecClass];
    
    // Convert the password NSString to NSData to fit the API paradigm:
    NSString *passwordString = [dictionaryToConvert objectForKey:(id)kSecValueData];
    [returnDictionary setObject:[passwordString dataUsingEncoding:NSUTF8StringEncoding]
                         forKey:(id)kSecValueData];
    return returnDictionary;
}

// Implement the secItemFormatToDictionary: method, which takes the attribute dictionary
//  obtained from the keychain item, acquires the password from the keychain, and
//  adds it to the attribute dictionary:
- (NSMutableDictionary *)secItemFormatToDictionary:(NSDictionary *)dictionaryToConvert
{
    // This method must be called with a properly populated dictionary
    // containing all the right key/value pairs for the keychain item.
    
    // Create a return dictionary populated with the attributes:
    NSMutableDictionary *returnDictionary = [NSMutableDictionary
                                             dictionaryWithDictionary:dictionaryToConvert];
    
    // To acquire the password data from the keychain item,
    // first add the search key and class attribute required to obtain the password:
    [returnDictionary setObject:(id)kCFBooleanTrue forKey:(id)kSecReturnData];
    [returnDictionary setObject:(id)kSecClassGenericPassword forKey:(id)kSecClass];
    // Then call Keychain Services to get the password:
    NSData *passwordData = NULL;
    OSStatus keychainError = noErr; //
    keychainError = SecItemCopyMatching((CFDictionaryRef)returnDictionary,
                                        (CFTypeRef *)&passwordData);
    if (keychainError == noErr)
    {
        // Remove the kSecReturnData key; we don't need it anymore:
        [returnDictionary removeObjectForKey:(id)kSecReturnData];
        
        // Convert the password to an NSString and add it to the return dictionary:
        NSString *password = [[[NSString alloc] initWithBytes:[passwordData bytes]
                                                       length:[passwordData length] encoding:NSUTF8StringEncoding] autorelease];
        [returnDictionary setObject:password forKey:(id)kSecValueData];
    }
    // Don't do anything if nothing is found.
    else if (keychainError == errSecItemNotFound) {
        NSAssert(NO, @"Nothing was found in the keychain.\n");
    }
    // Any other error is unexpected.
    else
    {
        NSAssert(NO, @"Serious error.\n");
    }
    
    [passwordData release];
    return returnDictionary;
}

// Implement the writeToKeychain method, which is called by the setObject routine,
//   which in turn is called by the UI when there is new data for the keychain. This
//   method modifies an existing keychain item, or--if the item does not already
//   exist--creates a new keychain item with the new attribute value plus
//  default values for the other attributes.
- (void)writeToKeychain
{
    NSDictionary *attributes = NULL;
    NSMutableDictionary *updateItem = NULL;
    
    // If the keychain item already exists, modify it:
    if (SecItemCopyMatching((CFDictionaryRef)genericPasswordQuery,
                            (CFTypeRef *)&attributes) == noErr)
    {
        // First, get the attributes returned from the keychain and add them to the
        // dictionary that controls the update:
        updateItem = [NSMutableDictionary dictionaryWithDictionary:attributes];
        
        // Second, get the class value from the generic password query dictionary and
        // add it to the updateItem dictionary:
        [updateItem setObject:[genericPasswordQuery objectForKey:(id)kSecClass]
                       forKey:(id)kSecClass];
        
        // Finally, set up the dictionary that contains new values for the attributes:
        NSMutableDictionary *tempCheck = [self dictionaryToSecItemFormat:keychainData];
        //Remove the class--it's not a keychain attribute:
        [tempCheck removeObjectForKey:(id)kSecClass];
        
        // You can update only a single keychain item at a time.
		//        NSAssert(SecItemUpdate((CFDictionaryRef)updateItem, (CFDictionaryRef)tempCheck) == noErr, @"Couldn't update the Keychain Item.");
        SecItemUpdate((CFDictionaryRef)updateItem, (CFDictionaryRef)tempCheck);
    }
    else
    {
        // No previous item found; add the new item.
        // The new value was added to the keychainData dictionary in the setObject routine,
        //  and the other values were added to the keychainData dictionary previously.
        
        // No pointer to the newly-added items is needed, so pass NULL for the second parameter:
		//        NSAssert(SecItemAdd((CFDictionaryRef)[self dictionaryToSecItemFormat:keychainData], NULL) == noErr, @"Couldn't add the Keychain Item." );
		SecItemAdd((CFDictionaryRef)[self dictionaryToSecItemFormat:keychainData], NULL);
    }
}


@end
