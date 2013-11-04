//
//  AppLimitSliderCell.h
//  Ishimura
//
//  Created by Maksym on 10/8/13.
//  Copyright (c) 2013 Maksym Stefanchuk. All rights reserved.
//

//#import <Cocoa/Cocoa.h>
@class NSSliderCell;

@interface AppLimitSliderCell : NSSliderCell
{
	@private
	NSInteger _penultimateTickMark;		// the next to last tick mark
	NSRect _penultimateTickMarkRect;
	CGFloat _offsetFromKnobCenter;
}

@end
