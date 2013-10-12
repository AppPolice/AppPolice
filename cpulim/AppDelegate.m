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
#import "CMMenu.h"
#import "StatusbarMenu.h"
//#include "C/def.h"
#include "C/proc_cpulim.h"

//#ifdef PROC_CPULIM_PROFILE
#include "C/selfprofile.h"
//#endif

@implementation AppDelegate

- (void)dealloc {
	[_statusbarItemController release];
	[_statusbarMenuController release];
	
	[_statusbarItem release];
//	[_statusbarMenu release];
    [super dealloc];
}


- (void)applicationWillFinishLaunching:(NSNotification *)notification {
	_statusbarItemController = [[StatusbarItemController alloc] init];
	[_statusbarItemController addItemToStatusbar];
	
	[self activateStatusbarItem];
}


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
#ifdef PROFILE_APPLICATION
	/* print stats right after App launch: resources used by OS X to launch the App */
	profiling_print_stats();
#endif
	
	_statusbarMenuController = [[StatusbarMenuController alloc] init];
//	[_statusbarMenuController createMainMenu];
	CMMenu *mainMenu = [_statusbarMenuController mainMenu];
	[_statusbarItemController setStatusbarItemMenu:mainMenu];
	

//	_statusbarMenu = [[StatusbarMenu alloc] init];
//	NSLog(@"menu:%@", [_statusbarMenu mainMenu]);
	[_statusbarMenu linkStatusbarItemWithMenu];
	
//	NSLog(@"!!!!!starting delay for menu update");
//	[self performSelector:@selector(updateMenu:) withObject:nil afterDelay:4.0];
//	[[NSRunLoop currentRunLoop] performSelector:@selector(delayAndUpdateMenu:) target:self argument:[statusbarMenuController statusbarMenu] order:0 modes:[NSArray arrayWithObject:NSEventTrackingRunLoopMode]];
	
//	NSLog(@"current run mode: %@", [[NSRunLoop currentRunLoop] currentMode]);
	[self performSelector:@selector(updateMenuFunc:) withObject:[_statusbarMenu mainMenu] afterDelay:2.0 inModes:[NSArray arrayWithObject:NSRunLoopCommonModes]];
//	[self performSelector:@selector(updateMenuFunc:) withObject:[statusbarMenuController statusbarMenu] afterDelay:4.0];

}

- (void)awakeFromNib {
	NSLog(@"%@ awakeFromNib", [self className]);
}

//- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {
//	
//	return NSTerminateNow;
//}

//extern void proc_cpulim_suspend_wait(void);		/* function returns only after limiter stopped */

- (void)applicationWillTerminate:(NSNotification *)notification {
	proc_cpulim_suspend_wait();
}


- (IBAction)toggleMainMenu:(id)sender {
	[[_statusbarMenuController mainMenu] start];
}


- (void)activateStatusbarItem {
	NSStatusBar *statusbar = [NSStatusBar systemStatusBar];
	_statusbarItem = [statusbar statusItemWithLength:NSVariableStatusItemLength];
	[_statusbarItem retain];
//	[_statusbarItem setView:[statusbarMenuController statusbarItemView]];
	[_statusbarItem setTitle:NSLocalizedString(@"Ishimura", @"")];
	[_statusbarItem setHighlightMode:YES];
	[_statusbarItem setTarget:self];
	[_statusbarItem setAction:@selector(statusbarItemAction)];
//	[_statusbarItem sendActionOn:NSRightMouseDownMask];
	[_statusbarItem setMenu:[_statusbarMenu mainMenu]];
}


- (IBAction)updateMenu:(id)sender {

}


- (void)delayAndUpdateMenu:(NSMenu *)menu {
	NSLog(@"delaying");
//	[[NSRunLoop currentRunLoop] performSelector:@selector(updateMenuFunc:) target:self argument:menu order:0 modes:[NSArray arrayWithObject:NSEventTrackingRunLoopMode]];

	[self performSelector:@selector(updateMenuFunc:) withObject:menu afterDelay:2.0 inModes:[NSArray arrayWithObject:NSRunLoopCommonModes]];
//	[self performSelector:@selector(updateMenuFunc:) withObject:menu afterDelay:2.0];
	

}


- (void)updateMenuFunc:(NSMenu *)menu {
	NSLog(@"inserting new menu item");
	NSLog(@"current run mode: %@", [[NSRunLoop currentRunLoop] currentMode]);
//	NSMenu *menu = [statusbarMenuController statusbarMenu];
	NSMenuItem *newItem = [[NSMenuItem alloc] initWithTitle:@"New Item" action:@selector(actionForMenuItem) keyEquivalent:@""];
	NSMenuItem *newItem2 = [[NSMenuItem alloc] initWithTitle:@"New Item 2" action:@selector(actionForItem2) keyEquivalent:@""];
	[menu insertItem:newItem atIndex:1];
	[menu insertItem:newItem2 atIndex:2];
	[newItem release];
	[newItem2 release];
	
	NSMenuItem *item = [menu itemAtIndex:0];
	[item setTitle:@"New Title"];
//	[menu update];
	
//	[self startRunLoop1:self];
	
//	[NSEvent addLocalMonitorForEventsMatchingMask:NSLeftMouseDownMask handler:^(NSEvent *theEvent) {
//		NSLog(@"local event monitor: %@", theEvent);
//		return theEvent;
//	}];
	
//	NSTimer *timer = [NSTimer timerWithTimeInterval:1.0 target:self selector:@selector(timerFire:) userInfo:nil repeats:YES];
//	[[NSRunLoop currentRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
}


- (void)timerFire:(NSTimer *)timer {
	NSLog(@"timer fire");
}

- (void)statusbarItemAction {
	NSLog(@"clicked statusbar item");
//	[statusbarItem popUpStatusItemMenu:[statusbarMenuController dummyMenu]];

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
		NSEvent *theEvent = [NSApp nextEventMatchingMask:NSMouseEnteredMask | NSLeftMouseDownMask | NSLeftMouseUpMask untilDate:[NSDate distantFuture] inMode:NSDefaultRunLoopMode dequeue:YES];
		
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