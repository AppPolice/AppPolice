//
//  AppInspectorController.h
//  Ishimura
//
//  Created by Maksym on 7/2/13.
//  Copyright (c) 2013 Maksym Stefanchuk. All rights reserved.
//

#import <AppKit/AppKit.h>
//#import "ChromeMenu.h"
@class CMMenuItem;

@interface AppInspectorController : NSObject <NSPopoverDelegate>
{
	IBOutlet NSPopover *popover;
	IBOutlet NSViewController *popoverViewController;
	IBOutlet NSView *popoverView;
	IBOutlet NSWindow *detachedWindow;
}

- (void)showAppDetailsPopoverRelativeTo:(NSView *)view;
- (NSPopover *)popover;

- (IBAction)asdf:(id)sender;

@property (assign) CMMenuItem *relativeItem;


@end
