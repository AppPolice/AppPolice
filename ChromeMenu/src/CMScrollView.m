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
	CGFloat lineHeight = [self lineScroll];
	CGFloat yOrigin = NSMinY([[self contentView] bounds]);
	if (theEvent.deltaY < 0) {
		yOrigin += lineHeight;
		CGFloat yBound = NSMaxY([[self documentView] bounds]) - NSHeight([[self contentView] bounds]);
		if (yOrigin > yBound) {
			yOrigin = yBound;
		}
	} else if (theEvent.deltaY > 0) {
		yOrigin -= lineHeight;
		if (yOrigin < 0)
			yOrigin = 0;
	}
	

	[[self documentView] scrollPoint:NSMakePoint(0, yOrigin)];
}


@end
