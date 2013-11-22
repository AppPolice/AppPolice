//
//  APPreferencesController.h
//  AppPolice
//
//  Created by Maksym on 20/11/13.
//  Copyright (c) 2013 Maksym Stefanchuk. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class APURLTextField;

@interface APAboutWindowController : NSWindowController <NSURLConnectionDelegate, NSURLConnectionDataDelegate>
{
	@private
	NSURLConnection *_connection;
	NSMutableData *_receivedData;	// used during NSURLConnection
	NSTextField *_statusTextField;
	struct {
		int update_available;
	} _flags;
}

- (IBAction)checkUpdates:(id)sender;
- (void)interpretReceivedResult:(NSDictionary *)serverInfo;

@property (assign) IBOutlet NSTextField *versionTextField;
@property (assign) IBOutlet NSView *updateStatusView;
@property (assign) IBOutlet NSButton *checkUpdatesButton;
@property (assign) IBOutlet APURLTextField *homepageTextField;

@end
