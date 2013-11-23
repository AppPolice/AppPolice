//
//  AppPopoverContentView.m
//  AppPolice
//
//  Created by Maksym on 02/11/13.
//  Copyright (c) 2013 Maksym Stefanchuk. All rights reserved.
//

#import "AppPopoverContentView.h"

@implementation AppPopoverContentView


- (void)updateConstraints {
	// Update the rightmost textfield's (200% label below slider) constraint to align
	// more intelligently by using multiplier rather then just a constant.
	// We want the textfield to align its center to the penultimate tick mark even
	// when the slider width changes.
	// This update happens just once when the popover is displayed first time.
	static int addedConstraints = 0;
	if (! addedConstraints) {
		addedConstraints = 1;
//	if (_rightTextfieldConstraint) {
//		[self removeConstraint:_rightTextfieldConstraint];
//		[self removeConstrainnt:_centerTextfieldConstraint];
//		_rightTextfieldConstraint = nil;
//		_centerTextfieldConstraint = nil;
		
		// 0.905: (11 sectors - 1 sector) / 11 sectors
		// 16: 32 is the label width. Offset to align to the center.
		NSLayoutConstraint *rightTextfieldConstraint = [NSLayoutConstraint constraintWithItem:_rightTextfield attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:_slider attribute:NSLayoutAttributeRight multiplier:0.905 constant:16];
		[self addConstraint:rightTextfieldConstraint];
		
		NSLayoutConstraint *centerTextfieldConstraint = [NSLayoutConstraint constraintWithItem:_slider attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:_centerTextfield attribute:NSLayoutAttributeCenterX multiplier:1.07 constant:0];
		[self addConstraint:centerTextfieldConstraint];

	}
	
	[super updateConstraints];
}


@end
