//
//  APPreferencesController.m
//  AppPolice
//
//  Created by Maksym on 20/11/13.
//  Copyright (c) 2013 Maksym Stefanchuk. All rights reserved.
//

#import "APPreferencesController.h"

@implementation APPreferencesController

- (id)init {
	return [super initWithWindowNibName:@"APPreferencesWindow"];
}


- (void)windowDidLoad {
    [super windowDidLoad];
	
	NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
	NSInteger sortByValue = [preferences integerForKey:@"APSortBy"];
	BOOL orderAsc = [preferences boolForKey:@"APOrderAsc"];
	BOOL showSystemProcesses = [preferences boolForKey:@"APShowSystemProcesses"];
	BOOL launchAtLogin = [preferences boolForKey:@"APLaunchAtLogin"];
	LSSharedFileListItemRef item = [self copyLoginItem];
	
	[[self sortByMatrix] selectCellAtRow:sortByValue column:0];
	[[self orderMatrix] selectCellAtRow:(orderAsc ? 0 : 1) column:0];
	[[self showSystemProcessesButton] setIntegerValue:(showSystemProcesses) ? 1 : 0];
	// Synchronize "Lauch at login" with real presence of login item in Mac OS X prefs
	if (item) {
		[[self launchAtLoginButton] setIntegerValue:1];
		if (! launchAtLogin) {
			[preferences setBool:YES forKey:@"APLaunchAtLogin"];
		}
		CFRelease(item);
	} else {
		[[self launchAtLoginButton] setIntegerValue:0];
		if (launchAtLogin)
			[preferences setBool:NO forKey:@"APLaunchAtLogin"];
	}
	
//	NSLog(@"showsys: %d", showSystemProcesses);
//	NSLog(@"launch: %d", launchAtLogin);
//	NSLog(@"prefs: %@", [preferences dictionaryRepresentation]);
}


- (IBAction)changeSortByPreferences:(id)sender {
	NSMatrix *matrix = (NSMatrix *)sender;
	NSNumber *value = [NSNumber numberWithInteger:[matrix selectedRow]];
	NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
	[preferences setValue:value forKey:@"APSortBy"];
}


- (IBAction)changeOrderPreferences:(id)sender {
	NSMatrix *matrix = (NSMatrix *)sender;
	NSInteger value = [matrix selectedRow];
	NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
	[preferences setBool:(value == 0) forKey:@"APOrderAsc"];
}


- (IBAction)changeShowSystemProcessesPreferences:(id)sender {
	NSButton *button = (NSButton *)sender;
	NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
	[preferences setBool:([button intValue] == 1) forKey:@"APShowSystemProcesses"];
}


- (IBAction)changeLaunchAtLoginPreferences:(id)sender {
	NSButton *button = (NSButton *)sender;
	BOOL stateOn = ([button intValue] == 1);
	NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
	[preferences setBool:stateOn forKey:@"APLaunchAtLogin"];

	if (stateOn) {
		(void) [self addLoginItem];
	} else {
		[self removeLoginItem];
	}
}


- (BOOL)addLoginItem {
	LSSharedFileListRef fileList = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
	if (fileList) {
		NSURL *bundleURL = [[NSBundle mainBundle] bundleURL];
		LSSharedFileListItemRef listItem = LSSharedFileListInsertItemURL(fileList, kLSSharedFileListItemLast, NULL, NULL, (CFURLRef)bundleURL, NULL, NULL);
		CFRelease(fileList);
		if (listItem) {
			CFRelease(listItem);
			return YES;
		}
	}
	
	return NO;
}

- (void)removeLoginItem {
	LSSharedFileListRef fileList;
	LSSharedFileListItemRef item;
	
	item = [self copyLoginItem];
	if (item) {
		fileList = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
		(void) LSSharedFileListItemRemove(fileList, item);
		CFRelease(fileList);
		CFRelease(item);
	}
}


- (LSSharedFileListItemRef)copyLoginItem {
	LSSharedFileListItemRef retRef = NULL;
	LSSharedFileListRef fileList;
	CFURLRef itemURLRef;
	NSURL *bundleURL;
	CFArrayRef arrayOfItems;
	CFIndex count;
	CFIndex i;
	
	fileList = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
	if (fileList) {
		arrayOfItems = LSSharedFileListCopySnapshot(fileList, NULL);
		count = CFArrayGetCount(arrayOfItems);
		if (count) {
			bundleURL = [[NSBundle mainBundle] bundleURL];
			for (i = 0; i < count; ++i) {
				LSSharedFileListItemRef item = (LSSharedFileListItemRef)CFArrayGetValueAtIndex(arrayOfItems, i);
				if ((LSSharedFileListItemResolve(item, 0, &itemURLRef, NULL) == noErr)) {
					if ([bundleURL isEqual:(NSURL *)itemURLRef]) {
						CFRetain(item);
						retRef = item;
						CFRelease(itemURLRef);
						break;
					}
					CFRelease(itemURLRef);
				}
			}
		}
		
//		CFStringRef description = CFCopyDescription(arrayOfItems);
//		NSLog(@"list: %@", (NSString *)description);
		
		CFRelease(arrayOfItems);
		CFRelease(fileList);
	}
	
	return retRef;
}

@end
