//
//  CMScrollView.m
//  Ishimura
//
//  Created by Maksym on 7/15/13.
//  Copyright (c) 2013 Maksym Stefanchuk. All rights reserved.
//

#import "CMScrollView.h"

@implementation CMScrollView


- (void)scrollWheel:(NSEvent *)theEvent {
	CGFloat deltaY = theEvent.deltaY;
	CGFloat lineHeight = [self lineScroll];
	CGFloat yOrigin = NSMinY([[self contentView] bounds]);
	int multiplier;
	
	multiplier = ceil(ABS(deltaY) / 2);
	
	if (deltaY < 0) {
		yOrigin += lineHeight * multiplier;
		CGFloat yBound = NSMaxY([[self documentView] bounds]) - NSHeight([[self contentView] bounds]);
		if (yOrigin > yBound) {
			yOrigin = yBound;
		}
	} else if (deltaY > 0) {
		yOrigin -= lineHeight * multiplier;
		if (yOrigin < 0)
			yOrigin = 0;
	}
	

	[[self documentView] scrollPoint:NSMakePoint(0, yOrigin)];
}


@end
