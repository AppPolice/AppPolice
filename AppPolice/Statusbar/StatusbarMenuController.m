//
//  StatusbarMenuController.m
//  AppPolice
//
//  Created by Maksym on 10/11/13.
//  Copyright (c) 2013 Maksym Stefanchuk. All rights reserved.
//

#import "StatusbarMenuController.h"
#import "AppInspector.h"
#import "APAboutWindowController.h"
#import "APPreferencesController.h"
#include <libproc.h>
#include "app_inspector_c.h"
#include "proc_cpulim.h"


#define kProcPidKey @"pid"
#define kProcNameKey @"name"
#define kNotFoundAppIndexesKey @"nfAppIdx"
#define kNotFoundSysProcIndexesKey @"nfSysIdx"
#define kNewSysProcIndexesKey @"newSysIdx"
#define PROCESS_NOT_LIMITED 0.0
#define ALL_LIMITS_PAUSED YES

static const unsigned int kPidFoundMask = 1U << (8 * sizeof(int) - 1);
//#define kPidFoundMask (1 << (8 * sizeof(int) - 1))
#define PID_MARK_FOUND(pid) (pid |= kPidFoundMask)
#define PID_UNMARK(pid) (pid &= ~kPidFoundMask)
#define PID_IS_MARKED(pid) (((unsigned)pid & kPidFoundMask) ? 1 : 0)
#define PROC_NAME_MAXLEN 128

// Global state used in main.m during SIGCONT signal handler whether
// to resume limits if they were running before SIGSTOP
extern int gAPAllLimitsPaused;


@interface StatusbarMenuController ()
{
	BOOL _showAllProcesses;
	BOOL _showOtherUsersProcesses;
	NSMutableArray *_limitedProcessItems;
	APAboutWindowController *_aboutWindowConstroller;
	APPreferencesController *_preferencesWindowController;
	BOOL _userDefaultsDidChange;
}

- (void)setupMenus;
- (void)populateMenu:(CMMenu *)menu withApplications:(NSArray *)runningApplications andSystemProcesses:(NSArray *)runningSystemProcesses;
/*!
  @abstract Makes changes to _runningApplications  and _runningSystemProcesses arrays
 	by removing processes that are no longer running, and adding new ones in
 	accordance with current sort option set.
  @discussion This method is the core of all business logic in this Class.

  @return Dictionary of three sets of NSIndexSet type that are to be accessed by keys:

 \return 1. \p kNotFoundAppIndexesKey Set of indexes of items that were removed from
 		_runningApplications array. These indexes tell us which menu items
 		should be remove.
 \return 2. \p kNotFoundSysProcIndexesKey Same as above but for _runningSystemProcesses.

 \return 3. \p kNewSysProcIndexesKey Set of indexes of new items that were added
 		to _runningSystemProcesses. Use this to insert new menu items at
 		corresponding locations.
 */
- (NSDictionary *)updateRunningProcesses;
- (void)appLaunchedNotificationHandler:(NSNotification *)notification;
- (void)appTerminatedNotificationHandler:(NSNotification *)notification;
// |APAppInspectorProcessDidChangeLimit| notification handler
- (void)processDidChangeLimitNotificationHandler:(NSNotification *)notification;
- (void)userDefaultsDidChangeNotificationHandler:(NSNotification *)notification;
// Helper for |APAppInspectorProcessDidChangeLimit| notification handler
//- (void)processPid:(NSNumber *)pid didChangeLimit:(float)limit;
// Menu actions
- (void)selectProcessMenuAction:(id)sender;
- (void)toggleLimiterMenuAction:(id)sender;
/*!
 @discussion CMMenu is built to instantly update when either title,
	image, etc. is changed. This method is used to delay title update
	after Action performs and menu is hidden.
*/
- (void)updateMenuItemWithTitle:(NSDictionary *)itemAndTitle;
- (void)showAboutWindowMenuAction:(id)sender;
- (void)showPreferecesWindowMenuAction:(id)sender;
- (void)terminateApplicationMenuAction:(id)sender;
/*!
 @discussion A dedicated method to process limit value change either by
	the slider in AppInspector or when the process is terminated. It sets
	appropriate menu item status icon (orange or green depending on Pause 
	state) and enables or disables Pause menu item depending on the number
	of processes currently being limited.
 */
- (void)processOfItem:(CMMenuItem *)item didChangeLimit:(float)limit;

@end



@implementation StatusbarMenuController

- (id)init {
	self = [super init];
	if (self) {
		NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
//		NSInteger sortByPreferences = [preferences integerForKey:@"APSortBy"];
//		_sortKey = (sortByPreferences == APApplicationsSortedByName) ? APApplicationsSortedByName : APApplicationsSortedByPid;
		_sortKey = (int)[preferences integerForKey:@"APSortBy"];;
		_orderAsc = [preferences boolForKey:@"APOrderAsc"];
		_showAllProcesses = [preferences boolForKey:@"APShowSystemProcesses"];
		// For now do not show processes not run by user
		_showOtherUsersProcesses = 0;
		_limitedProcessItems = [[NSMutableArray alloc] init];
		[self setupMenus];
	}
	return self;
}


- (void)dealloc {
	[_limitedProcessItems release];
	[_runningApplications release];
	[_runningSystemProcesses release];
	[_mainMenu release];
	[_appInspector release];
	// Remove ourself from notification centers
	[[[NSWorkspace sharedWorkspace] notificationCenter] removeObserver:self];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[super dealloc];
}


/*
 *
 */
- (void)setupMenus {
	CMMenu *runningAppsMenu;
	CMMenuItem *item;
	
	_mainMenu = [[CMMenu alloc] initWithTitle:@"MainMenu"];
	item = [[[CMMenuItem alloc] initWithTitle:NSLocalizedString(@"Running Apps", @"Menu Item")
									   action:NULL] autorelease];
	runningAppsMenu = [[[CMMenu alloc] initWithTitle:@"Running Apps Menu"] autorelease];
	[runningAppsMenu setPerformsActionInstantly:YES];
	[runningAppsMenu setDelegate:self];
	[runningAppsMenu setCancelsTrackingOnAction:NO];
//	[runningAppsMenu setCancelsTrackingOnMouseEventOutsideMenus:NO];
	[item setSubmenu:runningAppsMenu];
	[_mainMenu addItem:item];
	
	item = [[[CMMenuItem alloc] initWithTitle:NSLocalizedString(@"Pause all limits", @"Menu Item")
									   action:@selector(toggleLimiterMenuAction:)] autorelease];
	[item setTarget:self];
	[item setEnabled:NO];
	[_mainMenu addItem:item];
	
	[_mainMenu addItem:[CMMenuItem separatorItem]];
	
//	item = [[[CMMenuItem alloc] initWithTitle:@"Donate" action:NULL] autorelease];
//	[item setTarget:self];
//	[_mainMenu addItem:item];
	item = [[[CMMenuItem alloc] initWithTitle:NSLocalizedString(@"About AppPolice", @"Menu Item")
									   action:@selector(showAboutWindowMenuAction:)] autorelease];
	[item setTarget:self];
	[_mainMenu addItem:item];
	item = [[[CMMenuItem alloc] initWithTitle:NSLocalizedString(@"Preferences...", @"Menu Item")
									   action:@selector(showPreferecesWindowMenuAction:)] autorelease];
	[item setTarget:self];
	[_mainMenu addItem:item];
	[_mainMenu addItem:[CMMenuItem separatorItem]];
	item = [[[CMMenuItem alloc] initWithTitle:NSLocalizedString(@"Quit AppPolice", @"Menu Item")
									   action:@selector(terminateApplicationMenuAction:)] autorelease];
	[item setTarget:self];
	[_mainMenu addItem:item];
	
	
	NSWorkspace *workspace = [NSWorkspace sharedWorkspace];
	// This method is run just once at startup. So the array is guaranteed to
	// have not been previously used.
	_runningApplications = [[workspace runningApplications] mutableCopy];
	pid_t shared_pid = getpid();
	for (NSRunningApplication *app in _runningApplications) {
		if ([app processIdentifier] == shared_pid) {
			[_runningApplications removeObject:app];
			break;
		}
	}
	[self sortApplicationsByKey:[self sortKey] Asc:_orderAsc];
	if (_showAllProcesses) {
		_runningSystemProcesses = [[NSMutableArray alloc] init];
		(void) [self updateRunningProcesses];
	}
	
	[self populateMenu:runningAppsMenu
	  withApplications:_runningApplications
	andSystemProcesses:_runningSystemProcesses];
	
//	[self populateMenuWithRunningApplications:[[_mainMenu itemAtIndex:0] submenu]];

	
	// Subscribe to notifications
	NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
	[notificationCenter addObserver:self
						   selector:@selector(menuDidEndTrackingNotificationHandler:)
							   name:CMMenuDidEndTrackingNotification
							 object:nil];
	[notificationCenter addObserver:self
						   selector:@selector(processDidChangeLimitNotificationHandler:)
							   name:APAppInspectorProcessDidChangeLimit
							 object:nil];
	[notificationCenter addObserver:self
						   selector:@selector(userDefaultsDidChangeNotificationHandler:)
							   name:NSUserDefaultsDidChangeNotification
							 object:nil];
	
	NSNotificationCenter *workspaceNotificationCenter = [[NSWorkspace sharedWorkspace] notificationCenter];
	[workspaceNotificationCenter addObserver:self
								 selector:@selector(appLaunchedNotificationHandler:)
									 name:NSWorkspaceDidLaunchApplicationNotification
								   object:nil];
	[workspaceNotificationCenter addObserver:self
								 selector:@selector(appTerminatedNotificationHandler:)
									 name:NSWorkspaceDidTerminateApplicationNotification
								   object:nil];
}


/*
 *
 */
- (void)populateMenu:(CMMenu *)menu withApplications:(NSArray *)runningApplications andSystemProcesses:(NSArray *)runningSystemProcesses {
	if (! menu)
		return;
	
//	NSUInteger i;
//	NSUInteger elementsCount = [_runningApplications count];
//	NSUInteger elementsCount = [runningApplications count];
//	pid_t shared_pid = getpid();
//	NSUInteger shared_pid_index = UINT_MAX;
	NSUInteger systemProcessesCount = [runningSystemProcesses count];
	CMMenuItem *item;
	NSImage *onStateImageActive = [NSImage imageNamed:NSImageNameStatusAvailable];
	NSImage *onStateImagePaused = [NSImage imageNamed:NSImageNameStatusPartiallyAvailable];
	[onStateImageActive setSize:NSMakeSize(12, 12)];
	[onStateImagePaused setSize:NSMakeSize(12, 12)];
	
	// Show Applications delimiter
//	if (_showAllProcesses) {
	if (systemProcessesCount) {
		item = [[[CMMenuItem alloc] initWithTitle:NSLocalizedString(@"Applications", @"Delimiter Menu Item")
										   action:NULL] autorelease];
		[item setEnabled:NO];
		[menu addItem:item];
	}

	// --------------------------------------------------
	//		Populate with Applications
	// --------------------------------------------------
	for (NSRunningApplication *app in runningApplications) {
//		NSRunningApplication *app = [runningApplications objectAtIndex:i];
//		if (shared_pid == [app processIdentifier]) {
//			shared_pid_index = i;
//			continue;
//		}
		
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
				
		item = [[[CMMenuItem alloc] initWithTitle:[app localizedName]
											 icon:icon
										   action:@selector(selectProcessMenuAction:)] autorelease];
		[item setTarget:self];
		[item setOnStateImage:onStateImageActive];
//		if (_showAllProcesses)
		if (systemProcessesCount)
			[item setIndentationLevel:1];
				
		[item setRepresentedObject:appInfo];
		[menu addItem:item];
	}
	
	// Remove ourselves from running applications array
//	if (shared_pid_index != UINT_MAX)
//		[_runningApplications removeObjectAtIndex:shared_pid_index];
	
	// -----------------------------------------------------
	//		Populate with System processes if option is set
	// -----------------------------------------------------
//	if (_showAllProcesses) {
	if (systemProcessesCount) {
		item = [[[CMMenuItem alloc] initWithTitle:NSLocalizedString(@"System", @"Delimiter Menu Item")
										   action:NULL] autorelease];
		[item setEnabled:NO];
		[menu addItem:item];
	
//		if (! _runningSystemProcesses)
//			_runningSystemProcesses = [[NSMutableArray alloc] init];

//		
//		NSDictionary *updateIndexes = [self updateRunningProcesses];
//		NSIndexSet *notfoundAppIndexes = [updateIndexes objectForKey:kNotFoundAppIndexesKey];
//		NSIndexSet *newSysProcIndexes = [updateIndexes objectForKey:kNewSysProcIndexesKey];
//		
//		if ([notfoundAppIndexes count]) {
//			// Because of first menu item "Applications" shift indexes by 1
//			NSMutableIndexSet *shiftedIndexes = [NSMutableIndexSet indexSet];
//			[notfoundAppIndexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
//				[shiftedIndexes addIndex:(idx + 1)];
//			}];
//			[menu removeItemsAtIndexes:shiftedIndexes];
//		}
//		
//		if ([newSysProcIndexes count]) {
			NSImage *genericIcon = [[NSWorkspace sharedWorkspace] iconForFile:@"/bin/ls"];
//			[_runningSystemProcesses enumerateObjectsAtIndexes:newSysProcIndexes options:0 usingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		for (NSDictionary *procInfo in runningSystemProcesses) {
//				NSDictionary *procInfo = (NSDictionary *)obj;
				NSMutableDictionary *appInfo = [NSMutableDictionary dictionaryWithObjectsAndKeys:
												[procInfo objectForKey:kProcNameKey], APApplicationInfoNameKey,
												genericIcon, APApplicationInfoIconKey,
												[procInfo objectForKey:kProcPidKey], APApplicationInfoPidKey,
												[NSNumber numberWithFloat:0], APApplicationInfoLimitKey,
												nil];
				
				CMMenuItem *item = [[[CMMenuItem alloc] initWithTitle:[procInfo objectForKey:kProcNameKey]
																 icon:genericIcon
															   action:@selector(selectProcessMenuAction:)] autorelease];
				[item setTarget:self];
				[item setOnStateImage:onStateImageActive];
				[item setIndentationLevel:1];
				[item setRepresentedObject:appInfo];
				[menu addItem:item];
//			}];
		}
		
//		NSLog(@"not found indexes: %@", updateIndexes);
	}
	

	/* temp */ { /*
		NSMutableDictionary *appInfo = [NSMutableDictionary dictionaryWithObjectsAndKeys:
										@"Some really long name for some unexistant applicaton", APApplicationInfoNameKey,
										[NSImage imageNamed:NSImageNameBonjour], APApplicationInfoIconKey,
										[NSNumber numberWithInt:999], APApplicationInfoPidKey,
										[NSNumber numberWithFloat:0], APApplicationInfoLimitKey, nil];
		
		CMMenuItem *item = [[[CMMenuItem alloc] initWithTitle:@"Some really long name for some unexistant applicaton" icon:[NSImage imageNamed:NSImageNameBonjour] action:@selector(selectProcessMenuAction:)] autorelease];
		[item setTarget:self];
		[item setRepresentedObject:appInfo];
		[menu addItem:item];
*/	} // temp
	
}


/*
 *
 */
- (NSDictionary *)updateRunningProcesses {
	pid_t shared_pid = getpid();
	uid_t shared_uid;
	NSUInteger shownAppliationsCount = [_runningApplications count];
	NSUInteger shownSystemProcessesCount = [_runningSystemProcesses count];
	NSMutableIndexSet *notfoundAppIndexes = [NSMutableIndexSet indexSet];
	NSMutableIndexSet *notfoundSysProcIndexes = [NSMutableIndexSet indexSet];
	NSMutableIndexSet *newSysProcIndexes = [NSMutableIndexSet indexSet];
	
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
	NSUInteger idx;
	
	
	// Mark running processes as already shown.
	// If Application is not found among currently running processes, it most likely
	// has been terminated, therefore remove it.
	for (idx = 0; idx < shownAppliationsCount; ++idx) {
		int pid = (int)[[_runningApplications objectAtIndex:idx] processIdentifier];
		int found = 0;
		for (n = 0; n < numpids; ++n) {
			if (pid == proc_pids[n]) {
				PID_MARK_FOUND(proc_pids[n]);
				found = 1;
//				fprintf(stdout, "\nfound pid: %d after mark: %d", pid, proc_pids[n]);
				break;
			}
		}
		// If Application is no longer running -- remove it
		if (! found)
			[notfoundAppIndexes addIndex:idx];
	}
	
	if ([notfoundAppIndexes count])
		[_runningApplications removeObjectsAtIndexes:notfoundAppIndexes];
	

	
	// Now is the turn to mark System processes that we're already showing.
	for (idx = 0; idx < shownSystemProcessesCount; ++idx) {
		int pid = [(NSNumber *)[(NSDictionary *)[_runningSystemProcesses objectAtIndex:idx] objectForKey:kProcPidKey] intValue];
		int found = 0;
		for (n = 0; n < numpids; ++n) {
			if (pid == proc_pids[n]) {
				PID_MARK_FOUND(proc_pids[n]);
				found = 1;
				break;
			}
		}
		if (! found)
			[notfoundSysProcIndexes addIndex:idx];
	}
	
	if ([notfoundSysProcIndexes count]) {
//		/* temp */ {
//			[notfoundSysProcIndexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
//				NSLog(@"removing old process: %@", [_runningSystemProcesses objectAtIndex:idx]);
//			}];
//		}
		[_runningSystemProcesses removeObjectsAtIndexes:notfoundSysProcIndexes];
		// update the number of sys processes
		shownSystemProcessesCount -= [notfoundSysProcIndexes count];
	}
	
	
	
	// After the previous lookups we have an array of processes that
	// are marked as either already shown or not. Those that are not
	// shown, get process name and add to the System processes array.
	
	char *pathbuffer = (char *)malloc(PROC_PIDPATHINFO_MAXSIZE);
	char *namebuffer = (char *)malloc(PROC_NAME_MAXLEN * sizeof(char));
	//memset(pathbuffer, 0xDC, PROC_PIDPATHINFO_MAXSIZE);
	int *insert_indexes;
	int insert_indexes_num = 0;
	int insert_index_i;
	// If there are shown processes we will be inserting new processes
	// into an array accounting current sorting and store insertion indexes.
	// Previous insert indexes must be incremented if the new insertion was
	// above. For example, if current indexes are (5, 6, 9) and new one is (3)
	// the resulting indexes would be (3, 6, 7, 10).
	if (shownSystemProcessesCount)
		insert_indexes = (int *)malloc((size_t)numpids * sizeof(int));

	if ( !_showOtherUsersProcesses)
		shared_uid = getuid();


	for (n = 0; n < numpids; ++n) {
		if (proc_pids[n] == 0) // reached the bottom pid
			break;

		if (PID_IS_MARKED(proc_pids[n]) || proc_pids[n] == shared_pid)
			continue;
		
		// Skip processes not belonging to the user
		if (! _showOtherUsersProcesses) {
			uid_t proc_uid = get_proc_uid(proc_pids[n]);
//			printf("skipg pid: %d\n", proc_pids[n]);
			if (proc_uid != shared_uid)
				continue;
		}
		
		proc_pidpath(proc_pids[n], pathbuffer, PROC_PIDPATHINFO_MAXSIZE);
		int len = proc_name_from_path(namebuffer, pathbuffer, PROC_NAME_MAXLEN);
		if (! len)	// process doesn't have a name?
			continue;
		
		NSDictionary *procInfo = @{
			kProcPidKey : [NSNumber numberWithInt:proc_pids[n]],
			kProcNameKey : [NSString stringWithCString:namebuffer encoding:NSUTF8StringEncoding]
		};
		// If there are already objects in array, all new ones must be inserted in a
		// positon according to current sort key.
		if (shownSystemProcessesCount) {
			int insertIndex = (int)[self addProccessAccountingSorting:procInfo];
			for (insert_index_i = 0; insert_index_i < insert_indexes_num; ++insert_index_i)
				if (insertIndex <= insert_indexes[insert_index_i])
					insert_indexes[insert_index_i] += 1;
			insert_indexes[insert_indexes_num++] = insertIndex;
		} else {		// otherwise simply add them and sort later
			[_runningSystemProcesses addObject:procInfo];
		}
//		fprintf(stdout, "proc %d name: %s\n", proc_pids[n], namebuffer);
//		fprintf(stdout, "\npid[%d] = %d\tpath: %s", n, proc_pids[n], pathbuffer);
	}
	
	// Free used buffers
	free(namebuffer);
	free(pathbuffer);
	free(proc_pids);
	
	
	if (shownSystemProcessesCount) {
		for (insert_index_i = 0; insert_index_i < insert_indexes_num; ++insert_index_i)
			[newSysProcIndexes addIndex:(NSUInteger)insert_indexes[insert_index_i]];
		free(insert_indexes);
	} else {
		[self sortSystemProcessesByKey:[self sortKey] Asc:_orderAsc];
		[newSysProcIndexes addIndexesInRange:NSMakeRange(0, [_runningSystemProcesses count])];
	}
	
//	/* temp */ {
//		[_runningSystemProcesses enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
//			BOOL new = [newSysProcIndexes containsIndex:idx];
//			NSLog(@"%lu pid[%d][%@] %@", idx, [[obj objectForKey:kProcPidKey] intValue], [obj objectForKey:kProcNameKey], (new) ? @" -- is new" : @"");
//		}];
//	}
	
//	NSLog(@"running system processes: %@", _runningSystemProcesses);
//	NSLog(@"procs: %@", _runningProcesses);
	
	return @{
		kNotFoundAppIndexesKey : notfoundAppIndexes,
		kNotFoundSysProcIndexesKey : notfoundSysProcIndexes,
		kNewSysProcIndexesKey : newSysProcIndexes
	};
}


/*
 *
 */
- (NSUInteger)addProccessAccountingSorting:(NSDictionary *)processInfo {
	NSUInteger elementsCount = [_runningSystemProcesses count];
	NSUInteger index = 0;
	
	int sortKey = [self sortKey];
	if (sortKey == APApplicationsSortedByName) {
		NSString *name = [processInfo objectForKey:kProcNameKey];
		NSUInteger i = 0;
		while (i < elementsCount && [name localizedCompare:[(NSDictionary *)[_runningSystemProcesses objectAtIndex:i] objectForKey:kProcNameKey]] == NSOrderedDescending)
			++i;
		index = i;
		
	} else if (sortKey == APApplicationsSortedByPid) {
		NSNumber *pid = [processInfo objectForKey:kProcPidKey];
		NSUInteger i = 0;
		while (i < elementsCount && [pid compare:[(NSDictionary *)[_runningSystemProcesses objectAtIndex:i] objectForKey:kProcPidKey]] == NSOrderedDescending)
			++i;
		index = i;
	}
	
	[_runningSystemProcesses insertObject:processInfo atIndex:index];
	
	return index;
}


/*
 *
 */
- (void)sortApplicationsByKey:(int)sortKey Asc:(BOOL)Asc {
	NSSortDescriptor *descriptor;

	if (! [_runningApplications count])
		return;
	
	if (sortKey == APApplicationsSortedByName) {
		descriptor = [[NSSortDescriptor alloc] initWithKey:@"localizedName" ascending:Asc selector:@selector(localizedCompare:)];
	} else if (sortKey == APApplicationsSortedByPid) {
		descriptor = [[NSSortDescriptor alloc] initWithKey:@"processIdentifier" ascending:Asc];
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
- (void)sortSystemProcessesByKey:(int)sortKey Asc:(BOOL)Asc {
	NSSortDescriptor *descriptor;
	
	if (! [_runningSystemProcesses count])
		return;
	
	if (sortKey == APApplicationsSortedByName) {
		descriptor = [[NSSortDescriptor alloc] initWithKey:kProcNameKey ascending:Asc selector:@selector(localizedCompare:)];
	} else if (sortKey == APApplicationsSortedByPid) {
		descriptor = [[NSSortDescriptor alloc] initWithKey:kProcPidKey ascending:Asc];
	} else {
		NSLog(@"Provided sort key is not valid");
		return;
	}
	
	[_runningSystemProcesses sortUsingDescriptors:[NSArray arrayWithObject:descriptor]];
	[descriptor release];
}


/*
 *
 */
- (void)menuNeedsUpdate:(CMMenu *)menu {
	BOOL userDefaultsDidChange = NO;
	
	// Verify if defaults did change from the last time menu was displayed
	// and that those changes are unique (e.g. not turned off and back on)
	if (_userDefaultsDidChange) {
		// Reset flag
		_userDefaultsDidChange = NO;
		NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
		int currentSortKey = (int)[preferences integerForKey:@"APSortBy"];;
		BOOL currentOrderAsc = [preferences boolForKey:@"APOrderAsc"];
		BOOL currentShowAllProcesses = [preferences boolForKey:@"APShowSystemProcesses"];
		

		if (currentSortKey != _sortKey) {
			userDefaultsDidChange = YES;
			_sortKey = currentSortKey;
			_orderAsc = currentOrderAsc;
			[self sortApplicationsByKey:_sortKey Asc:_orderAsc];
			// If systems processes are already displayed and new option doesn't disable
			// them -- sort them too.
			if (_showAllProcesses == currentShowAllProcesses && currentShowAllProcesses)
				[self sortSystemProcessesByKey:_sortKey Asc:_orderAsc];
		} else if (currentOrderAsc != _orderAsc) {
			userDefaultsDidChange = YES;
			_orderAsc = currentOrderAsc;
			[self sortApplicationsByKey:_sortKey Asc:_orderAsc];
			if (_showAllProcesses == currentShowAllProcesses && currentShowAllProcesses)
				[self sortSystemProcessesByKey:_sortKey Asc:_orderAsc];
		}
		
		if (_showAllProcesses != currentShowAllProcesses) {
			userDefaultsDidChange = YES;
			_showAllProcesses = currentShowAllProcesses;
			if (_showAllProcesses) {
				if (! _runningSystemProcesses)
					_runningSystemProcesses = [[NSMutableArray alloc] init];
				(void) [self updateRunningProcesses];
			} else {
				if (_runningSystemProcesses)
					[_runningSystemProcesses removeAllObjects];
			}
		}
	}
	
	// If user changed defaults that control menu display recreate items with new settings (set above)
	if (userDefaultsDidChange) {
		[menu removeAllItems];
		[self populateMenu:menu withApplications:_runningApplications andSystemProcesses:_runningSystemProcesses];
	} else {
		NSDictionary *updateIndexSets = [self updateRunningProcesses];
		NSIndexSet *notfoundAppIndexes = [updateIndexSets objectForKey:kNotFoundAppIndexesKey];
		NSIndexSet *notfoundSysProcIndexes = [updateIndexSets objectForKey:kNotFoundSysProcIndexesKey];
		NSIndexSet *newSysProcIndexes = [updateIndexSets objectForKey:kNewSysProcIndexesKey];
	//	NSLog(@"update indexes: %@", updateIndexSets);
		
		
		if ([notfoundAppIndexes count]) {
			// Because of first menu item "Applications" shift indexes by 1
			NSMutableIndexSet *shiftedIndexes = [NSMutableIndexSet indexSet];
			[notfoundAppIndexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
				[shiftedIndexes addIndex:(idx + 1)];
			}];
			[menu removeItemsAtIndexes:shiftedIndexes];
		}
		
		if ([notfoundSysProcIndexes count]) {
			NSUInteger offset = [_runningApplications count] + 2;
			// Shift indexes by amount of Application items and two delimeters
			NSMutableIndexSet *shiftedIndexes = [NSMutableIndexSet indexSet];
			[notfoundSysProcIndexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
				[shiftedIndexes addIndex:(idx + offset)];
			}];
			// If any of the processes represented by menu item was limited before
			// pass its pid to limit handler method to remove it from array
			[[menu itemArray] enumerateObjectsAtIndexes:shiftedIndexes options:0 usingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
				[self processOfItem:(CMMenuItem *)obj didChangeLimit:PROCESS_NOT_LIMITED];
			}];
			
			[menu removeItemsAtIndexes:shiftedIndexes];
		}
		
		if ([newSysProcIndexes count]) {
			NSUInteger offset = [_runningApplications count];
			if (_showAllProcesses)
				offset += 2;		// two separator items
			NSImage *genericIcon = [[NSWorkspace sharedWorkspace] iconForFile:@"/bin/ls"];
			[_runningSystemProcesses enumerateObjectsAtIndexes:newSysProcIndexes options:0 usingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
				NSDictionary *procInfo = (NSDictionary *)obj;
				NSMutableDictionary *appInfo = [NSMutableDictionary dictionaryWithObjectsAndKeys:
												[procInfo objectForKey:kProcNameKey], APApplicationInfoNameKey,
												genericIcon, APApplicationInfoIconKey,
												[procInfo objectForKey:kProcPidKey], APApplicationInfoPidKey,
												[NSNumber numberWithFloat:0], APApplicationInfoLimitKey,
												nil];
				
				CMMenuItem *item = [[[CMMenuItem alloc] initWithTitle:[procInfo objectForKey:kProcNameKey]
																 icon:genericIcon
															   action:@selector(selectProcessMenuAction:)] autorelease];
				[item setTarget:self];
				NSImage *onStateImage = [NSImage imageNamed:NSImageNameStatusAvailable];
				[onStateImage setSize:NSMakeSize(12, 12)];
				[item setOnStateImage:onStateImage];
				[item setRepresentedObject:appInfo];
				if (_showAllProcesses)
					[item setIndentationLevel:1];
				[menu insertItem:item atIndex:(idx + offset) animate:NO];
			}];
		}
	}
}


/*
 *
 */
- (void)appLaunchedNotificationHandler:(NSNotification *)notification {
	NSRunningApplication *app = [[notification userInfo] objectForKey:NSWorkspaceApplicationKey];
	
	NSUInteger elementsCount = [_runningApplications count];
	NSUInteger index = elementsCount;
	NSComparisonResult orderedComparisonResult = (_orderAsc) ? NSOrderedDescending : NSOrderedAscending;
	
	/*----------------------------------------------------------------------------------------------------/
	  ASSUMTION:
		-appLaunchedNotificationHandler: and -appTerminatedNotificationHandler: are not re-entrant safe.
		These methods manage shared resource (NSArray *)_runningApplications.
		We assume that these notifications are queued and will be executed in certain order and 
		will not be interrupted by similar notifications.
	 /----------------------------------------------------------------------------------------------------*/
	
	int sortKey = [self sortKey];
	if (sortKey == APApplicationsSortedByName) {
		NSString *appName = [app localizedName];
		NSUInteger i = 0;
		while (i < elementsCount && [appName localizedCompare:[[_runningApplications objectAtIndex:i] localizedName]] == orderedComparisonResult)
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
		index = (_orderAsc) ? elementsCount : 0;
	}
	
	[_runningApplications insertObject:app atIndex:index];
	// If showing all processes the first menu item is "Applications". Offset index by 1.
	if (_showAllProcesses)
		++index;
	
	NSMutableDictionary *appInfo = [NSMutableDictionary dictionaryWithObjectsAndKeys:
									[app localizedName], APApplicationInfoNameKey,
									[app icon], APApplicationInfoIconKey,
									[NSNumber numberWithInt:[app processIdentifier]], APApplicationInfoPidKey,
									[NSNumber numberWithFloat:0], APApplicationInfoLimitKey, nil];
	
	CMMenuItem *item = [[[CMMenuItem alloc] initWithTitle:[app localizedName]
													 icon:[app icon]
												   action:@selector(selectProcessMenuAction:)] autorelease];
	[item setTarget:self];
	NSImage *onStateImage = [NSImage imageNamed:NSImageNameStatusAvailable];
	[onStateImage setSize:NSMakeSize(12, 12)];
	[item setOnStateImage:onStateImage];
	[item setRepresentedObject:appInfo];
	if (_showAllProcesses)
		[item setIndentationLevel:1];
	[[[_mainMenu itemAtIndex:0] submenu] insertItem:item atIndex:index animate:NO];
}


/*
 *
 */
- (void)appTerminatedNotificationHandler:(NSNotification *)notification {
	NSRunningApplication *app = [[notification userInfo] objectForKey:NSWorkspaceApplicationKey];
	
	for (NSRunningApplication *runningApp in _runningApplications) {
		if ([app isEqual:runningApp]) {
			NSUInteger index = [_runningApplications indexOfObject:runningApp];
			[_runningApplications removeObjectAtIndex:index];
			// If showing all process, the first menu item is "Applications". Shift index by 1
			NSInteger menuIndex = (_showAllProcesses) ? (NSInteger)(index + 1) : (NSInteger)index;
			
			CMMenu *menu = [[_mainMenu itemAtIndex:0] submenu];
			CMMenuItem *item = [menu itemAtIndex:menuIndex];
			AppInspector *appInspector = [self appInspector];
			NSPopover *popover = [appInspector popover];
			if ([popover isShown]) {
				CMMenuItem *attachedToItem = [appInspector attachedToItem];
				if (attachedToItem == item) {
					[popover setAnimates:YES];
					[popover close];
				}
			}
			[self processOfItem:item didChangeLimit:PROCESS_NOT_LIMITED];
			[menu removeItemAtIndex:menuIndex animate:NO];

			return;
		}
	}
}


/*
 *
 */
- (void)processDidChangeLimitNotificationHandler:(NSNotification *)notification {
	NSDictionary *userInfo = [notification userInfo];

	CMMenuItem *item = [userInfo objectForKey:@"menuItem"];
	NSDictionary *representedObj = [item representedObject];
	if (! representedObj)
		return;

	float limit = [[representedObj objectForKey:APApplicationInfoLimitKey] floatValue];
	[self processOfItem:item didChangeLimit:limit];
}


/*
 *
 */
- (void)processOfItem:(CMMenuItem *)item didChangeLimit:(float)limit {
	CMMenuItem *pauseItem = [_mainMenu itemAtIndex:1];
	BOOL pauseItemIsEnabled = YES;
	BOOL allLimitsPaused = [[pauseItem representedObject] boolValue];
	
	if (limit == PROCESS_NOT_LIMITED) {
		[item setState:NSMixedState];
		[_limitedProcessItems removeObject:item];
		if (! [_limitedProcessItems count])
			pauseItemIsEnabled = NO;
	} else {
		NSImage *image = (allLimitsPaused) ? [NSImage imageNamed:NSImageNameStatusPartiallyAvailable] : [NSImage imageNamed:NSImageNameStatusAvailable];
		if (! [[item onStateImage] isEqual:image])
			[item setOnStateImage:image];
		[item setState:NSOnState];
		if ([_limitedProcessItems indexOfObject:item] == NSNotFound)
			[_limitedProcessItems addObject:item];
		if (! allLimitsPaused)
			proc_cpulim_resume();
	}
	
	if ([pauseItem isEnabled] != pauseItemIsEnabled)
		[pauseItem setEnabled:pauseItemIsEnabled];
}


/*
 *
 */
- (void)selectProcessMenuAction:(id)sender {
	CMMenuItem *item = (CMMenuItem *)sender;
	AppInspector *appInspector = [self appInspector];
	NSPopover *popover = [appInspector popover];

	if ([popover isShown]) {
		CMMenuItem *attachedToItem = [appInspector attachedToItem];
		if ([attachedToItem state] == NSMixedState)
			[attachedToItem setState:NSOffState];

		if (attachedToItem == item) {
			[popover setAnimates:YES];
			[popover close];
			[[NSNotificationCenter defaultCenter] removeObserver:self
															name:CMMenuSuspendStatusDidChangeNotification
														  object:nil];
			[[item menu] setSuspendMenus:NO];
			[[item menu] setCancelsTrackingOnMouseEventOutsideMenus:YES];
			[appInspector setAttachedToItem:nil];
		} else {
			[appInspector setAttachedToItem:item];
			[[item menu] showPopover:popover forItem:item preferredEdge:NSMaxXEdge];
			if ([item state] == NSOffState)
				[item setState:NSMixedState];
		}
	} else {
		[appInspector setAttachedToItem:item];
		[[item menu] setSuspendMenus:YES];
		[[item menu] setCancelsTrackingOnMouseEventOutsideMenus:NO];
		[[item menu] showPopover:popover forItem:item preferredEdge:NSMaxXEdge];
		if ([item state] == NSOffState)
			[item setState:NSMixedState];
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(menuSuspendStatusDidChangeNotificationHandler:)
													 name:CMMenuSuspendStatusDidChangeNotification
												   object:nil];
	}
}


- (void)menuDidEndTrackingNotificationHandler:(NSNotification *)notification {
	NSPopover *popover = [[self appInspector] popover];
	if ([popover isShown]) {
		[popover close];
	}
}


- (void)menuSuspendStatusDidChangeNotificationHandler:(NSNotification *)notification {
	NSPopover *popover = [[self appInspector] popover];
	if ([popover isShown]) {
		[popover setAnimates:YES];
		[popover close];
		[[NSNotificationCenter defaultCenter] removeObserver:self
														name:CMMenuSuspendStatusDidChangeNotification
													  object:nil];
	}
}


- (void)userDefaultsDidChangeNotificationHandler:(NSNotification *)notification {
	_userDefaultsDidChange = YES;
}


/*
 *
 */
- (void)toggleLimiterMenuAction:(id)sender {
	CMMenuItem *item = (CMMenuItem *)sender;
	int state = [[item representedObject] intValue];

	if (state == ALL_LIMITS_PAUSED) {	// resume
		proc_cpulim_resume();
		gAPAllLimitsPaused = 0;
		[self performSelector:@selector(updateMenuItemWithTitle:)
				   withObject:@{ @"item" : item, @"title" : NSLocalizedString(@"Pause all limits", @"Menu Item") }
				   afterDelay:0.2];
		[item setRepresentedObject:[NSNumber numberWithBool:!ALL_LIMITS_PAUSED]];
		for (CMMenuItem *item in _limitedProcessItems) {
			[item setOnStateImage:[NSImage imageNamed:NSImageNameStatusAvailable]];
		}
	} else {	// pause
		proc_cpulim_suspend();
		gAPAllLimitsPaused = 1;
		[self performSelector:@selector(updateMenuItemWithTitle:)
				   withObject:@{ @"item" : item, @"title" : NSLocalizedString(@"Resume", @"Menu Item") }
				   afterDelay:0.2];
		[item setRepresentedObject:[NSNumber numberWithBool:ALL_LIMITS_PAUSED]];
		for (CMMenuItem *item in _limitedProcessItems) {
			[item setOnStateImage:[NSImage imageNamed:NSImageNameStatusPartiallyAvailable]];
		}
	}
}


/* Helper method to update menu item with new title after
	a certain delay */
- (void)updateMenuItemWithTitle:(NSDictionary *)itemAndTitle {
	CMMenuItem *item = [itemAndTitle objectForKey:@"item"];
	NSString *aString = [itemAndTitle objectForKey:@"title"];
	[item setTitle:aString];
}


/*
 *
 */
- (void)showAboutWindowMenuAction:(id)sender {
	if (! _aboutWindowConstroller) {
		_aboutWindowConstroller = [[APAboutWindowController alloc] init];
	}
	
	if (! [[_aboutWindowConstroller window] isVisible]) {
		NSRect screenFrame = [[NSScreen mainScreen] frame];
		NSRect windowFrame = [[_aboutWindowConstroller window] frame];
		[[_aboutWindowConstroller window] setFrameOrigin:NSMakePoint(((NSWidth(screenFrame) - NSWidth(windowFrame)) / 2), NSMaxY(screenFrame) - NSHeight(windowFrame) - 200)];
	}
	
	[_aboutWindowConstroller showWindow:nil];
}


/*
 *
 */
- (void)showPreferecesWindowMenuAction:(id)sender {
	if (! _preferencesWindowController) {
		_preferencesWindowController = [[APPreferencesController alloc] init];
	}
	
	if (! [[_aboutWindowConstroller window] isVisible]) {
		NSRect screenFrame = [[NSScreen mainScreen] frame];
		NSRect windowFrame = [[_preferencesWindowController window] frame];
		[[_preferencesWindowController window] setFrameOrigin:NSMakePoint(((NSWidth(screenFrame) - NSWidth(windowFrame)) / 2), NSMaxY(screenFrame) - NSHeight(windowFrame) - 200)];
	}
	
	[_preferencesWindowController showWindow:nil];
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


- (int)sortKey {
	return (_sortKey) ? _sortKey : APApplicationsSortedByName;
}


- (void)setSortKey:(int)sortKey {
	if (sortKey != APApplicationsSortedByName
		&& sortKey != APApplicationsSortedByPid) {
		NSLog(@"Provided sortKey does not exist");
		return;
	}
	
	if (_sortKey != sortKey) {
		_sortKey = sortKey;
		if ([_runningApplications count] == 0)
			return;
	}
}

@end
