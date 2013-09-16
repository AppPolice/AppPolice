//
//  CMMenuScroller.m
//  Ishimura
//
//  Created by Maksym on 9/7/13.
//  Copyright (c) 2013 Maksym Stefanchuk. All rights reserved.
//

#import "CMMenuScroller.h"
#import "NSImage+CMMenuImageRepAdditions.h"

@implementation CMMenuScroller


- (id)initWithScrollerType:(CMMenuScrollerType)scrollerType {
	self = [super init];
	if (self) {
		_scrollerType = scrollerType;
//		NSImageView *arrowView = [[NSImageView alloc] init];
//		[arrowView setImage:[NSImage imageNamed:NSImageNameGoRightTemplate]];
//		[self addSubview:arrowView];
//		[arrowView release];
	}
	
	return self;
}


- (void)dealloc {
	if (_trackingArea)
		[_trackingArea release];
	[super dealloc];
}


//- (void)viewDidMoveToSuperview {
//	NSLog(@"scroller moved to superview, rect: %@", NSStringFromRect([self bounds]));
//	NSImageView *arrowView = [[self subviews] objectAtIndex:0];
//	CGFloat width = 9;
//	CGFloat height = 9;
//	CGFloat x = (self.bounds.size.width - width ) / 2;
//	CGFloat y = self.bounds.size.height - height - 1;
//	[arrowView setFrame:NSMakeRect(x, y, width, height)];
//}


- (void)drawRect:(NSRect)dirtyRect {
//	NSLog(@"Scroller draw called, type: %ld", _scrollerType);
//	NSLog(@"frame: %@, bounds: %@, dirty: %@",
//		  NSStringFromRect([self frame]),
//		  NSStringFromRect([self bounds]),
//		  NSStringFromRect(dirtyRect));
	
//	[[NSColor redColor] set];
//	NSFrameRect([self bounds]);
	
	[[NSColor colorWithCalibratedWhite:1.0 alpha:0.95] setFill];
	NSRectFill([self bounds]);
//
//	NSBezierPath *path = [NSBezierPath bezierPath];
//	[path appendBezierPathWithRect:[self bounds]];
//	[path stroke];
	

	NSImage *goRightImage = [NSImage imageNamed:NSImageNameGoRightTemplate];
	NSSize imageSize = [goRightImage size];
	imageSize = NSMakeSize(imageSize.width - 1, imageSize.height + 1);	// we want it to be 8 by 10 pixels
//	NSSize imageSize = NSMakeSize(8.0, 10.0);
//	imageSize.width -= 1.5;
	

	NSAffineTransform *transform = [NSAffineTransform transform];
	if (_scrollerType == CMMenuScrollerTop) {
		CGFloat translateX = floor((self.bounds.size.width + imageSize.height) / 2);
		[transform translateXBy:translateX yBy:0.0];
		[transform rotateByDegrees:90.0];
		[transform translateXBy:(self.bounds.size.height - imageSize.width) yBy:0.0];
	} else {
		CGFloat translateX = floor((self.bounds.size.width - imageSize.height) / 2);
		[transform translateXBy:translateX yBy:0.0];
		[transform rotateByDegrees:-90.0];
		[transform translateXBy:-(imageSize.width + 1) yBy:0.0];
	}
//	NSAffineTransformStruct matrix = [transform transformStruct];
//	NSLog(@"matrix m1: %f, m2: %f, m3: %f, m4: %f, t1: %f, t2: %f",
//		  matrix.m11,
//		  matrix.m12,
//		  matrix.m21,
//		  matrix.m22,
//		  matrix.tX,
//		  matrix.tY);
	

	[transform concat];

//	[[NSColor redColor] setStroke];
//	NSFrameRect(NSMakeRect(0, 0, 100, 15));
	
//	NSImageView *arrowView = [[self subviews] objectAtIndex:0];
//	NSImage *image = [arrowView image];

//	NSLog(@"image Size: %@", NSStringFromSize(imageSize));
	
//	NSImageRep *rep = [goRightImage defaultImageRepresentation];
//	[rep drawInRect:NSMakeRect(0, 0, imageSize.width, imageSize.height) fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:0.75 respectFlipped:YES hints:nil];
	
	[goRightImage drawInRect:NSMakeRect(0, 0, imageSize.width, imageSize.height) fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:0.75 respectFlipped:YES hints:nil];
	
//	NSLog(@"bounds: %@", NSStringFromRect([self bounds]));
//	[arrowView lockFocus];
//	[[NSColor redColor] setStroke];
//	NSFrameRect(NSMakeRect(0, 0, 15, 10));
//
//	NSLog(@"bounds: %@", NSStringFromRect([self bounds]));
//	[arrowView unlockFocus];
	
//	NSLog(@"image reps: %@", [image representations]);
	
//	[[NSColor blueColor] setFill];
//	NSRectFill([self bounds]);
	
}


- (CMMenuScrollerType)scrollerType {
	return _scrollerType;
}


- (void)setTrackingArea:(NSTrackingArea *)trackingArea {
	if (_trackingArea != trackingArea) {
		if (_trackingArea)
			[_trackingArea release];
		if (trackingArea)
			_trackingArea = [trackingArea retain];
		else
			_trackingArea = nil;
	}
}


- (NSTrackingArea *)trackingArea {
	return _trackingArea;
}

@end
