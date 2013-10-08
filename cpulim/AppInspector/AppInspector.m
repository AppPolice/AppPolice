//
//  AppInspectorController.m
//  Ishimura
//
//  Created by Maksym on 7/2/13.
//  Copyright (c) 2013 Maksym Stefanchuk. All rights reserved.
//

#import "AppInspector.h"
#import "ChromeMenu.h"
//#import "AppLimitSlider.h"
#import "AppLimitSliderCell.h"


//@interface AppInspector ()
//{
//	NSTimer *_sliderMouseTrackingTimer;
//}
//
//@end


@implementation AppInspector

@synthesize attachedToItem;

- (id)init {
	self = [super init];
	if (self) {
		[NSBundle loadNibNamed:@"AppInspector" owner:self];
		[NSBundle loadNibNamed:@"PopoverContentView" owner:self];
	}
	return self;
}


- (void)awakeFromNib {
//	NSLog(@"%@ awakeFromNib", [self className]);
	[_popoverViewController setView:_popoverView];
	
//	NSLog(@"frame: %@", NSStringFromRect([_slider frame]));
	
//	[NSSlider setCellClass:[AppLimitSliderCell class]];
//	NSSlider *newSlider = [[NSSlider alloc] initWithFrame:NSMakeRect(15, 10, 300, 25)];
//	[NSSlider setCellClass:[NSSliderCell class]];
//	[newSlider setMinValue:0];
//	[newSlider setMaxValue:11];
//	[newSlider setNumberOfTickMarks:11];
//	[newSlider setTickMarkPosition:NSTickMarkBelow];
//	[newSlider setRefusesFirstResponder:YES];
//	[_popoverView addSubview:newSlider];
	
	[_slider setContinuous:YES];	// this is temporary here
	[_slider setTarget:self];
	[_slider setAction:@selector(sliderAction:)];
	[_levelIndicator setWarningValue:5];
	[_levelIndicator setCriticalValue:7.5];
//	[detachedWindow setContentView:popoverView];
}


// temp method
- (void)showPopoverRelativeTo:(NSView *)view {
//	if (popoverViewController == nil) {
//		popoverViewController = [[NSViewController alloc] initWithNibName:@"AppInspector" bundle:[NSBundle mainBundle]];
//	}
	
	
//	NSLog(@"called show popover: %@", popoverViewController);
	[_popover showRelativeToRect:[view bounds] ofView:view preferredEdge:NSMaxXEdge];
}


- (NSPopover *)popover {
	return _popover;
}


/*
- (NSWindow *)detachableWindowForPopover:(NSPopover *)thePopover {
	[thePopover setAnimates:NO];
	return detachedWindow;
}
 */

- (void)sliderAction:(id)sender {
	float value = [_slider floatValue];
//	NSEvent *theEvent = [NSApp currentEvent];
//	NSEventType eventType = [theEvent type];
//	NSPoint mouseLocation = [theEvent locationInWindow];
//	mouseLocation = [_slider convertPoint:mouseLocation fromView:nil];
//	mouseLocation = [theEvent window]
//	NSLog(@"event wind: %@", [theEvent window]);
//	NSLog(@"sliderh action: %f, event: %ld", value, eventType);

	
//	[_slider lockFocus];
//	[[NSColor redColor] set];
//	NSFrameRect(rect);
//	[_slider unlockFocus];
	
//	[_slider cell];
	
//	NSLog(@"sliderh action: %f", value);
//	NSLog(@"last before last rect: %@, mouse loca: %@", NSStringFromRect(rect), NSStringFromPoint(mouseLocation));

	/*
	if (eventType == NSLeftMouseUp) {
	
		if (_sliderMouseTrackingTimer) {
			[_sliderMouseTrackingTimer invalidate];
			_sliderMouseTrackingTimer = nil;
		}
	
	} else {
//	BOOL stopOnTickMarks = [_slider allowsTickMarkValuesOnly];
		NSInteger beforeLastTickMark = [_slider numberOfTickMarks] - 2;
		if (value >= beforeLastTickMark) {
			[_slider setAllowsTickMarkValuesOnly:YES];
			if (! _sliderMouseTrackingTimer) {
				NSRect tickMarkRect = [_slider rectOfTickMarkAtIndex:beforeLastTickMark];
				NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
										  [theEvent window], @"window",
										  [NSValue valueWithRect:tickMarkRect], @"tickMarkRect", nil];
				_sliderMouseTrackingTimer = [NSTimer timerWithTimeInterval:0.05 target:self selector:@selector(sliderTrackingTimerEvent:) userInfo:userInfo repeats:YES];
				[[NSRunLoop currentRunLoop] addTimer:_sliderMouseTrackingTimer forMode:NSRunLoopCommonModes];
			}
		} else {
			[_slider setAllowsTickMarkValuesOnly:NO];
		}
		
	}
	*/
	[_levelIndicator setFloatValue:value];
}

/*
- (void)sliderTrackingTimerEvent:(NSTimer *)timer {
	NSDictionary *userInfo = [timer userInfo];
	NSWindow *window = [userInfo objectForKey:@"window"];
	NSPoint mouseLocation = [NSEvent mouseLocation];
	mouseLocation = [_slider convertPoint:[window convertScreenToBase:mouseLocation] fromView:nil];
//	NSLog(@"timer event, mouseloc: %@", NSStringFromPoint(mouseLocation));
	
	NSRect rect = [(NSValue *)[userInfo objectForKey:@"tickMarkRect"] rectValue];
	
	if (mouseLocation.x < rect.origin.x) {
//		NSLog(@"snapping should be released");
		[_slider setAllowsTickMarkValuesOnly:NO];
		[timer invalidate];
		_sliderMouseTrackingTimer = nil;
	}
	
}
 */


- (void)setPopverDidCloseHandler:(void (^)(void))handler {
	if (_handler != handler)
		_handler = handler;
}

- (void)popoverDidClose:(NSNotification *)notification {
//	[[[self attachedToItem] menu] setSuspendMenus:NO];
	if (_handler)
		_handler();
}


@end
