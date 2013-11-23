//
//  AppLoadLevelIndicator.m
//  AppPolice
//
//  Created by Maksym on 10/7/13.
//  Copyright (c) 2013 Maksym Stefanchuk. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AppLoadLevelIndicator.h"

@implementation AppLoadLevelIndicator


// Draw custom Level Indicator
- (void)drawRect:(NSRect)dirtyRect {
//	[super drawRect:dirtyRect];
	
	NSRect rect = [self bounds];
	float value = [self floatValue];
	double minValue = [self minValue];
	double maxValue = [self maxValue];
	double percents = (value - minValue) / (maxValue - minValue);
	CGFloat x = rect.size.width * percents;
	double warningValue = [self warningValue];
	double criticalValue = [self criticalValue];
	
	[[NSColor colorWithCalibratedRed:0.7 green:0.7 blue:0.7 alpha:0.95] setFill];
	NSRectFill(rect);
	
	if (value < warningValue) {
//		[[NSColor colorWithCalibratedRed:0.031 green:0.7 blue:0.33 alpha:1.0] setFill];
		[[NSColor colorWithCalibratedRed:0.0 green:0.82 blue:0.36 alpha:1.0] setFill];
	} else if (value < criticalValue) {
//		[[NSColor colorWithCalibratedRed:0.87 green:0.74 blue:0.0 alpha:1.0] setFill];
//		[[NSColor colorWithCalibratedRed:0.72 green:0.82 blue:0.0 alpha:1.0] setFill];
		[[NSColor colorWithCalibratedRed:0.8 green:0.7 blue:0.1 alpha:1.0] setFill];
	} else {
		[[NSColor colorWithCalibratedRed:1.0 green:0.38 blue:0.38 alpha:1.0] setFill];
	}
	NSRectFill(NSMakeRect(rect.origin.x, rect.origin.y, x, rect.size.height));
}

@end
