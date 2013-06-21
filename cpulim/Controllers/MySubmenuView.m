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
	NSLog(@"called MySubmenuView DRAWRECT");
//	[[NSColor blueColor] set];
//	NSRectFill(dirtyRect);
}

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
	NSLog(@"MySubmenuView Mouse Donw");
}

- (void)keyDown:(NSEvent *)theEvent {
	NSLog(@"MySubmenuView key down");
}

//- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent {
//	NSLog(@"MySubmenuView accepts first mouse");
//	return YES;
//}

@end
