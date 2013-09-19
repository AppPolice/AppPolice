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

- (void)statusbarItemAction {
	NSLog(@"clicked statusbar item");
//	[statusbarItem popUpStatusItemMenu:[statusbarMenuController dummyMenu]];

}

@end