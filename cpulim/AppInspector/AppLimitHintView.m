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

- (void)drawRect:(NSRect)dirtyRect {
	[super drawRect:dirtyRect];
	
	[[NSColor redColor] set];
	NSFrameRect([self bounds]);
}


- (void)viewDidMoveToSuperview {
	NSLog(@"view did move");
	NSTrackingAreaOptions options = NSTrackingActiveInActiveApp | NSTrackingMouseEnteredAndExited;
	NSTrackingArea *trackingArea = [[NSTrackingArea alloc] initWithRect:[self bounds] options:options owner:self userInfo:nil];
	[self addTrackingArea:trackingArea];
	[trackingArea release];
}


- (void)updateTrackingAreas {
	NSLog(@"update trackings");
}


- (void)mouseEntered:(NSEvent *)theEvent {
	NSLog(@"entere");
	[_hintImage setAlphaValue:0];
	[_hintImage setHidden:NO];
	[[NSAnimationContext currentContext] setDuration:0.08];
	[[_hintImage animator] setAlphaValue:1.0];
}

- (void)mouseExited:(NSEvent *)theEvent {
	NSLog(@"exit");
	[NSAnimationContext beginGrouping];
	[[NSAnimationContext currentContext] setDuration:0.1];
	[[NSAnimationContext currentContext] setCompletionHandler:^(void) {
		NSLog(@"complimition handler");
		[_hintImage setHidden:YES];
	}];
	[[_hintImage animator] setAlphaValue:0];
	[NSAnimationContext endGrouping];

}


- (void)mouseUp:(NSEvent *)theEvent {
	if (_delegate) {
		if ([_delegate respondsToSelector:@selector(mouseUp:)]) {
			[_delegate performSelector:@selector(mouseUp:) withObject:self];
		}
	}
	[super mouseUp:theEvent];
}


@end
