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
#include "app_inspector_c.h"
#include "proc_cpulim.h"

//NSString *const APApplicationsSortedByName = @"APApplicationsSortedByName";
//NSString *const APApplicationsSortedByPid = @"APApplicationsSortedByPid";

static const int gShowAllProcesses = 1;
static const int gShowOtherUsersProcesses = 0;

#define kProcPidKey @"pid"
#define kProcNameKey @"name"
#define kNotFoundAppIndexesKey @"nfAppIdx"
#define kNotFoundSysProcIndexesKey @"nfSysIdx"
#define kNewSysProcIndexesKey @"newSysIdx"
#define PROCESS_NOT_LIMITED 0.0
#define ALL_LIMITS_PAUSED YES

static const int kPidFoundMask = 1 << (8 * sizeof(int) - 1);
//#define kPidFoundMask (1 << (8 * sizeof(int) - 1))
#define PID_MARK_FOUND(pid) (pid |= kPidFoundMask)
#define PID_UNMARK(pid) (pid &= ~kPidFoundMask)
#define PID_IS_MARKED(pid) ((pid & kPidFoundMask) ? 1 : 0)
#define PROC_NAME_MAXLEN 128



@interface StatusbarMenuController ()
{
	NSMutableArray *_limitedProcessItems;
}

- (void)setupMenus;
- (void)populateMenuWithRunningApplications:(CMMenu *)menu;
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
// Helper for |APAppInspectorProcessDidChangeLimit| notification handler
//- (void)processPid:(NSNumber *)pid didChangeLimit:(float)limit;
// Menu actions
- (void)selectProcessMenuItemAction:(id)sender;
- (void)toggleLimiterMenuAction:(id)sender;
/*!
 @discussion CMMenu is built to instantly update when either title,
	image, etc. is changed. This method is used to delay title update
	after Action performs and menu is hidden.
*/
- (void)updateMenuItemWithTitle:(NSDictionary *)itemAndTitle;
- (void)terminateApplicationMenuAction:(id)sender;

@end



@implementation StatusbarMenuController

- (id)init {
	self = [super init];
	if (self) {
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
	_mainMenu = [[CMMenu alloc] initWithTitle:@"MainMenu"];
	CMMenuItem *item;
	item = [[[CMMenuItem alloc] initWithTitle:@"Running Apps" action:NULL] autorelease];
	CMMenu *runningAppsMenu = [[[CMMenu alloc] initWithTitle:@"Running Apps Menu"] autorelease];
	[runningAppsMenu setDelegate:self];
	[runningAppsMenu setCancelsTrackingOnAction:NO];
//	[runningAppsMenu setCancelsTrackingOnMouseEventOutsideMenus:NO];
	[item setSubmenu:runningAppsMenu];
	[_mainMenu addItem:item];
	
	item = [[[CMMenuItem alloc] initWithTitle:@"Pause all limits" action:@selector(toggleLimiterMenuAction:)] autorelease];
	[item setTarget:self];
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
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(menuDidEndTrackingNotificationHandler:)
												 name:CMMenuDidEndTrackingNotification
											   object:nil];
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
	[self sortApplicationsByKey:[self sortKey]];
//	[self sortApplicationsByKey:APApplicationsSortedByPid];
	

	NSUInteger i;
	NSUInteger elementsCount = [_runningApplications count];
	pid_t shared_pid = getpid();
	NSUInteger shared_pid_index;
	CMMenuItem *item;
	NSImage *onStateImageActive = [NSImage imageNamed:NSImageNameStatusAvailable];
	NSImage *onStateImagePaused = [NSImage imageNamed:NSImageNameStatusPartiallyAvailable];
	[onStateImageActive setSize:NSMakeSize(12, 12)];
	[onStateImagePaused setSize:NSMakeSize(12, 12)];
	
	// Show Applications delimiter
	if (gShowAllProcesses) {
		item = [[[CMMenuItem alloc] initWithTitle:@"Applications" action:NULL] autorelease];
		[item setEnabled:NO];
		[menu addItem:item];
	}

	// --------------------------------------------------
	//		Populate with Applications
	// --------------------------------------------------
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
				
		item = [[[CMMenuItem alloc] initWithTitle:[app localizedName] icon:icon action:@selector(selectProcessMenuItemAction:)] autorelease];
		[item setTarget:self];
		[item setOnStateImage:onStateImageActive];
		if (gShowAllProcesses)
			[item setIndentationLevel:1];
//		NSImage *mixedStateImage = [NSImage imageNamed:NSImageNameStatusNone];
//		[mixedStateImage setSize:NSMakeSize(12, 12)];
//		[item setMixedStateImage:mixedStateImage];
		[item setRepresentedObject:appInfo];
		[menu addItem:item];
	}
	
	// Remove ourselves from running applications array
	[_runningApplications removeObjectAtIndex:shared_pid_index];
	
	// -----------------------------------------------------
	//		Populate with System processes if option is set
	// -----------------------------------------------------
	if (gShowAllProcesses) {
		item = [[[CMMenuItem alloc] initWithTitle:@"System" action:NULL] autorelease];
		[item setEnabled:NO];
		[menu addItem:item];
	
		if (! _runningSystemProcesses)
			_runningSystemProcesses = [[NSMutableArray alloc] init];

		
		NSDictionary *updateIndexes = [self updateRunningProcesses];
		NSIndexSet *notfoundAppIndexes = [updateIndexes objectForKey:kNotFoundAppIndexesKey];
		NSIndexSet *newSysProcIndexes = [updateIndexes objectForKey:kNewSysProcIndexesKey];
		
		if ([notfoundAppIndexes count]) {
			// Because of first menu item "Applications" shift indexes by 1
			NSMutableIndexSet *shiftedIndexes = [NSMutableIndexSet indexSet];
			[notfoundAppIndexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
				[shiftedIndexes addIndex:(idx + 1)];
			}];
			[menu removeItemsAtIndexes:shiftedIndexes];
		}
		
		if ([newSysProcIndexes count]) {
			NSImage *genericIcon = [[NSWorkspace sharedWorkspace] iconForFile:@"/bin/ls"];
			[_runningSystemProcesses enumerateObjectsAtIndexes:newSysProcIndexes options:0 usingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
				NSDictionary *procInfo = (NSDictionary *)obj;
				NSMutableDictionary *appInfo = [NSMutableDictionary dictionaryWithObjectsAndKeys:
												[procInfo objectForKey:kProcNameKey], APApplicationInfoNameKey,
												genericIcon, APApplicationInfoIconKey,
												[procInfo objectForKey:kProcPidKey], APApplicationInfoPidKey,
												[NSNumber numberWithFloat:0], APApplicationInfoLimitKey,
												nil];
				
				CMMenuItem *item = [[[CMMenuItem alloc] initWithTitle:[procInfo objectForKey:kProcNameKey] icon:genericIcon action:@selector(selectProcessMenuItemAction:)] autorelease];
				[item setTarget:self];
//				NSImage *onStateImage = [NSImage imageNamed:NSImageNameStatusAvailable];
//				[onStateImage setSize:NSMakeSize(12, 12)];
				[item setOnStateImage:onStateImageActive];
				[item setIndentationLevel:1];
				[item setRepresentedObject:appInfo];
				[menu addItem:item];
			}];
		}
		
//		NSLog(@"not found indexes: %@", updateIndexes);
	}
	

	/* temp */ {
		NSMutableDictionary *appInfo = [NSMutableDictionary dictionaryWithObjectsAndKeys:
										@"Some really long name for some unexistant applicaton", APApplicationInfoNameKey,
										[NSImage imageNamed:NSImageNameBonjour], APApplicationInfoIconKey,
										[NSNumber numberWithInt:999], APApplicationInfoPidKey,
										[NSNumber numberWithFloat:0], APApplicationInfoLimitKey, nil];
		
		CMMenuItem *item = [[[CMMenuItem alloc] initWithTitle:@"Some really long name for some unexistant applicaton" icon:[NSImage imageNamed:NSImageNameBonjour] action:@selector(selectProcessMenuItemAction:)] autorelease];
		[item setTarget:self];
		[item setRepresentedObject:appInfo];
		[menu addItem:item];
	} // temp
	

	NSNotificationCenter *notificationCenter = [workspace notificationCenter];
	[notificationCenter addObserver:self selector:@selector(appLaunchedNotificationHandler:) name:NSWorkspaceDidLaunchApplicationNotification object:nil];
	[notificationCenter addObserver:self selector:@selector(appTerminatedNotificationHandler:) name:NSWorkspaceDidTerminateApplicationNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(processDidChangeLimitNotificationHandler:) name:APAppInspectorProcessDidChangeLimit object:nil];
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
		int pid = [(NSNumber *)[[_runningSystemProcesses objectAtIndex:idx] objectForKey:kProcPidKey] intValue];
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

	if (!gShowOtherUsersProcesses)
		shared_uid = getuid();


	for (n = 0; n < numpids; ++n) {
		if (proc_pids[n] == 0) // reached the bottom pid
			break;

		if (PID_IS_MARKED(proc_pids[n]) || proc_pids[n] == shared_pid)
			continue;
		
		if (!gShowOtherUsersProcesses) {
			uid_t proc_uid = get_proc_uid(proc_pids[n]);
//			printf("skipg pid: %d\n", proc_pids[n]);
			if (proc_uid != shared_uid)
				continue;
		}
		
		//			int pid = PID_UNMARK(proc_pids[n]);
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
	free(namebuffer);
	free(pathbuffer);
	free(proc_pids);
	
	
	if (shownSystemProcessesCount) {
		for (insert_index_i = 0; insert_index_i < insert_indexes_num; ++insert_index_i)
			[newSysProcIndexes addIndex:(NSUInteger)insert_indexes[insert_index_i]];
		free(insert_indexes);
	} else {
		[self sortSystemProcessesByKey:[self sortKey]];
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
		while (i < elementsCount && [name localizedCompare:[[_runningSystemProcesses objectAtIndex:i] objectForKey:kProcNameKey]] == NSOrderedDescending)
			++i;
		index = i;
		
	} else if (sortKey == APApplicationsSortedByPid) {
		NSNumber *pid = [processInfo objectForKey:kProcPidKey];
		NSUInteger i = 0;
		while (i < elementsCount && [pid compare:[[_runningSystemProcesses objectAtIndex:i] objectForKey:kProcPidKey]] == NSOrderedDescending)
			++i;
		index = i;
	}
	
	[_runningSystemProcesses insertObject:processInfo atIndex:index];
	
	return index;
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
- (void)sortSystemProcessesByKey:(int)sortKey {
	NSSortDescriptor *descriptor;
	
	if (! [_runningSystemProcesses count])
		return;
	
	if (sortKey == APApplicationsSortedByName) {
		descriptor = [[NSSortDescriptor alloc] initWithKey:kProcNameKey ascending:YES selector:@selector(localizedCompare:)];
	} else if (sortKey == APApplicationsSortedByPid) {
		descriptor = [[NSSortDescriptor alloc] initWithKey:kProcPidKey ascending:YES];
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
	NSDictionary *updateIndexSets = [self updateRunningProcesses];
	NSIndexSet *notfoundAppIndexes = [updateIndexSets objectForKey:kNotFoundAppIndexesKey];
	NSIndexSet *notfoundSysProcIndexes = [updateIndexSets objectForKey:kNotFoundSysProcIndexesKey];
	NSIndexSet *newSysProcIndexes = [updateIndexSets objectForKey:kNewSysProcIndexesKey];
	NSLog(@"update indexes: %@", updateIndexSets);
	
	
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
//			NSDictionary *representedObj = [(CMMenuItem *)obj representedObject];
//			if (representedObj)
//				[self processPid:[representedObj objectForKey:APApplicationInfoPidKey] didChangeLimit:PROCESS_NOT_LIMITED];
			[self processOfItem:(CMMenuItem *)obj didChangeLimit:PROCESS_NOT_LIMITED];
		}];
		
		[menu removeItemsAtIndexes:shiftedIndexes];
	}
	
	if ([newSysProcIndexes count]) {
		NSUInteger offset = [_runningApplications count];
		if (gShowAllProcesses)
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
			
			CMMenuItem *item = [[[CMMenuItem alloc] initWithTitle:[procInfo objectForKey:kProcNameKey] icon:genericIcon action:@selector(selectProcessMenuItemAction:)] autorelease];
			[item setTarget:self];
			NSImage *onStateImage = [NSImage imageNamed:NSImageNameStatusAvailable];
			[onStateImage setSize:NSMakeSize(12, 12)];
			[item setOnStateImage:onStateImage];
			[item setRepresentedObject:appInfo];
			if (gShowAllProcesses)
				[item setIndentationLevel:1];
			[menu insertItem:item atIndex:(idx + offset) animate:NO];
		}];
	}
	
//	[notfoundSysProcIndexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
//		NSLog(@"notfound proc: %@", [_runningSystemProcesses objectAtIndex:idx]);
//	}];
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
	
	int sortKey = [self sortKey];
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
		// TODO: take into account the Asc/Desc
//		index = elementsCount;
	}
	
//	NSLog(@"inserting at index: %lu", index);
	
	[_runningApplications insertObject:app atIndex:index];
	// If showing all processes the first menu item is "Applications". Offset index by 1.
	if (gShowAllProcesses)
		++index;
	
	NSMutableDictionary *appInfo = [NSMutableDictionary dictionaryWithObjectsAndKeys:
									[app localizedName], APApplicationInfoNameKey,
									[app icon], APApplicationInfoIconKey,
									[NSNumber numberWithInt:[app processIdentifier]], APApplicationInfoPidKey,
									[NSNumber numberWithFloat:0], APApplicationInfoLimitKey, nil];
	
	CMMenuItem *item = [[[CMMenuItem alloc] initWithTitle:[app localizedName] icon:[app icon] action:@selector(selectProcessMenuItemAction:)] autorelease];
	[item setTarget:self];
	NSImage *onStateImage = [NSImage imageNamed:NSImageNameStatusAvailable];
	[onStateImage setSize:NSMakeSize(12, 12)];
	[item setOnStateImage:onStateImage];
	[item setRepresentedObject:appInfo];
	if (gShowAllProcesses)
		[item setIndentationLevel:1];
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
			// If showing all process, the first menu item is "Applications". Shift index by 1
			NSInteger menuIndex = (gShowAllProcesses) ? (NSInteger)(index + 1) : (NSInteger)index;
			
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
//			NSDictionary *representedObj = [item representedObject];
//			if (representedObj) {
//				NSNumber *pid = [representedObj objectForKey:APApplicationInfoPidKey];
//				[self processPid:pid didChangeLimit:0.0];
//			}
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
//	NSNumber *pid = [userInfo objectForKey:@"pid"];
//	float limit = [(NSNumber *)[userInfo objectForKey:@"limit"] floatValue];
//	[self processPid:pid didChangeLimit:limit];

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
	BOOL newState = YES;
	BOOL allLimitsPaused = [[pauseItem representedObject] boolValue];
	
	if (limit == PROCESS_NOT_LIMITED) {
		[item setState:NSMixedState];
		[_limitedProcessItems removeObject:item];
		if (! [_limitedProcessItems count])
			newState = NO;
	} else {
		NSImage *image = (allLimitsPaused) ? [NSImage imageNamed:NSImageNameStatusPartiallyAvailable] : [NSImage imageNamed:NSImageNameStatusAvailable];
		if (! [[item onStateImage] isEqual:image])
			[item setOnStateImage:image];
		[item setState:NSOnState];
		if ([_limitedProcessItems indexOfObject:item] == NSNotFound)
			[_limitedProcessItems addObject:item];
//		[pauseItem setTitle:@"Pause all limits"];
//		[pauseItem setRepresentedObject:[NSNumber numberWithInt:!ALL_LIMITS_PAUSED]];
		if (! allLimitsPaused)
			proc_cpulim_resume();
	}
	
	if ([pauseItem isEnabled] != newState)
		[pauseItem setEnabled:newState];
	
}


/*
 *
 */
- (void)selectProcessMenuItemAction:(id)sender {
	CMMenuItem *item = (CMMenuItem *)sender;
	AppInspector *appInspector = [self appInspector];
//	NSDictionary *inspectorAppInfo = [appInspector applicationInfo];
	NSPopover *popover = [appInspector popover];

//	if (_itemWithAttachedPopover && [_itemWithAttachedPopover isEqual:item] && [popover isShown]) {
	if ([popover isShown]) {
		CMMenuItem *attachedToItem = [appInspector attachedToItem];
		if ([attachedToItem state] == NSMixedState)
			[attachedToItem setState:NSOffState];

//		[popover setBehavior:NSPopoverBehaviorApplicationDefined];
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
//			[popover setBehavior:NSPopoverBehaviorTransient];
			if ([item state] == NSOffState)
				[item setState:NSMixedState];
		}
	} else {
//		NSMutableDictionary *appInfo = [item representedObject];
//		[appInspector setApplicationInfo:appInfo];
//		NSLog(@"popover behavior: %ld", [popover behavior]);
		[appInspector setAttachedToItem:item];
		[[item menu] setSuspendMenus:YES];
		[[item menu] setCancelsTrackingOnMouseEventOutsideMenus:NO];
//		[popover setBehavior:NSPopoverBehaviorApplicationDefined];
		[[item menu] showPopover:popover forItem:item preferredEdge:NSMaxXEdge];
		if ([item state] == NSOffState)
			[item setState:NSMixedState];
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(menuSuspendStatusDidChangeNotificationHandler:)
													 name:CMMenuSuspendStatusDidChangeNotification
												   object:nil];
//		[popover setBehavior:NSPopoverBehaviorTransient];

//		[item setEnabled:NO];
//		_itemWithAttachedPopover = item;
	}
}


- (void)menuDidEndTrackingNotificationHandler:(NSNotification *)notification {
	NSPopover *popover = [[self appInspector] popover];
	if ([popover isShown]) {
		[popover close];
	}
}


- (void)menuSuspendStatusDidChangeNotificationHandler:(NSNotification *)notification {
//	NSLog(@"suspend notification: %@", notification);
	NSPopover *popover = [[self appInspector] popover];
	if ([popover isShown]) {
		[popover setAnimates:YES];
		[popover close];
		[[NSNotificationCenter defaultCenter] removeObserver:self
														name:CMMenuSuspendStatusDidChangeNotification
													  object:nil];
	}
}


/*
 *
 */
- (void)toggleLimiterMenuAction:(id)sender {
	CMMenuItem *item = (CMMenuItem *)sender;
	int state = [[item representedObject] intValue];

	if (state == ALL_LIMITS_PAUSED) {	// resume
		proc_cpulim_resume();
//		[item setTitle:@"Pause all limits"];
		[self performSelector:@selector(updateMenuItemWithTitle:)
				   withObject:@{ @"item" : item, @"title" : @"Pause all limits" }
				   afterDelay:0.2];
		[item setRepresentedObject:[NSNumber numberWithBool:!ALL_LIMITS_PAUSED]];
		for (CMMenuItem *item in _limitedProcessItems) {
			[item setOnStateImage:[NSImage imageNamed:NSImageNameStatusAvailable]];
		}
	} else {	// pause
		proc_cpulim_suspend();
//		[item setTitle:@"Resume"];
		[self performSelector:@selector(updateMenuItemWithTitle:)
				   withObject:@{ @"item" : item, @"title" : @"Resume" }
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
	if ( sortKey != APApplicationsSortedByName
	  && sortKey != APApplicationsSortedByPid) {
		NSLog(@"Provided sortKey does not exist");
		return;
	}
	
	if (_sortKey != sortKey) {
		_sortKey = sortKey;

		// update menu here
		
	}
}

@end
