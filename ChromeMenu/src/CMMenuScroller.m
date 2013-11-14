//
//  CMMenuScroller.m
//  Ishimura
//
//  Created by Maksym on 9/7/13.
//  Copyright (c) 2013 Maksym Stefanchuk. All rights reserved.
//

#import <AppKit/AppKit.h>
#import "CMMenuScroller.h"
//#import "NSImage+CMMenuImageRepAdditions.h"

@implementation CMMenuScroller


- (id)initWithScrollerType:(CMMenuScrollerType)scrollerType {
	self = [super init];
	if (self) {
		_scrollerType = scrollerType;
	}
	
	return self;
}


- (void)dealloc {
	[super dealloc];
}



- (void)drawRect:(NSRect)dirtyRect {
	[[NSColor colorWithCalibratedWhite:1.0 alpha:0.95] setFill];
	NSRectFill([self bounds]);

	NSImage *goRightImage = [NSImage imageNamed:NSImageNameGoRightTemplate];
//	[goRightImage setSize:NSMakeSize(8, 10)];
//	NSSize imageSize = [goRightImage size];
//	imageSize = NSMakeSize(imageSize.width - 1, imageSize.height + 1);	// we want it to be 8 by 10 pixels
	NSSize imageSize = NSMakeSize(8.0, 10.0);
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
	
	[goRightImage drawInRect:NSMakeRect(0, 0, imageSize.width, imageSize.height) fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:0.75 respectFlipped:YES hints:nil];
}


- (CMMenuScrollerType)scrollerType {
	return _scrollerType;
}

@end
