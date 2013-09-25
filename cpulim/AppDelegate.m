//
//  AppDelegate.m
//  cpulim
//
//  Created by Maksym on 5/19/13.
//  Copyright (c) 2013 Maksym Stefanchuk. All rights reserved.
//

#import "AppDelegate.h"
#import "StatusbarMenuController.h"
#include "C/def.h"

#ifdef SELF_PROFILE
#include "C/selfprofile.h"
#endif

@implementation AppDelegate

- (void)dealloc {
	[statusbarItem release];
    [super dealloc];
}


- (void)applicationWillFinishLaunching:(NSNotification *)notification {
	[self activateStatusbarItem];
}


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
#ifdef SELF_PROFILE
	/* print stats right after App launch: resources used by OS X to launch the App */
	profiling_print_stats();
#endif


	[statusbarMenuController linkStatusbarItemWithMenu];
	
//	NSLog(@"!!!!!starting delay for menu update");
//	[self performSelector:@selector(updateMenu:) withObject:nil afterDelay:4.0];
//	[[NSRunLoop currentRunLoop] performSelector:@selector(delayAndUpdateMenu:) target:self argument:[statusbarMenuController statusbarMenu] order:0 modes:[NSArray arrayWithObject:NSEventTrackingRunLoopMode]];
	
//	NSLog(@"current run mode: %@", [[NSRunLoop currentRunLoop] currentMode]);
//	[self performSelector:@selector(updateMenuFunc:) withObject:[statusbarMenuController statusbarMenu] afterDelay:4.0 inModes:[NSArray arrayWithObject:NSRunLoopCommonModes]];
//	[self performSelector:@selector(updateMenuFunc:) withObject:[statusbarMenuController statusbarMenu] afterDelay:4.0];

}

- (void)awakeFromNib {
	NSLog(@"%@ awakeFromNib", [self className]);
}

//- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {
//	
//	return NSTerminateNow;
//}

extern void proc_cpulim_suspend_wait(void);		/* function returns only after limiter stopped */

- (void)applicationWillTerminate:(NSNotification *)notification {
	proc_cpulim_suspend_wait();
}


- (void)activateStatusbarItem {
	NSStatusBar *statusbar = [NSStatusBar systemStatusBar];
	statusbarItem = [statusbar statusItemWithLength:NSVariableStatusItemLength];
	[statusbarItem retain];
//	[statusbarItem setView:[statusbarMenuController statusbarItemView]];
	[statusbarItem setTitle: NSLocalizedString(@"Ishimura", @"")];
	[statusbarItem setHighlightMode: YES];
	[statusbarItem setTarget:self];
	[statusbarItem setAction:@selector(statusbarItemAction)];
//	[statusbarItem sendActionOn:NSRightMouseDownMask];
	[statusbarItem setMenu: [statusbarMenuController statusbarMenu]];
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
	NSMenuItem *newItem = [[NSMenuItem alloc] initWithTitle:@"New Item" action:NULL keyEquivalent:@""];
	[menu insertItem:newItem atIndex:1];
	[menu update];
}

- (void)statusbarItemAction {
	NSLog(@"clicked statusbar item");
//	[statusbarItem popUpStatusItemMenu:[statusbarMenuController dummyMenu]];

}


- (IBAction)someAction:(id)sender {
//	[self performSelector:@selector(delayedNSlog) withObject:nil afterDelay:5.0 inModes:[NSArray arrayWithObject:NSRunLoopCommonModes]];
	[self performSelector:@selector(delayedNSlog) withObject:nil afterDelay:10.0];
}

- (void)delayedNSlog {
	NSLog(@"\n\n\n!!!!!!!!!!!!!!!!!!!!!!! delayed nslog button click!!\n\n");
}


@end