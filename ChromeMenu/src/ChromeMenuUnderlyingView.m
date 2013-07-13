//
//  ChromMenuUnderlyingView.m
//  Ishimura
//
//  Created by Maksym on 7/3/13.
//  Copyright (c) 2013 Maksym Stefanchuk. All rights reserved.
//

#import "ChromeMenuUnderlyingView.h"

@implementation ChromeMenuUnderlyingView

//- (id)initWithFrame:(NSRect)frame {
//    self = [super initWithFrame:frame];
//    if (self) {
//        // Initialization code here.
////		[self setHidden:YES];
//    }
//    
//    return self;
//}

- (void)drawRect:(NSRect)dirtyRect {
	NSBezierPath *windowBorder = [NSBezierPath bezierPath];
	//	[windowBorder appendBezierPathWithRoundedRect:[self bounds] xRadius:5.0 yRadius:5.0];
	[windowBorder appendBezierPathWithRect:[self bounds]];
	[[NSColor windowFrameColor] set];
	[windowBorder stroke];
	[[NSColor colorWithCalibratedWhite:1.0 alpha:0.95] set];
	[windowBorder fill];
}


//- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent {
//	return YES;
//}


@end
