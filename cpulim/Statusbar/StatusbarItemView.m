//
//  StatusbarItemView.m
//  Ishimura
//
//  Created by Maksym on 7/3/13.
//  Copyright (c) 2013 Maksym Stefanchuk. All rights reserved.
//

#import "StatusbarItemView.h"

@implementation StatusbarItemView

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
	NSBezierPath *border = [NSBezierPath bezierPath];
	[border appendBezierPathWithRect:[self bounds]];
	[border stroke];
}

- (void)mouseDown:(NSEvent *)theEvent {
	NSLog(@"clicked on statusbar item %@", theEvent);
	
	NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
	[notificationCenter postNotificationName:@"StatusbarItemLMouseClick" object:self];
}

- (void)rightMouseDown:(NSEvent *)theEvent {
	NSLog(@"right mouse down %@", theEvent);
}

@end
