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
// C
#include <sys/sysctl.h>				/* sysctl() */
#include <unistd.h>					/* sysconf(_SC_NPROCESSORS_ONLN) */
#include <libproc.h>				/* proc_pidinfo() */
#include <pwd.h>					/* getpwuid() */
#include <mach/mach.h>				/* mach_absolute_time() */
#include <mach/mach_time.h>



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


/*
 *
 */
//static void pid_bsd_shortinfo(pid_t pid) {
static char *get_proc_username(pid_t pid) {
	int error;
	struct passwd *pwdinfo;
	struct proc_bsdshortinfo bsdinfo;
//	char *pw_name;						// process name
	
	error = 0;
	error = proc_pidinfo(pid, PROC_PIDT_SHORTBSDINFO, (uint64_t)0, &bsdinfo, PROC_PIDT_SHORTBSDINFO_SIZE);
	if (error < 1) {
		// no process info couldn't be fetched.
		fprintf(stdout, "\nProcess pid: %d info couldn't be fetched.", pid);
		return NULL;
	}
	pwdinfo = getpwuid(bsdinfo.pbsi_uid);
//	pw_name = pwdinfo->pw_name;
	return pwdinfo->pw_name;
}


/*
 *
 */
static uint64_t get_proc_cputime(pid_t pid) {
	int error;
	struct proc_taskinfo ptinfo;
	
	error = 0;
	error = proc_pidinfo(pid, PROC_PIDTASKINFO, (uint64_t)0, &ptinfo, PROC_PIDTASKINFO_SIZE);
	if (error < 1) {
		// no process info couldn't be fetched.
		fprintf(stdout, "\nProcess pid: %d info couldn't be fetched.", pid);
		return 0;
	}
	
	return (ptinfo.pti_total_user + ptinfo.pti_total_system);
}


/*
 *
 */
static uint64_t get_timestamp() {
	uint64_t timestamp;
	uint64_t mach_time;
	static mach_timebase_info_data_t sTimebaseInfo;
	
	// See "Mach Absolute Time Units" for instructions:
	// https://developer.apple.com/library/mac/qa/qa1398/
	mach_time = mach_absolute_time();
	if (sTimebaseInfo.denom == 0) {
		(void) mach_timebase_info(&sTimebaseInfo);
	}
	timestamp = mach_time * sTimebaseInfo.numer / sTimebaseInfo.denom;
	return timestamp;
}


// ---------------------------------- Obj-c ---------------------------------------

@interface AppInspector ()

- (float)limitFromSliderValue:(double)value;
- (double)sliderValueFromLimit:(float)limit;
- (double)levelIndicatorValueFromCPU:(double)cpu;
- (void)cpuTimerFire:(NSTimer *)timer;

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
	if (attachedToItem) {
		NSMutableDictionary *applicationInfo = [attachedToItem representedObject];
		if (! applicationInfo) {
			NSLog(@"Pleaes provide application info for menu item (represented object).");
			return;
		}
		
		NSImage *icon = [applicationInfo objectForKey:APApplicationInfoIconKey];
		NSString *name = [applicationInfo objectForKey:APApplicationInfoNameKey];
		pid_t pid = [(NSNumber *)[applicationInfo objectForKey:APApplicationInfoPidKey] intValue];
		float limit = [(NSNumber *)[applicationInfo objectForKey:APApplicationInfoLimitKey] floatValue];

//		NSLog(@"app icon: %@", icon);
//		if (! icon) {
////			NSImage *genericIcon = [[NSWorkspace sharedWorkspace] iconForFileType:NSFileTypeForHFSTypeCode(kGenericExtensionIcon)];
//			NSImage *genericIcon = [[NSWorkspace sharedWorkspace] iconForFile:@"/bin/ls"];
//			NSLog(@"generic icon: %@, %@", [genericIcon name], genericIcon);
////			NSLog(@"image types: %@", [NSImage imageFileTypes]);
//			NSLog(@"file type: %@", NSHFSTypeOfFile(@"/usr/bin/ssh"));
//			
//			icon = genericIcon;
//		}
		
		[icon setSize:[_applicationIcon frame].size];
		[_applicationIcon setImage:icon];
		[_applicationNameTextfield setStringValue:[NSString stringWithFormat:@"%@ (%d)", name, pid]];
		if (limit == 0) {
			[_slider setDoubleValue:[_slider maxValue]];
		} else {
			double sliderValue = [self sliderValueFromLimit:limit];
			[_slider setDoubleValue:sliderValue];
		}
		[self updateTextfieldsWithLimitValue:limit];
		
		// TODO: NULL username
		char *proc_username = get_proc_username(pid);
		if (proc_username)
			[_applicationUserTextfield setStringValue:[NSString stringWithFormat:@"User: %@", [NSString stringWithCString:proc_username encoding:NSUTF8StringEncoding]]];
		else
			[_applicationUserTextfield setStringValue:@"User: -"];
		[_applicationCPUTextfield setStringValue:@"\% CPU: 0.00"];
		[_levelIndicator setFloatValue:0.0];
		
		if (_cpuTimer) {
			[_cpuTimer invalidate];
			_cpuTimer = nil;
		}
		
		// Current cpu time for a process
		_cpuTime.cputime = get_proc_cputime(pid);
		_cpuTime.timestamp = get_timestamp();
		NSDictionary *timerUserInfo = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:pid], @"pid", nil];
		_cpuTimer = [NSTimer timerWithTimeInterval:2.0 target:self selector:@selector(cpuTimerFire:) userInfo:timerUserInfo repeats:YES];
		[[NSRunLoop currentRunLoop] addTimer:_cpuTimer forMode:NSRunLoopCommonModes];
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
	cputime = get_proc_cputime(pid);
	timestamp = get_timestamp();
	
	// Info about the process is not available. Stop polling
	if (cputime == 0) {
		[_applicationCPUTextfield setStringValue:@"% CPU: -"];
		[_cpuTimer invalidate];
		_cpuTimer = nil;
		return;
	}
	
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
		percents = (int)floor(limit * 100 + 0.5);
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



- (float)limitFromSliderValue:(double)value {
	double maxValue = [_slider maxValue];
	double minValue = [_slider minValue];
	double middleValue;
	float limit;
	int ncpu = system_ncpu();
//	int ncpu = system_ncpu();
//	maxValue -= [_slider minValue];
//	maxValue -= maxValue / ([_slider numberOfTickMarks] - 1);		// deduct one tick mark
//	limit = value / maxValue * ncpu;
	


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
			limit = (float)(value / middleValue);
		else
			limit = (float)((value - middleValue) / middleValue * (ncpu - 1) + 1);
	} else {
		if (value > maxValue)
			value = maxValue;
		
		limit = (float)(value / maxValue * ncpu);
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


// temp method
- (void)showPopoverRelativeTo:(NSView *)view {
	//	if (popoverViewController == nil) {
	//		popoverViewController = [[NSViewController alloc] initWithNibName:@"AppInspector" bundle:[NSBundle mainBundle]];
	//	}
	
	
	//	NSLog(@"called show popover: %@", popoverViewController);
	[_popover showRelativeToRect:[view bounds] ofView:view preferredEdge:NSMaxXEdge];
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
	[[NSNotificationCenter defaultCenter] removeObserver:self name:AppLimitHintMouseDownNotification object:nil];
}


@end
