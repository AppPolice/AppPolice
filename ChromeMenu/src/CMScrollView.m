//
//  CMScrollView.m
//  Ishimura
//
//  Created by Maksym on 7/15/13.
//  Copyright (c) 2013 Maksym Stefanchuk. All rights reserved.
//

#import "CMScrollView.h"

const short up = 0;
const short down = 1;


@implementation CMScrollView

//- (void)drawRect:(NSRect)dirtyRect {
//	[[NSColor greenColor] set];
//	NSFrameRect([self bounds]);
//}

- (void)scrollWheel:(NSEvent *)theEvent {
//	NSLog(@"event: %@", theEvent);
	
	CGFloat deltaY = theEvent.deltaY;
	CGFloat lineHeight = [self lineScroll];
//	CGFloat yOrigin = NSMinY([[self contentView] bounds]);
	int multiplier;
	CGFloat amount;
	short direction;
	
	multiplier = (int)ceil(ABS(deltaY) / 2);
	amount = multiplier * lineHeight;
	direction = (deltaY < 0) ? down : up;
	
	[self scrollInDirection:direction byAmount:amount];
	
//	if (deltaY < 0) {
//		yOrigin += lineHeight * multiplier;
//		CGFloat yBound = NSMaxY([[self documentView] bounds]) - NSHeight([[self contentView] bounds]);
//		if (yOrigin > yBound) {
//			yOrigin = yBound;
//		}
//	} else if (deltaY > 0) {
//		yOrigin -= lineHeight * multiplier;
//		if (yOrigin < 0)
//			yOrigin = 0;
//	}
//	
//
//	[[self documentView] scrollPoint:NSMakePoint(0, yOrigin)];
}


- (void)scrollUpByAmount:(CGFloat)amount {
	[self scrollInDirection:up byAmount:amount];
}


- (void)scrollDownByAmount:(CGFloat)amount {
	[self scrollInDirection:down byAmount:amount];
}


- (void)scrollInDirection:(NSInteger)direction byAmount:(CGFloat)amount {
	CGFloat yOrigin = NSMinY([[self contentView] bounds]);
	
	if (direction == down) {
		yOrigin += amount;
		CGFloat yBound = NSMaxY([[self documentView] bounds]) - NSHeight([[self contentView] bounds]);
		if (yOrigin > yBound) {
			yOrigin = yBound;
		}
	} else {
		yOrigin -= amount;
		if (yOrigin < 0)
			yOrigin = 0;
	}
	
	
	[[self documentView] scrollPoint:NSMakePoint(0, yOrigin)];
}

@end
