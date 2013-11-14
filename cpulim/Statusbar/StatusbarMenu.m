//
//  StatusbarMenuController.m
//  Ishimura
//
//  Created by Maksym on 5/28/13.
//  Copyright (c) 2013 Maksym Stefanchuk. All rights reserved.
//

#import "StatusbarMenu.h"

#import "AppInspector.h"
#import "ChromeMenu.h"


@interface StatusbarMenu()
{
	CMMenu *menu;
	CMMenu *smallMenu;
}

- (IBAction)changeMenu:(id)sender;

@end


@implementation StatusbarMenu

@synthesize mainMenu = _mainMenu;

static NSString *tableData[] = {
    @"NSQuickLookTemplate",
    @"NSBluetoothTemplate",
    @"NSIChatTheaterTemplate",
    @"NSSlideshowTemplate",
    @"NSActionTemplate",
    @"NSSmartBadgeTemplate",
    @"NSIconViewTemplate",
    @"NSListViewTemplate",
    @"NSColumnViewTemplate",
    @"NSFlowViewTemplate",
    @"NSPathTemplate",
    @"NSInvalidDataFreestandingTemplate",
    @"NSLockLockedTemplate",
    @"NSLockUnlockedTemplate",
    @"NSGoRightTemplate",
    @"NSGoLeftTemplate",
    @"NSRightFacingTriangleTemplate",
    @"NSLeftFacingTriangleTemplate",
    @"NSAddTemplate",
    @"NSRemoveTemplate",
    @"NSRevealFreestandingTemplate",
    @"NSFollowLinkFreestandingTemplate",
    @"NSEnterFullScreenTemplate",
    @"NSExitFullScreenTemplate",
    @"NSStopProgressTemplate",
    @"NSStopProgressFreestandingTemplate",
    @"NSRefreshTemplate",
    @"NSRefreshFreestandingTemplate",
    @"NSBonjour",
    @"NSComputer",
    @"NSFolderBurnable",
    @"NSFolderSmart",
    @"NSFolder",
    @"NSNetwork",
    @"NSMobileMe",
    @"NSMultipleDocuments",
    @"NSUserAccounts",
    @"NSPreferencesGeneral",
    @"NSAdvanced",
    @"NSInfo",
    @"NSFontPanel",
    @"NSColorPanel",
    @"NSUser",
    @"NSUserGroup",
    @"NSEveryone",
    @"NSUserGuest",
    @"NSMenuOnStateTemplate",
    @"NSMenuMixedStateTemplate",
    @"NSApplicationIcon",
    @"NSTrashEmpty",
    @"NSTrashFull",
    @"NSHomeTemplate",
    @"NSBookmarksTemplate",
    @"NSCaution",
    @"NSStatusAvailable",
    @"NSStatusPartiallyAvailable",
    @"NSStatusUnavailable",
    @"NSStatusNone",
    nil };



- (void)dealloc {

	[super dealloc];
}





- (void)tempObserver:(NSNotification *)notification {
//	[self performSelector:@selector(log) withObject:nil afterDelay:0 inModes:[NSArray arrayWithObject:NSRunLoopCommonModes]];
	NSLog(@"----- observer notification, app resigned active status");
}

- (void)log {
	NSLog(@"lgogogogo");
}

- (void)appDidDeactiveteNote:(NSNotification *)note {
	NSLog(@"app did deactivate: %@", note);
	NSRunningApplication *app = [[note userInfo] objectForKey:NSWorkspaceApplicationKey];
	NSLog(@"noteapp: %@, our app:%@", app, [NSRunningApplication currentApplication]);
	if ([app isEqual:[NSRunningApplication currentApplication]]) {
		NSLog(@"we hid our app");
	}
}



- (void)addLocalMonitor {
	NSLog(@"installing local monitor");
	[NSEvent addLocalMonitorForEventsMatchingMask:NSLeftMouseDownMask handler:^(NSEvent *theEvent) {
		NSLog(@"left mouse down: %@", theEvent);
		
		//		theEvent = nil;
		return theEvent;
	}];
}






- (IBAction)addMenu:(id)sender {
//	NSMutableArray *items = [[NSMutableArray alloc] init];


//    @"NSSmartBadgeTemplate",
//    @"NSIconViewTemplate",

//	[items addObject:[NSDictionary dictionaryWithObjectsAndKeys:
//					  [NSImage imageNamed:@"NSIChatTheaterTemplate"], @"Icon",
//					  @"Chat Template", @"Text", nil]];
//	[items addObject:[NSDictionary dictionaryWithObjectsAndKeys:
//					  [NSImage imageNamed:@"NSSlideshowTemplate"], @"Icon",
//					  @"Slideshow Template", @"Text", nil]];
//	[items addObject:[NSDictionary dictionaryWithObjectsAndKeys:
//					  [NSImage imageNamed:@""], @"Icon",
//					  @"Without icon", @"Text", nil]];
//	[items addObject:[NSDictionary dictionaryWithObjectsAndKeys:
//					  [NSImage imageNamed:@"NSActionTemplate"], @"Icon",
//					  @"Action Template", @"Text", nil]];

	menu = [[CMMenu alloc] initWithTitle:@"Root menu"];
//	[menu setCancelsTrackingOnAction:NO];
	
//	CMMenuItem *item1 = [[CMMenuItem alloc] initWithTitle:@"Chat Template"];
//	[item1 setIcon:[NSImage imageNamed:@"NSIChatTheaterTemplate"]];
//	
//	CMMenuItem *item2 = [[CMMenuItem alloc] initWithTitle:@"Slideshow Template"];
//	[item2 setIcon:[NSImage imageNamed:@"NSSlideshowTemplate"]];
//	
//	CMMenuItem *item3 = [[CMMenuItem alloc] initWithTitle:@"Without icon"];
//
//	CMMenuItem *item4 = [[CMMenuItem alloc] initWithTitle:@"Actions Template"];
//	[item4 setIcon:[NSImage imageNamed:@"NSActionTemplate"]];
//	
//	
//	[menu addItem:item1];
//	[menu addItem:item2];
//	[menu addItem:item3];
//	[menu addItem:item4];
	
//	NSArray *viewProperties = [[NSArray alloc] initWithObjects:@"statusIcon", @"icon", @"title", nil];
//	[menu setDefaultViewForItemsFromNibNamed:@"MenuItemView" withIdentifier:@"CMTableCellViewIdOverride" andPropertyNames:viewProperties];

	
	int i = 0;
	NSString **data = &tableData[0];
	while (*data != nil) {
		NSString *name = *data;
		NSImage *image = [NSImage imageNamed:name];
//		NSString *statusImageName = [NSString stringWithString:(i % 2 == 0) ? @"NSStatusAvailable" : @"NSStatusUnavailable"];

		id item = nil;
		
		if (i == 2 || i == 12) {
			item = [CMMenuItem separatorItem];
			[menu addItem:item];
		}
//			++i;
//			continue;
//		} else {

		

//			if (i == 1 || i == 9) {
//				item = [[CMMenuItemOverride alloc] initWithTitle:name action:NULL];
////				[item setViewFromNibNamed:@"MenuItemView" withIdentifier:@"CMTableCellViewIdOverride" andPropertyNames:viewProperties];
//				[item setViewFromNibNamed:@"MenuItemView" andPropertyNames:viewProperties];
//				[item setStatusIcon:[NSImage imageNamed:statusImageName]];
//			} else {
				item = [[CMMenuItem alloc] initWithTitle:name action:NULL];
//			}
					
//			if (i > 3)
				[item setIcon:image];
			
			if (i == 10) {
				NSImage *image = [NSImage imageNamed:NSImageNameStatusNone];
				[image setSize:NSMakeSize(12, 12)];
				[item setMixedStateImage:image];
				[item setState:NSMixedState];
			}
			if (i == 8) {
				NSImage *image = [NSImage imageNamed:NSImageNameStatusAvailable];
				[image setSize:NSMakeSize(12, 12)];
				[item setOnStateImage:image];
				[item setState:NSOnState];
			}
			
	//		[item setIcon:image];

//		}
		
		[menu addItem:item];
		[item release];
		
		++data;
		++i;
	}
	
//	[viewProperties release];
	

	CMMenu *submenu = [[CMMenu alloc] initWithTitle:@"Submenu 1"];
	[submenu setCancelsTrackingOnAction:NO];
	[submenu setCancelsTrackingOnMouseEventOutsideMenus:NO];
	CMMenuItem *submenuItem1 = [[CMMenuItem alloc] initWithTitle:@"ViewTemplate" action:NULL];
	[submenuItem1 setTarget:self];
	[submenu addItem:submenuItem1];
	[submenuItem1 release];
	CMMenuItem *submenuItem2 = [[CMMenuItem alloc] initWithTitle:@"Item" action:NULL];
	[submenuItem2 setTarget:self];
	[submenu addItem:submenuItem2];
	[submenuItem2 release];
	
	[menu setSubmenu:submenu forItem:[menu itemAtIndex:7]];
	[submenu release];
	
	
	submenu = [[CMMenu alloc] initWithTitle:@"Submenu 2"];
	[submenu setBorderRadius:0.0];
	submenuItem1 = [[CMMenuItem alloc] initWithTitle:@"one" action:NULL];
	[submenu addItem:submenuItem1];
	[submenuItem1 release];
	submenuItem2 = [[CMMenuItem alloc] initWithTitle:@"Item" action:NULL];
	[submenu addItem:submenuItem2];
	[submenuItem2 release];
	
	[menu setSubmenu:submenu forItem:[menu itemAtIndex:6]];
	[submenu release];
	
	
	CMMenu *submenuOfSubmenu = [[CMMenu alloc] initWithTitle:@"Submenu of submenu"];
	submenuItem1 = [[CMMenuItem alloc] initWithTitle:@"one" action:NULL];
	[submenuOfSubmenu addItem:submenuItem1];
	[submenuItem1 release];
	submenuItem2 = [[CMMenuItem alloc] initWithTitle:@"two" action:NULL];
	CMMenuItem *item3 = [[CMMenuItem alloc] initWithTitle:@"three" action:NULL];
	[submenuOfSubmenu addItem:item3];
	[item3 release];
	[submenuOfSubmenu addItem:submenuItem2];
	[submenuItem2 release];
	
	[submenu setSubmenu:submenuOfSubmenu forItem:[submenu itemAtIndex:1]];
	[submenuOfSubmenu release];


	
	
	submenu = [[CMMenu alloc] initWithTitle:@"Submenu 3"];
	submenuItem1 = [[CMMenuItem alloc] initWithTitle:@"three" action:NULL];
	[submenu addItem:submenuItem1];
	[submenuItem1 release];
	submenuItem2 = [[CMMenuItem alloc] initWithTitle:@"four" action:NULL];
	[submenu addItem:submenuItem2];
	[submenuItem2 release];
	
	CMMenuItem *submenuItem3 = [[CMMenuItem alloc] initWithTitle:@"five" action:NULL];
	[submenu addItem:submenuItem3];
	[submenuItem3 release];

	CMMenuItem *submenuItem4 = [[CMMenuItem alloc] initWithTitle:@"six, little bit longer" action:NULL];
	[submenu addItem:submenuItem4];
	[submenuItem4 release];

	CMMenuItem *submenuItem5 = [[CMMenuItem alloc] initWithTitle:@"seven" action:NULL];
	[submenu addItem:submenuItem5];
	[submenuItem5 release];
	
	
	i = 0;
	int lim = 14;
	for (i = 0; i < lim; ++i) {
		CMMenuItem *submenuItemA = [[CMMenuItem alloc] initWithTitle:@"Automatically generated" action:NULL];
		[submenu addItem:submenuItemA];
		[submenuItemA release];
	}

	
	[menu setSubmenu:submenu forItem:[menu itemAtIndex:22]];
	[submenu release];
	

//	[menu update];
	
//	NSLog(@"Should create menu with items: %@", items);
//	NSLog(@"menu: %@", menu);
//	[items release];
}


- (IBAction)changeMenu:(id)sender {
//	NSInteger index = 4;
//	static int i = 0;
//	NSString *statuses[] = {
//		@"NSStatusAvailable",
//		@"NSStatusUnavailable",
//		@"NSStatusPartiallyAvailable",
//		@"NSStatusNone"
//	};
//	
//	CMMenuItemOverride *item = [menu itemAtIndex:index];
//	[item setStatusIcon:[NSImage imageNamed:statuses[i % 4]]];
//	++i;
//	[menu updateItemsAtIndexes:[NSIndexSet indexSetWithIndex:index]];
//	NSLog(@"Item change: %@", item);
	
	static int i = 0;
	if ((i % 2) == 0)
		[menu popUpMenuPositioningItem:nil atLocation:NSMakePoint(200, 5) inView:nil];
	else
		[menu cancelTrackingWithoutAnimation];
	
	++i;
}


- (IBAction)addSmallMenu:(id)sender {
	smallMenu = [[CMMenu alloc] initWithTitle:@"Small menu"];
	
	int i;
	int count = 4;
	
	for (i = 0; i < count; ++i) {
		CMMenuItem *item  = [[CMMenuItem alloc] initWithTitle:[NSString stringWithFormat:@"Menu Item %d", (i + 1)] action:NULL];
//		CMMenuItem *item  = [[CMMenuItem alloc] initWithTitle:@"Some title"];
		[smallMenu addItem:item];
		[item release];
	}
	
}

- (IBAction)toggleSmallMenu:(id)sender {
	static int i = 0;
	if ((i % 2) == 0)
		[smallMenu popUpMenuPositioningItem:nil atLocation:NSMakePoint(200, 200) inView:nil];
	else
		[smallMenu cancelTrackingWithoutAnimation];
	
	++i;
}


- (void)someActionForOurCustomMenu:(id)sender {
	CMMenuItem *item = (CMMenuItem *)sender;
	NSLog(@"custom menu action, sender: %@", item);
	
}


- (IBAction)showmenu:(id)sender {
	NSLog(@"BBBBB");
//	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notificationDeliver:) name:NSMenuDidEndTrackingNotification object:nil];
	[_mainMenu popUpMenuPositioningItem:nil atLocation:NSMakePoint(1920, 0) inView:nil];
//	[statusbarMenu popUpMenuPositioningItem:nil atLocation:NSMakePoint(200, 200) inView:nil];
}

- (IBAction)showPopoverForButton:(id)sender {


}




@end
