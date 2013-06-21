//
//  TestView2.m
//  Ishimura
//
//  Created by Maksym on 6/3/13.
//  Copyright (c) 2013 Maksym Stefanchuk. All rights reserved.
//

#import "TestView2.h"

@implementation TestView2

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)drawRect:(NSRect)dirtyRect
{
    // Drawing code here.
}

//- (BOOL)acceptsFirstResponder {
//	return NO;
//}
//
- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent {
	return YES;
}

- (void)mouseDown:(NSEvent *)theEvent {
	NSLog(@"TestView2: %@", theEvent);
	[super mouseDown:theEvent];
}



@end
