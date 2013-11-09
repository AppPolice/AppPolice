//
//  ChromMenuUnderlyingView.m
//  Ishimura
//
//  Created by Maksym on 7/3/13.
//  Copyright (c) 2013 Maksym Stefanchuk. All rights reserved.
//

#import "ChromeMenuUnderlyingView.h"

@implementation ChromeMenuUnderlyingView

- (id)initWithFrame:(NSRect)frameRect borderRadiuses:(NSArray *)radiuses {
	self = [super initWithFrame:frameRect];
	if (self) {
		if (radiuses)
			_borderRadiuses = [radiuses retain];
	}
	
	return self;
}

//- (BOOL)acceptsFirstResponder {
//	return YES;
//}

- (void)dealloc {
	[_borderRadiuses release];
	
	[super dealloc];
}


- (void)drawRect:(NSRect)dirtyRect {	
	NSBezierPath *windowBorder = [NSBezierPath bezierPath];
	
	NSRect rect = [self bounds];
	if (! _borderRadiuses) {
		[windowBorder appendBezierPathWithRect:rect];
	} else {
		CGFloat bottomLeft = [(NSNumber *)[_borderRadiuses objectAtIndex:0] doubleValue];
		CGFloat topLeft = [(NSNumber *)[_borderRadiuses objectAtIndex:1] doubleValue];
		CGFloat topRight = [(NSNumber *)[_borderRadiuses objectAtIndex:2] doubleValue];
		CGFloat bottomRight = [(NSNumber *)[_borderRadiuses objectAtIndex:3] doubleValue];
		
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


- (void)setBorderRadiuses:(NSArray *)radiuses {
	if (_borderRadiuses != radiuses) {
		BOOL radiusesEqual = YES;
		if (_borderRadiuses) {
			NSUInteger len = [_borderRadiuses count];
			NSUInteger i;
			for (i = 0; i < len; ++i) {
				if (! [_borderRadiuses[i] isEqualToNumber:radiuses[i]]) {
					radiusesEqual = NO;
					break;
				}
			}
		} else {
			radiusesEqual = NO;
		}
		
		[_borderRadiuses release];
		_borderRadiuses = [radiuses retain];
		if (! radiusesEqual) {
			[self setNeedsDisplay:YES];
//			NSLog(@"new radisues are set!!!");
		}
	}
}


- (BOOL)shouldDelayWindowOrderingForEvent:(NSEvent *)theEvent {
	NSLog(@"should delay: %@", theEvent);
	return YES;
}

- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent {
	NSLog(@"accepts first mouse: %@", theEvent);
	return YES;
}


- (void)mouseDown:(NSEvent *)theEvent {
	[NSApp preventWindowOrdering];
}



@end
