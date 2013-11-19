//
//  AppDelegate.h
//  cpulim
//
//  Created by Maksym on 5/19/13.
//  Copyright (c) 2013 Maksym Stefanchuk. All rights reserved.
//

#import <AppKit/AppKit.h>

@class StatusbarMenu;
@class StatusbarItemController, StatusbarMenuController;

@interface AppDelegate : NSObject <NSApplicationDelegate>
{
	@private
	IBOutlet StatusbarMenu *_statusbarMenu;
	
	StatusbarItemController *_statusbarItemController;
	StatusbarMenuController *_statusbarMenuController;
}

@property (assign) IBOutlet NSWindow *window;

- (IBAction)toggleMainMenu:(id)sender;


@end
