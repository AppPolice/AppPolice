//
//  StatusbarMenuController.m
//  Ishimura
//
//  Created by Maksym on 10/11/13.
//  Copyright (c) 2013 Maksym Stefanchuk. All rights reserved.
//

#import "StatusbarMenuController.h"
#import "ChromeMenu.h"
#import "AppInspector.h"

//NSString *const APApplicationsSortedByName = @"APApplicationsSortedByName";
//NSString *const APApplicationsSortedByPid = @"APApplicationsSortedByPid";


@interface StatusbarMenuController ()

- (void)setupMenus;
- (void)populateMenuWithRunningApplications:(CMMenu *)menu;
- (void)appLaunchedNotificationHandler:(NSNotification *)notification;
- (void)appTerminatedNotificationHandler:(NSNotification *)notification;

@end



@implementation StatusbarMenuController

- (id)init {
	self = [super init];
	if (self) {
		[self setupMenus];
	}
	return self;
}


- (void)dealloc {
	[_mainMenu release];
	[_appInspector release];
	[super dealloc];
}


/*
 *
 */
- (void)setupMenus {
	_mainMenu = [[CMMenu alloc] initWithTitle:@"MainMenu"];
	CMMenuItem *item;
	item = [[[CMMenuItem alloc] initWithTitle:@"Running Apps" action:NULL] autorelease];
	CMMenu *runningAppsMenu = [[[CMMenu alloc] initWithTitle:@"Running Apps Menu"] autorelease];
	[runningAppsMenu setCancelsTrackingOnAction:NO];
//	[runningAppsMenu setCancelsTrackingOnMouseEventOutsideMenus:NO];
	[item setSubmenu:runningAppsMenu];
	[_mainMenu addItem:item];
	
	item = [[[CMMenuItem alloc] initWithTitle:@"Pause" action:NULL] autorelease];
	[item setEnabled:NO];
	[_mainMenu addItem:item];
	
	[_mainMenu addItem:[CMMenuItem separatorItem]];
	
	item = [[[CMMenuItem alloc] initWithTitle:@"Donate" action:NULL] autorelease];
	[_mainMenu addItem:item];
	item = [[[CMMenuItem alloc] initWithTitle:@"About" action:NULL] autorelease];
	[_mainMenu addItem:item];

	[_mainMenu addItem:[CMMenuItem separatorItem]];
	
	item = [[[CMMenuItem alloc] initWithTitle:@"Preferences" action:NULL] autorelease];
	[_mainMenu addItem:item];
	item = [[[CMMenuItem alloc] initWithTitle:@"Quit" action:@selector(terminateApplicationMenuAction:)] autorelease];
	[item setTarget:self];
	[_mainMenu addItem:item];
	
	[self populateMenuWithRunningApplications:[[_mainMenu itemAtIndex:0] submenu]];
}


/*
 *
 */
- (void)populateMenuWithRunningApplications:(CMMenu *)menu {
	if (! menu)
		return;
	
	if (_runningApps) {
		[_runningApps removeAllObjects];
		[_runningApps release];
	}
	
	NSWorkspace *workspace = [NSWorkspace sharedWorkspace];
	_runningApps = [[workspace runningApplications] mutableCopy];
	[self sortApplicationsByKey:[self applicationSortKey]];
//	[self sortApplicationsByKey:APApplicationsSortedByPid];
	

	NSUInteger i;
	NSUInteger elementsCount = [_runningApps count];
	pid_t shared_pid = getpid();
	NSUInteger shared_pid_index;
	CMMenuItem *item;
	
	for (i = 0; i < elementsCount; ++i) {
		NSRunningApplication *app = [_runningApps objectAtIndex:i];
		if (shared_pid == [app processIdentifier]) {
			shared_pid_index = i;
			continue;
		}
		
		NSMutableDictionary *appInfo = [NSMutableDictionary dictionaryWithObjectsAndKeys:
								 [app localizedName], APApplicationInfoNameKey,
								 [app icon], APApplicationInfoIconKey,
								 [NSNumber numberWithInt:[app processIdentifier]], APApplicationInfoPidKey,
								 [NSNumber numberWithFloat:0], APApplicationInfoLimitKey, nil];
		
		item = [[[CMMenuItem alloc] initWithTitle:[app localizedName] icon:[app icon] action:@selector(selectApplicationItemMenuAction:)] autorelease];
		[item setTarget:self];
		NSImage *onStateImage = [NSImage imageNamed:NSImageNameStatusAvailable];
		[onStateImage setSize:NSMakeSize(12, 12)];
		[item setOnStateImage:onStateImage];
//		NSImage *mixedStateImage = [NSImage imageNamed:NSImageNameStatusNone];
//		[mixedStateImage setSize:NSMakeSize(12, 12)];
//		[item setMixedStateImage:mixedStateImage];
		[item setRepresentedObject:appInfo];
		[menu addItem:item];
	}
	
	// Remove ourselves from running applications array
	[_runningApps removeObjectAtIndex:shared_pid_index];
	
	
	// temp
	NSMutableDictionary *appInfo = [NSMutableDictionary dictionaryWithObjectsAndKeys:
									@"Some really long name for some unexistant applicaton", APApplicationInfoNameKey,
									[NSImage imageNamed:NSImageNameBonjour], APApplicationInfoIconKey,
									[NSNumber numberWithInt:999], APApplicationInfoPidKey,
									[NSNumber numberWithFloat:0], APApplicationInfoLimitKey, nil];
	
	item = [[[CMMenuItem alloc] initWithTitle:@"Some really long name for some unexistant applicaton" icon:[NSImage imageNamed:NSImageNameBonjour] action:@selector(selectApplicationItemMenuAction:)] autorelease];
	[item setTarget:self];
	[item setRepresentedObject:appInfo];
	[menu addItem:item];
	// temp
	

	NSNotificationCenter *notificationCenter = [workspace notificationCenter];
	[notificationCenter addObserver:self selector:@selector(appLaunchedNotificationHandler:) name:NSWorkspaceDidLaunchApplicationNotification object:nil];
	[notificationCenter addObserver:self selector:@selector(appTerminatedNotificationHandler:) name:NSWorkspaceDidTerminateApplicationNotification object:nil];
}


/*
 *
 */
- (void)sortApplicationsByKey:(int)sortKey {
	NSSortDescriptor *descriptor;

	if (! [_runningApps count])
		return;
	
	if (sortKey == APApplicationsSortedByName) {
		descriptor = [[NSSortDescriptor alloc] initWithKey:@"localizedName" ascending:YES selector:@selector(localizedCompare:)];
	} else if (sortKey == APApplicationsSortedByPid) {
		descriptor = [[NSSortDescriptor alloc] initWithKey:@"processIdentifier" ascending:YES];
	} else {
		NSLog(@"Provided sort key is not valid");
		return;
	}
	
	[_runningApps sortUsingDescriptors:[NSArray arrayWithObject:descriptor]];
	[descriptor release];
}


/*
 *
 */
- (void)appLaunchedNotificationHandler:(NSNotification *)notification {
//	NSLog(@"launched %@ BEGIN", [[notification userInfo] objectForKey:@"NSApplicationName"]);
	NSRunningApplication *app = [[notification userInfo] objectForKey:NSWorkspaceApplicationKey];
//	NSLog(@"launched %@\n", app);
	//	NSLog(@"App object: %@", app);
	
	NSUInteger elementsCount = [_runningApps count];
	NSUInteger index = elementsCount;
	
	/*----------------------------------------------------------------------------------------------------/
	  ASSUMTION!
		-appLaunchedNotificationHandler: and -appTerminatedNotificationHandler: are not re-entrant safe.
		These methods manage shared resource (NSArray *)_runningApps.
		We assume that these notifications are queued and will be executed in certain order and 
		will not be interrupted by similar notifications.
	 /----------------------------------------------------------------------------------------------------*/
	
	int sortKey = [self applicationSortKey];
	if (sortKey == APApplicationsSortedByName) {
		NSString *appName = [app localizedName];
		NSUInteger i = 0;
		while (i < elementsCount && [appName localizedCompare:[[_runningApps objectAtIndex:i] localizedName]] == NSOrderedDescending)
			++i;

		//		while (i < elementsCount) {
		//			NSString *name = [[_runningApps objectAtIndex:i] localizedName];
		//			NSComparisonResult result = [appName localizedCompare:name];
		//			if (result == NSOrderedAscending) {
		//				break;
		//			}

		
		index = i;

	} else if (sortKey == APApplicationsSortedByPid) {
		// New apps most likely will have pid greater then the pid of last app in array
//		index = elementsCount;
	}
	
//	NSLog(@"inserting at index: %lu", index);
	
	[_runningApps insertObject:app atIndex:index];
	
	NSMutableDictionary *appInfo = [NSMutableDictionary dictionaryWithObjectsAndKeys:
									[app localizedName], APApplicationInfoNameKey,
									[app icon], APApplicationInfoIconKey,
									[NSNumber numberWithInt:[app processIdentifier]], APApplicationInfoPidKey,
									[NSNumber numberWithFloat:0], APApplicationInfoLimitKey, nil];
	
	CMMenuItem *item = [[[CMMenuItem alloc] initWithTitle:[app localizedName] icon:[app icon] action:@selector(selectApplicationItemMenuAction:)] autorelease];
	[item setTarget:self];
	NSImage *onStateImage = [NSImage imageNamed:NSImageNameStatusAvailable];
	[onStateImage setSize:NSMakeSize(12, 12)];
	[item setOnStateImage:onStateImage];
	[item setRepresentedObject:appInfo];
	[[[_mainMenu itemAtIndex:0] submenu] insertItem:item atIndex:index animate:NO];
	
//	NSLog(@"launched %@ END", [[notification userInfo] objectForKey:@"NSApplicationName"]);
}


/*
 *
 */
- (void)appTerminatedNotificationHandler:(NSNotification *)notification {
//	NSLog(@"terminated %@\n", [[notification userInfo] objectForKey:@"NSApplicationName"]);
	NSRunningApplication *app = [[notification userInfo] objectForKey:NSWorkspaceApplicationKey];
//	NSLog(@"terminated %@\n", app);
//	NSUInteger index = [_runningApps indexOfObject:app];
//	NSUInteger index;
	
//	NSLog(@"running apps: %@", _runningApps);

	for (NSRunningApplication *runningApp in _runningApps) {
		if ([app isEqual:runningApp]) {
			NSUInteger index = [_runningApps indexOfObject:runningApp];
			[_runningApps removeObjectAtIndex:index];

			CMMenu *menu = [[_mainMenu itemAtIndex:0] submenu];
			AppInspector *appInspector = [self appInspector];
			NSPopover *popover = [appInspector popover];
			if ([popover isShown]) {
				CMMenuItem *attachedToItem = [appInspector attachedToItem];
				CMMenuItem *item = [menu itemAtIndex:(NSInteger)index];
				if (attachedToItem == item) {
					[popover setAnimates:YES];
					[popover close];
				}
			}
			[menu removeItemAtIndex:(NSInteger)index animate:NO];

			return;
		}
	}
}


/*
 *
 */
- (void)selectApplicationItemMenuAction:(id)sender {
	CMMenuItem *item = (CMMenuItem *)sender;
	AppInspector *appInspector = [self appInspector];
//	NSDictionary *inspectorAppInfo = [appInspector applicationInfo];
	NSPopover *popover = [appInspector popover];

//	if (_itemWithAttachedPopover && [_itemWithAttachedPopover isEqual:item] && [popover isShown]) {
	if ([popover isShown]) {
		CMMenuItem *attachedToItem = [appInspector attachedToItem];
		if ([attachedToItem state] == NSMixedState)
			[attachedToItem setState:NSOffState];

		if (attachedToItem == item) {
			[popover setAnimates:YES];
			[popover close];
			[[item menu] setSuspendMenus:NO];
			[[item menu] setCancelsTrackingOnMouseEventOutsideMenus:YES];
			[appInspector setAttachedToItem:nil];
			
//			[item setEnabled:YES];
		} else {
//			NSDictionary *appInfo = [attachedToItem representedObject];
//			NSNumber *limitNumber = [appInfo objectForKey:APApplicationInfoLimitKey];
//			if ([limitNumber floatValue] == 0)
//				[attachedToItem setState:NSOffState];
//			if ([attachedToItem state] == NSMixedState)
//				[attachedToItem setState:NSOffState];
			[appInspector setAttachedToItem:item];
			[[item menu] showPopover:popover forItem:item];
			if ([item state] == NSOffState)
				[item setState:NSMixedState];
		}
	} else {
//		NSMutableDictionary *appInfo = [item representedObject];
//		[appInspector setApplicationInfo:appInfo];
		[appInspector setAttachedToItem:item];
		[[item menu] setSuspendMenus:YES];
		[[item menu] setCancelsTrackingOnMouseEventOutsideMenus:NO];
		[[item menu] showPopover:popover forItem:item];
		if ([item state] == NSOffState)
			[item setState:NSMixedState];

//		[item setEnabled:NO];
//		_itemWithAttachedPopover = item;
	}
}


/*
 *
 */
- (void)terminateApplicationMenuAction:(id)sender {
	[NSApp terminate:self];
}


/*
 * Cold load of Applicatoins Inspector
 */
- (AppInspector *)appInspector {
	if (_appInspector == nil) {
		_appInspector = [[AppInspector alloc] init];
	}
	return _appInspector;
}


- (CMMenu *)mainMenu {
	return _mainMenu;
}


- (int)applicationSortKey {
	return (_applicationSortKey) ? _applicationSortKey : APApplicationsSortedByName;
}


- (void)setApplicationSortKey:(int)sortKey {
	if ( sortKey !=APApplicationsSortedByName
	  && sortKey != APApplicationsSortedByPid) {
		NSLog(@"Provided sortKey does not exist");
		return;
	}
	
	if (_applicationSortKey != sortKey) {
		_applicationSortKey = sortKey;

		// update menu here
		
	}
}

@end
