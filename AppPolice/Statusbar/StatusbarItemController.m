//
//  StatusbarItemController.m
//  Ishimura
//
//  Created by Maksym on 10/11/13.
//  Copyright (c) 2013 Maksym Stefanchuk. All rights reserved.
//

#import "StatusbarItemController.h"
#import "StatusbarItemView.h"

@implementation StatusbarItemController


// Designated initializer
- (id)init {
	self = [super init];
	if (self) {
		NSStatusBar *statusbar = [NSStatusBar systemStatusBar];
		_statusbarItem = [statusbar statusItemWithLength:NSVariableStatusItemLength];
		[_statusbarItem retain];
		
		CGFloat thickness = [statusbar thickness];
		_view = [[StatusbarItemView alloc] initWithFrame:NSMakeRect(0, 0, 21, thickness)];
		[_statusbarItem setView:_view];
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(statusItemMouseDownNotificationHandler:) name:StatusbarItemLeftMouseDownNotification object:nil];
	}
	return self;
}


- (void)dealloc {
	[[NSStatusBar systemStatusBar] removeStatusItem:_statusbarItem];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
//	[_image release];
//	[_alternateImage release];
	[_view release];
	[_statusbarItem release];
	[_menu release];
	[super dealloc];
}


- (void)setImage:(NSImage *)image {
//	[_image autorelease];
//	_image = [image retain];
	[_view setImage:image];
}


- (NSImage *)image {
	return [_view image];
}


- (void)setAlternateImage:(NSImage *)image {
//	[_alternateImage autorelease];
//	_alternateImage = [image retain];
	[_view setAlternateImage:image];
}


- (NSImage *)alternateImage {
	return [_view alternateImage];
}


- (void)addItemToStatusbar {
	NSStatusBar *statusbar = [NSStatusBar systemStatusBar];
	_statusbarItem = [statusbar statusItemWithLength:NSVariableStatusItemLength];
	[_statusbarItem retain];
	
	
	[_statusbarItem setView:_view];
}


- (void)setStatusbarItemMenu:(CMMenu *)menu {
	[_menu autorelease];
	_menu = [menu retain];
}


- (void)statusItemMouseDownNotificationHandler:(NSNotification *)notification {
//	NSLog(@"mouse down on status item notification: %@", notification);
	NSRect frame = [_view frame];
	frame = [[_view window] convertRectToScreen:frame];
	[_menu popUpMenuForStatusItemWithRect:frame];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(menuDidEndTrackingNotificationHandler:) name:CMMenuDidEndTrackingNotification object:nil];
}


- (void)menuDidEndTrackingNotificationHandler:(NSNotification *)notification {
	[_view setHighlighted:NO];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:CMMenuDidEndTrackingNotification object:nil];
}

@end
