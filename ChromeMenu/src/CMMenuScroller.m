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
		NSImageView *arrowView = [[NSImageView alloc] init];
		[arrowView setImage:[NSImage imageNamed:NSImageNameGoRightTemplate]];
		[self addSubview:arrowView];
		[arrowView release];
	}
	
	return self;
}


- (void)viewDidMoveToSuperview {
	NSLog(@"scroller moved to superview, rect: %@", NSStringFromRect([self bounds]));
	NSImageView *arrowView = [[self subviews] objectAtIndex:0];
	CGFloat width = 10;
	CGFloat height = 8;
	CGFloat x = (self.bounds.size.width - width ) / 2;
	CGFloat y = self.bounds.size.height - height - 1;
	[arrowView setFrame:NSMakeRect(x, y, width, height)];
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
	[[NSColor colorWithCalibratedWhite:1.0 alpha:0.5] set];
//	[[NSColor clearColor] setFill];
	[path fill];

}

@end
