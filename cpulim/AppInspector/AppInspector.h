//
//  AppInspectorController.h
//  Ishimura
//
//  Created by Maksym on 7/2/13.
//  Copyright (c) 2013 Maksym Stefanchuk. All rights reserved.
//

//#import <AppKit/AppKit.h>

#define APApplicationInfoNameKey @"appInfoNameKey"
#define APApplicationInfoIconKey @"appInfoIconKey"
#define APApplicationInfoPidKey @"appInfoPidKey"
#define APApplicationInfoLimitKey @"appInfoLimitKey"
#define APApplicationInfoUserKey @"appInfoUserKey"

#define APAppInspectorPopoverDidShow @"appInspectorPopoverDidShow"
#define APAppInspectorProcessDidChangeLimit @"appInspectorProcDidChangeLim"


@class NSObject, NSView, NSViewController, NSPopover, NSSlider, NSLevelIndicator;
@class CMMenuItem;
@protocol NSPopoverDelegate;

@interface AppInspector : NSObject <NSPopoverDelegate>
{
	@private
//	NSMutableDictionary *_applicationInfo;
	CMMenuItem *_attachedToItem;
	IBOutlet NSPopover *_popover;
	IBOutlet NSViewController *_popoverViewController;
	IBOutlet NSView *_popoverView;
//	IBOutlet NSWindow *detachedWindow;
	void (^_popoverDidClosehandler)(void);
	NSTimer *_cpuTimer;
	struct {
		uint64_t cputime;
		uint64_t timestamp;
	} _cpuTime;
	
	IBOutlet NSImageView *_applicationIcon;
	IBOutlet NSTextField *_applicationNameTextfield;
	IBOutlet NSTextField *_applicationUserTextfield;
	IBOutlet NSTextField *_applicationCPUTextfield;
	IBOutlet NSTextField *_sliderLimit1Textfield;
	IBOutlet NSTextField *_sliderLimit2Textfield;
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

@property (assign) NSMutableDictionary *applicationInfo;
@property (assign, nonatomic) CMMenuItem *attachedToItem;


@end
