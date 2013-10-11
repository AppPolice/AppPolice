//
//  StatusbarMenuController.h
//  Ishimura
//
//  Created by Maksym on 5/28/13.
//  Copyright (c) 2013 Maksym Stefanchuk. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MySubmenuView, MyTableView, AppInspector;

@interface StatusbarMenu : NSObject<NSTableViewDataSource, NSTableViewDelegate>
{
	BOOL sortApplications; // it's temporary here
@private
	IBOutlet NSMenu *_mainMenu;
	IBOutlet NSView *statusbarItemView;
	IBOutlet NSPanel *myPanel;
	AppInspector *_appInspector;
//	NSMenu *appsSubmenu;

	IBOutlet MySubmenuView *appSubmenuView;
	IBOutlet MyTableView *appListTableView;
	IBOutlet MyTableView *testTable;
	
	IBOutlet NSView *secondSubmenuView;

	NSMutableArray *runningApplications;
	NSMutableArray *tableContents;
}

@property (assign) NSMenu *mainMenu;
@property (assign) NSView *statusbarItemView;
@property (assign) NSPanel *myPanel;
@property (readonly) AppInspector *appInspector;

- (void)linkStatusbarItemWithMenu;
- (IBAction)activateSelf:(id)sender;
- (IBAction)addMenu:(id)sender;

- (void)sortApplicationsByNameAndReload:(BOOL)reload;

@end

