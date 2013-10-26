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
#import <QuartzCore/CAMediaTimingFunction.h>
#import <objc/runtime.h>



@interface CMMenuItemView ()
{
//	NSView *_submenuIconView;
	NSImageView *_submenuIconView;
	NSMutableArray *_submenuIconConstraints;
	BOOL _isAnimating;
}

@end


@implementation CMMenuItemView

@synthesize state = _state;
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
//	NSLog(@"DRAW ItemView with rect: %@", NSStringFromRect([self frame]));
//	NSLog(@"frame: %@", NSStringFromRect([self frame]));
	

//	NSBezierPath *path = [NSBezierPath bezierPath];
//	[path appendBezierPathWithRect:[self bounds]];
//	[[NSColor blueColor] set];
//	[path stroke];
	
	if (! _enabled) {
		[_title setTextColor:[NSColor colorWithDeviceRed:0.0 green:0.0 blue:0.0 alpha:0.4]];
	} else if (_selected) {
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
	
	
	// Let NSCell to choose which image to draw. For example if backgraund is dark, cell
	//	may choose to draw the light image color.
	if ([_state image]) {
		NSCell *cell = [_state cell];
		if (! _enabled) {
			[cell setBackgroundStyle:NSBackgroundStyleLight];
			if (! _isAnimating)
				[_state setAlphaValue:0.6];
		} else if (_selected) {
			[cell setBackgroundStyle:NSBackgroundStyleDark];
			if (! _isAnimating)
				[_state setAlphaValue:1.0];
		} else {
			[cell setBackgroundStyle:NSBackgroundStyleLight];
			if (! _isAnimating)
				[_state setAlphaValue:1.0];
		}
	}
	
	if (_icon && [_icon image]) {
		NSCell *cell = [_icon cell];
		if (! _enabled) {
			[cell setBackgroundStyle:NSBackgroundStyleLight];
			if (! _isAnimating)
				[_icon setAlphaValue:0.6];
		} else if (_selected) {
			[cell setBackgroundStyle:NSBackgroundStyleDark];
			if (! _isAnimating)
				[_icon setAlphaValue:1.0];
		} else {
			[cell setBackgroundStyle:NSBackgroundStyleLight];
			if (! _isAnimating)
				[_icon setAlphaValue:1.0];
		}
	}
	
	if (_submenuIconView) {
//		NSImage *goRightImage = [NSImage imageNamed:NSImageNameGoRightTemplate];
//		NSImageRep *rep;
//		if (_selected) {
//			rep = [goRightImage invertedImageRepresentation];
//			[rep drawInRect:[_submenuIconView frame] fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0 respectFlipped:YES hints:nil];
//		} else {
//			rep = [goRightImage defaultImageRepresentation];
//			[rep drawInRect:[_submenuIconView frame] fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:0.7 respectFlipped:YES hints:nil];
//		}
		
		NSCell *cell = [_submenuIconView cell];
		if (! _enabled) {
			[cell setBackgroundStyle:NSBackgroundStyleLight];
			if (! _isAnimating)
				[_submenuIconView setAlphaValue:0.5];
		} else if (_selected) {
			[cell setBackgroundStyle:NSBackgroundStyleDark];
			if (! _isAnimating)
				[_submenuIconView setAlphaValue:1.0];
		} else {
			[cell setBackgroundStyle:NSBackgroundStyleLight];
			if (! _isAnimating)
				[_submenuIconView setAlphaValue:1.0];
		}
	}
	

	
}


- (BOOL)needsTracking {
	return (_enabled) ? YES : NO;
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


- (BOOL)isEnabled {
	return _enabled;
}


- (void)setEnabled:(BOOL)enabled {
	if (_enabled != enabled) {
		_enabled = enabled;
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


//- (void)mouseDown:(NSEvent *)theEvent {
////	NSLog(@"View mouse down");
////	NSLog(@"contstraints: %@", [self constraints]);
////	NSLog(@"subview: %@", [self subviews]);
////	NSView *documentView = [self superview];
////	NSSize size = [documentView frame].size;
////	[[documentView animator] setFrame:NSMakeRect(0, 0, size.width, size.height - 19)];
//	
//	[super mouseDown:theEvent];
//}

//- (void)rightMouseDown:(NSEvent *)theEvent {
//	NSLog(@"View right mouse down");
//}


//- (void)updateTrackingAreas {
//	NSLog(@"Update tracking areas called");
//	[super updateTrackingAreas];
//}



//- (void)viewDidMoveToSuperview {
//	[[[self superview] window] visualizeConstraints:[self constraints]];
//	NSLog(@"window: %@", [[self superview] window]);
//	NSLog(@"contstraints: %@", [self constraints]);
//}


/*
 *
 */
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

	NSImage *goRightImage = [NSImage imageNamed:@"ImageNameMenuGoRightTemplate"];
	if (! goRightImage) {
//		NSLog(@"createing goRight image");
		goRightImage = [[NSImage imageNamed:NSImageNameGoRightTemplate] copy];
		[goRightImage setSize:NSMakeSize(9, 10)];
		[goRightImage setName:@"ImageNameMenuGoRightTemplate"];
	}
	
//	NSImage *goRightImage = [NSImage imageNamed:NSImageNameGoRightTemplate];
	// Caution! Changing image size changes its global state. If it's drawn somewhere else
	//	it will draw with this size if not set explicitly again.
//	[goRightImage setSize:NSMakeSize(9, 10)];
//	NSLog(@"goRightImage size: %@", NSStringFromSize([goRightImage size]));

	_submenuIconView = [[NSImageView alloc] initWithFrame:NSMakeRect(0, 0, goRightImage.size.width, goRightImage.size.height)];
//	_submenuIconView = [[NSView alloc] init];
	[_submenuIconView setImage:goRightImage];

	[_submenuIconView setTranslatesAutoresizingMaskIntoConstraints:NO];
	[self addSubview:_submenuIconView];
	[constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[lastView]-(>=27)-[_submenuIconView(9)]-(9)-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(lastView, _submenuIconView)]];
	
//	[constraints addObject:[NSLayoutConstraint constraintWithItem:lastView attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:_submenuIconView attribute:NSLayoutAttributeLeading multiplier:1.0 constant:-27]];
//	
//	[constraints addObject:[NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:_submenuIconView attribute:NSLayoutAttributeTrailing multiplier:1.0 constant:9]];
	
//	[constraints addObject:[NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:_submenuIconView attribute:NSLayoutAttributeWidth multiplier:1.0 constant:9.0]];
	
	[constraints addObject:[NSLayoutConstraint constraintWithItem:_submenuIconView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:_submenuIconView attribute:NSLayoutAttributeHeight multiplier:0.0 constant:10.0]];
	
	[constraints addObject:[NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:_submenuIconView attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0.0]];
	
//	[constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-[_submenuIconView]-|" options:NSLayoutFormatAlignAllCenterY metrics:nil views:NSDictionaryOfVariableBindings(_submenuIconView)]];
	
	[self addConstraints:constraints];
	_submenuIconConstraints = [constraints retain];
	
//	[goRightImage setSize:NSMakeSize(9, 9)];
	
//	NSWindow *window = [[[self superview] superview] window];
//	NSLog(@"window: %@", window);
//	[window visualizeConstraints:constraints];
	
//	NSTimer *timer = [NSTimer timerWithTimeInterval:2.0 target:self selector:@selector(visualizeConstraints:) userInfo:constraints repeats:NO];
//	[[NSRunLoop currentRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
}


//- (void)visualizeConstraints:(NSTimer *)timer {
//	NSArray *userInfo = [timer userInfo];
//	NSLog(@"timer, contstraints: %@", userInfo);
//	
////	NSWindow *window = [[[self superview] superview] window];
//	NSWindow *window = [self window];
////	NSLog(@"window: %@", window);
//	[window visualizeConstraints:userInfo];
//
//}

/*
 *
 */
- (void)fadeIn {
	NSArray *subviews = [self subviews];
//	NSLog(@"fade these subviews: %@", subviews);
	_isAnimating = YES;
	[NSAnimationContext beginGrouping];
	[[NSAnimationContext currentContext] setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn]];
	[[NSAnimationContext currentContext] setDuration:0.25];
	[[NSAnimationContext currentContext] setCompletionHandler:^(void) {
		_isAnimating = NO;
	}];
	for (NSView *view in subviews) {
		[view setAlphaValue:0.0];
		[[view animator] setAlphaValue:1.0];
	}
	[NSAnimationContext endGrouping];
}


/*
 *
 */
- (void)fadeOutWithComplitionHandler:(void (^)(void))handler {
	NSArray *subviews = [self subviews];

	_isAnimating = YES;
	[NSAnimationContext beginGrouping];
	[[NSAnimationContext currentContext] setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear]];
	[[NSAnimationContext currentContext] setDuration:0.25];
	[[NSAnimationContext currentContext] setCompletionHandler:^(void) {
		_isAnimating = NO;
		if (handler)
			handler();
	}];
	
	for (NSView *view in subviews) {
		[[view animator] setAlphaValue:0.0];
	}
	[NSAnimationContext endGrouping];
}


/*
 *
 */
- (void)blink {
	if (_selected) {
		[self setSelected:NO];
		[self performSelector:@selector(blink) withObject:nil afterDelay:0.05 inModes:[NSArray arrayWithObject:NSRunLoopCommonModes]];
	} else {
		[self setSelected:YES];
	}
}


/*
 *
 */
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
