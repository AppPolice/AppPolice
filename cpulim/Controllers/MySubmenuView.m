//
//  MySubmenuView.m
//  Ishimura
//
//  Created by Maksym on 6/1/13.
//  Copyright (c) 2013 Maksym Stefanchuk. All rights reserved.
//

#import "MySubmenuView.h"

@implementation MySubmenuView

//- (id)initWithFrame:(NSRect)frame
//{
//    self = [super initWithFrame:frame];
//    if (self) {
//        // Initialization code here.
//    }
//    
//    return self;
//}
//
- (void)drawRect:(NSRect)dirtyRect {
    // Drawing code here.
//	NSLog(@"called MySubmenuView DRAWRECT");
//	[[NSColor blueColor] set];
//	NSRectFill(dirtyRect);
}


//- (void)setFrameSize:(NSSize)newSize {
//	NSLog(@"set frame size is called");
//	if ([self inLiveResize])
//		NSLog(@"IN live resize");
//	
//	NSLog(@"%@", tableView);
//	[tableView setNeedsDisplay:NO];
//	[self setNeedsDisplay:NO];
//	[super setNeedsDisplay:NO];
//	[super setFrameSize:newSize];
//}
//
//- (BOOL)preservesContentDuringLiveResize {
//	NSLog(@"Called preservesContentDuringLiveResize");
//	return YES;
//}

//- (BOOL)acceptsFirstResponder {
//	return YES;
//}

//- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent {
//	return YES;
//}

//- (void)updateTrackingAreas {
//	NSLog(@"Tracking areas MYSubmenuView: %@", [self trackingAreas]);
//}

- (void)mouseDown:(NSEvent *)theEvent {
//	NSLog(@"MySubmenuView Mouse Donw");
}

- (void)keyDown:(NSEvent *)theEvent {
//	NSLog(@"MySubmenuView key down");
}

- (void)viewDidMoveToSuperview {
//	NSLog(@"MySubmenuView did movo to superview");
//	[self setWantsLayer:YES];
}


//- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent {
//	NSLog(@"MySubmenuView accepts first mouse");
//	return YES;
//}

@end
