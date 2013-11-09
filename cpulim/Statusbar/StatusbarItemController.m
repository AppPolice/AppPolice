//
//  StatusbarItemController.m
//  Ishimura
//
//  Created by Maksym on 10/11/13.
//  Copyright (c) 2013 Maksym Stefanchuk. All rights reserved.
//

#import "StatusbarItemController.h"
#import "StatusbarItemView.h"
#import "ChromeMenu.h"

@implementation StatusbarItemController


// Designated initializer
- (id)init {
	self = [super init];
	if (self) {
		NSStatusBar *statusbar = [NSStatusBar systemStatusBar];
		_statusbarItem = [statusbar statusItemWithLength:NSVariableStatusItemLength];
		[_statusbarItem retain];
		
		CGFloat thickness = [statusbar thickness];
//		NSLog(@"thickness: %f", thickness);
		_view = [[StatusbarItemView alloc] initWithFrame:NSMakeRect(0, 0, 21, thickness)];
		[_statusbarItem setView:_view];
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(statusItemMouseDownNotificationHandler:) name:StatusbarItemLeftMouseDownNotification object:nil];
	}
	return self;
}


- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[_view release];
	[_statusbarItem release];
	[_menu release];
	[super dealloc];
}


- (void)setImage:(NSImage *)image {
	[_image autorelease];
	_image = [image retain];
	[_view setImage:image];
}


- (NSImage *)image {
	return _image;
}


- (void)setAlternateImage:(NSImage *)image {
	[_alternateImage autorelease];
	_alternateImage = [image retain];
	[_view setAlternateImage:image];
}


- (NSImage *)alternateImage {
	return _alternateImage;
}


- (void)addItemToStatusbar {
	NSStatusBar *statusbar = [NSStatusBar systemStatusBar];
	_statusbarItem = [statusbar statusItemWithLength:NSVariableStatusItemLength];
	[_statusbarItem retain];
	
	
	[_statusbarItem setView:_view];
	
//	NSString *imagePath = [[NSBundle mainBundle] pathForResource:@"statusbar_image" ofType:@"tiff"];
//	NSImage *ico = [[[NSImage alloc] initWithContentsOfFile:imagePath] autorelease];
//	imagePath = [[NSBundle mainBundle] pathForResource:@"statusbar_image_inv" ofType:@"tiff"];
//	NSImage *ico_alt = [[[NSImage alloc] initWithContentsOfFile:imagePath] autorelease];
//	
//	//	[_statusbarItem setTitle:NSLocalizedString(@"Ishimura", @"")];
//	[_statusbarItem setImage:ico];
//	[_statusbarItem setAlternateImage:ico_alt];
//	[_statusbarItem setHighlightMode:YES];
//	[_statusbarItem setTarget:self];
//	[_statusbarItem setAction:@selector(statusbarItemAction:)];
//	[_statusbarItem sendActionOn:NSLeftMouseDownMask | NSRightMouseDownMask];
}


- (void)setStatusbarItemMenu:(CMMenu *)menu {
	[_menu autorelease];
	_menu = [menu retain];
}


- (void)statusItemMouseDownNotificationHandler:(NSNotification *)notification {
	NSLog(@"mouse down on status item notification: %@", notification);
	NSRect frame = [_view frame];
	frame = [[_view window] convertRectToScreen:frame];
	[_menu popUpMenuForStatusItemWithRect:frame];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(menuDidEndTrackingNotificationHandler:) name:CMMenuDidEndTrackingNotification object:nil];
}


- (void)menuDidEndTrackingNotificationHandler:(NSNotification *)notification {
	[_view setHighlighted:NO];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:CMMenuDidEndTrackingNotification object:nil];
	NSLog(@"menu did end: %@", notification);
}

@end
