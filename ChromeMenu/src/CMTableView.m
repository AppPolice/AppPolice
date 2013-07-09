//
//  CMTableView.m
//  Ishimura
//
//  Created by Maksym on 7/5/13.
//  Copyright (c) 2013 Maksym Stefanchuk. All rights reserved.
//

#import "CMTableView.h"
#import "CMMenuItemBackgroundView.h"

@implementation CMTableView


//- (void)drawRect:(NSRect)dirtyRect {
//    // Drawing code here.
//}

- (void)mouseDown:(NSEvent *)theEvent {
	[super mouseDown:theEvent];
	
	//	NSLog(@"table view mouse down: %@", [self subviews]);
	
	NSPoint mouseDownPoint = [self convertPoint:[theEvent locationInWindow] fromView:nil];
	NSInteger row = [self rowAtPoint:mouseDownPoint];
	if (row >= 0) {
		CMMenuItemBackgroundView *rowView = [self viewAtColumn:0 row:row makeIfNecessary:NO];
		[rowView mouseDown:theEvent];
	}
}


- (void)rightMouseDown:(NSEvent *)theEvent {
	[super rightMouseDown:theEvent];
	
	NSLog(@"table view right mouse down: %@", theEvent);
}

@end
