//
//  StatusbarMenuController.h
//  Ishimura
//
//  Created by Maksym on 10/11/13.
//  Copyright (c) 2013 Maksym Stefanchuk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ChromeMenu/ChromeMenu.h>

#define APApplicationsSortedByName 0
#define APApplicationsSortedByPid 1

@class AppInspector;

@interface StatusbarMenuController : NSObject<CMMenuDelegate>
{
	@private;
	CMMenu *_mainMenu;
	NSMutableArray *_runningApplications;
	NSMutableArray *_runningSystemProcesses;
	int _sortKey;
	AppInspector *_appInspector;
}

- (CMMenu *)mainMenu;

// Default is |APApplicationsSortedByName|
- (int)sortKey;
- (void)setSortKey:(int)sortKey;

@end
