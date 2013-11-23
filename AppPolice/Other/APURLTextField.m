//
//  APURLTextField.m
//  AppPolice
//
//  Created by Maksym on 20/11/13.
//  Copyright (c) 2013 Maksym Stefanchuk. All rights reserved.
//

#import "APURLTextField.h"

@implementation APURLTextField

@synthesize URLAttribute;
@synthesize preferredColor;

//- (id)initWithFrame:(NSRect)frame {
//    self = [super initWithFrame:frame];
//    if (self) {
//		//
//    }
//    return self;
//}


- (id)init {
	self = [super init];
	if (self) {
		[self setupDefaultParameters];
	}
	return self;
}


//- (void)drawRect:(NSRect)dirtyRect {
//	[super drawRect:dirtyRect];
//	
//    // Drawing code here.
//}


- (void)dealloc {
//	[_URLAttribute release];
//	[_preferredColor release];
	[self setURLAttribute:nil];
	[self setPreferredColor:nil];
	[_attributedString release];
	[super dealloc];
}


- (void)setupDefaultParameters {
	[self setBordered:NO];
	[self setBezeled:NO];
	[self setBezelStyle:NSTextFieldSquareBezel];
	[self setDrawsBackground:NO];
	[self setEditable:NO];
	[self setRefusesFirstResponder:YES];
}


- (void)viewDidMoveToSuperview {
	NSString *string = [self stringValue];
	NSDictionary *attributes = @{
		NSFontAttributeName : [NSFont fontWithName:@"Lucida Grande" size:11.0],
		NSUnderlineStyleAttributeName : [NSNumber numberWithInt:NSUnderlineStyleSingle],
		NSForegroundColorAttributeName : ([self preferredColor]) ? [self preferredColor] : [NSColor blueColor]
	};
	_attributedString = [[NSMutableAttributedString alloc] initWithString:string attributes:attributes];
	[self setAttributedStringValue:_attributedString];
	
//	NSLog(@"bounds: %@", NSStringFromRect([self bounds]));
//	_trackingRect = [self addTrackingRect:[self bounds] owner:self userData:nil assumeInside:NO];
}


- (void)layout {
	[super layout];
//	NSLog(@"after layout, bounds: %@", NSStringFromRect([self bounds]));
	_trackingRect = [self addTrackingRect:[self bounds] owner:self userData:nil assumeInside:NO];
}


- (void)mouseEntered:(NSEvent *)theEvent {
	[_attributedString removeAttribute:NSUnderlineStyleAttributeName
								 range:NSMakeRange(0, [_attributedString length])];
	[self setAttributedStringValue:_attributedString];
}


- (void)mouseExited:(NSEvent *)theEvent {
	// Update cursor
	[[NSCursor arrowCursor] set];
	// Update string underline attribute
	[_attributedString addAttribute:NSUnderlineStyleAttributeName
							  value:[NSNumber numberWithInt:NSUnderlineStyleSingle]
							  range:NSMakeRange(0, [_attributedString length])];
	[self setAttributedStringValue:_attributedString];
}


- (void)resetCursorRects {
	[self addCursorRect:[self bounds] cursor:[NSCursor pointingHandCursor]];
}


- (void)mouseUp:(NSEvent *)theEvent {
	NSPoint mouseLocation = [theEvent locationInWindow];
	mouseLocation = [[self superview] convertPoint:mouseLocation fromView:nil];
	
	if (NSPointInRect(mouseLocation, [self frame]) && [self URLAttribute])
		(void) [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[self URLAttribute]]];
//	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[self stringValue]]];
}

@end
