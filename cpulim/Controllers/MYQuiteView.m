//
//  MYQuiteView.m
//  Ishimura
//
//  Created by Maksym on 07/11/13.
//  Copyright (c) 2013 Maksym Stefanchuk. All rights reserved.
//

#import "MYQuiteView.h"

@implementation MYQuiteView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    return self;
}

- (void)drawRect:(NSRect)dirtyRect {
	[super drawRect:dirtyRect];
	
    [[NSColor redColor] set];
	NSFrameRect([self bounds]);
}


- (BOOL)shouldDelayWindowOrderingForEvent:(NSEvent *)theEvent {
	NSLog(@"should delay event on view: %@", theEvent);
	return YES;
}


- (void)mouseDown:(NSEvent *)theEvent {
	NSLog(@"quite view mouse down");
	[NSApp preventWindowOrdering];
}


- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent {
	NSLog(@"quite view accepts fisrt mouse: %@", theEvent);
	return YES;
}


@end
