//
//  HintPopoverTextField.m
//  Ishimura
//
//  Created by Maksym on 10/10/13.
//  Copyright (c) 2013 Maksym Stefanchuk. All rights reserved.
//

#import "HintPopoverTextField.h"

@implementation HintPopoverTextField


/*
 * Override default NSTextField's method to return actual size of textfield when
 *	cell wraps the content.
 */
- (NSSize)intrinsicContentSize {
	if (! [[self cell] wraps])
		return [super intrinsicContentSize];
	
	NSRect frame = [self bounds];
	// set height big enough to fit eny text
	frame.size.height = CGFLOAT_MAX;
	// calculate new size for content
	NSSize cellSize = [[self cell] cellSizeForBounds:frame];
	return cellSize;
}


@end
