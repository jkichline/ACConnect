//
//  ACFileTransfer.m
//  OnSong
//
//  Created by Jason Kichline on 8/16/11.
//  Copyright 2011 andCulture. All rights reserved.
//

#import "ACFileTransfer.h"
#import "ACFileTransferDetails.h"

#define MAX_PACKET_SIZE 65536	
#define DEFAULT_PACKET_SIZE 8192

NSString* const ACFileTransferFileSent = @"ACFileTransferFileSent";
NSString* const ACFileTransferFileBegan = @"ACFileTransferFileBegan";
NSString* const ACFileTransferFileReceived = @"ACFileTransferFileReceived";
NSString* const ACFileTransferFileFailed = @"ACFileTransferFileFailed";
NSString* const ACFileTransferPacketSent = @"ACFileTransferPacketSent";
NSString* const ACFileTransferPacketReceived = @"ACFileTransferPacketReceived";
NSString* const ACFileTransferPacketFailed = @"ACFileTransferPacketFailed";
NSString* const ACFileTransferAvailabilityChanged = @"ACFileTransferAvailabilityChanged";
NSString* const ACFileTransferUpdatedPeers = @"ACFileTransferUpdatedPeers";

#if 0
#define kGKSessionErrorDomain GKSessionErrorDomain
#else
#define kGKSessionErrorDomain @"com.apple.gamekit.GKSessionErrorDomain"
#endif

@interface ACFileTransfer (Private)

-(NSString*)makeUUID;
-(NSMutableDictionary*)removeDataFrom:(NSDictionary*)input;

@end


@implementation ACFileTransfer

@synthesize filename, contents, delegate, session, peers, logging, enabled, peersConnected;

#pragma mark -
#pragma mark Initialization

-(id)initWithDelegate:(id<ACFileTransferDelegate>)_delegate {
	self = [self init];
	if(self) {
		self.delegate = _delegate;
	}
	return self;
}

-(id)initWithContentsOfFile:(NSString*)filepath {
	self = [self initWithData:[NSData dataWithContentsOfFile:filepath]];
	if(self) {
		self.filename = [filepath lastPathComponent];
	}
	return self;
}

-(id)initWithData:(NSData*)data {
	self = [self init];
	if(self) {
		self.contents = data;
	}
	return self;
}

-(id)init {
	self = [super init];
	if(self) {
		// Set up if it's enabled
		enabled = YES;
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(determineEnabled:) name:@"BluetoothAvailabilityChangedNotification" object:nil];
		peersConnected = 0;
		
		// Create the session
		NSString* sessionID = [NSString stringWithFormat:@"%@.%@", [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleIdentifier"], @"filetransfer"];
		if(logging) { NSLog(@"Using session ID: %@", sessionID); }
		session = [[GKSession alloc] initWithSessionID:sessionID displayName:nil sessionMode:GKSessionModePeer];
		[self connect];
		
		// Set up the assembly line to reassemble packets
		assemblyLine = [[NSMutableDictionary alloc] init];
		self.packetSize = DEFAULT_PACKET_SIZE;
		
		// Listen for notifications
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleFileSent:) name:ACFileTransferFileSent object:self];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleFileBegan:) name:ACFileTransferFileBegan object:self];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleFileReceived:) name:ACFileTransferFileReceived object:self];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handlePacketSent:) name:ACFileTransferPacketSent object:self];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handlePacketReceived:) name:ACFileTransferPacketReceived object:self];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleFileFailed:) name:ACFileTransferFileFailed object:self];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handlePacketFailed:) name:ACFileTransferPacketFailed object:self];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleUpdatedPeers:) name:ACFileTransferUpdatedPeers object:self];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleAvailabilityChanged:) name:ACFileTransferAvailabilityChanged object:self];
	}
	return self;
}

-(void)determineEnabled:(NSNotification*)note {
	enabled = [[note object] boolValue];
	if(logging) { NSLog(@"Bluetooth: %@", (enabled) ? @"On" : @"Off"); }
	[[NSNotificationCenter defaultCenter] postNotificationName:ACFileTransferAvailabilityChanged object:self userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:enabled] forKey:@"enabled"]];
}

#pragma mark -
#pragma mark Connection Methods

-(void)connect {
	session.delegate = self;
	session.available = YES;
	[session setDataReceiveHandler:self withContext:nil];
}

-(void)disconnect {
	[session disconnectFromAllPeers];
	session.available = NO;
	session.delegate = nil;
}

#pragma mark -
#pragma mark Properties

-(int)packetSize {
	return packetSize;
}

-(void)setPacketSize:(int)value {
	if(value > MAX_PACKET_SIZE) {
		value = MAX_PACKET_SIZE;
	}
	packetSize = value;
}

-(NSString*)filename {
	if(filename == nil) { return [NSString stringWithFormat:@"%@.dat", [self.contents md5]]; }
	return filename;
}

-(NSArray*)peers {
	return [session peersWithConnectionState:GKPeerStateConnected];
}

-(NSArray*)packets {
	NSString* digest = [contents md5];
	NSMutableArray* a = [NSMutableArray array];
	int sent = 0;
	NSString* uuid = [self makeUUID];
	while(sent < contents.length) {
		int last = sent + self.packetSize;
		if(last > contents.length) {
			last = contents.length;
		}
		NSRange range = NSMakeRange(sent, last - sent);
		sent = last;
		NSDictionary* d = [NSDictionary dictionaryWithObjectsAndKeys:
						   uuid, @"uuid",
						   digest, @"digest",
						   self.filename, @"filename",
						   [self.contents subdataWithRange:range], @"data",
						   [NSNumber numberWithInt:contents.length], @"total",
						   [NSNumber numberWithInt:range.location], @"start",
						   [NSNumber numberWithInt:range.length], @"length", nil];
		NSData* packet = [NSPropertyListSerialization dataWithPropertyList:d format:NSPropertyListBinaryFormat_v1_0 options:0 error:nil];
		[a addObject:packet];
	}
	return [NSArray arrayWithArray:a];
}

#pragma mark -
#pragma mark Send Method

-(BOOL)sendFile:(NSString *)filepath toPeers:(NSArray *)_peers {
	self.contents = [NSData dataWithContentsOfFile:filepath];
	self.filename = [filepath lastPathComponent];
	return [self sendToPeers:_peers];
}

-(BOOL)sendData:(NSData *)data toPeers:(NSArray *)_peers {
	self.contents = data;
	return [self sendToPeers:_peers];
}

-(BOOL)sendToPeers:(NSArray*)recipients {
	if(!enabled) { return NO; }
	for(NSData* packet in self.packets) {
		NSError* error = nil;
		[self.session sendData:packet toPeers:recipients withDataMode:GKSendDataReliable error:&error];
		if(error != nil) {
			[[NSNotificationCenter defaultCenter] postNotificationName:ACFileTransferPacketFailed object:self userInfo:[NSDictionary dictionaryWithObject:error forKey:@"error"]];
		} else {
			[[NSNotificationCenter defaultCenter] postNotificationName:ACFileTransferPacketSent object:self];
		}
	}
	[[NSNotificationCenter defaultCenter] postNotificationName:ACFileTransferFileSent object:self];
	return YES;
}

#pragma mark -
#pragma mark Receive Method

-(void)receiveData:(NSData*)data fromPeer:(NSString*)peer inSession:(GKSession*)s context:(void*)context {

	// Extract the data back into a dictioanry
	NSDictionary* packet = [NSPropertyListSerialization propertyListWithData:data options:0 format:NULL error:nil];
	if(packet == nil) { return; }
	
	// Notify that we received a packet
	[[NSNotificationCenter defaultCenter] postNotificationName:ACFileTransferPacketReceived object:self userInfo:packet];
	
	// Generate the key from the peer and the UUID
	NSString* key = [NSString stringWithFormat:@"%@_%@", peer, [packet objectForKey:@"uuid"]];
	
	// If we are not currently processing, then make it
	NSMutableDictionary* received = [assemblyLine objectForKey:key];
	if(received == nil) {
		int size = [[packet objectForKey:@"total"] intValue];
		NSMutableData* data = [NSMutableData dataWithCapacity:size];
		data.length = size;
		received = [NSMutableDictionary dictionaryWithObjectsAndKeys:
					peer, @"peer",
					[packet objectForKey:@"digest"], @"digest",
					[packet objectForKey:@"uuid"], @"uuid",
					[packet objectForKey:@"filename"], @"filename",
					[NSNumber numberWithInt:0], @"bytes",
					data, @"data", nil];
		[assemblyLine setObject:received forKey:key];
		[[NSNotificationCenter defaultCenter] postNotificationName:ACFileTransferFileBegan object:self userInfo:received];
	}

	// Replace the bytes in the range
	[[received objectForKey:@"data"] replaceBytesInRange:NSMakeRange([[packet objectForKey:@"start"] intValue], [[packet objectForKey:@"length"] intValue]) withBytes:[(NSData*)[packet objectForKey:@"data"] bytes]];
	
	// Determine the total number of bytes received
	int totalBytes = [[received objectForKey:@"bytes"] intValue] + [[packet objectForKey:@"length"] intValue];
	if(logging) { NSLog(@"Received %d of %d bytes", totalBytes, [[packet objectForKey:@"total"] intValue]); }
	[received setObject:[NSNumber numberWithInt:totalBytes] forKey:@"bytes"];
	
	// If the total bytes equals or is greater than the expected, then notify
	if(totalBytes >= [[packet objectForKey:@"total"] intValue]) {
		
		// Check to make sure the data was received properly
		if([[packet objectForKey:@"digest"] isEqualToString:[[received objectForKey:@"data"] md5]]) {
			[[NSNotificationCenter defaultCenter] postNotificationName:ACFileTransferFileReceived object:self userInfo:received];
		} else {
			[[NSNotificationCenter defaultCenter] postNotificationName:ACFileTransferFileFailed object:self userInfo:received];
		}
		[assemblyLine removeObjectForKey:key];
	}
}

#pragma mark -
#pragma mark Session Connection

-(void)session:(GKSession*)s peer:(NSString *)peerID didChangeState:(GKPeerConnectionState)state {
	NSLog(@"Peer %@ changed state", peerID);
	switch(state) {
		case GKPeerStateAvailable:
			if(logging) {
				NSLog(@"%@ Available", [session displayNameForPeer:peerID]);
			}
			[s connectToPeer:peerID withTimeout:10];
			break;
		case GKPeerStateUnavailable:
			if(logging) {
				NSLog(@"%@ Unavailable", [session displayNameForPeer:peerID]);
			}
			break;
		case GKPeerStateConnected:
			peersConnected++;
			[[NSNotificationCenter defaultCenter] postNotificationName:ACFileTransferUpdatedPeers object:self];
			if(logging) {
				NSLog(@"%@ Connected", [session displayNameForPeer:peerID]);
			}
			break;
		case GKPeerStateConnecting:
			if(logging) {
				NSLog(@"%@ Connecting", [session displayNameForPeer:peerID]);
			}
			break;
		case GKPeerStateDisconnected:
			peersConnected--;
			if(logging) {
				NSLog(@"%@ Disconnected", [session displayNameForPeer:peerID]);
			}
			[[NSNotificationCenter defaultCenter] postNotificationName:ACFileTransferUpdatedPeers object:self];
			break;
	}
}

- (void)session:(GKSession *)s didReceiveConnectionRequestFromPeer:(NSString *)peerID {
	NSError* error;
	NSLog(@"Connect request received from %@", peerID);
	[s acceptConnectionFromPeer:peerID error:&error];
}

-(void)session:(GKSession*)session connectionWithPeerFailed:(NSString*)peerID withError:(NSError*)error {
	if(logging) {
		NSLog(@"Peer %@ Failed", peerID);
	}
}

-(void)session:(GKSession*)session didFailWithError:(NSError*)error {
    if ([[error domain] isEqual:kGKSessionErrorDomain] && ([error code] == GKSessionCannotEnableError)) {
		enabled = NO;
    } else {
		if(logging) {
			NSLog(@"didFailWithError: %@", error);
		}
    }
}

#pragma mark -
#pragma mark Handle Notifications

-(void)handleFileSent:(NSNotification*)notification {
	if(self.delegate != nil && [(NSObject*)self.delegate respondsToSelector:@selector(fileTransfer:sentFile:)]) {
		[self.delegate fileTransfer:self sentFile:self.filename];
	}
	if(logging) { NSLog(@"File Sent %@", self.filename); }
}

-(void)handleFileBegan:(NSNotification*)notification {
	if(self.delegate != nil && [(NSObject*)self.delegate respondsToSelector:@selector(fileTransfer:beganFile:)]) {
		[self.delegate fileTransfer:self beganFile:[ACFileTransferDetails detailsWithDictionary:[notification userInfo]]];
	}
	if(logging) { NSLog(@"File Began %@", [self removeDataFrom:[notification userInfo]]); }
}

-(void)handleFileReceived:(NSNotification*)notification {
	if(self.delegate != nil && [(NSObject*)self.delegate respondsToSelector:@selector(fileTransfer:receivedFile:)]) {
		[self.delegate fileTransfer:self receivedFile:[ACFileTransferDetails detailsWithDictionary:[notification userInfo]]];
	}
	if(logging) { NSLog(@"File Received %@", [self removeDataFrom:[notification userInfo]]); }
}

-(void)handleFileFailed:(NSNotification*)notification {
	if(self.delegate != nil && [(NSObject*)self.delegate respondsToSelector:@selector(fileTransfer:failedFile:)]) {
		[self.delegate fileTransfer:self failedFile:[ACFileTransferDetails detailsWithDictionary:[notification userInfo]]];
	}
	if(logging) { NSLog(@"File Failed %@", [self removeDataFrom:[notification userInfo]]); }
}

-(void)handlePacketSent:(NSNotification*)notification {
	if(self.delegate != nil && [(NSObject*)self.delegate respondsToSelector:@selector(fileTransfer:sentPacket:)]) {
		[self.delegate fileTransfer:self sentPacket:[ACFileTransferDetails detailsWithDictionary:[notification userInfo]]];
	}
}

-(void)handlePacketReceived:(NSNotification*)notification {
	if(self.delegate != nil && [(NSObject*)self.delegate respondsToSelector:@selector(fileTransfer:receivedPacket:)]) {
		[self.delegate fileTransfer:self receivedPacket:[ACFileTransferDetails detailsWithDictionary:[notification userInfo]]];
	}
	if(logging) { NSLog(@"Packet Received %@", [self removeDataFrom:[notification userInfo]]); }
}

-(void)handlePacketFailed:(NSNotification*)notification {
	if(self.delegate != nil && [(NSObject*)self.delegate respondsToSelector:@selector(fileTransfer:failedPacket:)]) {
		[self.delegate fileTransfer:self failedPacket:[ACFileTransferDetails detailsWithDictionary:[notification userInfo]]];
	}
	if(logging) { NSLog(@"Packet Failed %@", [self removeDataFrom:[notification userInfo]]); }
}

-(void)handleUpdatedPeers:(NSNotification*)notification {
	if(self.delegate != nil && [(NSObject*)self.delegate respondsToSelector:@selector(fileTransfer:updatedPeers:)]) {
		[self.delegate fileTransfer:self updatedPeers:self.peers];
	}
	if(logging) { NSLog(@"Updated Peers %@", self.peers); }
}

-(void)handleAvailabilityChanged:(NSNotification*)notification {
	BOOL available = [[[notification userInfo] objectForKey:@"enabled"] boolValue];
	if(self.delegate != nil && [(NSObject*)self.delegate respondsToSelector:@selector(fileTransfer:changedAvailability:)]) {
		[self.delegate fileTransfer:self changedAvailability:available];
	}
	if(logging) { NSLog(@"Availability Changed To %@", (available) ? @"YES" : @"NO"); }
}

#pragma mark -
#pragma mark Utility Methods

-(NSMutableDictionary*)removeDataFrom:(NSDictionary*)input {
	NSMutableDictionary* o = [NSMutableDictionary dictionaryWithDictionary:input];
	[o removeObjectForKey:@"data"];
	return o;
}

-(NSString*)makeUUID {
	CFUUIDRef uuid = CFUUIDCreate(kCFAllocatorDefault);
	NSString* uuidString = (NSString *)CFUUIDCreateString(kCFAllocatorDefault, uuid);
	[uuidString autorelease];
	CFRelease(uuid);
	return uuidString;
}

#pragma mark -
#pragma mark Memory Management

-(void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[self disconnect];
	[filename release];
	[contents release];
	[assemblyLine release];
	[session release];
	[super dealloc];
}

@end

@implementation NSData (MD5)
-(NSString*)md5 {
    unsigned char result[16];
    CC_MD5(self.bytes, self.length, result);
    return [NSString stringWithFormat:
			@"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
			result[0], result[1], result[2], result[3], 
			result[4], result[5], result[6], result[7],
			result[8], result[9], result[10], result[11],
			result[12], result[13], result[14], result[15]
			];
}

@end
