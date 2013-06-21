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


#import "TestView1.h"
#import "TestTableRowView.h"

@implementation AppDelegate

- (void)dealloc {
	[statusbarItem release];
    [super dealloc];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
#ifdef SELF_PROFILE
	/* print stats right after App launch: resources used by OS X to launch the App */
	profiling_print_stats();
#endif

	[statusbarMenuController populateMenuWithRunningApps];
	
	[_tableView reloadData];
}

- (void)applicationWillFinishLaunching:(NSNotification *)notification {
	[self activateStatusbarItem];
}

//- (void)awakeFromNib {
//		[statusbarMenuController populateMenuWithRunningApps];
//}

//- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {
//	
//	return NSTerminateNow;
//}

extern void proc_cpulim_suspend_wait(void);		/* function returns only after limiter stoped */

- (void)applicationWillTerminate:(NSNotification *)notification {
	proc_cpulim_suspend_wait();
}


- (void)activateStatusbarItem {
	NSStatusBar *statusbar = [NSStatusBar systemStatusBar];
	statusbarItem = [statusbar statusItemWithLength: NSVariableStatusItemLength];
	[statusbarItem retain];
	[statusbarItem setTitle: NSLocalizedString(@"Ishimura", @"")];
	[statusbarItem setHighlightMode: YES];
	[statusbarItem setMenu: [statusbarMenuController statusbarMenu]];
}






- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
	return 10;
}


- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
	
	NSString *tableId = [tableView identifier];
	if ([tableId isEqualToString:@"SecondTableView"]) {
		
		NSString *columnId = [tableColumn identifier];
		if ([columnId isEqualToString:@"MainCell"]) {
			NSTableCellView *cellView;
			cellView = [tableView makeViewWithIdentifier:@"MainCell" owner:self];
			[[cellView textField] setStringValue:@"one"];
			return cellView;
		} else {
			NSTableCellView *cellView;
			cellView = [tableView makeViewWithIdentifier:@"SecondaryCell" owner:self];
			[[cellView textField] setStringValue:@"two"];
			return cellView;
		}
	} else {
		
		
		NSTableCellView *cellView;
		//	NSString *identifier = [tableColumn identifier];
		//	if ([identifier isEqualToString:@"Main"]) {
		cellView = [tableView makeViewWithIdentifier:@"AppCellView2" owner:self];
		[[cellView textField] setStringValue:@"one"];
		//	} else if ([identifier isEqualToString:@"Sec"]) {
		//		 cellView = [tableView makeViewWithIdentifier:@"AppCellView" owner:self];
		//		 [[cellView textField] setStringValue:@"two"];
		//	}
		
		return cellView;
		
	}
}


- (IBAction)someAction4:(NSButton *)sender {
	//	[statusbarMenu itemAtIndex:0]
	NSLog(@"AAAAA");
	NSButton *button = (NSButton *)sender;
	[[button superview] becomeFirstResponder];
	
	int i;
	for (i = 0; i < [[NSApp windows] count]; ++i) {
//		[[[NSApp windows] objectAtIndex:i] becomeKeyWindow];
//		[[[NSApp windows] objectAtIndex:i] becomeFirstResponder];
//		[[[NSApp windows] objectAtIndex:i] becomeMainWindow];
	}
	
	[[[NSApp windows] objectAtIndex:2] becomeKeyWindow];
	[[[NSApp windows] objectAtIndex:0] becomeKeyWindow];
	
	[_tableView becomeFirstResponder];
	[_testView1 setNextKeyView:_tableView];
	
	
	//	NSLog(@"%@", [secondSubmenuView trackingAreas]);
	
//	[statusbarMenu performActionForItemAtIndex:0];
	
	//	[appsSubmenu cancelTrackingWithoutAnimation];
	//	[appsSubmenu cancelTracking];
	//	[appsSubmenu popUpMenuPositioningItem:[appsSubmenu itemAtIndex:0] atLocation:NSMakePoint(200, 200) inView:nil];
	
	//	[[statusbarMenu itemAtIndex:0] action]
}


- (NSTableRowView *)tableView:(NSTableView *)tableView rowViewForRow:(NSInteger)row {
//	NSLog(@"hahahah");
	TestTableRowView *tableRow = [tableView makeViewWithIdentifier:@"TestTableRowViewId" owner:self];
	return tableRow;
}


@end
