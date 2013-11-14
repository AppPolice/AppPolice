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
//	NSString *imagePath = [[NSBundle mainBundle] pathForResource:@"statusbar_image" ofType:@"tiff"];
	NSString *imagePath = [[NSBundle mainBundle] pathForResource:@"status_icon" ofType:@"tiff"];
	NSImage *ico = [[[NSImage alloc] initWithContentsOfFile:imagePath] autorelease];
	imagePath = [[NSBundle mainBundle] pathForResource:@"status_icon_inv" ofType:@"tiff"];
	NSImage *ico_alt = [[[NSImage alloc] initWithContentsOfFile:imagePath] autorelease];
	[_statusbarItemController setImage:ico];
	[_statusbarItemController setAlternateImage:ico_alt];
//	[_statusbarItemController addItemToStatusbar];
	
//	[self activateStatusbarItem];
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
	

//	[NSApp activateIgnoringOtherApps:YES];
//	[[self window] makeKeyAndOrderFront:self];
	
//	_statusbarMenu = [[StatusbarMenu alloc] init];
//	NSLog(@"menu:%@", [_statusbarMenu mainMenu]);
//	[_statusbarMenu linkStatusbarItemWithMenu];
	
//	NSLog(@"!!!!!starting delay for menu update");
//	[self performSelector:@selector(updateMenu:) withObject:nil afterDelay:4.0];
//	[[NSRunLoop currentRunLoop] performSelector:@selector(delayAndUpdateMenu:) target:self argument:[statusbarMenuController statusbarMenu] order:0 modes:[NSArray arrayWithObject:NSEventTrackingRunLoopMode]];
	
//	NSLog(@"current run mode: %@", [[NSRunLoop currentRunLoop] currentMode]);
//	[self performSelector:@selector(updateMenuFunc:) withObject:[_statusbarMenu mainMenu] afterDelay:2.0 inModes:[NSArray arrayWithObject:NSRunLoopCommonModes]];
//	[self performSelector:@selector(updateMenuFunc:) withObject:[statusbarMenuController statusbarMenu] afterDelay:4.0];

}

- (void)awakeFromNib {
	NSLog(@"%@ awakeFromNib", [self className]);
	
	NSLog(@"orientation: %lu", [NSApp userInterfaceLayoutDirection]);

//	NSMutableArray *array = [[NSMutableArray alloc] initWithObjects:@3, @4, @7, @8, nil];
//	NSLog(@"inex: %lu", [array indexOfObject:@7]);
//	NSMutableIndexSet *indexes = [NSMutableIndexSet indexSet];
//	[indexes addIndex:1];
//	[indexes addIndex:3];
//	[array removeObjectsAtIndexes:indexes];
//	NSLog(@"array: %@", array);
	
// ---------------
//	NSMutableIndexSet *indexSet = [NSMutableIndexSet indexSet];
//	[indexSet addIndex:3];
//	[indexSet addIndex:4];
//	[indexSet addIndex:7];
//	
//	[indexSet enumerateIndexesUsingBlock:^(NSUInteger index, BOOL *stop) {
//		index += 1;
//	}];
//	NSLog(@"final index set: %@", indexSet);
// ----------------
//	int a = 1;
//	int mask = 1 << (8 * sizeof(int) - 1);
//	a |= mask;
//	a &= ~mask;
	
	
//	uint64_t a = 10;
//	uint64_t b = 5;
//	int64_t c = (int64_t)(b - a);
////	uint64_t b = (uint64_t)a;
//	printf("c = %lld", c);
	
//	NSDictionary *dic = [NSDictionary dictionaryWithObjectsAndKeys:@"some obj", @"some key", nil];
//	NSLog(@"print dic: %@", dic);
	
//	uint64_t orignal = 10;
//	uint64_t mask = 1ULL << 47;
//	orignal &= ~mask;
//	printf("orignal: %llu", orignal);	
}

//- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {
//	
//	return NSTerminateNow;
//}

//extern void proc_cpulim_suspend_wait(void);		/* function returns only after limiter stopped */

- (void)applicationWillTerminate:(NSNotification *)notification {
	// We really want to stop limiter before application terminates, or otherwise any limited processes will remain sleeping.
	proc_cpulim_suspend_wait();
}


- (IBAction)toggleMainMenu:(id)sender {
	[[_statusbarMenuController mainMenu] popUpMenuPositioningItem:nil atLocation:NSMakePoint(200, 800) inView:nil];
}


- (void)activateStatusbarItem {
	NSStatusBar *statusbar = [NSStatusBar systemStatusBar];
	_statusbarItem = [statusbar statusItemWithLength:NSVariableStatusItemLength];
	[_statusbarItem retain];
//	[_statusbarItem setView:[statusbarMenuController statusbarItemView]];
	
	NSString *imagePath = [[NSBundle mainBundle] pathForResource:@"statusbar_image" ofType:@"tiff"];
	NSImage *ico = [[[NSImage alloc] initWithContentsOfFile:imagePath] autorelease];
	imagePath = [[NSBundle mainBundle] pathForResource:@"statusbar_image_inv" ofType:@"tiff"];
	NSImage *ico_alt = [[[NSImage alloc] initWithContentsOfFile:imagePath] autorelease];

//	[_statusbarItem setTitle:NSLocalizedString(@"Ishimura", @"")];
	[_statusbarItem setImage:ico];
	[_statusbarItem setAlternateImage:ico_alt];
	[_statusbarItem setHighlightMode:YES];
	[_statusbarItem setTarget:self];
	[_statusbarItem setAction:@selector(statusbarItemAction:)];
	[_statusbarItem sendActionOn:NSLeftMouseDownMask | NSRightMouseDownMask];
//	[_statusbarItem setMenu:[_statusbarMenu mainMenu]];
	
//	NSView *view = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 21, 21)];
//	[_statusbarItem setView:view];
//	[view lockFocusIfCanDraw];
//	[[NSColor redColor] set];
//	NSFrameRect([view frame]);
//	[view unlockFocus];
}


- (void)statusbarItemAction:(id)sender {
	NSLog(@"clicked statusbar item: %@", sender);
	//	[statusbarItem popUpStatusItemMenu:[statusbarMenuController dummyMenu]];
	
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
	NSMenuItem *newItem2 = [[NSMenuItem alloc] initWithTitle:@"New Item 2" action:NULL keyEquivalent:@""];
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


- (IBAction)donateMenuAction2:(id)sender {
	NSLog(@"donate click: %@", sender);
	[self performSelector:@selector(donateMenuActionHelper:) withObject:(NSMenuItem *)sender afterDelay:0.0 inModes:[NSArray arrayWithObject:NSRunLoopCommonModes]];
}


- (void)donateMenuActionHelper:(NSMenuItem *)item {
	static int i = 0;
	NSLog(@"donate helper");
//	NSMenuItem *item = (NSMenuItem *)sender;
	if ((i % 2) == 0) {
		[item setTitle:@"New title for Donate"];
		[item setState:NSMixedState];
	} else {
		[item setTitle:@"Donate"];
		[item setState:NSOnState];
	}
	++i;
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
