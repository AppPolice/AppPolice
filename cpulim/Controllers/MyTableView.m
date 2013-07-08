//
//  MyTableView.m
//  Ishimura
//
//  Created by Maksym on 5/31/13.
//  Copyright (c) 2013 Maksym Stefanchuk. All rights reserved.
//

#import "MyTableView.h"
#import "MyTableRowView.h"

@implementation MyTableView

//@synthesize selectedRow;
//@synthesize mouseoverRow;
//@synthesize rowView;

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

/*
 * When clicked on empty space in table, then trying to click on actual rows will result
 * in no response.
 * Returning NO helps.
 */
//- (BOOL)acceptsFirstResponder {
//	return NO;
//}



- (void)mouseDown:(NSEvent *)theEvent {
	[super mouseDown:theEvent];
	
//	NSLog(@"table view mouse down: %@", [self subviews]);
	
	NSPoint mousePoint = [self convertPoint:[theEvent locationInWindow] fromView:nil];
	NSInteger row = [self rowAtPoint:mousePoint];
	if (row >= 0) {
		MyTableRowView *rowView = [self viewAtColumn:0 row:row makeIfNecessary:NO];
		[rowView mouseDown:theEvent];
	}
}


//- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent {
//	return YES;
//}


//- (void)viewDidMoveToSuperview {
//	NSLog(@"TableView did move to superview");
//}


@end
