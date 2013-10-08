//
//  AppDelegate.h
//  cpulim
//
//  Created by Maksym on 5/19/13.
//  Copyright (c) 2013 Maksym Stefanchuk. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class StatusbarMenu;


@interface AppDelegate : NSObject <NSApplicationDelegate>
{
	@private
	NSStatusItem *_statusbarItem;
	IBOutlet StatusbarMenu *_statusbarMenu;
}

@property (assign) IBOutlet NSWindow *window;


@end
