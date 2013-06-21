//
//  TestView1.m
//  Ishimura
//
//  Created by Maksym on 6/3/13.
//  Copyright (c) 2013 Maksym Stefanchuk. All rights reserved.
//

#import "TestView1.h"

@implementation TestView1

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

- (void)mouseDown:(NSEvent *)theEvent {
	NSLog(@"TestView1: %@", theEvent);
}

//- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent {
//	return YES;
//}

@end
