//
//  APURLTextField.m
//  AppPolice
//
//  Created by Maksym on 20/11/13.
//  Copyright (c) 2013 Maksym Stefanchuk. All rights reserved.
//

#import "APURLTextField.h"

@implementation APURLTextField

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
		//
    }
    return self;
}

//- (void)drawRect:(NSRect)dirtyRect {
//	[super drawRect:dirtyRect];
//	
//    // Drawing code here.
//}


- (void)dealloc {
	[_attributedString release];
	[super dealloc];
}


- (void)viewDidMoveToWindow {
	NSString *string = [self stringValue];
	NSDictionary *attributes = @{
		NSFontAttributeName : [NSFont fontWithName:@"Lucida Grande" size:11.0],
		NSUnderlineStyleAttributeName : [NSNumber numberWithInt:NSUnderlineStyleSingle],
		NSForegroundColorAttributeName : [NSColor blueColor]
	};
	_attributedString = [[NSMutableAttributedString alloc] initWithString:string attributes:attributes];
	[self setAttributedStringValue:_attributedString];
	
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
	if (NSPointInRect([theEvent locationInWindow], [self frame]))
		(void) [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://google.com"]];
//	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[self stringValue]]];
}

@end
