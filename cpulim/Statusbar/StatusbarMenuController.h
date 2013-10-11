//
//  StatusbarMenuController.h
//  Ishimura
//
//  Created by Maksym on 10/11/13.
//  Copyright (c) 2013 Maksym Stefanchuk. All rights reserved.
//

#import <Foundation/Foundation.h>


@class CMMenu, CMMenuItem, AppInspector;

@interface StatusbarMenuController : NSObject
{
	@private;
	CMMenu *_mainMenu;
	NSMutableArray *_runningApps;
	NSString *_applicationSortingKey;
	AppInspector *_appInspector;
	CMMenuItem *_itemWithAttachedPopover;
}

- (CMMenu *)mainMenu;

// APApplicationsSortedByName is the default
- (NSString *)applicationSortingKey;
- (void)setApplicationSortingKey:(NSString *)sortingKey;


extern NSString *const APApplicationsSortedByName;
extern NSString *const APApplicationsSortedByPid;

@end
