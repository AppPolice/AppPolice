//
//  AppLimitHintView.m
//  AppPolice
//
//  Created by Maksym on 10/9/13.
//  Copyright (c) 2013 Maksym Stefanchuk. All rights reserved.
//

#import "AppInspector.h"
#import "AppLimitHintView.h"

@implementation AppLimitHintView


- (void)dealloc {
	[_trackingArea release];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[super dealloc];
}


- (void)viewDidMoveToSuperview {
	[self updateTrackingAreas];
	
	if (! _observingAppInspectorNotifications) {
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(appInsepctorPopoverDidShowNotificationHandler:)
													 name:APAppInspectorPopoverDidShow
												   object:nil];
		_observingAppInspectorNotifications = YES;
	}
}


- (void)updateTrackingAreas {
	if (_trackingArea) {
		[self removeTrackingArea:_trackingArea];
		[_trackingArea release];
		_trackingArea = nil;
	}
	
	NSTrackingAreaOptions options = NSTrackingActiveAlways | NSTrackingMouseEnteredAndExited;
	_trackingArea = [[NSTrackingArea alloc] initWithRect:[self bounds] options:options owner:self userInfo:nil];
	[self addTrackingArea:_trackingArea];
	
	// Run RunLoop in default mode for AppKit to update tracking areas
	CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0, YES);
}


- (void)mouseEntered:(NSEvent *)theEvent {
	[_hintImage setAlphaValue:0];
	[_hintImage setHidden:NO];
	[[NSAnimationContext currentContext] setDuration:0.08];
	[[_hintImage animator] setAlphaValue:1.0];
}


- (void)mouseExited:(NSEvent *)theEvent {
	[_hintImage setHidden:YES];
//	[NSAnimationContext beginGrouping];
//	[[NSAnimationContext currentContext] setDuration:0.1];
//	[[NSAnimationContext currentContext] setCompletionHandler:^(void) {
//		[_hintImage setHidden:YES];
//	}];
//	[[_hintImage animator] setAlphaValue:0];
//	[NSAnimationContext endGrouping];
}


- (void)mouseDown:(NSEvent *)theEvent {
	NSNotification *notification = [NSNotification notificationWithName:APAppLimitHintMouseDownNotification object:self userInfo:nil];
	[[NSNotificationQueue defaultQueue] enqueueNotification:notification
											   postingStyle:NSPostASAP
											   coalesceMask:NSNotificationCoalescingOnName
												   forModes:[NSArray arrayWithObject:NSRunLoopCommonModes]];
	
//	[super mouseUp:theEvent];
}


- (void)appInsepctorPopoverDidShowNotificationHandler:(NSNotification *)notification {
	[self updateTrackingAreas];
}


@end
