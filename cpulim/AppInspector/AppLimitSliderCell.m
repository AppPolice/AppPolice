//
//  AppLimitSliderCell.m
//  Ishimura
//
//  Created by Maksym on 10/8/13.
//  Copyright (c) 2013 Maksym Stefanchuk. All rights reserved.
//

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


//- (void)drawKnob:(NSRect)knobRect {
//	[[NSColor blueColor] set];
//	NSFrameRect(knobRect);
//}

- (void)awakeFromNib {
	_penultimateTickMark = [self numberOfTickMarks] - 2;
	_penultimateTickMarkRect = [self rectOfTickMarkAtIndex:_penultimateTickMark];
	NSLog(@"rect: %@", NSStringFromRect(_penultimateTickMarkRect));
	CGFloat knobThickness = [self knobThickness];
	NSLog(@"thickness: %f", knobThickness);
	NSLog(@"image: %@", [self image]);
}


- (BOOL)continueTracking:(NSPoint)lastPoint at:(NSPoint)currentPoint inView:(NSView *)controlView {
	NSLog(@"continue tracking: lastpoint: %@, current point: %@", NSStringFromPoint(lastPoint), NSStringFromPoint(currentPoint));
	
	CGFloat value = [self floatValue];
	if (value >= _penultimateTickMark) {
		
	}
	
	return [super continueTracking:lastPoint at:currentPoint inView:controlView];
}

@end
