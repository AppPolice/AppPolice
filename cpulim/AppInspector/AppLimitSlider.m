//
//  AppLimitSlider.m
//  Ishimura
//
//  Created by Maksym on 10/7/13.
//  Copyright (c) 2013 Maksym Stefanchuk. All rights reserved.
//

#import "AppLimitSlider.h"
#import "AppLimitSliderCell.h"

@implementation AppLimitSlider

//- (id)init {
//	self = [super init];
//	if (self) {
//		NSLog(@"init");
//	}
//	return  self;
//}
//
//
//- (id)initWithCoder:(NSCoder *)aDecoder {
//	self = [super initWithCoder:aDecoder];
//	if (self) {
//		NSLog(@"init w/ coder");
//	}
//	return self;
//}
//
//
//- (id)initWithFrame:(NSRect)frame {
//    self = [super initWithFrame:frame];
//    if (self) {
//        // Initialization code here.
//    }
//    return self;
//}


- (void)awakeFromNib {
	NSLog(@"slider awake from nib");
//	AppLimitSliderCell *customCell = [[[AppLimitSliderCell alloc] init] autorelease];
//	[self setCell:customCell];
//	[AppLimitSlider setCellClass:[AppLimitSliderCell class]];
	NSCell *cell = [self cell];

	NSLog(@"slider cell: %@", cell);

}


//- (void)drawRect:(NSRect)dirtyRect {
//	[super drawRect:dirtyRect];
//
//	NSRect rect = [self rectOfTickMarkAtIndex:([self numberOfTickMarks] - 1)];
//	NSLog(@"rect: %@", NSStringFromRect(rect));
//	rect.origin.y -= 5;
//	rect.size.width += 1;
//	rect.size.height += 5;
//
//	[[NSColor windowBackgroundColor] set];
//	NSFrameRect(rect);
//}


- (void)mouseDown:(NSEvent *)theEvent {
	// If mouse is down to the left of the before last tick mark -- disable the slider's stopOnlyOnMarks option 
	NSPoint mouseLocation = [theEvent locationInWindow];
	mouseLocation = [self convertPoint:mouseLocation fromView:nil];
	NSRect rect = [self rectOfTickMarkAtIndex:([self numberOfTickMarks] - 2)];
	if (mouseLocation.x < rect.origin.x)
		[self setAllowsTickMarkValuesOnly:NO];
	else
		[self setAllowsTickMarkValuesOnly:YES];

//	NSLog(@"slider down");

	[super mouseDown:theEvent];
}


@end
