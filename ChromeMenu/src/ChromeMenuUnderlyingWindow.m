//
//  ChromMenuUnderlyingWindow.m
//  Ishimura
//
//  Created by Maksym on 7/3/13.
//  Copyright (c) 2013 Maksym Stefanchuk. All rights reserved.
//

#import "ChromeMenuUnderlyingWindow.h"

@implementation ChromeMenuUnderlyingWindow

- (id)initWithContentRect:(NSRect)contentRect defer:(BOOL)flag {
	return [self initWithContentRect:contentRect styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:YES];
}


- (id)initWithContentRect:(NSRect)contentRect styleMask:(NSUInteger)aStyle backing:(NSBackingStoreType)bufferingType defer:(BOOL)flag {
	if (self = [super initWithContentRect:contentRect styleMask:aStyle backing:bufferingType defer:flag]) {
		[self setBackgroundColor:[NSColor clearColor]];
		[self setHasShadow:YES];
		[self setOpaque:NO];
//		[self setAlphaValue:0.5];
//		[self setHasShadow:NO];
	}
	return self;
}

//- (BOOL)canBecomeKeyWindow {
//	NSLog(@"aksed if canBecomeKeyWindow");
//	return NO;
//}


@end
