//
//  TestTableRowView.m
//  Ishimura
//
//  Created by Maksym on 6/3/13.
//  Copyright (c) 2013 Maksym Stefanchuk. All rights reserved.
//

#import "TestTableRowView.h"

@interface TestTableRowView()
	@property BOOL mouseInside;
@end

@implementation TestTableRowView


@dynamic mouseInside;


- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    NSLog(@"Inited %@", self);
    return self;
}

- (void)drawRect:(NSRect)dirtyRect {
    // Drawing code here.
	NSLog(@"drawing called");
	
//	if ([(NSTableView *)[self superview] rowForView:self] == 0)
//		self.selected = YES;
	
	if (self.selected)
		[self drawSelectionInRect:dirtyRect];
	
//	[super drawRect:dirtyRect];
}




- (void)dealloc {
    [trackingArea release];
    [super dealloc];
}


- (void)setMouseInside:(BOOL)_mouseInside {
	if (mouseInside != _mouseInside) {
		mouseInside = _mouseInside;
		[self setNeedsDisplay:YES];
	}
}

- (BOOL)mouseInside {
	return mouseInside;
}



//
//- (void)ensureTrackingArea {
//    if (trackingArea == nil) {
//        trackingArea = [[NSTrackingArea alloc] initWithRect:NSZeroRect options:NSTrackingInVisibleRect | NSTrackingActiveAlways | NSTrackingMouseEnteredAndExited owner:self userInfo:nil];
//    }
//}
//
//- (void)updateTrackingAreas {
//    [super updateTrackingAreas];
//    [self ensureTrackingArea];
//    if (![[self trackingAreas] containsObject:trackingArea]) {
//        [self addTrackingArea:trackingArea];
//    }
//	
//	//	NSLog(@"Tracking areas: %@", [self trackingAreas]);
//	//	NSRect trackRect = [[self superview] convertRect:[trackingArea rect] fromView:self];
//	//	[self printRect:trackRect withTitle:@"Tracking RECT:"];
//	//	[[self superview] lockFocus];
//	//	[[NSColor redColor] set];
//	//	NSRectFill(trackRect);
//	//	[[self superview] unlockFocus];
//}


- (void)mouseEntered:(NSEvent *)theEvent {
	NSLog(@"mouse enter");
//	self.mouseInside = YES;
}

- (void)mouseExited:(NSEvent *)theEvent {
	NSLog(@"mouse exit");
//	self.mouseInside = NO;
}


- (void)drawBackgroundInRect:(NSRect)dirtyRect {
	NSLog(@"Called drawBackgroundInRect");
	[[NSColor yellowColor] set];
	NSRectFill([self bounds]);
}

- (void)drawSelectionInRect:(NSRect)dirtyRect {
	NSLog(@"called selection");
 	[[NSColor orangeColor] set];
	NSRectFill([self bounds]);
}

- (void)scrollWheel:(NSEvent *)theEvent {
	NSLog(@"wheeel %@", theEvent);
	[super scrollWheel:theEvent];
}

//- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent {
//	return YES;
//}
//
//- (BOOL)acceptsFirstResponder {
//	return YES;
//}


@end
