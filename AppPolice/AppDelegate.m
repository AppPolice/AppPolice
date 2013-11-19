//
//  AppDelegate.m
//  cpulim
//
//  Created by Maksym on 5/19/13.
//  Copyright (c) 2013 Maksym Stefanchuk. All rights reserved.
//

#import "AppDelegate.h"
#import "StatusbarItemController.h"
#import "StatusbarMenuController.h"
#import "ChromeMenu.h"

// temp
#import "StatusbarMenu.h"

#include "C/proc_cpulim.h"
#include "C/selfprofile.h"


@implementation AppDelegate


- (void)dealloc {
	[_statusbarItemController release];
	[_statusbarMenuController release];
	
    [super dealloc];
}


- (void)applicationWillFinishLaunching:(NSNotification *)notification {
	_statusbarItemController = [[StatusbarItemController alloc] init];
//	NSString *imagePath = [[NSBundle mainBundle] pathForResource:@"status_icon" ofType:@"tiff"];
//	NSImage *ico = [[[NSImage alloc] initWithContentsOfFile:imagePath] autorelease];
//	imagePath = [[NSBundle mainBundle] pathForResource:@"status_icon_inv" ofType:@"tiff"];
//	NSImage *ico_alt = [[[NSImage alloc] initWithContentsOfFile:imagePath] autorelease];
	NSImage *ico = [NSImage imageNamed:@"status_icon"];
	NSImage *ico_alt = [NSImage imageNamed:@"status_icon_inv"];
	[_statusbarItemController setImage:ico];
	[_statusbarItemController setAlternateImage:ico_alt];
}


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
#ifdef PROFILE_APPLICATION
	/* print stats right after App launch: resources used by OS X to launch the App */
	profiling_print_stats();
#endif
	
	_statusbarMenuController = [[StatusbarMenuController alloc] init];
	CMMenu *mainMenu = [_statusbarMenuController mainMenu];
	[_statusbarItemController setStatusbarItemMenu:mainMenu];
	
	
//	CMMenuItem *item = [[[CMMenuItem alloc] initWithTitle:@"Free" action:@selector(freeMenus:)] autorelease];
//	[item setTarget:self];
//	[mainMenu addItem:item];


}


//- (void)freeMenus:(id)sender {
//	[self performSelector:@selector(freeMenusHelper) withObject:nil afterDelay:0 inModes:[NSArray arrayWithObject:NSRunLoopCommonModes]];
//}
//
//- (void)freeMenusHelper {
//	NSLog(@"free menus");
////	[_statusbarItemController setStatusbarItemMenu:nil];
//	[_statusbarItemController release];
//	[_statusbarMenuController release];
//	[_statusbarMenuController release];
//}



- (void)applicationWillTerminate:(NSNotification *)notification {
	// We really want to stop limiter before application terminates,
	// or otherwise any limited processes will remain sleeping.
	proc_cpulim_suspend_wait();
}












- (IBAction)toggleMainMenu:(id)sender {
	[[_statusbarMenuController mainMenu] popUpMenuPositioningItem:nil atLocation:NSMakePoint(200, 800) inView:nil];
}


- (void)timerFire:(NSTimer *)timer {
	NSLog(@"timer fire");
}


- (void)actionForMenuItem {
	NSLog(@"item pressed");
}

- (IBAction)someAction:(id)sender {
//	[self performSelector:@selector(delayedNSlog) withObject:nil afterDelay:5.0 inModes:[NSArray arrayWithObject:NSRunLoopCommonModes]];
	NSLog(@"delay 5 sec before nslog");
	[self performSelector:@selector(delayedNSlog) withObject:nil afterDelay:5.0];
}

- (void)delayedNSlog {
	NSLog(@"\n\n\n!!!!!!!!!!!!!!!!!!!!!!! delayed nslog button click!!\n\n");
}


- (IBAction)startRunLoop1:(id)sender {
	static BOOL keepRunning = false;
	if (! keepRunning) {
		keepRunning = true;
		NSLog(@"Starting run loop 1");
	} else {
		keepRunning = false;
		NSLog(@"Stopping run loop 1");
	}

	while (keepRunning) {
		NSEvent *theEvent = [NSApp nextEventMatchingMask:NSMouseEnteredMask | NSLeftMouseDownMask | NSLeftMouseUpMask untilDate:[NSDate distantFuture] inMode:NSEventTrackingRunLoopMode dequeue:YES];
		
		NSLog(@"run loop 1 event: %@", theEvent);
		[[theEvent window] sendEvent:theEvent];
	}
}


- (IBAction)startRunLoop2:(id)sender {
	static BOOL keepRunning = false;
	
	if (! keepRunning) {
		keepRunning = true;
		NSLog(@"Starting run loop 2");
	} else {
		keepRunning = false;
		NSLog(@"Stopping run loop 2");
	}
	while (keepRunning) {
		NSEvent *theEvent = [NSApp nextEventMatchingMask:NSMouseEnteredMask | NSLeftMouseDownMask untilDate:[NSDate distantFuture] inMode:NSEventTrackingRunLoopMode dequeue:YES];
		
		NSLog(@"run loop 2 event: %@", theEvent);
		[[theEvent window] sendEvent:theEvent];
	}

}


@end
