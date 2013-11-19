//
//  CMMenuItemSeparatorView.m
//  Ishimura
//
//  Created by Maksym on 7/22/13.
//  Copyright (c) 2013 Maksym Stefanchuk. All rights reserved.
//

#import "CMMenuItemSeparatorView.h"

@implementation CMMenuItemSeparatorView


- (void)drawRect:(NSRect)dirtyRect {
//	NSLog(@"separator frame: %@", NSStringFromRect([self frame]));
	
	NSBezierPath *line = [NSBezierPath bezierPath];
	// we wan't pixel precies drawing, thus the shift by 0.5
	[line moveToPoint:NSMakePoint(1, 5.5)];
	[line lineToPoint:NSMakePoint([self bounds].size.width - 1, 5.5)];
	[[NSColor colorWithSRGBRed:0.85 green:0.85 blue:0.85 alpha:0.9] set];
	[line stroke];
}


- (BOOL)needsTracking {
	return NO;
}


@end
