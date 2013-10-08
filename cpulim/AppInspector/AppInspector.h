//
//  AppInspectorController.h
//  Ishimura
//
//  Created by Maksym on 7/2/13.
//  Copyright (c) 2013 Maksym Stefanchuk. All rights reserved.
//

//#import <AppKit/AppKit.h>
@class NSObject, NSView, NSViewController, NSPopover, NSSlider, NSLevelIndicator;
@class CMMenuItem;
@protocol NSPopoverDelegate;

@interface AppInspector : NSObject <NSPopoverDelegate>
{
	IBOutlet NSPopover *_popover;
	IBOutlet NSViewController *_popoverViewController;
	IBOutlet NSView *_popoverView;
//	IBOutlet NSWindow *detachedWindow;
	void (^_handler)(void);
	
	IBOutlet NSSlider *_slider;
	IBOutlet NSLevelIndicator *_levelIndicator;
}

// temp method
- (void)showPopoverRelativeTo:(NSView *)view;
- (NSPopover *)popover;
- (void)setPopverDidCloseHandler:(void (^)(void))handler;

@property (assign) CMMenuItem *attachedToItem;


@end
