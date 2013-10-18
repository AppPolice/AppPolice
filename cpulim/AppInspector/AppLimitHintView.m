//
//  AppLimitHintView.m
//  Ishimura
//
//  Created by Maksym on 10/9/13.
//  Copyright (c) 2013 Maksym Stefanchuk. All rights reserved.
//

#import "AppLimitHintView.h"

@implementation AppLimitHintView

//- (id)initWithFrame:(NSRect)frame
//{
//    self = [super initWithFrame:frame];
//    if (self) {
//        // Initialization code here.
//    }
//    return self;
//}

//- (void)drawRect:(NSRect)dirtyRect {
//	[super drawRect:dirtyRect];
//	
//	[[NSColor redColor] set];
//	NSFrameRect([self bounds]);
//}

- (void)dealloc {
	[_trackingArea release];
	[super dealloc];
}


- (void)viewDidMoveToSuperview {
//	NSLog(@"view did move");
//	NSTrackingAreaOptions options = NSTrackingActiveInActiveApp | NSTrackingMouseEnteredAndExited;
//	_trackingArea = [[NSTrackingArea alloc] initWithRect:[self bounds] options:options owner:self userInfo:nil];
//	[self addTrackingArea:_trackingArea];
	[self updateTrackingAreas];
}


- (void)updateTrackingAreas {
	NSLog(@"update trackings");
	if (_trackingArea) {
		[self removeTrackingArea:_trackingArea];
		[_trackingArea release];
	}
	NSTrackingAreaOptions options = NSTrackingActiveInActiveApp | NSTrackingMouseEnteredAndExited;
	_trackingArea = [[NSTrackingArea alloc] initWithRect:[self bounds] options:options owner:self userInfo:nil];
	[self addTrackingArea:_trackingArea];
}


- (void)mouseEntered:(NSEvent *)theEvent {
//	NSLog(@"entere");
	[_hintImage setAlphaValue:0];
	[_hintImage setHidden:NO];
	[[NSAnimationContext currentContext] setDuration:0.08];
	[[_hintImage animator] setAlphaValue:1.0];
}


- (void)mouseExited:(NSEvent *)theEvent {
//	NSLog(@"exit");
	
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
//	if (_delegate) {
//		if ([_delegate respondsToSelector:@selector(mouseUp:)]) {
//			[_delegate performSelector:@selector(mouseUp:) withObject:self];
//		}
//	}
//	[[NSNotificationCenter defaultCenter] postNotificationName:AppLimitHintMouseDownNotification object:self userInfo:nil];
	NSNotification *notification = [NSNotification notificationWithName:AppLimitHintMouseDownNotification object:self userInfo:nil];
	[[NSNotificationQueue defaultQueue] enqueueNotification:notification postingStyle:NSPostASAP coalesceMask:NSNotificationCoalescingOnName forModes:[NSArray arrayWithObject:NSRunLoopCommonModes]];
	
	[super mouseUp:theEvent];
}


@end
