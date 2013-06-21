//
//  StatusbarMenuController.h
//  Ishimura
//
//  Created by Maksym on 5/28/13.
//  Copyright (c) 2013 Maksym Stefanchuk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MyTableView.h"
#import "MySubmenuView.h"
#import "MyMenu.h"

@interface StatusbarMenuController : NSObject<NSTableViewDataSource, NSTableViewDelegate>
{
	IBOutlet NSMenu *statusbarMenu;
	NSMenu *appsSubmenu;
//	IBOutlet NSMenu *statusbarMenu;
//	NSMenu *appsSubmenu;

	IBOutlet MySubmenuView *appsSubmenuView;
//	IBOutlet NSView *appsSubmenuView;
	
//	IBOutlet NSTableView *menuTableView;
	IBOutlet MyTableView *menuTableView;
	NSMutableArray *tableContents;
	
	IBOutlet NSView *secondSubmenuView;
}

@property (assign) NSMenu *statusbarMenu;

- (void)populateMenuWithRunningApps;
- (IBAction)clickButton1:(id)sender;

@end

