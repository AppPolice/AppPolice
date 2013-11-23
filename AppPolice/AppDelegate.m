//
//  AppDelegate.m
//  AppPolice
//
//  Created by Maksym on 5/19/13.
//  Copyright (c) 2013 Maksym Stefanchuk. All rights reserved.
//

#import "AppDelegate.h"
#import "StatusbarItemController.h"
#import "StatusbarMenuController.h"
#import <ChromeMenu/ChromeMenu.h>

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
	
	// Add status item with menu
	_statusbarMenuController = [[StatusbarMenuController alloc] init];
	CMMenu *mainMenu = [_statusbarMenuController mainMenu];
	[_statusbarItemController setStatusbarItemMenu:mainMenu];
	
	// Register default preferences
	NSString *defaultsPath = [[NSBundle mainBundle] pathForResource:@"UserDefaults" ofType:@"plist"];
	NSDictionary *defaults = [NSDictionary dictionaryWithContentsOfFile:defaultsPath];
	NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
	[preferences registerDefaults:defaults];
	
	// Set default task schedule interval
	unsigned int task_schedule_interval = (unsigned int)[preferences integerForKey:@"APProcCpulimTaskScheduleInterval"];
	(void) proc_cpulim_schedule_interval(task_schedule_interval, NULL);
}


- (void)applicationWillTerminate:(NSNotification *)notification {
	// We really want to stop limiter before application terminates,
	// or otherwise any limited processes will remain sleeping.
	proc_cpulim_suspend_wait();
}



@end
