//
//  MyTableCellView.m
//  Ishimura
//
//  Created by Maksym on 6/1/13.
//  Copyright (c) 2013 Maksym Stefanchuk. All rights reserved.
//

#import "MyTableCellView.h"

@implementation MyTableCellView

@synthesize cellImage;
@synthesize cellText;

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
//- (void)drawRect:(NSRect)dirtyRect {
//    // Drawing code here.
//	
//	NSLog(@"CellView DRAW RECT: %@", [[self superview] trackingAreas]);
//	[super drawRect:dirtyRect];
//}

- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent {
	NSLog(@"MyTableCellView accepts first mouse");
	return YES;
}

@end
