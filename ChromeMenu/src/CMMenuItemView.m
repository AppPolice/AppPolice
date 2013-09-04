//
//  CMTableCellView.m
//  Ishimura
//
//  Created by Maksym on 7/3/13.
//  Copyright (c) 2013 Maksym Stefanchuk. All rights reserved.
//

#import "CMMenuItemView.h"
#import "CMMenuItemView+InternalMethods.h"
#import <objc/runtime.h>



@interface CMMenuItemView ()
{
	NSImageView *_submenuIconView;
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
//	NSLog(@"DRAW ItemView");
//	NSLog(@"frame: %@", NSStringFromRect([self frame]));
	

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
	
	_submenuIconView = [[NSImageView alloc] initWithFrame:NSMakeRect(0, 0, 9, 9)];
	[_submenuIconView setTranslatesAutoresizingMaskIntoConstraints:NO];
	[_submenuIconView setImage:[NSImage imageNamed:@"NSGoRightTemplate"]];
	[self addSubview:_submenuIconView];
	[constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[lastView]-(>=27)-[_submenuIconView(9)]-(9)-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(lastView, _submenuIconView)]];
	
//	[constraints addObject:[NSLayoutConstraint constraintWithItem:lastView attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:_submenuIconView attribute:NSLayoutAttributeLeading multiplier:1.0 constant:-27]];
//	
//	[constraints addObject:[NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:_submenuIconView attribute:NSLayoutAttributeTrailing multiplier:1.0 constant:9]];
	
	[constraints addObject:[NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:_submenuIconView attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0.0]];
	
//	[constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-[_submenuIconView]-|" options:NSLayoutFormatAlignAllCenterY metrics:nil views:NSDictionaryOfVariableBindings(_submenuIconView)]];
	
	[self addConstraints:constraints];
	_submenuIconConstraints = [constraints retain];
}






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
