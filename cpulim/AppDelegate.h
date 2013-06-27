//
//  AppDelegate.h
//  cpulim
//
//  Created by Maksym on 5/19/13.
//  Copyright (c) 2013 Maksym Stefanchuk. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class StatusbarMenuController;

@class TestView1;

@interface AppDelegate : NSObject <NSApplicationDelegate, NSTableViewDataSource, NSTableViewDelegate>
{
	NSStatusItem *statusbarItem;
	IBOutlet StatusbarMenuController *statusbarMenuController;
	
//	IBOutlet NSTableView *_tableView;
//	IBOutlet TestView1 *_testView1;
}

@property (assign) IBOutlet NSWindow *window;


//- (IBAction)someAction4:(NSButton *)sender;

@end
