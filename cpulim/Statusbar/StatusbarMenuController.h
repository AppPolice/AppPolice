//
//  StatusbarMenuController.h
//  Ishimura
//
//  Created by Maksym on 10/11/13.
//  Copyright (c) 2013 Maksym Stefanchuk. All rights reserved.
//

#import <Foundation/Foundation.h>

#define APApplicationsSortedByName 0
#define APApplicationsSortedByPid 1

@class CMMenu, CMMenuItem, AppInspector;

@interface StatusbarMenuController : NSObject
{
	@private;
	CMMenu *_mainMenu;
	NSMutableArray *_runningApps;
	int _applicationSortKey;
	AppInspector *_appInspector;
	CMMenuItem *_itemWithAttachedPopover;
}

- (CMMenu *)mainMenu;

// APApplicationsSortedByName is the default
- (int)applicationSortKey;
- (void)setApplicationSortKey:(int)sortKey;

//extern NSString *const APApplicationsSortedByName;
//extern NSString *const APApplicationsSortedByPid;


@end
