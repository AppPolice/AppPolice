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

NSString *const APApplicationsSortedByName = @"APApplicationsSortedByName";
NSString *const APApplicationsSortedByPid = @"APApplicationsSortedByPid";


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
	
	// remove ourselves from applications list
	NSInteger i;
	NSInteger elementsCount = [_runningApps count];
	pid_t shared_pid = getpid();
	CMMenuItem *item;
	
	for (i = 0; i < elementsCount; ++i) {
		NSRunningApplication *app = [_runningApps objectAtIndex:i];
		if (shared_pid == [app processIdentifier]) {
			[_runningApps removeObjectAtIndex:i];
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
	
	NSMutableDictionary *appInfo = [NSMutableDictionary dictionaryWithObjectsAndKeys:
									@"Some really long name for some unexistant applicaton", APApplicationInfoNameKey,
									[NSImage imageNamed:NSImageNameBonjour], APApplicationInfoIconKey,
									[NSNumber numberWithInt:999], APApplicationInfoPidKey,
									[NSNumber numberWithFloat:0], APApplicationInfoLimitKey, nil];
	
	item = [[[CMMenuItem alloc] initWithTitle:@"Some really long name for some unexistant applicaton" icon:[NSImage imageNamed:NSImageNameBonjour] action:@selector(selectApplicationItemMenuAction:)] autorelease];
	[item setTarget:self];
	[item setRepresentedObject:appInfo];
	[menu addItem:item];
	
//	if (sortApplications)
//		[self sortApplicationsByNameAndReload:NO];
	

	
	
	
	NSNotificationCenter *notificationCenter = [workspace notificationCenter];
	[notificationCenter addObserver:self selector:@selector(appLaunchedNotificationHandler:) name:NSWorkspaceDidLaunchApplicationNotification object:nil];
	[notificationCenter addObserver:self selector:@selector(appTerminatedNotificationHandler:) name:NSWorkspaceDidTerminateApplicationNotification object:nil];
}


/*
 *
 */
- (void)appLaunchedNotificationHandler:(NSNotification *)notification {
	NSLog(@"launched %@\n", [[notification userInfo] objectForKey:@"NSApplicationName"]);
	NSRunningApplication *app = [[notification userInfo] objectForKey:NSWorkspaceApplicationKey];
	//	NSLog(@"App object: %@", app);
	
/*
	
	NSUInteger index;
	NSUInteger count = [runningApplications count];
	if (sortApplications) {
		NSString *appName = [app localizedName];
		NSUInteger i = 0;
		while (i < count && [appName compare:[[runningApplications objectAtIndex:i] localizedName]] == NSOrderedDescending)
			++i;
		index = i;
	} else
		index = count;
	
	[runningApplications insertObject:app atIndex:index];
	
	
	//	[self setAppSubmenuSizeWithWidth:0 andHeight:0 relative:YES];
	[self updateAppSubmenuViewSize];
	[appListTableView insertRowsAtIndexes:[NSIndexSet indexSetWithIndex:index] withAnimation:NSTableViewAnimationEffectFade];
 */
}


/*
 *
 */
- (void)appTerminatedNotificationHandler:(NSNotification *)notification {
	NSLog(@"terminated %@\n", [[notification userInfo] objectForKey:@"NSApplicationName"]);
	NSRunningApplication *app = [[notification userInfo] objectForKey:NSWorkspaceApplicationKey];
	NSUInteger index = [_runningApps indexOfObject:app];
	if (index != NSNotFound) {
		[_runningApps removeObjectAtIndex:index];
		[[[_mainMenu itemAtIndex:0] menu] removeItemAtIndex:index animate:NO];
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


- (NSString *)applicationSortingKey {
	return (_applicationSortingKey) ? _applicationSortingKey : APApplicationsSortedByName;
}


- (void)setApplicationSortingKey:(NSString *)sortingKey {
	if (! [_applicationSortingKey isEqualToString:sortingKey]) {
		_applicationSortingKey = sortingKey;

		// update menu here
		
	}
}

@end
