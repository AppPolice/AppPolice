//
//  MyImageView.m
//  Ishimura
//
//  Created by Maksym on 5/31/13.
//  Copyright (c) 2013 Maksym Stefanchuk. All rights reserved.
//

#import "MyImageView.h"

@implementation MyImageView

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
//- (void)drawRect:(NSRect)dirtyRect
//{
//    // Drawing code here.
//	[super drawRect:dirtyRect];
//}

- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent {
	NSLog(@"MyImageView accepts first mosue: %@", theEvent);
	return YES;
}

@end
