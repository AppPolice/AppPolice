//
//  CMMenuScroller.m
//  Ishimura
//
//  Created by Maksym on 9/7/13.
//  Copyright (c) 2013 Maksym Stefanchuk. All rights reserved.
//

#import "CMMenuScroller.h"

@implementation CMMenuScroller

//- (id)initWithFrame:(NSRect)frame
//{
//    self = [super initWithFrame:frame];
//    if (self) {
//        // Initialization code here.
//    }
//    
//    return self;
//}

- (id)initWithScrollerType:(CMMenuScrollerType)scrollerType {
	self = [super init];
	if (self) {
		_scrollerType = scrollerType;
	}
	
	return self;
}

- (void)drawRect:(NSRect)dirtyRect {
//	NSLog(@"Scroller draw called, type: %ld", _scrollerType);
//	NSLog(@"frame: %@, bounds: %@, dirty: %@",
//		  NSStringFromRect([self frame]),
//		  NSStringFromRect([self bounds]),
//		  NSStringFromRect(dirtyRect));
	
	[[NSColor redColor] set];
	NSFrameRect([self bounds]);
	
//	[[NSColor blueColor] setFill];
//	NSRectFill([self bounds]);
	
	NSBezierPath *path = [NSBezierPath bezierPath];
	//	[windowBorder appendBezierPathWithRoundedRect:[self bounds] xRadius:5.0 yRadius:5.0];
	[path appendBezierPathWithRect:[self bounds]];
	[[NSColor colorWithCalibratedWhite:1.0 alpha:0.95] set];
	[path fill];

}

@end
