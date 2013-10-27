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
#include <libproc.h>

//NSString *const APApplicationsSortedByName = @"APApplicationsSortedByName";
//NSString *const APApplicationsSortedByPid = @"APApplicationsSortedByPid";

static const int gShowAllProcesses = 1;

static const int kPidFoundMask = 1 << (8 * sizeof(int) - 1);
//#define kPidFoundMask (1 << (8 * sizeof(int) - 1))
#define PID_MARK_FOUND(pid) (pid |= kPidFoundMask)
#define PID_UNMARK(pid) (pid &= ~kPidFoundMask)
#define PID_IS_MARKED(pid) ((pid & kPidFoundMask) ? 1 : 0)

// Sets "logind" into provided name buffer for the path
// like "/System/Library/CoreServices/logind"
int process_name_from_path(char name[], const char path[]);

int process_name_from_path(char name[], const char path[]) {
	int pos = -1;
	int i = 0;
	
	for (i = 0; path[i] != '\0'; ++i) {
		if (path[i] == '/')
			pos = i;
	}
	
	if (pos == -1)
		return 0;
	
	i = 0;
	++pos;
	while ((name[i] = path[pos]) != '\0') {
		++i;
		++pos;
	}
	
	return i;
}


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
	[_runningApplications release];
	[_runningProcesses release];
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
	[runningAppsMenu setDelegate:self];
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
	
//	if (_runningApplications) {
//		[_runningApplications removeAllObjects];
//		[_runningApplications release];
//	}
	
	NSWorkspace *workspace = [NSWorkspace sharedWorkspace];
	// This method is run just once at startup. So the array is guaranteed to
	// have not been previously used.
	_runningApplications = [[workspace runningApplications] mutableCopy];
	[self sortApplicationsByKey:[self applicationSortKey]];
//	[self sortApplicationsByKey:APApplicationsSortedByPid];
	

	NSUInteger i;
	NSUInteger elementsCount = [_runningApplications count];
	pid_t shared_pid = getpid();
	NSUInteger shared_pid_index;
	CMMenuItem *item;
	
	// Show Applications delimiter
	if (gShowAllProcesses) {
		item = [[[CMMenuItem alloc] initWithTitle:@"Applications" action:NULL] autorelease];
		[item setEnabled:NO];
		[menu addItem:item];
	}
	
	for (i = 0; i < elementsCount; ++i) {
		NSRunningApplication *app = [_runningApplications objectAtIndex:i];
		if (shared_pid == [app processIdentifier]) {
			shared_pid_index = i;
			continue;
		}
		
		NSImage *icon = [app icon];
		if (! icon) {
			// Get a process generic icon.
			// Do not retain explicitly since it will be added to a dictionary
			icon = [[NSWorkspace sharedWorkspace] iconForFile:@"/bin/ls"];
			// if for some reason it failed again (ls doesn't exit), get a generic app icon
			if (! icon)
				icon = [[NSWorkspace sharedWorkspace] iconForFileType:NSFileTypeForHFSTypeCode(kGenericApplicationIcon)];
		}
		
		NSMutableDictionary *appInfo = [NSMutableDictionary dictionaryWithObjectsAndKeys:
										[app localizedName], APApplicationInfoNameKey,
										icon, APApplicationInfoIconKey,
										[NSNumber numberWithInt:[app processIdentifier]], APApplicationInfoPidKey,
										[NSNumber numberWithFloat:0], APApplicationInfoLimitKey,
										nil];
				
		item = [[[CMMenuItem alloc] initWithTitle:[app localizedName] icon:icon action:@selector(selectApplicationItemMenuAction:)] autorelease];
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
	[_runningApplications removeObjectAtIndex:shared_pid_index];
	
	// Show System processes delimiter
	if (gShowAllProcesses) {
		item = [[[CMMenuItem alloc] initWithTitle:@"System" action:NULL] autorelease];
		[item setEnabled:NO];
		[menu addItem:item];
	
	

		// Now get running processes. It is complete list that includes also the pids
		// from above applications.
		int *proc_pids;
		int buffersize = proc_listpids(PROC_ALL_PIDS, (uint32_t)0, NULL, 0);
		proc_pids = (int *)malloc((size_t)buffersize);
		//memset(buffer, 0xDC, buffersize);
		// On the first call proc_listpids() returns buffer size with +(20 * sizeof(int))
		// On the second call it returns the actual size used by buffer; use it to calculate
		// number of elements in array.
		int buffersize_used = proc_listpids(PROC_ALL_PIDS, (uint32_t)0, proc_pids, buffersize);
		int numpids = buffersize_used / (int)(sizeof(int));
		int n;
		
		for (NSRunningApplication *app in _runningApplications) {
			int pid = (int)[app processIdentifier];
			//int found = 0;
			for (n = 0; n < numpids; ++n) {
				if (pid == proc_pids[n]) {
					PID_MARK_FOUND(proc_pids[n]);
					//found = 1;
//				fprintf(stdout, "\nfound pid: %d after mark: %d", pid, proc_pids[n]);
					break;
				}
			}
			// What if Application ID was not found in the process list? It probably was
			// terminatated in such a short period of time?
			// if (! found) {}
		}
	
		// After the previous lookup we have a list of processes marked as either
		// already displayed as Application or not marked (system process).
		_runningProcesses = [[NSMutableArray alloc] init];

		char *pathbuffer = (char *)malloc(PROC_PIDPATHINFO_MAXSIZE);
		char *namebuffer = (char *)malloc(128 * sizeof(char));
		//memset(pathbuffer, 0xDC, PROC_PIDPATHINFO_MAXSIZE);
		for (n = 0; n < numpids; ++n) {
			if (PID_IS_MARKED(proc_pids[n]))
				continue;
			if (proc_pids[n] == 0) {
				// reached the bottom pid
				break;
			}
			int pid = PID_UNMARK(proc_pids[n]);
			proc_pidpath(pid, pathbuffer, PROC_PIDPATHINFO_MAXSIZE);
			int len = process_name_from_path(namebuffer, pathbuffer);
			fprintf(stdout, "\nproc name: %s", namebuffer);
//			fprintf(stdout, "\npid[%d] = %d\tpath: %s", n, proc_pids[n], pathbuffer);
		}
		free(namebuffer);
		free(pathbuffer);
		free(proc_pids);
//	fputs("\n", stdout);
//	fflush(stdout);
		
	}
	
	
	

	/* temp */ {
		NSMutableDictionary *appInfo = [NSMutableDictionary dictionaryWithObjectsAndKeys:
										@"Some really long name for some unexistant applicaton", APApplicationInfoNameKey,
										[NSImage imageNamed:NSImageNameBonjour], APApplicationInfoIconKey,
										[NSNumber numberWithInt:999], APApplicationInfoPidKey,
										[NSNumber numberWithFloat:0], APApplicationInfoLimitKey, nil];
		
		CMMenuItem *item = [[[CMMenuItem alloc] initWithTitle:@"Some really long name for some unexistant applicaton" icon:[NSImage imageNamed:NSImageNameBonjour] action:@selector(selectApplicationItemMenuAction:)] autorelease];
		[item setTarget:self];
		[item setRepresentedObject:appInfo];
		[menu addItem:item];
	} // temp
	

	NSNotificationCenter *notificationCenter = [workspace notificationCenter];
	[notificationCenter addObserver:self selector:@selector(appLaunchedNotificationHandler:) name:NSWorkspaceDidLaunchApplicationNotification object:nil];
	[notificationCenter addObserver:self selector:@selector(appTerminatedNotificationHandler:) name:NSWorkspaceDidTerminateApplicationNotification object:nil];
}


/*
 *
 */
- (void)sortApplicationsByKey:(int)sortKey {
	NSSortDescriptor *descriptor;

	if (! [_runningApplications count])
		return;
	
	if (sortKey == APApplicationsSortedByName) {
		descriptor = [[NSSortDescriptor alloc] initWithKey:@"localizedName" ascending:YES selector:@selector(localizedCompare:)];
	} else if (sortKey == APApplicationsSortedByPid) {
		descriptor = [[NSSortDescriptor alloc] initWithKey:@"processIdentifier" ascending:YES];
	} else {
		NSLog(@"Provided sort key is not valid");
		return;
	}
	
	[_runningApplications sortUsingDescriptors:[NSArray arrayWithObject:descriptor]];
	[descriptor release];
}


/*
 *
 */
- (void)menuNeedsUpdate:(CMMenu *)menu {
	NSLog(@"menu needs upate: %@", menu);
}


/*
 *
 */
- (void)appLaunchedNotificationHandler:(NSNotification *)notification {
//	NSLog(@"launched %@ BEGIN", [[notification userInfo] objectForKey:@"NSApplicationName"]);
	NSRunningApplication *app = [[notification userInfo] objectForKey:NSWorkspaceApplicationKey];
//	NSLog(@"launched %@\n", app);
	//	NSLog(@"App object: %@", app);
	
	NSUInteger elementsCount = [_runningApplications count];
	NSUInteger index = elementsCount;
	
	/*----------------------------------------------------------------------------------------------------/
	  ASSUMTION:
		-appLaunchedNotificationHandler: and -appTerminatedNotificationHandler: are not re-entrant safe.
		These methods manage shared resource (NSArray *)_runningApplications.
		We assume that these notifications are queued and will be executed in certain order and 
		will not be interrupted by similar notifications.
	 /----------------------------------------------------------------------------------------------------*/
	
	int sortKey = [self applicationSortKey];
	if (sortKey == APApplicationsSortedByName) {
		NSString *appName = [app localizedName];
		NSUInteger i = 0;
		while (i < elementsCount && [appName localizedCompare:[[_runningApplications objectAtIndex:i] localizedName]] == NSOrderedDescending)
			++i;

		//		while (i < elementsCount) {
		//			NSString *name = [[_runningApplications objectAtIndex:i] localizedName];
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
	
	[_runningApplications insertObject:app atIndex:index];
	
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
//	NSUInteger index = [_runningApplications indexOfObject:app];
//	NSUInteger index;
	
//	NSLog(@"running apps: %@", _runningApplications);

	for (NSRunningApplication *runningApp in _runningApplications) {
		if ([app isEqual:runningApp]) {
			NSUInteger index = [_runningApplications indexOfObject:runningApp];
			[_runningApplications removeObjectAtIndex:index];

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
	if ( sortKey != APApplicationsSortedByName
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
