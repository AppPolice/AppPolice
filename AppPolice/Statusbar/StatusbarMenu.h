//
//  StatusbarMenuController.h
//  Ishimura
//
//  Created by Maksym on 5/28/13.
//  Copyright (c) 2013 Maksym Stefanchuk. All rights reserved.
//

#import <AppKit/AppKit.h>

@class MySubmenuView, MyTableView, AppInspector;

@interface StatusbarMenu : NSObject<NSTableViewDataSource, NSTableViewDelegate>
{
	BOOL sortApplications; // it's temporary here
@private
	IBOutlet NSMenu *_mainMenu;
	
//	NSMutableArray *runningApplications;
}

@property (assign) NSMenu *mainMenu;


- (IBAction)addMenu:(id)sender;


@end

