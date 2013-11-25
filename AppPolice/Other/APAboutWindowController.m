//
//  APPreferencesController.m
//  AppPolice
//
//  Created by Maksym on 20/11/13.
//  Copyright (c) 2013 Maksym Stefanchuk. All rights reserved.
//

#import "APAboutWindowController.h"
#import "APURLTextField.h"

#define AP_UPDATES_SERVER @"http://www.rk.loc/checkupdate"
#define kRemoteAvaibleVersionKey @"version"
#define kRemoteDownloadURLKey @"download_url"


@implementation APAboutWindowController

- (id)init {
	return [super initWithWindowNibName:@"APAboutWindow"];
}


- (void)dealloc {
	[_statusTextField release];
	[[self checkUpdatesButton] release];
	[super dealloc];
}


- (void)windowDidLoad {
    [super windowDidLoad];
	// Retain button. When user presses the Check for Updates button it is
	// remove from superview but don't let it to be released just yet, since
	// we can re-use it if there are no updates avaible and the About window
	// is re-opened again.
	[[self checkUpdatesButton] retain];
	
	NSDictionary *bundleInfo = [[NSBundle mainBundle] infoDictionary];
	[[self versionTextField] setStringValue:[NSString stringWithFormat:NSLocalizedString(@"Version: %@", @"About window"), [bundleInfo objectForKey:@"CFBundleShortVersionString"]]];
	[[self homepageTextField] setURLAttribute:@"http://definemac.com/"];
}


// Override window controller's method to re-display 'Check for Updates' button
// if needed.
- (void)showWindow:(id)sender {
	NSButton *btn = [self checkUpdatesButton];
	// If checked earlier and there are no updates available re-display button
	// when About window is opened again.
	if (! [[self window] isVisible] && [btn superview] == NULL && _flags.update_available == 0) {
		[_statusTextField removeFromSuperview];
		[[self updateStatusView] addSubview:btn];
		[[self updateStatusView] addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[btn]|"
																						options:0
																						metrics:nil
																						  views:NSDictionaryOfVariableBindings(btn)]];
		[[self updateStatusView] addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[btn]|"
																						options:0
																						metrics:nil
																						  views:NSDictionaryOfVariableBindings(btn)]];
	}
	
	[super showWindow:sender];
}


- (IBAction)checkUpdates:(id)sender {
	[[self checkUpdatesButton] removeFromSuperview];

	if (! _statusTextField) {
		_statusTextField = [[NSTextField alloc] init];
		[[_statusTextField cell] setWraps:YES];
		[_statusTextField setPreferredMaxLayoutWidth:170.0];
		[_statusTextField setFont:[NSFont systemFontOfSize:11]];
		[_statusTextField setTextColor:[NSColor colorWithCalibratedWhite:0.4 alpha:1.0]];
		[_statusTextField setBordered:NO];
		[_statusTextField setBezeled:NO];
		[_statusTextField setBezelStyle:NSTextFieldSquareBezel];
		[_statusTextField setDrawsBackground:NO];
		[_statusTextField setEditable:NO];
		[_statusTextField setRefusesFirstResponder:YES];
		[_statusTextField setTranslatesAutoresizingMaskIntoConstraints:NO];
	}
	[_statusTextField setStringValue:NSLocalizedString(@"Checking for updates...", @"About window")];
	[[self updateStatusView] addSubview:_statusTextField];
	[[self updateStatusView] addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_statusTextField]|"
																		 options:0
																		 metrics:nil
																		   views:NSDictionaryOfVariableBindings(_statusTextField)]];
	[[self updateStatusView] addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_statusTextField]"
																		 options:0
																		 metrics:nil
																		   views:NSDictionaryOfVariableBindings(_statusTextField)]];

	
	NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:AP_UPDATES_SERVER]
											 cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
										 timeoutInterval:30.0];
	_receivedData = [[NSMutableData alloc] init];
	_connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
	if (! _connection) {
		[_statusTextField setStringValue:NSLocalizedString(@"Couldn't connect to server", @"About window")];
		[_connection release];
		[_receivedData release];
	}
}


- (void)interpretReceivedResult:(NSDictionary *)serverInfo {
	NSDictionary *bundleInfo = [[NSBundle mainBundle] infoDictionary];
	NSString *version = [bundleInfo objectForKey:@"CFBundleShortVersionString"];
	NSString *availableVersion = [serverInfo objectForKey:kRemoteAvaibleVersionKey];
		
	if ([availableVersion compare:version] == NSOrderedDescending) {
		_flags.update_available = 1;
		[_statusTextField setStringValue:NSLocalizedString(@"New version is available.", @"About window")];
		
		APURLTextField *downloadLink = [[[APURLTextField alloc] init] autorelease];
		[[downloadLink cell] setWraps:YES];
		[downloadLink setPreferredMaxLayoutWidth:170.0];
		[downloadLink setURLAttribute:[serverInfo objectForKey:kRemoteDownloadURLKey]];
		[downloadLink setPreferredColor:[NSColor colorWithDeviceRed:0.35 green:0.42 blue:0.53 alpha:1.0]];
		[downloadLink setStringValue:NSLocalizedString(@"Go to download page", @"About window")];
		[[self updateStatusView] addSubview:downloadLink];
		[downloadLink setTranslatesAutoresizingMaskIntoConstraints:NO];
		[[self updateStatusView] addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[downloadLink]|"
																						options:0
																						metrics:nil
																						  views:NSDictionaryOfVariableBindings(downloadLink)]];
		[[self updateStatusView] addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[_statusTextField]-(1)-[downloadLink]|"
																					   options:0
																					   metrics:nil
																						 views:NSDictionaryOfVariableBindings(_statusTextField, downloadLink)]];
	} else {
		[_statusTextField setStringValue:NSLocalizedString(@"AppPolice is up to date", @"About window")];
	}
}


#pragma mark *** Connection delegate methods ***

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
	// In case of redirect empty data
	[_receivedData setLength:0];
}


- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
	[_receivedData appendData:data];
}


- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
	NSError *error = nil;
	id JSONObject = [NSJSONSerialization JSONObjectWithData:_receivedData options:0 error:&error];
	if (error) {
		[_statusTextField setStringValue:NSLocalizedString(@"Error occurred while processing data.", @"About window, received data from remote server is not valid")];
		NSLog(@"Error occurred while processing data received from server: %@", [error localizedDescription]);
	} else {
		[self interpretReceivedResult:(NSDictionary *)JSONObject];
	}
	[_connection release];
	[_receivedData release];
}


- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
	[_statusTextField setStringValue:NSLocalizedString(@"Couldn't connect to server", @"About window")];
	NSLog(@"Connection to \"%@\" failed with error: %@", AP_UPDATES_SERVER, [error localizedDescription]);
	[_connection release];
	[_receivedData release];

}

@end
