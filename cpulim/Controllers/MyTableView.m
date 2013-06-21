//
//  MyTableView.m
//  Ishimura
//
//  Created by Maksym on 5/31/13.
//  Copyright (c) 2013 Maksym Stefanchuk. All rights reserved.
//

#import "MyTableView.h"
//#import "MyTableRowView.h"

@implementation MyTableView

//@synthesize selectedRow;
@synthesize mouseoverRow;

//- (id)initWithFrame:(NSRect)frame
//{
//    self = [super initWithFrame:frame];
//    if (self) {
//        // Initialization code here.
//    }
//    NSLog(@"table inited");
//    return self;
//}
//
- (void)drawRect:(NSRect)dirtyRect {
    // Drawing code here.
	
	NSLog(@"TableView DRAW RECT");
//	[super drawRect:dirtyRect];
}

//- (BOOL)acceptsFirstResponder {
//	return YES;
//}

- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent {
	return YES;
}


//- (void)updateTrackingAreas {
//	NSLog(@"Tracking areas TABLE: %@", [self trackingAreas]);
////	NSRect trackRect = [[self superview] convertRect:[trackingArea rect] fromView:self];
////	[self printRect:trackRect withTitle:@"Tracking RECT:"];
////	[[self superview] lockFocus];
////	[[NSColor redColor] set];
////	NSRectFill(trackRect);
////	[[self superview] unlockFocus];
//}

//- (void)mouseDown:(NSEvent *)theEvent {
//	NSLog(@"Event: %@", theEvent);
//	NSUInteger index = [self rowAtPoint:[self convertPoint:[theEvent locationInWindow] fromView:nil]];
//	NSLog(@"row: %ld", index);
//}


//- (void)mouseEntered:(NSEvent *)theEvent {
//	NSLog(@"TableView, Mouse Entered: %@", theEvent);
//}


//- (void)scrollWheel:(NSEvent *)theEvent {
////	NSLog(@"Scroll WHEEL: %@, %@", theEvent, [self superview]);
//	NSPoint mouseLocation = [[self superview] convertPoint:[theEvent locationInWindow] fromView:nil];
//	NSLog(@"Scroll WHEEL !!!!!! Mouse LOC: x: %f, y: %f", mouseLocation.x, mouseLocation.y);
//	[super scrollWheel:theEvent];
//}


//- (void)keyDown:(NSEvent *)theEvent {
//	NSLog(@"KEY DOWN :::: %@", theEvent);
//}



//- (CGFloat)yPositionPastLastRow {
//    // Only draw the grid past the last visible row
//    NSInteger numberOfRows = self.numberOfRows;
//    CGFloat yStart = 0;
//    if (numberOfRows > 0) {
//        yStart = NSMaxY([self rectOfRow:numberOfRows - 1]);
//    }
//    return yStart;
//}
//
//- (void)drawGridInClipRect:(NSRect)clipRect {
//    // Only draw the grid past the last visible row
//    CGFloat yStart = [self yPositionPastLastRow];
//    // Draw the first separator one row past the last row
//    yStart += self.rowHeight;
//	
//    // One thing to do is smarter clip testing to see if we actually need to draw!
//    NSRect boundsToDraw = self.bounds;
//    NSRect separatorRect = boundsToDraw;
//    separatorRect.size.height = 1;
//    while (yStart < NSMaxY(boundsToDraw)) {
//        separatorRect.origin.y = yStart;
////        DrawSeparatorInRect(separatorRect);
//        yStart += self.rowHeight;
//    }
//}
//
//- (void)setFrameSize:(NSSize)size {
//    [super setFrameSize:size];
//    // We need to invalidate more things when live-resizing since we fill with a gradient and stroke
//    if ([self inLiveResize]) {
//        CGFloat yStart = [self yPositionPastLastRow];
//        if (NSHeight(self.bounds) > yStart) {
//            // Redraw our horizontal grid lines
//            NSRect boundsPastY = self.bounds;
//            boundsPastY.size.height -= yStart;
//            boundsPastY.origin.y = yStart;
//            [self setNeedsDisplayInRect:boundsPastY];
//        }
//    }
//}



//- (BOOL)acceptsFirstResponder {
//	return YES;
//}

//- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent {
//	NSLog(@"MyTableView accepts first mouse");
//	return YES;
//}


@end
