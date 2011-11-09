//
//  ACFileTransfer.h
//  OnSong
//
//  Created by Jason Kichline on 8/16/11.
//  Copyright 2011 Jason Kichline. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ACFileTransferDetails.h"
#import <GameKit/GameKit.h>

extern NSString* const ACFileTransferFileSentNotification;
extern NSString* const ACFileTransferFileBeganNotification;
extern NSString* const ACFileTransferFileReceivedNotification;
extern NSString* const ACFileTransferFileFailedNotification;
extern NSString* const ACFileTransferPacketSentNotification;
extern NSString* const ACFileTransferPacketReceivedNotification;
extern NSString* const ACFileTransferPacketFailedNotification;
extern NSString* const ACFileTransferAvailabilityChangedNotification;
extern NSString* const ACFileTransferUpdatedPeersNotification;

@class ACFileTransfer;

@protocol ACFileTransferDelegate

@optional

-(void)fileTransfer:(ACFileTransfer*)fileTransfer sentFile:(NSString*)file;
-(void)fileTransfer:(ACFileTransfer*)fileTransfer beganFile:(ACFileTransferDetails*)file;
-(void)fileTransfer:(ACFileTransfer*)fileTransfer receivedFile:(ACFileTransferDetails*)file;
-(void)fileTransfer:(ACFileTransfer*)fileTransfer failedFile:(ACFileTransferDetails*)file;
-(void)fileTransfer:(ACFileTransfer*)fileTransfer sentPacket:(ACFileTransferDetails*)packet;
-(void)fileTransfer:(ACFileTransfer*)fileTransfer receivedPacket:(ACFileTransferDetails*)packet;
-(void)fileTransfer:(ACFileTransfer*)fileTransfer failedPacket:(ACFileTransferDetails*)packet;
-(void)fileTransfer:(ACFileTransfer*)fileTransfer updatedPeers:(NSArray*)peers;
-(void)fileTransfer:(ACFileTransfer*)fileTransfer changedAvailability:(BOOL)available;

@end


@interface ACFileTransfer : NSObject <GKSessionDelegate> {
	NSData* contents;
	NSString* filename;
	int packetSize;
	NSMutableDictionary* assemblyLine;
	GKSession* session;
	BOOL logging;
	BOOL enabled;
	int peersConnected;
	id<ACFileTransferDelegate> delegate;
}

@property (nonatomic, retain) NSString* filename;
@property (nonatomic, retain) NSData* contents;
@property (nonatomic, retain) id<ACFileTransferDelegate> delegate;
@property (readonly) NSArray* packets;
@property (readonly) GKSession* session;
@property (readonly) NSArray* peers;
@property int packetSize;
@property BOOL logging;
@property (readonly) BOOL enabled;
@property (readonly) int peersConnected;

-(id)initWithSessionID:(NSString*)sessionID;
-(id)initWithDelegate:(id<ACFileTransferDelegate>)delegate;
-(id)initWithData:(NSData*)data;
-(id)initWithContentsOfFile:(NSString*)filepath;

-(void)connect;
-(void)disconnect;

-(BOOL)sendFile:(NSString*)filepath toPeers:(NSArray*)peers;
-(BOOL)sendData:(NSData*)data toPeers:(NSArray*)peers;
-(BOOL)sendData:(NSData*)data withFilename:(NSString*)filename toPeers:(NSArray*)peers;
-(BOOL)sendToPeers:(NSArray*)peers;

@end

@interface NSData (MD5)
-(NSString*)md5;
@end