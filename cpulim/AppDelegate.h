//
//  AppDelegate.h
//  cpulim
//
//  Created by Maksym on 5/19/13.
//  Copyright (c) 2013 Maksym Stefanchuk. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class StatusbarMenuController;


@interface AppDelegate : NSObject <NSApplicationDelegate>
{
	NSStatusItem *statusbarItem;
	IBOutlet StatusbarMenuController *statusbarMenuController;
}

@property (assign) IBOutlet NSWindow *window;


@end
