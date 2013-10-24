//
//  CMScrollView.m
//  Ishimura
//
//  Created by Maksym on 7/15/13.
//  Copyright (c) 2013 Maksym Stefanchuk. All rights reserved.
//

#import "CMScrollView.h"

static const short up = 0;
static const short down = 1;


@implementation CMScrollView


- (void)scrollWheel:(NSEvent *)theEvent {
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
}


- (void)scrollWithEvent:(NSEvent *)theEvent {
	CGFloat deltaY = theEvent.deltaY;
	CGFloat lineHeight = [self lineScroll];
	int multiplier;
	CGFloat amount;
	short direction;
	
	multiplier = (int)ceil(ABS(deltaY) / 2);
	amount = multiplier * lineHeight;
	direction = (deltaY < 0) ? down : up;
	
	[self scrollInDirection:direction byAmount:amount];
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
		CGFloat yBound = NSMaxY([[self documentView] bounds]) - NSHeight([[self contentView] bounds]);
		if (yOrigin == yBound) {	// no need to update contentView
			NSLog(@"no more down: %@", NSStringFromRect([[self contentView] bounds]));
			return;
		}
		
		yOrigin += amount;
		if (yOrigin > yBound) {
			NSLog(@"new yOrigin");
			yOrigin = yBound;
		}
	} else {
		if (yOrigin == 0) {	// no need to update contentView
			NSLog(@"no more up: %@",  NSStringFromRect([[self contentView] bounds]));
			return;
		}
		yOrigin -= amount;
		if (yOrigin < 0)
			yOrigin = 0;
	}
	
	[[self contentView] setBoundsOrigin:NSMakePoint(0, yOrigin)];
//	[[self documentView] scrollPoint:NSMakePoint(0, yOrigin)];
}

@end
