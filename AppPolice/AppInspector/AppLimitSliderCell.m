//
//  AppLimitSliderCell.m
//  AppPolice
//
//  Created by Maksym on 10/8/13.
//  Copyright (c) 2013 Maksym Stefanchuk. All rights reserved.
//

#import "AppLimitSliderCell.h"

@implementation AppLimitSliderCell


- (BOOL)startTrackingAt:(NSPoint)startPoint inView:(NSView *)controlView {
	_penultimateTickMark = [self numberOfTickMarks] - 2;
	_penultimateTickMarkRect = [self rectOfTickMarkAtIndex:_penultimateTickMark];
	
	NSRect knobRect = [self knobRectFlipped:[controlView isFlipped]];
	CGFloat knobThickness = [self knobThickness];
	_offsetFromKnobCenter = startPoint.x - knobRect.origin.x - knobThickness / 2;
	if (ABS(_offsetFromKnobCenter) > knobThickness / 2)
		_offsetFromKnobCenter = 0;
	
//	NSLog(@"Start tracking, value: %f", [self floatValue]);
//	NSLog(@"Start tracking, offset from knob: %f\tstart point: %@", _offsetFromKnobCenter, NSStringFromPoint(startPoint));

	// When the mouse is down between penultimate and final tick marks
	// the slider is not yet sticky and the value is wrong. Run the method
	// manually once to validate mouse starting point.
	(void) [self continueTracking:NSMakePoint(0, 0) at:startPoint inView:controlView];
	
	return [super startTrackingAt:startPoint inView:controlView];
}


- (BOOL)continueTracking:(NSPoint)lastPoint at:(NSPoint)currentPoint inView:(NSView *)controlView {
	CGFloat value = [self floatValue];
//	NSLog(@"value: %f\t last: %f\t current: %f \t delta: %f", value, lastPoint.x, currentPoint.x, _offsetFromKnobCenter);
	
	if (currentPoint.x > _penultimateTickMarkRect.origin.x + _offsetFromKnobCenter) {
		[self setAllowsTickMarkValuesOnly:YES];
		
		// NSSlider value is not being updated once NSSliderCell sets allowsTickMarkValuesOnly.
		// Send the finalizing action manually.
		NSSlider *slider = (NSSlider *)controlView;
		if (value != [slider floatValue]) {
			[NSApp sendAction:[self action] to:[self target] from:self];
		}
	} else if ([self allowsTickMarkValuesOnly]) {
		[self setAllowsTickMarkValuesOnly:NO];
	}
	
	return [super continueTracking:lastPoint at:currentPoint inView:controlView];
}


@end
