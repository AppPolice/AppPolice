//
//  MyCustomWindowView.m
//  Ishimura
//
//  Created by Maksym on 7/3/13.
//  Copyright (c) 2013 Maksym Stefanchuk. All rights reserved.
//

#import "MyCustomWindowView.h"

@implementation MyCustomWindowView

//- (id)initWithFrame:(NSRect)frame
//{
//    self = [super initWithFrame:frame];
//    if (self) {
//        // Initialization code here.
//    }
//    
//    return self;
//}

- (void)drawRect:(NSRect)dirtyRect {
//	[[NSColor whiteColor] set];
//	NSRectFill([self bounds]);
	
	
	NSBezierPath *windowBorder = [NSBezierPath bezierPath];
//	[windowBorder appendBezierPathWithRoundedRect:[self bounds] xRadius:5.0 yRadius:5.0];
	[windowBorder appendBezierPathWithRect:[self bounds]];
	[[NSColor windowFrameColor] set];
	[windowBorder stroke];
	[[NSColor colorWithCalibratedWhite:1.0 alpha:0.95] set];
	[windowBorder fill];
	
//	[self setAlphaValue:0.5];
}

@end
