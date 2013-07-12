//
//  ChromMenuUnderlyingWindow.m
//  Ishimura
//
//  Created by Maksym on 7/3/13.
//  Copyright (c) 2013 Maksym Stefanchuk. All rights reserved.
//

#import "ChromeMenuUnderlyingWindow.h"

@implementation ChromeMenuUnderlyingWindow

- (id)initWithContentRect:(NSRect)contentRect styleMask:(NSUInteger)aStyle backing:(NSBackingStoreType)bufferingType defer:(BOOL)flag {
	if (self = [super initWithContentRect:contentRect styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:YES]) {
		[self setBackgroundColor:[NSColor clearColor]];
		[self setOpaque:NO];
		//		[self setAlphaValue:0.95];
	}
	return self;
}


//- (BOOL)canBecomeKeyWindow {
//	return YES;
//}

- (void)mouseDown:(NSEvent *)theEvent {
	NSLog(@"Mouse Down");
    // Get the mouse location in window coordinates.
    initialLocation = [theEvent locationInWindow];
}


/*
 Once the user starts dragging the mouse, move the window with it. The window has no title bar for
 the user to drag (so we have to implement dragging ourselves)
 */
- (void)mouseDragged:(NSEvent *)theEvent {
    
    NSRect screenVisibleFrame = [[NSScreen mainScreen] visibleFrame];
    NSRect windowFrame = [self frame];
    NSPoint newOrigin = windowFrame.origin;
	
    // Get the mouse location in window coordinates.
    NSPoint currentLocation = [theEvent locationInWindow];
    // Update the origin with the difference between the new mouse location and the old mouse location.
    newOrigin.x += (currentLocation.x - initialLocation.x);
    newOrigin.y += (currentLocation.y - initialLocation.y);
	
    // Don't let window get dragged up under the menu bar
    if ((newOrigin.y + windowFrame.size.height) > (screenVisibleFrame.origin.y + screenVisibleFrame.size.height)) {
        newOrigin.y = screenVisibleFrame.origin.y + (screenVisibleFrame.size.height - windowFrame.size.height);
    }
    
    // Move the window to the new location
    [self setFrameOrigin:newOrigin];
}


- (void)keyDown:(NSEvent *)theEvent {
	[super keyDown:theEvent];
	NSLog(@"window key down event");
}


@end
