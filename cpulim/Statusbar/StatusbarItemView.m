//
//  StatusbarItemView.m
//  Ishimura
//
//  Created by Maksym on 7/3/13.
//  Copyright (c) 2013 Maksym Stefanchuk. All rights reserved.
//

#import "StatusbarItemView.h"

#define HORIZONTAL_PADDING 4

@implementation StatusbarItemView


- (void)dealloc {
	[_image release];
	[_alternateImage release];
	[_imageView release];
	[super dealloc];
}


- (void)drawRect:(NSRect)dirtyRect {
	if (_highlighted) {
		NSGraphicsContext *currentContext = [NSGraphicsContext currentContext];
		//		[currentContext saveGraphicsState];
		
		// Note that saving and restoreing GraphicsState is expensive thus we change one
		// parameter and then restore it back manually. More info at Apple Docs:
		// https://developer.apple.com/library/mac/documentation/Cocoa/Conceptual/CocoaDrawingGuide/GraphicsContexts/GraphicsContexts.html#//apple_ref/doc/uid/TP40003290-CH203-SW9
		// Get the pattern phase before modification
		NSPoint patternPhase = [currentContext patternPhase];
		
		CGFloat xOffset = NSMinX([self convertRect:self.bounds toView:nil]);
		CGFloat yOffset = NSMaxY([self convertRect:self.bounds toView:nil]);
		[currentContext setPatternPhase:NSMakePoint(xOffset, yOffset)];

		[[NSColor selectedMenuItemColor] setFill];
		NSRectFill([self bounds]);
		
		// Restore original pattern phase
		[currentContext setPatternPhase:patternPhase];
		
		if (_imageView) {
			[_imageView setImage:_alternateImage];
		}
	} else {
		if (_imageView && ![[_imageView image] isEqual:_image]) {
			[_imageView setImage:_image];
		}
	}
	
	
//	NSLog(@"image view: %@", NSStringFromRect([_imageView frame]));
	
//	NSBezierPath *border = [NSBezierPath bezierPath];
//	[border appendBezierPathWithRect:[self bounds]];
//	[[NSColor redColor] set];
//	[border stroke];
}


- (void)setImage:(NSImage *)image {
	if (_image != image) {
		[_image release];
		_image = [image retain];
		
		if (! _imageView) {
			NSRect frame = [self frame];
//			NSLog(@"frame: %@", NSStringFromRect(frame));
			NSSize imageSize = [image size];
			_imageView = [[NSImageView alloc] initWithFrame:NSMakeRect(HORIZONTAL_PADDING, floor((frame.size.height - imageSize.height) / 2 + 0.5), imageSize.width, imageSize.height)];
			[self setFrame:NSMakeRect(frame.origin.x, frame.origin.y, frame.size.width + HORIZONTAL_PADDING * 2, frame.size.height)];
			[self addSubview:_imageView];
			[_imageView setImage:image];
		}
		
		[self setNeedsDisplay:YES];
	}
}


- (NSImage *)image {
	return _image;
}


- (void)setAlternateImage:(NSImage *)image {
	if (_alternateImage != image) {
		[_alternateImage release];
		_alternateImage = [image retain];
		
		if (! _imageView) {
			NSSize size = [image size];
			_imageView = [[NSImageView alloc] initWithFrame:NSMakeRect(0, 0, size.width, size.height)];
			[self addSubview:_imageView];
		}
		
		[self setNeedsDisplay:YES];
	}
}


- (NSImage *)alternateImage {
	return _alternateImage;
}


- (void)setHighlighted:(BOOL)highlighted {
	if (_highlighted == highlighted)
		return;
	
	_highlighted = highlighted;
	[self setNeedsDisplay:YES];
}


- (BOOL)highlighted {
	return  _highlighted;
}



- (void)mouseDown:(NSEvent *)theEvent {
	NSRect frame = [self frame];
	frame = [[self window] convertRectToScreen:frame];
	NSLog(@"mouse down on status item rect: %@", NSStringFromRect(frame));
	
	[self setHighlighted:YES];
	
	NSDictionary *userInfo = @{
		@"timestamp" : [NSNumber numberWithDouble:[theEvent timestamp]]
	};
	NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
	[notificationCenter postNotificationName:StatusbarItemLeftMouseDownNotification object:self userInfo:userInfo];
}


- (void)mouseUp:(NSEvent *)theEvent {
	NSLog(@"mouse up on status item");
	[self setHighlighted:NO];
}

- (void)rightMouseDown:(NSEvent *)theEvent {
	[self setHighlighted:YES];
	NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
	[notificationCenter postNotificationName:StatusbarItemRightMouseDownNotification object:self];

}

- (void)rightMouseUp:(NSEvent *)theEvent {
	[self setHighlighted:NO];
}

@end
