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
	void (^_popoverDidClosehandler)(void);
	
	IBOutlet NSTextField *_applicationNameTextfield;
	IBOutlet NSTextField *_applicationUserTextfield;
	IBOutlet NSTextField *_cpuLoadTextfield;
	IBOutlet NSTextField *_sliderTopTextfield;
	IBOutlet NSTextField *_sliderTopRightTextField;
	IBOutlet NSTextField *_sliderLeftTextfield;
	IBOutlet NSTextField *_sliderMiddleTextfield;
	IBOutlet NSTextField *_sliderRightTextfield;
//	IBOutlet NSTextField *_sliderBottomTextfield;
	IBOutlet NSSlider *_slider;
	IBOutlet NSLevelIndicator *_levelIndicator;
	NSPopover *_hintPopover;
}

// temp method
- (void)showPopoverRelativeTo:(NSView *)view;
- (NSPopover *)popover;
- (void)setPopverDidCloseHandler:(void (^)(void))handler;

// as part of AppLimitHintViewDelegate
//- (void)mouseUp:(id)sender;

@property (assign) CMMenuItem *attachedToItem;


@end
