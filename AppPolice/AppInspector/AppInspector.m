//
//  AppInspectorController.m
//  Ishimura
//
//  Created by Maksym on 7/2/13.
//  Copyright (c) 2013 Maksym Stefanchuk. All rights reserved.
//

#import "AppInspector.h"
#import "AppLimitSliderCell.h"
#import "AppLimitHintView.h"
#include "app_inspector_c.h"
#include "proc_cpulim.h"
#include <errno.h>

#define SLIDER_NOT_LIMITED_VALUE [_slider maxValue]
#define NO_LIMIT 0.0


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
	// Set popover content view
	[_popoverViewController setView:_popoverView];
	int ncpu = system_ncpu();
	
	[_slider setContinuous:YES];
	[_slider setTarget:self];
	[_slider setAction:@selector(sliderAction:)];
	[_levelIndicator setWarningValue:5];
	[_levelIndicator setCriticalValue:7.5];
	[_sliderMiddleTextfield setStringValue:[NSString stringWithFormat:@"%d%%", (ncpu > 2) ? 100 : ncpu / 2 * 100]];
	[_sliderRightTextfield setStringValue:[NSString stringWithFormat:@"%d%%", ncpu * 100]];
}


- (CMMenuItem *)attachedToItem {
	return _attachedToItem;
}


/*
 *
 */
- (void)setAttachedToItem:(CMMenuItem *)attachedToItem {
	if (attachedToItem == _attachedToItem)
		return;
	
	_attachedToItem = attachedToItem;
	if (! attachedToItem)
		return;
	
	NSMutableDictionary *applicationInfo = [attachedToItem representedObject];
	if (! applicationInfo) {
		NSLog(@"No application info provided with menu item (represented object).");
		return;
	}
	
	NSImage *icon = [applicationInfo objectForKey:APApplicationInfoIconKey];
	NSString *name = [applicationInfo objectForKey:APApplicationInfoNameKey];
	pid_t pid = [(NSNumber *)[applicationInfo objectForKey:APApplicationInfoPidKey] intValue];
	float limit = [(NSNumber *)[applicationInfo objectForKey:APApplicationInfoLimitKey] floatValue];

	// Technics used to load default images (kept for reference)
	// NSImage *genericIcon = [[NSWorkspace sharedWorkspace] iconForFileType:NSFileTypeForHFSTypeCode(kGenericExtensionIcon)];
	// NSImage *genericIcon = [[NSWorkspace sharedWorkspace] iconForFile:@"/bin/ls"];
	
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
			[_applicationUserTextfield setStringValue:NSLocalizedString(@"No such process", @"AppInspector")];
		} else if (errno == EPERM) {
			[[_applicationUserTextfield cell] setWraps:YES];
			[_applicationUserTextfield setPreferredMaxLayoutWidth:150.0];
			[_applicationUserTextfield setStringValue:NSLocalizedString(@"No permission to access process information", @"AppInspector")];
		} else {
			[[_applicationUserTextfield cell] setWraps:YES];
			[_applicationUserTextfield setPreferredMaxLayoutWidth:150.0];
			[_applicationUserTextfield setStringValue:NSLocalizedString(@"Error accessing process information", @"AppInspector")];
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
			[_applicationUserTextfield setStringValue:[NSString stringWithFormat:NSLocalizedString(@"User: %@", @"AppInspector process User name"), [NSString stringWithCString:proc_username encoding:NSUTF8StringEncoding]]];
		else
			[_applicationUserTextfield setStringValue:[NSString stringWithFormat:NSLocalizedString(@"User: %@", @"AppInspector process User name"), @"-"]];
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
			[_applicationUserTextfield setStringValue:NSLocalizedString(@"No such process", @"AppInspector")];
		} else if (errno == EPERM) {
			[[_applicationUserTextfield cell] setWraps:YES];
			[_applicationUserTextfield setPreferredMaxLayoutWidth:150.0];
			[_applicationUserTextfield setStringValue:NSLocalizedString(@"No permission to access process information", @"AppInspector")];
		} else {
			[[_applicationUserTextfield cell] setWraps:YES];
			[_applicationUserTextfield setPreferredMaxLayoutWidth:150.0];
			[_applicationUserTextfield setStringValue:NSLocalizedString(@"Error accessing process information", @"AppInspector")];
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
	

	cpuload = (double)(cputime - _cpuTime.cputime) / (timestamp - _cpuTime.timestamp) * 100;
	_cpuTime.cputime = cputime;
	_cpuTime.timestamp = timestamp;
	
	[_applicationCPUTextfield setStringValue:[NSString stringWithFormat:@"%% CPU: %.2f", cpuload]];
	[_levelIndicator setDoubleValue:[self levelIndicatorValueFromCPU:cpuload]];
}


/*
 *
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
}


/*
 *
 */
- (void)updateTextfieldsWithLimitValue:(float)limit {
	if (limit == NO_LIMIT) {
		[_sliderLimit2Textfield setStringValue:NSLocalizedString(@"Not limited", @"AppInspector slider Not limiter")];
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
	
	NSNumber *pid_n = [applicationInfo objectForKey:APApplicationInfoPidKey];
	pid_t pid = [pid_n intValue];
	// Set limit for process and start limiter in case it's not already running
	proc_cpulim_set(pid, limit);
//	proc_cpulim_resume();
	
	// Post notification about process changed limit
	NSDictionary *userInfo = @{
		@"menuItem" : _attachedToItem
	};
	NSNotification *postNotification = [NSNotification notificationWithName:APAppInspectorProcessDidChangeLimit object:self userInfo:userInfo];
	[[NSNotificationQueue defaultQueue] enqueueNotification:postNotification
											   postingStyle:NSPostNow
											   coalesceMask:NSNotificationCoalescingOnName
												   forModes:[NSArray arrayWithObject:NSRunLoopCommonModes]];

}


/*
 *
 */
- (float)limitFromSliderValue:(double)value {
	double maxValue = [_slider maxValue];
	double minValue = [_slider minValue];
	double rangeOfValues;
	double middleRange;
	float limit;
	int ncpu;
	
	if (value == maxValue)
		return 0;

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
	double rangeOfValues;
	double value;
	int ncpu;
	
	if (limit == 0)
		return maxValue;
	
	ncpu = system_ncpu();
	rangeOfValues = maxValue - minValue;
	rangeOfValues -= maxValue / ([_slider numberOfTickMarks] - 1);		// deduct one tick mark
	
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
	double value;
	int ncpu;
	
	if (cpu == 0)
		return minValue;
	
	ncpu = system_ncpu();
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
	if (! _hintPopover) {
		_hintPopover = [[NSPopover alloc] init];
		NSViewController *popoverViewController = [[[NSViewController alloc] init] autorelease];
		NSView *view = [[[NSView alloc] initWithFrame:NSMakeRect(0, 0, 10, 10)] autorelease];
		[popoverViewController setView:view];
		[_hintPopover setContentViewController:popoverViewController];
		[_hintPopover setAppearance:NSPopoverAppearanceHUD];
		[_hintPopover setBehavior:NSPopoverBehaviorTransient];
		NSTextField *textField = [[[NSTextField alloc] init] autorelease];
		[[textField cell] setWraps:YES];
		[textField setPreferredMaxLayoutWidth:150.0];
		// String: Limit values greater then 100% cover multiple cores of CPU with 100% for each core.
		[textField setStringValue:NSLocalizedString(@"Hint_popover_string", @"AppInspector, a hint popover for limit value greater then 100%")];
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
//- (void)showPopoverRelativeTo:(NSView *)view {
//	[_popover showRelativeToRect:[view bounds] ofView:view preferredEdge:NSMaxXEdge];
//}



- (void)popoverDidShow:(NSNotification *)notification {
	[_popover setAnimates:NO];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(limitHintViewMouseUpNotification:) name:APAppLimitHintMouseDownNotification object:nil];

	NSNotification *postNotification = [NSNotification notificationWithName:APAppInspectorPopoverDidShow object:self userInfo:nil];
	[[NSNotificationQueue defaultQueue] enqueueNotification:postNotification
											   postingStyle:NSPostNow
											   coalesceMask:NSNotificationCoalescingOnName
												   forModes:[NSArray arrayWithObject:NSRunLoopCommonModes]];
}


- (void)popoverWillClose:(NSNotification *)notification {
	[_popover setAnimates:YES];
}


- (void)popoverDidClose:(NSNotification *)notification {
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
