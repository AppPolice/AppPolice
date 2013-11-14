//
//  AppLimitSliderCell.m
//  Ishimura
//
//  Created by Maksym on 10/8/13.
//  Copyright (c) 2013 Maksym Stefanchuk. All rights reserved.
//

#import <AppKit/AppKit.h>
#import "AppLimitSliderCell.h"


@implementation AppLimitSliderCell

//- (id)init {
//	self = [super init];
//	if (self) {
//		NSLog(@"cell init called");
//	}
//	return self;
//}

//- (void)drawBarInside:(NSRect)aRect flipped:(BOOL)flipped {
//	NSLog(@"draw bar inside called");
//	[[NSColor redColor] set];
//	NSFrameRect(NSMakeRect(aRect.origin.x, aRect.origin.y + 5, aRect.size.width, 10));
	
//	[super drawBarInside:aRect flipped:flipped];
//}

//- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
//	NSLog(@"frame: %@, view: %@", NSStringFromRect(cellFrame), controlView);
//}


//- (void)drawKnob:(NSRect)knobRect {
//	[[NSColor blueColor] set];
//	NSFrameRect(knobRect);
//}

//- (void)awakeFromNib {
//	_penultimateTickMark = [self numberOfTickMarks] - 2;
//	_penultimateTickMarkRect = [self rectOfTickMarkAtIndex:_penultimateTickMark];
//	NSLog(@"rect: %@", NSStringFromRect(_penultimateTickMarkRect));
//	CGFloat knobThickness = [self knobThickness];
//	NSLog(@"thickness: %f", knobThickness);
//	NSLog(@"image: %@", [self image]);
//}


- (BOOL)startTrackingAt:(NSPoint)startPoint inView:(NSView *)controlView {
//	CGFloat value = [self floatValue];
//	CGFloat x = ([self doubleValue] - [self minValue]) / ([self maxValue] - [self minValue]) * ([self trackRect].size.width - [self knobThickness]);
	
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
//	BOOL stopOnTickMarks = [self allowsTickMarkValuesOnly];
	CGFloat value = [self floatValue];
//	NSRect rect = _penultimateTickMarkRect;
//	NSLog(@"value: %f\t last: %f\t current: %f \t delta: %f", value, lastPoint.x, currentPoint.x, _offsetFromKnobCenter);
	
	if (currentPoint.x > _penultimateTickMarkRect.origin.x + _offsetFromKnobCenter) {
		[self setAllowsTickMarkValuesOnly:YES];
		
		// NSSlider value is not being updated once NSSliderCell sets allowsTickMarkValuesOnly.
		// Send the finalizing action manually.
		NSSlider *slider = (NSSlider *)controlView;
		if (value != [slider floatValue]) {
//			NSLog(@"sending extra action for veiw: %@", controlView);
			[NSApp sendAction:[self action] to:[self target] from:self];
		}
	} else if ([self allowsTickMarkValuesOnly]) {
		[self setAllowsTickMarkValuesOnly:NO];
	}

//	if (currentPoint.x < _penultimateTickMarkRect.origin.x + _offsetFromKnobCenter || value < _penultimateTickMark) {
//		if ([self allowsTickMarkValuesOnly])
//			[self setAllowsTickMarkValuesOnly:NO];
//	} else {
//		[self setAllowsTickMarkValuesOnly:YES];
//	}

	
	
	/*
	
	if (value == _penultimateTickMark) {
		if (currentPoint.x < rect.origin.x + _delta)
			[self setAllowsTickMarkValuesOnly:NO];
//		if (currentPoint.x > rect.origin.x) {
//			[self setAllowsTickMarkValuesOnly:YES];
//		} else {
//			if (currentPoint.x < lastPoint.x) {
//				[self setAllowsTickMarkValuesOnly:NO];
//			} //else {
////				[self setAllowsTickMarkValuesOnly:NO];
////			}
//		}
//		if (currentPoint.x <= rect.origin.x)
//			[self setAllowsTickMarkValuesOnly:NO];
	} else if (value > _penultimateTickMark) {
		[self setAllowsTickMarkValuesOnly:YES];
	} else if (stopOnTickMarks) {
		[self setAllowsTickMarkValuesOnly:NO];
	}
	 */
	
	return [super continueTracking:lastPoint at:currentPoint inView:controlView];
}


@end
