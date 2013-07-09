//
//  CMTableCellView.m
//  Ishimura
//
//  Created by Maksym on 7/3/13.
//  Copyright (c) 2013 Maksym Stefanchuk. All rights reserved.
//

#import "CMMenuItemView.h"
#import <objc/runtime.h>


@implementation CMMenuItemView

@synthesize icon = _icon;
@synthesize title = _title;
@synthesize ownersIcon = _ownersIcon;


//- (id)initWithFrame:(NSRect)frame
//{
//    self = [super initWithFrame:frame];
//    if (self) {
//        // Initialization code here.
//    }
//    
//    return self;
//}


//- (void)drawRect:(NSRect)dirtyRect {
//	//	NSLog(@"Cell View draw rect called. Cell subviews: %@", [self subviews]);
//	
//
//	NSBezierPath *path = [NSBezierPath bezierPath];
//	[path appendBezierPathWithRect:[self bounds]];
//	[[NSColor greenColor] set];
//	[path stroke];
//	
//	//	[self printRect:[self bounds] withTitle:@"Cell Rect:"];
//	//	[self printRect:[[self superview] bounds] withTitle:@"Superview rect:"];
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
	NSLog(@"Cell mouse down");
	[super mouseDown:theEvent];
}

- (void)rightMouseDown:(NSEvent *)theEvent {
	NSLog(@"Cell right mouse down");
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


- (void)printRect:(NSRect)rect withTitle:(NSString *)title {
	NSLog(@"%@. Rect: x: %f, y: %f, width: %f, height: %f",
		  title,
		  rect.origin.x,
		  rect.origin.y,
		  rect.size.width,
		  rect.size.height);
	
}

@end