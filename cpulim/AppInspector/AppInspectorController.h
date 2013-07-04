//
//  AppInspectorController.h
//  Ishimura
//
//  Created by Maksym on 7/2/13.
//  Copyright (c) 2013 Maksym Stefanchuk. All rights reserved.
//

#import <AppKit/AppKit.h>

@interface AppInspectorController : NSObject <NSPopoverDelegate>
{
	IBOutlet NSPopover *popover;
	IBOutlet NSViewController *popoverViewController;
	IBOutlet NSView *popoverView;
}

- (void)showAppDetailsPopoverRelativeTo:(NSView *)view;

@end
