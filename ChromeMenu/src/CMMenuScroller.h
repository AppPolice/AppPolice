//
//  CMMenuScroller.h
//  Ishimura
//
//  Created by Maksym on 9/7/13.
//  Copyright (c) 2013 Maksym Stefanchuk. All rights reserved.
//

//#import <Cocoa/Cocoa.h>

@class NSView, NSTrackingArea;

enum {
	CMMenuScrollerTop = 1,
	CMMenuScrollerBottom = 2
};
typedef NSUInteger CMMenuScrollerType;



@interface CMMenuScroller : NSView
{
	@private
	CMMenuScrollerType _scrollerType;
	NSTrackingArea *_trackingArea;
}

- (id)initWithScrollerType:(CMMenuScrollerType)scrollerType;

- (CMMenuScrollerType)scrollerType;

@end
