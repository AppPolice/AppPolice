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
#include "app_inspector_c.h"
#include "proc_cpulim.h"
#include <errno.h>

#define SLIDER_NOT_LIMITED_VALUE [_slider maxValue]
#define NO_LIMIT 0.0


// ---------------------------------- Obj-c ---------------------------------------

@interface AppInspector ()
{
	BOOL _processIsRunning;
}

- (void)cpuTimerFire:(NSTimer *)timer;
- (void)updateTextfieldsWithLimitValue:(float)limit;
- (void)setProcessLimit:(float)limit;
- (float)limitFromSliderValue:(double)value;			// |limit| is a fraction of 1 for 100%
- (double)sliderValueFromLimit:(float)limit;
- (double)levelIndicatorValueFromCPU:(double)cpu;

@end



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

	
//	NSLog(@"cpu's: %d", system_ncpu());
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
	if (! attachedToItem)
		return;
	
//	NSLog(@"attached ot item: %@", attachedToItem);
	
	NSMutableDictionary *applicationInfo = [attachedToItem representedObject];
	if (! applicationInfo) {
		NSLog(@"No application info provided with menu item (represented object).");
		return;
	}
	
	NSImage *icon = [applicationInfo objectForKey:APApplicationInfoIconKey];
	NSString *name = [applicationInfo objectForKey:APApplicationInfoNameKey];
	pid_t pid = [(NSNumber *)[applicationInfo objectForKey:APApplicationInfoPidKey] intValue];
	float limit = [(NSNumber *)[applicationInfo objectForKey:APApplicationInfoLimitKey] floatValue];

//		NSImage *genericIcon = [[NSWorkspace sharedWorkspace] iconForFileType:NSFileTypeForHFSTypeCode(kGenericExtensionIcon)];
//		NSImage *genericIcon = [[NSWorkspace sharedWorkspace] iconForFile:@"/bin/ls"];
	
	[icon setSize:[_applicationIcon frame].size];
	[_applicationIcon setImage:icon];
	[_applicationNameTextfield setStringValue:[NSString stringWithFormat:@"%@ (%d)", name, pid]];
	
	
	if (_cpuTimer) {
		[_cpuTimer invalidate];
		_cpuTimer = nil;
	}
	


	errno = 0;
	// Current cpu time for a process
	_cpuTime.cputime = get_proc_cputime(pid);
	if (_cpuTime.cputime == 0 && errno != 0) {
		_processIsRunning = NO;
		if (errno == ESRCH) {
			[_applicationUserTextfield setStringValue:@"No such process"];
		} else if (errno == EPERM) {
			[[_applicationUserTextfield cell] setWraps:YES];
			[_applicationUserTextfield setPreferredMaxLayoutWidth:150.0];
			[_applicationUserTextfield setStringValue:@"No permission to access process information"];
		} else {
			[[_applicationUserTextfield cell] setWraps:YES];
			[_applicationUserTextfield setPreferredMaxLayoutWidth:150.0];
			[_applicationUserTextfield setStringValue:@"Error accessing process information"];
		}
		[_applicationCPUTextfield setStringValue:@""];
		[_slider setDoubleValue:SLIDER_NOT_LIMITED_VALUE];
		[self updateTextfieldsWithLimitValue:NO_LIMIT];
		[_levelIndicator setDoubleValue:0.0];
		[self setProcessLimit:NO_LIMIT];
	} else {
		_processIsRunning = YES;
		_cpuTime.timestamp = get_timestamp();
		
		// Reset params
		if ([[_applicationUserTextfield cell] wraps]) {
			[[_applicationUserTextfield cell] setWraps:NO];
			[_applicationUserTextfield setPreferredMaxLayoutWidth:0.0];
		}
		// Basically, we handled to possible process access permission problem above
		// so this should always evaluate to true.
		char *proc_username = get_proc_username(pid);
		if (proc_username)
			[_applicationUserTextfield setStringValue:[NSString stringWithFormat:@"User: %@", [NSString stringWithCString:proc_username encoding:NSUTF8StringEncoding]]];
		else
			[_applicationUserTextfield setStringValue:@"User: -"];
		[_applicationCPUTextfield setStringValue:@"\% CPU: 0.00"];
		// Update level indicator
		[_levelIndicator setFloatValue:0.0];
		// Update slider
		if (limit == 0) {
			[_slider setDoubleValue:[_slider maxValue]];
		} else {
			double sliderValue = [self sliderValueFromLimit:limit];
			[_slider setDoubleValue:sliderValue];
		}
		[self updateTextfieldsWithLimitValue:limit];
		
		
		NSDictionary *timerUserInfo = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:pid], @"pid", nil];
		_cpuTimer = [NSTimer timerWithTimeInterval:2.0 target:self selector:@selector(cpuTimerFire:) userInfo:timerUserInfo repeats:YES];
		[[NSRunLoop currentRunLoop] addTimer:_cpuTimer forMode:NSRunLoopCommonModes];
	}
	
	if ([_popover isShown]) {
		// post notification about popover having been updated
//		NSLog(@"postnotification from setAttached");
		NSNotification *postNotification = [NSNotification notificationWithName:APAppInspectorPopoverDidShow object:self userInfo:nil];
		[[NSNotificationQueue defaultQueue] enqueueNotification:postNotification
												   postingStyle:NSPostASAP
												   coalesceMask:NSNotificationCoalescingOnName
													   forModes:[NSArray arrayWithObject:NSRunLoopCommonModes]];
	}
}


/*
 *
 */
- (void)cpuTimerFire:(NSTimer *)timer {
	uint64_t cputime;
	uint64_t timestamp;
	double cpuload;
	pid_t pid;
	NSDictionary *userInfo;
	
	userInfo = [timer userInfo];
	pid = [(NSNumber *)[userInfo objectForKey:@"pid"] intValue];
	errno = 0;
	cputime = get_proc_cputime(pid);

	
	// Info about the process is not available. Stop polling
	if (cputime == 0 && errno != 0) {
		_processIsRunning = NO;
		if (errno == ESRCH) {
			[_applicationUserTextfield setStringValue:@"No such process"];
		} else if (errno == EPERM) {
			[[_applicationUserTextfield cell] setWraps:YES];
			[_applicationUserTextfield setPreferredMaxLayoutWidth:150.0];
			[_applicationUserTextfield setStringValue:@"No permission to access process information"];
		} else {
			[[_applicationUserTextfield cell] setWraps:YES];
			[_applicationUserTextfield setPreferredMaxLayoutWidth:150.0];
			[_applicationUserTextfield setStringValue:@"Error accessing process information"];
		}
		[_applicationCPUTextfield setStringValue:@""];
		[_slider setDoubleValue:SLIDER_NOT_LIMITED_VALUE];
		[self updateTextfieldsWithLimitValue:NO_LIMIT];
		[_levelIndicator setDoubleValue:0.0];
		[self setProcessLimit:NO_LIMIT];
		
		[_cpuTimer invalidate];
		_cpuTimer = nil;
		return;
	}
	
	timestamp = get_timestamp();
	
	// First run: write values and continue
	if (_cpuTime.cputime == 0) {
		_cpuTime.cputime = cputime;
		_cpuTime.timestamp = timestamp;
		return;
	}
	
//	NSLog(@"timer event :: cputime_prev: %llu, cputtime: %llu (difference: %llu), timestamp_prev: %llu, timestampt: %llu", _cpuTime.cputime, cputime, (cputime - _cpuTime.cputime), _cpuTime.timestamp, timestamp);

//	NSLog(@"%llu / %llu = %f",
//		  (cputime - _cpuTime.cputime),
//		  (timestamp - _cpuTime.timestamp) / 100,
//		  (double)(cputime - _cpuTime.cputime) / (timestamp - _cpuTime.timestamp) * 100.0);
	

	
	cpuload = (double)(cputime - _cpuTime.cputime) / (timestamp - _cpuTime.timestamp) * 100;
	_cpuTime.cputime = cputime;
	_cpuTime.timestamp = timestamp;
	
	[_applicationCPUTextfield setStringValue:[NSString stringWithFormat:@"%% CPU: %.2f", cpuload]];
	[_levelIndicator setDoubleValue:[self levelIndicatorValueFromCPU:cpuload]];
	
//	NSLog(@"level value: %.3f", [self levelIndicatorValueFromCPU:cpuload]);
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


/*
- (NSWindow *)detachableWindowForPopover:(NSPopover *)thePopover {
	[thePopover setAnimates:NO];
	return detachedWindow;
}
 */

- (void)sliderAction:(id)sender {
	double value = [_slider doubleValue];
	float limit;
	if (value == [_slider maxValue])
		limit = NO_LIMIT;
	else
		limit = [self limitFromSliderValue:value];
		
	[self updateTextfieldsWithLimitValue:limit];
	
	NSEvent *theEvent = [NSApp currentEvent];
	NSEventType eventType = [theEvent type];
	
	if (eventType == NSLeftMouseUp) {		// update applicatoinInfo when slider is released
		[self setProcessLimit:limit];
	}

//	NSLog(@"limit: %f", limit);
}


/*
 *
 */
- (void)updateTextfieldsWithLimitValue:(float)limit {
	if (limit == NO_LIMIT) {
		[_sliderLimit2Textfield setStringValue:@"Not limited"];
	} else {
		int percents;
		percents = (int)floor(limit * 100 + 0.5);
		if (percents < 1)
			percents = 1;
		[_sliderLimit2Textfield setStringValue:[NSString stringWithFormat:@"%d%%", percents]];
	}
}


/*
 *
 */
- (void)setProcessLimit:(float)limit {
	// Update the attached-to menu item state
	if (! _attachedToItem)
		return;
	
	if (! _processIsRunning)
		limit = NO_LIMIT;
	
	NSMutableDictionary *applicationInfo = [_attachedToItem representedObject];
	[applicationInfo setObject:[NSNumber numberWithFloat:limit] forKey:APApplicationInfoLimitKey];
//	if (limit == NO_LIMIT)
//		[_attachedToItem setState:NSMixedState];
//	else
//		[_attachedToItem setState:NSOnState];
	
	NSNumber *pid_n = [applicationInfo objectForKey:APApplicationInfoPidKey];
	pid_t pid = [pid_n intValue];
	// Set limit for process and start limiter in case it's not already running
	proc_cpulim_set(pid, limit);
//	proc_cpulim_resume();
	
	// Post notification about process changed limit
//	NSDictionary *userInfo = @{
//		@"pid" : pid_n,
//		@"limit" : [NSNumber numberWithFloat:limit]
//	};
	NSDictionary *userInfo = @{
		@"menuItem" : _attachedToItem
	};
	NSNotification *postNotification = [NSNotification notificationWithName:APAppInspectorProcessDidChangeLimit object:self userInfo:userInfo];
	[[NSNotificationQueue defaultQueue] enqueueNotification:postNotification
											   postingStyle:NSPostNow
											   coalesceMask:NSNotificationCoalescingOnName
												   forModes:[NSArray arrayWithObject:NSRunLoopCommonModes]];

}



- (float)limitFromSliderValue:(double)value {
	double maxValue = [_slider maxValue];
	double minValue = [_slider minValue];
//	double middleValue;
	double rangeOfValues;
	double middleRange;
	float limit;
	int ncpu;
//	int ncpu = system_ncpu();
//	maxValue -= [_slider minValue];
//	maxValue -= maxValue / ([_slider numberOfTickMarks] - 1);		// deduct one tick mark
//	limit = value / maxValue * ncpu;
	
	if (value == maxValue)
		return 0;

//	int percents;
	
//	if (minValue) {		// shift all values by min value
//		value -= minValue;
//		maxValue -= minValue;
//	}
//	
//	// max value is reduced on the amount of one tick mark
//	maxValue -= maxValue / ([_slider numberOfTickMarks] - 1);
//	middleValue = maxValue / 2;
	
	value -= minValue;
	rangeOfValues = maxValue - minValue;
	rangeOfValues -= maxValue / ([_slider numberOfTickMarks] - 1);	// last mark is deducted from the range
	middleRange = rangeOfValues / 2;
	ncpu = system_ncpu();
	
	if (ncpu > 2) {
		if (value <= middleRange)
			limit = (float)(value / middleRange);
		else
			limit = (float)((value - middleRange) / middleRange * (ncpu - 1) + 1);
	} else {
		if (value > rangeOfValues)
			value = rangeOfValues;
		
		limit = (float)(value / rangeOfValues * ncpu);
	}
	
	if (limit < 0.01f)
		limit = 0.01f;
	
	return limit;
}


- (double)sliderValueFromLimit:(float)limit {
	double maxValue = [_slider maxValue];
	double minValue = [_slider minValue];
//	double middleValue;
	double rangeOfValues;
	double value;
	int ncpu;
	
	if (limit == 0)
		return maxValue;
	
	ncpu = system_ncpu();
//	maxValue -= [_slider minValue];
	rangeOfValues = maxValue - minValue;
//	maxValue -= maxValue / ([_slider numberOfTickMarks] - 1);		// deduct one tick mark
	rangeOfValues -= maxValue / ([_slider numberOfTickMarks] - 1);		// deduct one tick mark
//	middleValue = maxValue / 2;
//	middleValue = valuesRange / 2;
//	value = limit / ncpu * maxValue;
	
	// If there are more that 2 CPUs we take half of the slider width
	// to show 100%. Other half will show (ncpu - 1) * 100%
	if (ncpu > 2) {
		double middleRange = rangeOfValues / 2;
		if (limit <= 1)
			value = limit * middleRange;
		else
			value = (limit - 1) / (ncpu - 1) * middleRange + middleRange;
	} else {
		value = limit / ncpu * rangeOfValues;
	}
	
	// offset |value| back by minValue
	if (minValue)
		value += minValue;

	return value;
}


- (double)levelIndicatorValueFromCPU:(double)cpu {
	double minValue = [_levelIndicator minValue];
	double maxValue = [_levelIndicator maxValue];
	double rangeOfValues;
//	double middleRange;
	double value;
	int ncpu;
	
	if (cpu == 0)
		return minValue;
	
	ncpu = system_ncpu();
//	maxValue -= minValue;
//	value = cpu / ncpu / 100 * maxValue + minValue;		// cpu / (ncpu * 100) * maxValue + minValue
	rangeOfValues = maxValue - minValue;

	
	if (ncpu > 2) {
		double middleRange = rangeOfValues / 2;
		if (cpu <= 100.0) {
			value = cpu / 100 * middleRange;
		} else {
			value = (cpu / 100.0 - 1) / (ncpu - 1) * middleRange + middleRange;
		}
	} else {
		value = cpu / 100 / ncpu * rangeOfValues;
	}
	
	if (minValue)
		value += minValue;

	return value;
}


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
//		HintPopoverTextField *textField = [[[HintPopoverTextField alloc] initWithFrame:NSMakeRect(0, 0, 150, 1)] autorelease];
		NSTextField *textField = [[[NSTextField alloc] init] autorelease];
		[[textField cell] setWraps:YES];
		[textField setPreferredMaxLayoutWidth:150.0];
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


// temp method
- (void)showPopoverRelativeTo:(NSView *)view {
	//	if (popoverViewController == nil) {
	//		popoverViewController = [[NSViewController alloc] initWithNibName:@"AppInspector" bundle:[NSBundle mainBundle]];
	//	}
	
	
	//	NSLog(@"called show popover: %@", popoverViewController);
	[_popover showRelativeToRect:[view bounds] ofView:view preferredEdge:NSMaxXEdge];
}




- (void)popoverDidShow:(NSNotification *)notification {
//	NSLog(@"popover did show");
	[_popover setAnimates:NO];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(limitHintViewMouseUpNotification:) name:APAppLimitHintMouseDownNotification object:nil];

//	NSLog(@"post appinspector notification from popoverDidShow");
	NSNotification *postNotification = [NSNotification notificationWithName:APAppInspectorPopoverDidShow object:self userInfo:nil];
	[[NSNotificationQueue defaultQueue] enqueueNotification:postNotification
											   postingStyle:NSPostNow
											   coalesceMask:NSNotificationCoalescingOnName
												   forModes:[NSArray arrayWithObject:NSRunLoopCommonModes]];
}


- (void)popoverWillClose:(NSNotification *)notification {
//		NSLog(@"popover will close");
	[_popover setAnimates:YES];
}


- (void)popoverDidClose:(NSNotification *)notification {
//	NSLog(@"popover did close");
//	[[[self attachedToItem] menu] setSuspendMenus:NO];
	if (_cpuTimer) {
		[_cpuTimer invalidate];
		_cpuTimer = nil;
	}
	
	if (_attachedToItem) {
		if ([_attachedToItem state] == NSMixedState)
			[_attachedToItem setState:NSOffState];
		[[_attachedToItem menu] setSuspendMenus:NO];
		[[_attachedToItem menu] setCancelsTrackingOnMouseEventOutsideMenus:YES];
	}
	[self setAttachedToItem:nil];
	if (_popoverDidClosehandler)
		_popoverDidClosehandler();
	[[NSNotificationCenter defaultCenter] removeObserver:self name:APAppLimitHintMouseDownNotification object:nil];
}


@end
