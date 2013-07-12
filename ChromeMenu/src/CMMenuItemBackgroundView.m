//
//  CMTableRowView.m
//  Ishimura
//
//  Created by Maksym on 7/4/13.
//  Copyright (c) 2013 Maksym Stefanchuk. All rights reserved.
//

#import "CMMenuItem.h"
#import "CMMenuItemBackgroundView.h"


/* Private properties */
@interface CMMenuItemBackgroundView()
{
	BOOL _mouseInside;
	NSTrackingArea *_trackingArea;
}

@property BOOL mouseInside;

@end


/******************* IMPLEMENTATION ******************/

@implementation CMMenuItemBackgroundView

@dynamic mouseInside;



- (void)viewDidMoveToSuperview {
	//	NSLog(@"View: %@ Did Move to Superview: %@", self, [self superview]);
	NSView *superview = [self superview];
	if ([[superview className] isEqualToString:@"MyTableView"]) {
//		table = (MyTableView *)superview;
		//		NSLog(@"View written as table: %@", superview);
	}
}


- (void)drawRect:(NSRect)dirtyRect {
	
	/* Print currently drawing row.
	 * We have this check to not include rows that might be in the process of drawing using methods like: -insertRowWithIndexes
	 * because row won't belong to a TableView during animation effect.
	 */
	NSView *superview = [self superview];
	if ([[superview className] isEqualToString:@"CMTableView"]) {
		NSString *title = [NSString stringWithFormat:@"DRAW ROW RECT # %ld ::", [(NSTableView *)superview rowForView:self]];
		[self printRect:[[self superview] convertRect:dirtyRect fromView:self] withTitle:title];
	}
	
//	NSLog(@"rows subviews: %@", [self subviews]);
//	NSLog(@"row's supervew: %@", [self superview]);
//	[[NSColor grayColor] set];
//	NSRectFill([[[self subviews] objectAtIndex:0] bounds]);
	
	
	NSPoint mouseLocation = [[self window] convertScreenToBase:[NSEvent mouseLocation]];
	mouseLocation = [[self superview] convertPoint:mouseLocation fromView:nil];
//	NSLog(@"TABLE ROW DRAWRECT. mouseLocation :::: x: %f, y: %f", mouseLocation.x, mouseLocation.y);
	
	_mouseInside = [self mouse:mouseLocation inRect:[self frame]];

	//	if (mouseInside) {
	//		if ([table mouseoverRow] != self)
	//			[[table mouseoverRow] setNeedsDisplay:YES];
	//		[table setMouseoverRow:self];
	////		NSLog(@"Table: %@", [self superview]);
	//	}
	//	NSLog(@"Mouse in RECT: %d", mouseInside);
	//	if (mouseOverView && !self.mouseInside) {
	//		mouseInside = YES;
	//	} else if (!mouseOverView && self.mouseInside) {
	//		mouseInside = NO;
	//	}
	
	
	
	[self drawBackgroundInRect:dirtyRect];
	
	if (self.isSelected && !_mouseInside) {
		[self drawSelectionInRect:dirtyRect];
	}
	
	
	//	[super drawRect:dirtyRect];
}


- (void)dealloc {
    [_trackingArea release];
    [super dealloc];
}


- (void)setMouseInside:(BOOL)mouseInside {
	if (_mouseInside != mouseInside) {
		_mouseInside = mouseInside;
		[self setNeedsDisplay:YES];
	}
}

- (BOOL)mouseInside {
	return _mouseInside;
}

- (void)setOwner:(CMMenuItem *)owner {
	if (_owner != owner) {
		_owner = owner;
	}
}

- (CMMenuItem *)owner {
	return _owner;
}


//- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent {
//	NSLog(@"row accepts");
//	return YES;
//}

//- (void)setInteriorBackgroundStyle:(NSBackgroundStyle)_interiorBackgroundStyle {
//	interiorBackgroundStyle = _interiorBackgroundStyle;
////	[self setNeedsDisplay:YES];
//}
//
//- (NSBackgroundStyle)interiorBackgroundStyle {
//	if (self.mouseInside) {
//		NSLog(@"Called BACKGROUND STYLE ::: DARK");
//		return NSBackgroundStyleDark;
//	} else {
//		NSLog(@"Called BACKGROUND STYLE ::: LIGHT");
//		return NSBackgroundStyleLight;
//	}
//}


// interiorBackgroundStyle is normaly "dark" when the selection is drawn (self.selected == YES) and we are in a key window (self.emphasized == YES). However, we always draw a light selection, so we override this method to always return a light color.
//- (NSBackgroundStyle)interiorBackgroundStyle {
//	if (self.mouseInside) {
//		NSLog(@":::: DARK");
//		return NSBackgroundStyleDark;
//	} else {
//		NSLog(@":::: LIGHT");
//		return NSBackgroundStyleLight;
//	}
//}


- (void)ensureTrackingArea {
    if (_trackingArea == nil) {
        _trackingArea = [[NSTrackingArea alloc] initWithRect:NSZeroRect options:NSTrackingInVisibleRect | NSTrackingActiveAlways | NSTrackingMouseEnteredAndExited owner:self userInfo:nil];
    }
}

/*
 * NSView's -updateTrackingAreas method override
 */
- (void)updateTrackingAreas {
	//	[super updateTrackingAreas];
	[self ensureTrackingArea];
	if (![[self trackingAreas] containsObject:_trackingArea]) {
		[self addTrackingArea:_trackingArea];
	}
	
	//	NSLog(@"Tracking areas: %@", [self trackingAreas]);
	//	NSRect trackRect = [[self superview] convertRect:[trackingArea rect] fromView:self];
	//	[self printRect:trackRect withTitle:@"Tracking RECT:"];
	//	[[self superview] lockFocus];
	//	[[NSColor redColor] set];
	//	NSRectFill(trackRect);
	//	[[self superview] unlockFocus];
	
	//	NSLog(@"Trackings count::: %ld", [[self trackingAreas] count]); // result: all have 1
}



- (void)mouseEntered:(NSEvent *)theEvent {
	NSLog(@"Entered: %@", theEvent);
	
	[_owner mouseEntered:theEvent];
	
	//	[self becomeFirstResponder];
	[self setMouseInside:YES];
}

- (void)mouseExited:(NSEvent *)theEvent {
	NSLog(@"Exited: %@", theEvent);
	
	[_owner mouseExited:theEvent];
	
	[self setMouseInside:NO];
}

- (void)mouseDown:(NSEvent *)theEvent {
//	NSLog(@"Row mouse down. View: %@, superview: %@", self, [self superview]);
//	NSLog(@"Row owner: %@, owner title: %@, submenu: %@", _owner, [_owner title], [_owner submenu]);
	
	[_owner mouseDown:theEvent];
	
//	if (!self.selected) {
//		self.selected = YES;
//		[table selectRowIndexes:[NSIndexSet indexSetWithIndex:[table rowForView:self]] byExtendingSelection:NO];

		//		if ([table selectedRow])
		//			[[table selectedRow] setSelected:NO];
		
		//		[table setSelectedRow:self];
		
		
		//	NSPoint mouseLocation = [[self superview] convertPoint:[theEvent locationInWindow] fromView:nil];
		//	NSLog(@"Down: %@ \nMouse loc. converted: %f, %f", theEvent, mouseLocation.x, mouseLocation.y);
		//	NSLog(@"superview: %@", [self superview]);
		
//	}
	
	
//	NSLog(@"Owner: %@ with title: %@");
}


//- (void)mouseUp:(NSEvent *)theEvent {
//	NSLog(@"Row mouse UP: %@", self);
//}

- (void)rightMouseDown:(NSEvent *)theEvent {
	NSLog(@"right mouse donw!!");
}

//- (void)scrollWheel:(NSEvent *)theEvent {
//	NSLog(@"Scroll WHEEL: %@, %@", theEvent, [self superview]);
//	NSPoint mouseLocation = [[self superview] convertPoint:[theEvent locationInWindow] fromView:nil];
//	NSLog(@"!!!!!! Mouse LOC: x: %f, y: %f", mouseLocation.x, mouseLocation.y);
//	[super scrollWheel:theEvent];
//}

//- (BOOL)acceptsFirstResponder {
//	return YES;
//}

//
- (void)keyDown:(NSEvent *)theEvent {
	NSLog(@"KEY DOWN ROW :::: %@", theEvent);
}


- (void)moveUp:(id)sender {
	NSLog(@"Move up");
}


static NSGradient *gradientWithTargetColor(NSColor *targetColor) {
    NSArray *colors = [NSArray arrayWithObjects:[targetColor colorWithAlphaComponent:0], targetColor, targetColor, [targetColor colorWithAlphaComponent:0], nil];
    const CGFloat locations[4] = { 0.0, 0.35, 0.65, 1.0 };
    return [[[NSGradient alloc] initWithColors:colors atLocations:locations colorSpace:[NSColorSpace sRGBColorSpace]] autorelease];
}


- (NSGradient *)gradientWithTargetColor:(NSColor *)color1 andColor:(NSColor *)color2 {
	//    NSArray *colors = [NSArray arrayWithObjects:[color1 colorWithAlphaComponent:0.5], color1, color2, [color2 colorWithAlphaComponent:0.5], nil];
    NSArray *colors = [NSArray arrayWithObjects:color1, color2, nil];
    const CGFloat locations[2] = {0.0, 1.0};
    return [[[NSGradient alloc] initWithColors:colors atLocations:locations colorSpace:[NSColorSpace sRGBColorSpace]] autorelease];
	//	return [[[NSGradient alloc] initWithStartingColor:color1 endingColor:color2] autorelease];
}



- (void)drawBackgroundInRect:(NSRect)dirtyRect {
	//	[[self backgroundColor] set];
	//	NSRectFill([self bounds]);
	
	//	[[self backgroundColor] set];
	//	[NSBezierPath fillRect:dirtyRect];
	
	//	NSLog(@"Called drawBackgroundInRect");
	//	NSLog(@"%@", [[self viewAtColumn:0] subviews]);
	
	
    if (_mouseInside) {
		//        NSGradient *gradient = gradientWithTargetColor([NSColor blueColor]);
		//        NSGradient *gradient = [self gradientWithTargetColor:[NSColor colorWithSRGBRed:0.52 green:0.7 blue:0.99 alpha:1.0] andColor:[NSColor colorWithSRGBRed:0.34 green:0.53 blue:0.89 alpha:1.0]];
		
		NSGradient *gradient = [[[NSGradient alloc] initWithStartingColor:[NSColor colorWithSRGBRed:0.52 green:0.7 blue:0.99 alpha:1.0] endingColor:[NSColor colorWithSRGBRed:0.34 green:0.53 blue:0.89 alpha:1.0]] autorelease];
        [gradient drawInRect:self.bounds angle:90];
		
		NSBezierPath *topLine = [NSBezierPath bezierPath];
		[topLine moveToPoint:NSMakePoint(0.0, 0.0)];
		[topLine lineToPoint:NSMakePoint([self bounds].size.width, 0.0)];
		[[NSColor colorWithSRGBRed:0.43 green:0.59 blue:0.97 alpha:1.0] setStroke];
		[topLine stroke];
		
		[self updateTextColorForBackgroundStyle:NSBackgroundStyleDark];
		
		//		[self printRect:[self frame] withTitle:@"Called Draw BACKGROUND INSIDE :::"];
		//		self.interiorBackgroundStyle = NSBackgroundStyleDark;
	} else {
		//		[[self backgroundColor] set];
		[[NSColor clearColor] set];
		//		NSRectFill([self bounds]);
		[NSBezierPath fillRect:dirtyRect];
		
		[self updateTextColorForBackgroundStyle:NSBackgroundStyleLight];
		
	}
}


- (void)updateTextColorForBackgroundStyle:(NSBackgroundStyle)backgroundStyle {
	int column;
	int i;
	NSView *view;
	NSUInteger numberOfViews;
	NSInteger numberOfColumns = self.numberOfColumns;
	for (column = 0; column < numberOfColumns; ++column) {
		NSArray *cellViews = [[self viewAtColumn:column] subviews];
		numberOfViews = [cellViews count];
		for (i = 0; i < numberOfViews; ++i) {
			view = [cellViews objectAtIndex:i];
			if ([view isKindOfClass:[NSTextField class]]) {
				NSTextField *textField = (NSTextField *)view;
				if (backgroundStyle == NSBackgroundStyleDark) {
					[textField setTextColor:[NSColor whiteColor]];
				} else if(backgroundStyle == NSBackgroundStyleLight) {
					[textField setTextColor:[NSColor blackColor]];
				}
				
			}
		}
	}
}


// Only called if the 'selected' property is yes.
- (void)drawSelectionInRect:(NSRect)dirtyRect {
    // Check the selectionHighlightStyle, in case it was set to None
	//    if (self.selectionHighlightStyle != NSTableViewSelectionHighlightStyleNone) {
	// We want a hard-crisp stroke, and stroking 1 pixel will border half on one side and half on another, so we offset by the 0.5 to handle this
	//        NSRect selectionRect = NSInsetRect(self.bounds, 5.5, 5.5);
	//        [[NSColor colorWithCalibratedWhite:.72 alpha:1.0] setStroke];
	//        [[NSColor colorWithCalibratedWhite:.82 alpha:1.0] setFill];
	//        NSBezierPath *selectionPath = [NSBezierPath bezierPathWithRoundedRect:selectionRect xRadius:10 yRadius:10];
	//        [selectionPath fill];
	//        [selectionPath stroke];
	//    }
	
	//	[self printRect:[self frame] withTitle:@"Called Draw SELECTION :::"];
	//	NSGradient *gradient = gradientWithTargetColor([NSColor lightGrayColor]);
	//	[gradient drawInRect:self.bounds angle:0];
	
	
	//	[[NSColor colorWithSRGBRed:0.66 green:0.8 blue:0.98 alpha:0.3] setFill];
	[[NSColor colorWithSRGBRed:0.45 green:0.66 blue:0.96 alpha:0.7] setFill];
	//	[NSBezierPath strokeRect:[self bounds]];
	[NSBezierPath fillRect:[self bounds]];
	
	NSBezierPath *topBottomLine = [NSBezierPath bezierPath];
	[topBottomLine moveToPoint:NSMakePoint(0.0, 0.0)];
	[topBottomLine lineToPoint:NSMakePoint([self bounds].size.width, 0.0)];
	//	[topBottomLine moveToPoint:NSMakePoint(0.0, [self bounds].size.height)];
	//	[topBottomLine lineToPoint:NSMakePoint([self bounds].size.width, [self bounds].size.height)];
	//	[[NSColor colorWithSRGBRed:0.7 green:0.78 blue:1.0 alpha:1.0] setStroke];
	[[NSColor colorWithSRGBRed:0.54 green:0.67 blue:1.0 alpha:1.0] setStroke];
	[topBottomLine stroke];
}




- (void)resetBackgroundViewProperties {
	_mouseInside = NO;
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
