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
//	[_receivedData release];
	[_statusTextField release];
	[super dealloc];
}


- (void)windowDidLoad {
    [super windowDidLoad];
	NSDictionary *bundleInfo = [[NSBundle mainBundle] infoDictionary];
	[[self versionTextField] setStringValue:[NSString stringWithFormat:@"Version: %@", [bundleInfo objectForKey:@"CFBundleShortVersionString"]]];
	[[self homepageTextField] setURLAttribute:@"http://www.google.com/"];
}


- (IBAction)checkUpdates:(id)sender {
	[[self checkUpdatesButton] removeFromSuperview];

	_statusTextField = [[NSTextField alloc] init];
	[[_statusTextField cell] setWraps:YES];
	[_statusTextField setPreferredMaxLayoutWidth:170.0];
	[_statusTextField setStringValue:@"Checking for updates..."];
	[_statusTextField setFont:[NSFont systemFontOfSize:11]];
	[_statusTextField setTextColor:[NSColor colorWithCalibratedWhite:0.4 alpha:1.0]];
	[_statusTextField setBordered:NO];
	[_statusTextField setBezeled:NO];
	[_statusTextField setBezelStyle:NSTextFieldSquareBezel];
	[_statusTextField setDrawsBackground:NO];
	[_statusTextField setEditable:NO];
	[_statusTextField setRefusesFirstResponder:YES];
	[_statusTextField setTranslatesAutoresizingMaskIntoConstraints:NO];
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
		[_statusTextField setStringValue:@"Couldn't connect to server"];
		[_connection release];
		[_receivedData release];
	}
}


- (void)interpretReceivedResult:(NSDictionary *)serverInfo {
	NSDictionary *bundleInfo = [[NSBundle mainBundle] infoDictionary];
	NSString *version = [bundleInfo objectForKey:@"CFBundleShortVersionString"];
	NSString *availableVersion = [serverInfo objectForKey:kRemoteAvaibleVersionKey];
	
//	NSLog(@"v: %@, new: %@", version, availableVersion);
	
	if ([availableVersion compare:version] == NSOrderedDescending) {
		[_statusTextField setStringValue:@"New version is available."];
		
		APURLTextField *downloadLink = [[[APURLTextField alloc] init] autorelease];
		[[downloadLink cell] setWraps:YES];
		[downloadLink setPreferredMaxLayoutWidth:170.0];
		[downloadLink setURLAttribute:[serverInfo objectForKey:kRemoteDownloadURLKey]];
		[downloadLink setPreferredColor:[NSColor colorWithDeviceRed:0.35 green:0.42 blue:0.53 alpha:1.0]];
		[downloadLink setStringValue:@"Go to download page"];
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
		[_statusTextField setStringValue:@"AppPolice is up to date"];
	}
	
//	[[self window] visualizeConstraints:[[self updateStatusView] constraints]];
}


#pragma mark *** Connection delegate methods ***

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
//	NSLog(@"response: %@", response);
	// In case of redirect empty data
	[_receivedData setLength:0];
}


- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
	[_receivedData appendData:data];
//	NSLog(@"data: %@", data);
//	NSError *error = [[NSError alloc] init];
//	[data writeToFile:@"/Users/objective/Desktop/response.html" options:NSDataWritingAtomic error:&error];
}


- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
//	NSLog(@"finish loading connection: %@", _receivedData);
	NSError *error = nil;
	id JSONObject = [NSJSONSerialization JSONObjectWithData:_receivedData options:0 error:&error];
	if (error) {
		[_statusTextField setStringValue:@"Error occurred while processing data."];
		NSLog(@"Error occurred while processing data received from server: %@", [error localizedDescription]);
	} else {
		NSDictionary *dict = (NSDictionary *)JSONObject;
		NSLog(@"json: %@", dict);
		
		[self interpretReceivedResult:(NSDictionary *)JSONObject];
	}
	[_connection release];
	[_receivedData release];
}


- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
	[_statusTextField setStringValue:@"Couldn't connect to server"];
	NSLog(@"Connection to \"%@\" failed with error: %@", AP_UPDATES_SERVER, [error localizedDescription]);
	[_connection release];
	[_receivedData release];

}

@end
