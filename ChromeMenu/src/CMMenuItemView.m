//
//  CMTableCellView.m
//  Ishimura
//
//  Created by Maksym on 7/3/13.
//  Copyright (c) 2013 Maksym Stefanchuk. All rights reserved.
//

//#import <QuartzCore/CoreImage.h>
#import "CMMenuItemView.h"
#import "CMMenuItemView+InternalMethods.h"
#import "NSImage+CMMenuImageRepAdditions.h"
#import <objc/runtime.h>



@interface CMMenuItemView ()
{
	NSView *_submenuIconView;
	NSMutableArray *_submenuIconConstraints;
}

@end


@implementation CMMenuItemView

@synthesize icon = _icon;
@synthesize title = _title;
//@synthesize ownersIcon = _ownersIcon;
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


- (void)dealloc {
	[_submenuIconView release];
	[_submenuIconConstraints release];
	[super dealloc];
}


- (void)drawRect:(NSRect)dirtyRect {
//	NSLog(@"Cell View draw rect called. Cell subviews: %@", [self subviews]);
	NSLog(@"DRAW ItemView with rect: %@", NSStringFromRect([self frame]));
//	NSLog(@"frame: %@", NSStringFromRect([self frame]));
	

//	NSBezierPath *path = [NSBezierPath bezierPath];
//	[path appendBezierPathWithRect:[self bounds]];
//	[[NSColor blueColor] set];
//	[path stroke];
		
	if (_selected) {
		NSGraphicsContext *currentContext = [NSGraphicsContext currentContext];
//		[currentContext saveGraphicsState];
		
		// Note that saving and restoreing GraphicsState is expensive thus we change one
		// parameter and then restore it back manually. More info on Apple Docs:
		// https://developer.apple.com/library/mac/documentation/Cocoa/Conceptual/CocoaDrawingGuide/GraphicsContexts/GraphicsContexts.html#//apple_ref/doc/uid/TP40003290-CH203-SW9
		// Get the patter phase before modification
		NSPoint patternPhase = [currentContext patternPhase];
		
		CGFloat xOffset = NSMinX([self convertRect:self.bounds toView:nil]);
		CGFloat yOffset = NSMaxY([self convertRect:self.bounds toView:nil]);
		[currentContext setPatternPhase:NSMakePoint(xOffset, yOffset)];
				
		[[NSColor selectedMenuItemColor] setFill];
		NSRectFill([self bounds]);
//		[currentContext restoreGraphicsState];
		// Restore original pattern phase
		[currentContext setPatternPhase:patternPhase];
				
		[_title setTextColor:[NSColor selectedMenuItemTextColor]];
	} else {
		[_title setTextColor:[NSColor textColor]];
	}
	
	if (_submenuIconView) {
//		NSImage *image = [_submenuIconView image];
//		[image setBackgroundColor:nil];
//		NSLog(@"drawing item ivew: %@", [image representations]);
//		NSImageRep *rep = [[image representations] objectAtIndex:0];
//		NSLog(@"isopaque: %d, hasAlpha: %d", [rep isOpaque], [rep hasAlpha]);
//		[image drawRepresentation:rep inRect:NSMakeRect(10, 5, 9, 9)];
//		[image drawInRect:NSMakeRect(2, 1, 18, 18) fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
//		NSImageRep *rep = [image defaultImageRepresentation];
//		[rep drawInRect:NSMakeRect(1, 5, 9, 9) fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:0.7 respectFlipped:YES hints:nil];
		
//		NSImageRep *bestRep = [image bestRepresentationForRect:NSMakeRect(1, 1, 9, 9) context:nil hints:nil];
//		NSLog(@"best rep: %@", bestRep);
		
//		NSLog(@"nsimage: %@", image);
//		[[NSColor redColor] set];
//		NSFrameRect(NSMakeRect(0, 0, 9, 9));
		
		
		NSImage *goRightImage = [NSImage imageNamed:NSImageNameGoRightTemplate];
		NSImageRep *rep;
		if (_selected) {
//			[goRightImage createInvertedImageRepresentation];
			rep = [goRightImage invertedImageRepresentation];
			[rep drawInRect:[_submenuIconView frame] fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0 respectFlipped:YES hints:nil];
		} else {
			rep = [goRightImage defaultImageRepresentation];
			[rep drawInRect:[_submenuIconView frame] fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:0.7 respectFlipped:YES hints:nil];
		}
		
//		NSLog(@"iconViewframe: %@, bounds: %@", NSStringFromRect([_submenuIconView frame]), NSStringFromRect([_submenuIconView bounds]));
//		[[NSColor redColor] setStroke];
//		[NSBezierPath strokeRect:[_submenuIconView frame]];

	}

}


- (BOOL)needsTracking {
	return YES;
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
//	NSLog(@"View mouse down");
//	NSLog(@"contstraints: %@", [self constraints]);
//	NSLog(@"subview: %@", [self subviews]);
//	NSView *documentView = [self superview];
//	NSSize size = [documentView frame].size;
//	[[documentView animator] setFrame:NSMakeRect(0, 0, size.width, size.height - 19)];
	
	[super mouseDown:theEvent];
}

- (void)rightMouseDown:(NSEvent *)theEvent {
	NSLog(@"View right mouse down");
}


//- (void)updateTrackingAreas {
//	NSLog(@"Update tracking areas called");
//	[super updateTrackingAreas];
//}



//- (void)viewDidMoveToSuperview {
//	[[[self superview] window] visualizeConstraints:[self constraints]];
//	NSLog(@"window: %@", [[self superview] window]);
//	NSLog(@"contstraints: %@", [self constraints]);
//}



- (void)setHasSubmenuIcon:(BOOL)hasIcon {
	if (hasIcon == NO) {
		if (_submenuIconView) {
			[self removeConstraints:_submenuIconConstraints];
			[_submenuIconView removeFromSuperview];
			[_submenuIconView release];
			[_submenuIconConstraints release];
		}
		return;
	}


	NSView *lastView = [[self subviews] lastObject];
	NSMutableArray *constraints = [NSMutableArray array];
	
//	_submenuIconView = [[NSImageView alloc] initWithFrame:NSMakeRect(0, 0, goRightImage.size.width, goRightImage.size.height)];
	_submenuIconView = [[NSView alloc] init];
	[_submenuIconView setTranslatesAutoresizingMaskIntoConstraints:NO];
//	NSImage *goRightImage = [NSImage imageNamed:NSImageNameGoRightTemplate];
//	NSImage *goRightImage = [NSImage imageNamed:NSImageNameFolder];


//	[goRightImage createInvertedImageRepresentation];
	
	
	// Trying to add White representation of image to use during mouse over event
//	if ([[goRightImage representations] count] < 2) {
//	NSSize size = [goRightImage size];
//	[goRightImage lockFocus];
//	NSBitmapImageRep *bitmapImageRep = [[NSBitmapImageRep alloc] initWithFocusedViewRect:NSMakeRect(0, 0, size.width, size.height)];
//	[goRightImage unlockFocus];
	
//	NSBitmapImageRep *bitmapImageRep = [goRightImage bitmapImageRepresentation];	
//	NSLog(@"bitmap image rep: %@", bitmapImageRep);
	
//	CIImage *ciImage = [[CIImage alloc] initWithBitmapImageRep:bitmapImageRep];
//	CIFilter *ciFilter = [CIFilter filterWithName:@"CIColorInvert"];
//	[ciFilter setValue:ciImage forKey:@"inputImage"];
//	CIImage *resultImage = [ciFilter valueForKey:@"outputImage"];
//
//	CIFilter *maskFilter = [CIFilter filterWithName:@"CIMaskToAlpha"];
//	[maskFilter setValue:resultImage forKey:@"inputImage"];
//	resultImage = [maskFilter valueForKey:@"outputImage"];
		
//	NSImageRep *newImageRep = [NSCIImageRep imageRepWithCIImage:resultImage];
//	[newImageRep setAlpha:YES];
//	[goRightImage addRepresentation:newImageRep];
//	[goRightImage drawRepresentation:[[goRightImage representations] objectAtIndex:1] inRect:NSMakeRect(0, 0, 9, 9)];
	
//	[goRightImage setTemplate:NO];
//	[goRightImage setBackgroundColor:[NSColor clearColor]];
//	NSLog(@"goRight template: %@, reps: %@", [goRightImage backgroundColor], [goRightImage representations]);
	
//	NSBitmapImageRep *rep = [goRightImage bitmapImageRepresentation];
//	NSLog(@"new rep: %@", rep);
//	[goRightImage addRepresentation:rep];
//	}
	
//	NSLog(@"goRight template: %@", [goRightImage backgroundColor]);
	
//	[_submenuIconView setImage:goRightImage];
	[self addSubview:_submenuIconView];
	[constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[lastView]-(>=27)-[_submenuIconView(9)]-(9)-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(lastView, _submenuIconView)]];
	
//	[constraints addObject:[NSLayoutConstraint constraintWithItem:lastView attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:_submenuIconView attribute:NSLayoutAttributeLeading multiplier:1.0 constant:-27]];
//	
//	[constraints addObject:[NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:_submenuIconView attribute:NSLayoutAttributeTrailing multiplier:1.0 constant:9]];
	
	[constraints addObject:[NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:_submenuIconView attribute:NSLayoutAttributeHeight multiplier:1.0 constant:9.0]];
	
	[constraints addObject:[NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:_submenuIconView attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0.0]];
	
//	[constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-[_submenuIconView]-|" options:NSLayoutFormatAlignAllCenterY metrics:nil views:NSDictionaryOfVariableBindings(_submenuIconView)]];
	
	[self addConstraints:constraints];
	_submenuIconConstraints = [constraints retain];
}



- (NSString *)description {
	NSMutableString *description = [[NSMutableString alloc] initWithString:[super description]];
	[description appendString:@" Properties: ("];
	
	id currentClass = [self class];
	NSString *propertyName;
	unsigned int outCount, i;
	objc_property_t *properties = class_copyPropertyList(currentClass, &outCount);
	for (i = 0; i < outCount; ++i) {
		objc_property_t property = properties[i];
		propertyName = [NSString stringWithCString:property_getName(property) encoding:NSASCIIStringEncoding];
		[description appendFormat:@"\n\t%@:  %@", propertyName, [self valueForKey:propertyName]];
    }
	free(properties);
	
	// if object was subclassed, let's print parent's properties
	if (! [[self className] isEqualToString:@"CMMenuItemView"]) {
		[description appendFormat:@"\n\ticon: %@", _icon];
		[description appendFormat:@"\n\ttitle: %@", _title];
	}
	
	[description appendString:@")"];
	
	return description;
}


@end
