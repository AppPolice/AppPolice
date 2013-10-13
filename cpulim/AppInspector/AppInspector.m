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
#import "AppLimitHintView.h"
#import "HintPopoverTextField.h"
#include <sys/sysctl.h>
#include <unistd.h>


/*
 * Return number of CPUs in computer
 */
static int system_ncpu() {
	static int ncpu = 0;
	if (ncpu)
		return ncpu;
	
#ifdef _SC_NPROCESSORS_ONLN
	ncpu = (int)sysconf(_SC_NPROCESSORS_ONLN);
#else
	int mib[2];
	mib[0] = CTL_HW;
	mig[1] = HW_NCPU;
	size_t len = sizeof(ncpu);
	sysctl(mib, 2, &ncpu, &len, NULL, 0);
#endif
	return ncpu;
}




@implementation AppInspector

//@synthesize applicationInfo;
//@synthesize attachedToItem;

- (id)init {
	self = [super init];
	if (self) {
		[NSBundle loadNibNamed:@"AppInspector" owner:self];
		[NSBundle loadNibNamed:@"PopoverContentView" owner:self];
	}
	return self;
}


- (void)dealloc {
	[_hintPopover release];
	[super dealloc];
}


- (void)awakeFromNib {
//	NSLog(@"%@ awakeFromNib", [self className]);
//	[_popoverView setTranslatesAutoresizingMaskIntoConstraints:NO];
	[_popoverViewController setView:_popoverView];
//	[_popover setAppearance:NSPopoverAppearanceHUD];
	
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
	int ncpu = system_ncpu();
	
	[_slider setContinuous:YES];	// this is temporary here
	[_slider setTarget:self];
	[_slider setAction:@selector(sliderAction:)];
	[_levelIndicator setWarningValue:5];
	[_levelIndicator setCriticalValue:7.5];
	[_sliderMiddleTextfield setStringValue:[NSString stringWithFormat:@"%d%%", (ncpu > 2) ? 100 : ncpu / 2 * 100]];
	[_sliderRightTextfield setStringValue:[NSString stringWithFormat:@"%d%%", ncpu * 100]];
//	[detachedWindow setContentView:popoverView];
	
//	[self performSelector:@selector(updateTrackingAreaForHint) withObject:nil afterDelay:0.0];

	
	NSLog(@"cpu's: %d", system_ncpu());
}


//- (NSDictionary *)applicationInfo {
//	return _applicationInfo;
//}

- (CMMenuItem *)attachedToItem {
	return _attachedToItem;
}


- (void)setAttachedToItem:(CMMenuItem *)attachedToItem {
	if (attachedToItem == _attachedToItem)
		return;
	
	_attachedToItem = attachedToItem;
	if (attachedToItem) {
		NSMutableDictionary *applicationInfo = [attachedToItem representedObject];
		if (! applicationInfo)
			return;
		
		NSImage *icon = [applicationInfo objectForKey:APApplicationInfoIconKey];
		NSString *name = [applicationInfo objectForKey:APApplicationInfoNameKey];
		pid_t pid = [(NSNumber *)[applicationInfo objectForKey:APApplicationInfoPidKey] intValue];
		float limit = [(NSNumber *)[applicationInfo objectForKey:APApplicationInfoLimitKey] floatValue];

		[icon setSize:[_applicationIcon frame].size];
		[_applicationIcon setImage:icon];
		[_applicationNameTextfield setStringValue:[NSString stringWithFormat:@"%@ (%d)", name, pid]];
		if (limit == 0) {
			[_slider setFloatValue:[_slider maxValue]];
		} else {
			float sliderValue = [self sliderValueFromLimit:limit];
			[_slider setFloatValue:sliderValue];
		}
		[self updateTextfieldsWithLimitValue:limit];
	}
}

//- (void)setApplicationInfo:(NSMutableDictionary *)applicationInfo {
//	if (_applicationInfo == applicationInfo)
//		return;
//		
//	_applicationInfo = applicationInfo;
//	if (applicationInfo) {
//		NSImage *icon = [applicationInfo objectForKey:APApplicationInfoIconKey];
//		NSString *name = [applicationInfo objectForKey:APApplicationInfoNameKey];
//		pid_t pid = [(NSNumber *)[applicationInfo objectForKey:APApplicationInfoPidKey] intValue];
//		float limit = [(NSNumber *)[applicationInfo objectForKey:APApplicationInfoLimitKey] floatValue];
//		
//		[_applicationIcon setImage:icon];
//		[_applicationNameTextfield setStringValue:[NSString stringWithFormat:@"%@ (%d)", name, pid]];
//		if (limit == 0) {
//			[_slider setFloatValue:[_slider maxValue]];
////			[_sliderLimit2Textfield setStringValue:@"Not limited"];
//		} else {
//			float sliderValue = [self sliderValueFromLimit:limit];
//			[_slider setFloatValue:sliderValue];
////			int intLimit = limit * 100;
////			[_sliderLimit2Textfield setStringValue:[NSString stringWithFormat:@"%d%%", intLimit]];
//		}
//		[self updateTextfieldsWithLimitValue:limit];
//	}
//}


// temp method
- (void)showPopoverRelativeTo:(NSView *)view {
//	if (popoverViewController == nil) {
//		popoverViewController = [[NSViewController alloc] initWithNibName:@"AppInspector" bundle:[NSBundle mainBundle]];
//	}
	
	
//	NSLog(@"called show popover: %@", popoverViewController);
	[_popover showRelativeToRect:[view bounds] ofView:view preferredEdge:NSMaxXEdge];
}



/*
- (NSWindow *)detachableWindowForPopover:(NSPopover *)thePopover {
	[thePopover setAnimates:NO];
	return detachedWindow;
}
 */

- (void)sliderAction:(id)sender {
	float value = [_slider floatValue];
	float limit;
	if (value == [_slider maxValue])
		limit = 0;
	else
		limit = [self limitFromSliderValue:value];
		
	[self updateTextfieldsWithLimitValue:limit];
	
	NSEvent *theEvent = [NSApp currentEvent];
	NSEventType eventType = [theEvent type];
	
	if (eventType == NSLeftMouseUp) {		// update applicatoinInfo when slider is released
//		NSNumber *appLimit = [_applicationInfo objectForKey:APApplicationInfoLimitKey];
//		appLimit = [NSNumber numberWithFloat:limit];
//		[_applicationInfo removeObjectForKey:APApplicationInfoLimitKey];
//		[_applicationInfo setObject:[NSNumber numberWithFloat:limit] forKey:APApplicationInfoLimitKey];
		if (_attachedToItem) {
			NSMutableDictionary *applicationInfo = [_attachedToItem representedObject];
			[applicationInfo setObject:[NSNumber numberWithFloat:limit] forKey:APApplicationInfoLimitKey];
			if (limit == 0)
				[_attachedToItem setState:NSMixedState];
			else
				[_attachedToItem setState:NSOnState];
		}
	}
	
	
//	NSLog(@"limit: %f", limit);
}


/*
 *
 */
- (void)updateTextfieldsWithLimitValue:(float)limit {
//	float value = [_slider floatValue];
//	NSLog(@"slider value: %f", value);
	
//	double minValue = [_slider minValue];
//	double maxValue = [_slider maxValue];
	
//	if (value == ([_slider numberOfTickMarks] - 1)) {
//	if (value == [_slider maxValue]) {
	if (limit == 0) {
		[_sliderLimit2Textfield setStringValue:@"Not limited"];
//		if (! [_sliderBottomTextfield isHidden])
//			[_sliderBottomTextfield setHidden:YES];
	} else {
/*
		int ncpu = system_ncpu();
//		NSInteger penultimateValue = [_slider numberOfTickMarks] - 2;
//		NSInteger middleValue = penultimateValue / 2;
		double middleValue;
		int percents;

		if (minValue) {		// shift all values by min value
			value -= minValue;
			maxValue -= minValue;
		}

		// max value is reduced on the amount of one tick mark
		maxValue -= (maxValue - minValue) / ([_slider numberOfTickMarks] - 1);
		middleValue = maxValue / 2;
		

		if (ncpu > 2) {
			if (value <= middleValue)
				percents = floor(value / middleValue * 100 + 0.5);
			else
				percents = floor((value - middleValue) / middleValue * (ncpu - 1) * 100 + 100.5);	// 100.5 = 100% + 0.5 to round to greater value
		} else {
			if (value > maxValue)
				value = maxValue;
		
			percents = floor(value / maxValue * ncpu * 100 + 0.5);
		}
		
		if (percents == 0)
			percents = 1;
 */
//		int fullyLoadedCoresCount = floor(percents / 100);
//		int percentsLeft = percents - fullyLoadedCoresCount * 100;

		int percents;
		percents = floor(limit * 100 + 0.5);
		if (percents < 1)
			percents = 1;
		[_sliderLimit2Textfield setStringValue:[NSString stringWithFormat:@"%d%%", percents]];
		
//		if (fullyLoadedCoresCount > 1 || (fullyLoadedCoresCount && percentsLeft)) {
//			if ([_sliderBottomTextfield isHidden])
//				[_sliderBottomTextfield setHidden:NO];
//			if (percentsLeft) {
//				[_sliderBottomTextfield setStringValue:[NSString stringWithFormat:@"%d CPU%@ at 100%% and 1 CPU at %d%%",
//					fullyLoadedCoresCount,
//					(fullyLoadedCoresCount == 1) ? @"" : @"s",
//					percentsLeft]];
//			} else {
//				[_sliderBottomTextfield setStringValue:[NSString stringWithFormat:@"%d CPUs at 100%%", fullyLoadedCoresCount]];
//			}
//
//		} else {
//			if (! [_sliderBottomTextfield isHidden])
//				[_sliderBottomTextfield setHidden:YES];
//		}
	}


//	[_levelIndicator setFloatValue:value];
}



- (float)limitFromSliderValue:(float)value {
	double maxValue = [_slider maxValue];
	double minValue = [_slider minValue];
	float limit;
//	int ncpu = system_ncpu();
//	maxValue -= [_slider minValue];
//	maxValue -= maxValue / ([_slider numberOfTickMarks] - 1);		// deduct one tick mark
//	limit = value / maxValue * ncpu;
	
	int ncpu = system_ncpu();
	double middleValue;
//	int percents;
	
	if (minValue) {		// shift all values by min value
		value -= minValue;
		maxValue -= minValue;
	}
	
	// max value is reduced on the amount of one tick mark
	maxValue -= maxValue / ([_slider numberOfTickMarks] - 1);
	middleValue = maxValue / 2;
	
	
	if (ncpu > 2) {
		if (value <= middleValue)
			limit = value / middleValue;
		else
			limit = (value - middleValue) / middleValue * (ncpu - 1) + 1;
	} else {
		if (value > maxValue)
			value = maxValue;
		
		limit = value / maxValue * ncpu;
	}
	
	if (limit < 0.01)
		limit = 0.01;
	
	return limit;
}


- (float)sliderValueFromLimit:(float)limit {
	double maxValue = [_slider maxValue];
	double middleValue;
	float value;
	int ncpu;
	
	if (limit == 0)
		return maxValue;
	
	ncpu = system_ncpu();
	maxValue -= [_slider minValue];
	maxValue -= maxValue / ([_slider numberOfTickMarks] - 1);		// deduct one tick mark
	middleValue = maxValue / 2;
//	value = limit / ncpu * maxValue;
	
	if (ncpu > 2) {
		if (limit <= 1)
			value = limit * middleValue;
		else
			value = (limit - 1) / (ncpu - 1) * middleValue + middleValue;
	} else {
		value = limit / ncpu * maxValue;
	}

	return value;
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


//- (void)updateTrackingAreaForHint {
//	NSRect frame = [_sliderTopRightTextField frame];
//	frame.origin.x -= 50;
//	frame.origin.y -= 10;
//	frame.size.width += 100;
//	frame.size.height += 20;
////	frame = [_sliderTopRightTextField convertRect:frame toView:_popoverView];
////	NSLog(@"super: %d", [_popoverView canDraw]);
//	if ([_popoverView canDraw]) {
//		[_popoverView lockFocus];
////		NSLog(@"sub: %@", [_popoverView subviews]);
//		[[NSColor redColor] set];
//		NSFrameRect(frame);
//		[_popoverView unlockFocus];
////				[_popoverView display];
////		[_popoverView setNeedsDisplay:YES];
//	}
////	NSLog(@"frame: %@", NSStringFromRect(frame));	
////	NSTrackingAreaOptions options = NSTrackingActiveInActiveApp | NSTrackingMouseEnteredAndExited;
////	NSTrackingArea *trackingArea = [[NSTrackingArea alloc] initWithRect:frame options:options owner:self userInfo:nil];
////	[_popoverView addTrackingArea:trackingArea];
////	[trackingArea release];
//	
//	
//	
//}


//- (void)mouseUp:(id)sender {
//	NSLog(@"mouse is up on hint");
//}


- (void)limitHintViewMouseUpNotification:(NSNotification *)notification {
//	NSLog(@"notification: %@", notification);
	if (! _hintPopover) {
		_hintPopover = [[NSPopover alloc] init];
		NSViewController *popoverViewController = [[[NSViewController alloc] init] autorelease];
		NSView *view = [[[NSView alloc] initWithFrame:NSMakeRect(0, 0, 10, 10)] autorelease];
		[popoverViewController setView:view];
		[_hintPopover setContentViewController:popoverViewController];
		[_hintPopover setAppearance:NSPopoverAppearanceHUD];
		[_hintPopover setBehavior:NSPopoverBehaviorTransient];
//		[_hintPopover setAnimates:NO];
		// 150 here is the maximum width of popover textfield.
		HintPopoverTextField *textField = [[[HintPopoverTextField alloc] initWithFrame:NSMakeRect(0, 0, 150, 1)] autorelease];
		[textField setStringValue:@"Limit values greater then 100% cover multiple cores of CPU with 100% for each core."];
		[textField setFont:[NSFont systemFontOfSize:10]];
		[textField setTextColor:[NSColor colorWithCalibratedWhite:0.8 alpha:1.0]];
		[textField setBordered:NO];
		[textField setBezeled:NO];
		[textField setBezelStyle:NSTextFieldSquareBezel];
		[textField setDrawsBackground:NO];
		[textField setEditable:NO];
		[textField setRefusesFirstResponder:YES];

		[view addSubview:textField];
		[textField setTranslatesAutoresizingMaskIntoConstraints:NO];
		NSMutableArray *constraints = [NSMutableArray arrayWithArray:[NSLayoutConstraint constraintsWithVisualFormat:@"|-[textField(<=150)]-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(textField)]];
		[constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(15)-[textField]-(15)-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(textField)]];
		[view addConstraints:constraints];
	}
	
//	if ([_hintPopover isShown]) {
//		[_hintPopover close];
//	} else {
	if (! [_hintPopover isShown]) {
		AppLimitHintView *hintView = (AppLimitHintView *)[notification object];
		[_hintPopover showRelativeToRect:[hintView bounds] ofView:hintView preferredEdge:NSMaxYEdge];
	}
}


- (NSPopover *)popover {
	return _popover;
}


- (void)setPopverDidCloseHandler:(void (^)(void))handler {
	if (_popoverDidClosehandler != handler)
		_popoverDidClosehandler = handler;
}


- (void)popoverDidShow:(NSNotification *)notification {
	NSLog(@"popover did show");
	[_popover setAnimates:NO];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(limitHintViewMouseUpNotification:) name:AppLimitHintMouseDownNotification object:nil];
}


- (void)popoverWillClose:(NSNotification *)notification {
//		NSLog(@"popover will close");
	[_popover setAnimates:YES];
}


- (void)popoverDidClose:(NSNotification *)notification {
//	NSLog(@"popover did close");
//	[[[self attachedToItem] menu] setSuspendMenus:NO];
	if (_attachedToItem) {
		if ([_attachedToItem state] == NSMixedState)
			[_attachedToItem setState:NSOffState];
		[[_attachedToItem menu] setSuspendMenus:NO];
		[[_attachedToItem menu] setCancelsTrackingOnMouseEventOutsideMenus:YES];
	}
	[self setAttachedToItem:nil];
	if (_popoverDidClosehandler)
		_popoverDidClosehandler();
	[[NSNotificationCenter defaultCenter] removeObserver:self name:AppLimitHintMouseDownNotification object:nil];
}


@end
