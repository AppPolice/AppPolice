//
//  ChromMenuUnderlyingView.m
//  Ishimura
//
//  Created by Maksym on 7/3/13.
//  Copyright (c) 2013 Maksym Stefanchuk. All rights reserved.
//

#import "ChromeMenuUnderlyingView.h"

@implementation ChromeMenuUnderlyingView

- (id)initWithFrame:(NSRect)frameRect borderRadius:(NSArray *)radius {
	self = [super initWithFrame:frameRect];
	if (self) {
		if (radius)
			_borderRadius = [radius retain];
	}
	
	return self;
}

//- (BOOL)acceptsFirstResponder {
//	return YES;
//}

- (void)dealloc {
	[_borderRadius release];
	
	[super dealloc];
}


- (void)drawRect:(NSRect)dirtyRect {	
	NSBezierPath *windowBorder = [NSBezierPath bezierPath];
	
	NSRect rect = [self bounds];
	if (! _borderRadius) {
		[windowBorder appendBezierPathWithRect:rect];
	} else {
		CGFloat bottomLeft = [(NSNumber *)[_borderRadius objectAtIndex:0] doubleValue];
		CGFloat topLeft = [(NSNumber *)[_borderRadius objectAtIndex:1] doubleValue];
		CGFloat topRight = [(NSNumber *)[_borderRadius objectAtIndex:2] doubleValue];
		CGFloat bottomRight = [(NSNumber *)[_borderRadius objectAtIndex:3] doubleValue];
		
		CGFloat width = rect.size.width;
		CGFloat height = rect.size.height;
		
		if (bottomLeft) {
			[windowBorder moveToPoint:NSMakePoint(bottomLeft, 0)];
			[windowBorder appendBezierPathWithArcFromPoint:NSMakePoint(0, 0) toPoint:NSMakePoint(0, bottomLeft) radius:bottomLeft];
		} else {
			[windowBorder moveToPoint:NSMakePoint(0, 0)];
		}
		
		if (topLeft) {
			[windowBorder lineToPoint:NSMakePoint(0, height - topLeft)];
			[windowBorder appendBezierPathWithArcFromPoint:NSMakePoint(0, height) toPoint:NSMakePoint(topLeft, height) radius:topLeft];
		} else {
			[windowBorder lineToPoint:NSMakePoint(0, height)];
		}
		
		if (topRight) {
			[windowBorder lineToPoint:NSMakePoint(width - topRight, height)];
			[windowBorder appendBezierPathWithArcFromPoint:NSMakePoint(width, height) toPoint:NSMakePoint(width, height - topRight) radius:topRight];
		} else {
			[windowBorder lineToPoint:NSMakePoint(width, height)];
		}
		
		if (bottomRight) {
			[windowBorder lineToPoint:NSMakePoint(width, bottomRight)];
			[windowBorder appendBezierPathWithArcFromPoint:NSMakePoint(width, 0) toPoint:NSMakePoint(width - bottomRight, 0) radius:bottomRight];
		} else {
			[windowBorder lineToPoint:NSMakePoint(width, 0)];
		}
		
		[windowBorder closePath];
		
//		[windowBorder appendBezierPathWithRoundedRect:[self bounds] xRadius:5.0 yRadius:5.0];
	}


//	[[NSColor colorWithCalibratedWhite:1.0 alpha:0.95] set];
	[[NSColor colorWithDeviceWhite:1.0 alpha:0.95] set];
	[windowBorder fill];
//	[[NSColor windowFrameColor] set];
//	[[NSColor colorWithDeviceRed:1.0 green:0.5 blue:0.5 alpha:0.7] set];
//	[windowBorder stroke];
	

}


@end
