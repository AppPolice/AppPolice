//
//  StatusbarMenuController.h
//  Ishimura
//
//  Created by Maksym on 5/28/13.
//  Copyright (c) 2013 Maksym Stefanchuk. All rights reserved.
//

#import <Foundation/Foundation.h>
//#import "MyTableView.h"
//#import "MySubmenuView.h"

@class MySubmenuView, MyTableView;

@interface StatusbarMenuController : NSObject<NSTableViewDataSource, NSTableViewDelegate>
{
	BOOL sortApplications; // it's temporary here
@private
	IBOutlet NSMenu *statusbarMenu;
//	NSMenu *appsSubmenu;

	IBOutlet MySubmenuView *appSubmenuView;
	IBOutlet MyTableView *appListTableView;
	
	IBOutlet NSView *secondSubmenuView;

	NSMutableArray *runningApplications;
	NSMutableArray *tableContents;
}

@property (assign) NSMenu *statusbarMenu;

- (void)linkStatusbarItemWithMenu;
- (IBAction)activateSelf:(id)sender;

- (void)sortApplicationsByNameAndReload:(BOOL)reload;

@end

