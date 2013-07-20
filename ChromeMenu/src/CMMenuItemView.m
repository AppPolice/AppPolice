//
//  CMTableCellView.m
//  Ishimura
//
//  Created by Maksym on 7/3/13.
//  Copyright (c) 2013 Maksym Stefanchuk. All rights reserved.
//

#import "CMMenuItemView.h"
#import <objc/runtime.h>
//
//@interface CMMenuItemView ()
//{
//	BOOL _mouseInside;
//}
//
//@end


@implementation CMMenuItemView

@synthesize icon = _icon;
@synthesize title = _title;
@synthesize ownersIcon = _ownersIcon;
//@synthesize mouseInside = _mouseInside;

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
//	NSLog(@"Cell View draw rect called. Cell subviews: %@", [self subviews]);
//	NSLog(@"DRAW ItemView");
	

//	NSBezierPath *path = [NSBezierPath bezierPath];
//	[path appendBezierPathWithRect:[self bounds]];
//	[[NSColor blueColor] set];
//	[path stroke];
	
	
	if (_selected) {
		NSGraphicsContext *currentContext = [NSGraphicsContext currentContext];
		[currentContext saveGraphicsState];
		CGFloat xOffset = NSMinX([self convertRect:self.bounds toView:nil]);
		CGFloat yOffset = NSMaxY([self convertRect:self.bounds toView:nil]);
		[currentContext setPatternPhase:NSMakePoint(xOffset, yOffset)];
		
		[[NSColor selectedMenuItemColor] setFill];
		NSRectFill([self bounds]);
		[currentContext restoreGraphicsState];
		
		[_title setTextColor:[NSColor selectedMenuItemTextColor]];
	} else {
		[_title setTextColor:[NSColor textColor]];
	}
}


- (BOOL)isSelected {
	return _selected;
}


- (void)setSelected:(BOOL)selected {
	if (_selected != selected) {
		_selected = selected;
		[self setNeedsDisplay:YES];
	}
}


//- (void)setMouseInside:(BOOL)inside {
//	if (_mouseInside != inside) {
//		_mouseInside = inside;
//		[self setNeedsDisplay:YES];
//	}
//}

//- (NSImageView *)icon {
//	return _icon;
//}
//
//- (void)setIcon:(NSImageView *)aIcon {
//	_icon = aIcon;
//	[_icon setImage:aIcon];
//}



- (void)setIconProperty:(NSImage *)aImage {
	[_icon setImage:aImage];
}

- (void)setTitleProperty:(NSString *)aTitle {
	[_title setStringValue:aTitle];
}


//- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent {
//	return YES;
//}


- (void)mouseDown:(NSEvent *)theEvent {
	NSLog(@"View mouse down");
	[super mouseDown:theEvent];
}

- (void)rightMouseDown:(NSEvent *)theEvent {
	NSLog(@"View right mouse down");
}


//- (void)updateTrackingAreas {
//	NSLog(@"Update tracking areas called");
//	[super updateTrackingAreas];
//}



- (NSString *)description {
	NSMutableString *description = [[NSMutableString alloc] initWithString:[super description]];
	
	id currentClass = [self class];
	NSString *propertyName;
	unsigned int outCount, i;
	objc_property_t *properties = class_copyPropertyList(currentClass, &outCount);
	for (i = 0; i < outCount; ++i) {
		objc_property_t property = properties[i];
		propertyName = [NSString stringWithCString:property_getName(property) encoding:NSASCIIStringEncoding];
		[description appendFormat:@"\n\t%@: %@", propertyName, [self valueForKey:propertyName]];
    }
	free(properties);
	
	// if object was subclassed, let's print parent's properties
	if (![[self className] isEqualToString:@"CMTableCellView"]) {
		[description appendFormat:@"\n\ticon: %@", _icon];
		[description appendFormat:@"\n\ttitle: %@", _title];
	}
	
	return description;
}


@end
