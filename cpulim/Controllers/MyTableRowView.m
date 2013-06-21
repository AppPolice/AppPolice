//
//  MyTableRowView.m
//  Ishimura
//
//  Created by Maksym on 6/1/13.
//  Copyright (c) 2013 Maksym Stefanchuk. All rights reserved.
//

#import "MyTableRowView.h"
#import "MyTableView.h"

@interface MyTableRowView()
	@property BOOL mouseInside;
//	@property NSBackgroundStyle interiorBackgroundStyle;
@end

@implementation MyTableRowView

//@synthesize interiorBackgroundStyle;
@dynamic mouseInside;


//- (id)initWithFrame:(NSRect)frame {
//    self = [super initWithFrame:frame];
//    if (self) {
//    }
//    
//    return self;
//}

- (void)viewDidMoveToSuperview {
	table = (MyTableView *)[self superview];
}


- (void)drawRect:(NSRect)dirtyRect {
//	[[self backgroundColor] set];
//	[[NSColor clearColor] set];
//	[NSBezierPath fillRect:dirtyRect];
//	[[NSColor redColor] set];
//	NSRectFill([self bounds]);
	

	NSString *title = [NSString stringWithFormat:@"DRAW ROW RECT # %ld ::", [(NSTableView *)[self superview] rowForView:self]];
	[self printRect:[[self superview] convertRect:dirtyRect fromView:self] withTitle:title];

	
	
	NSPoint mouseLocation = [[self window] convertScreenToBase:[NSEvent mouseLocation]];
	mouseLocation = [[self superview] convertPoint:mouseLocation fromView:nil];
	NSLog(@"TABLE ROW DRAWRECT. mouseLocation :::: x: %f, y: %f", mouseLocation.x, mouseLocation.y);
	
	mouseInside = [self mouse:mouseLocation inRect:[self frame]];
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
	
	
	if (self.isSelected) {
		[self drawSelectionInRect:dirtyRect];
//		NSLog(@"!!!!!!!!!!!!");
	}
	
//	[super drawRect:dirtyRect];
}


- (void)dealloc {
    [trackingArea release];
    [super dealloc];
}


- (void)setMouseInside:(BOOL)_mouseInside {
//	self.interiorBackgroundStyle = (_mouseInside) ? NSBackgroundStyleDark : NSBackgroundStyleLight;
	if (mouseInside != _mouseInside) {
		mouseInside = _mouseInside;
		[self setNeedsDisplay:YES];
	}
}

- (BOOL)mouseInside {
	return mouseInside;
}


- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent {
	return YES;
}

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
    if (trackingArea == nil) {
        trackingArea = [[NSTrackingArea alloc] initWithRect:NSZeroRect options:NSTrackingInVisibleRect | NSTrackingActiveAlways | NSTrackingMouseEnteredAndExited owner:self userInfo:nil];
    }
}

- (void)updateTrackingAreas {
//	[super updateTrackingAreas];
	[self ensureTrackingArea];
	if (![[self trackingAreas] containsObject:trackingArea]) {
		[self addTrackingArea:trackingArea];
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
//	[self becomeFirstResponder];
	[self setMouseInside:YES];
}

- (void)mouseExited:(NSEvent *)theEvent {
	NSLog(@"Exited: %@", theEvent);
	[self setMouseInside:NO];
}

- (void)mouseDown:(NSEvent *)theEvent {
	NSLog(@"Selected: %d", self.selected);
	if (!self.selected) {
		self.selected = YES;
		[table selectRowIndexes:[NSIndexSet indexSetWithIndex:[table rowForView:self]] byExtendingSelection:NO];
//		if ([table selectedRow])
//			[[table selectedRow] setSelected:NO];
		
//		[table setSelectedRow:self];
		
	
//	NSPoint mouseLocation = [[self superview] convertPoint:[theEvent locationInWindow] fromView:nil];
//	NSLog(@"Down: %@ \nMouse loc. converted: %f, %f", theEvent, mouseLocation.x, mouseLocation.y);
//	NSLog(@"superview: %@", [self superview]);
	
	}
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
//- (void)keyDown:(NSEvent *)theEvent {
//	NSLog(@"KEY DOWN ROW :::: %@", theEvent);
//}


static NSGradient *gradientWithTargetColor(NSColor *targetColor) {
    NSArray *colors = [NSArray arrayWithObjects:[targetColor colorWithAlphaComponent:0], targetColor, targetColor, [targetColor colorWithAlphaComponent:0], nil];
    const CGFloat locations[4] = { 0.0, 0.35, 0.65, 1.0 };
    return [[[NSGradient alloc] initWithColors:colors atLocations:locations colorSpace:[NSColorSpace sRGBColorSpace]] autorelease];
}


- (void)drawBackgroundInRect:(NSRect)dirtyRect {
//	[[self backgroundColor] set];
//	NSRectFill([self bounds]);

	
	//	[[self backgroundColor] set];
//	[NSBezierPath fillRect:dirtyRect];
	
//	NSLog(@"Called drawBackgroundInRect");
//	NSLog(@"%@", [[self viewAtColumn:0] subviews]);
	
//	[self lockFocus];
	
	// Draw a white/alpha gradient
    if (self.mouseInside) {
//        NSGradient *gradient = gradientWithTargetColor([NSColor blueColor]);
//        [gradient drawInRect:self.bounds angle:0];
		[[NSColor selectedMenuItemColor] set];
		[NSBezierPath fillRect:dirtyRect];
//		NSRectFill([self bounds]);

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
	
//	[self unlockFocus];
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


	
	
	[self printRect:[self frame] withTitle:@"Called Draw SELECTION :::"];
	
	NSGradient *gradient = gradientWithTargetColor([NSColor lightGrayColor]);
	[gradient drawInRect:self.bounds angle:0];
}


//- (void)setFrame:(NSRect)frameRect {
//    [super setFrame:frameRect];
//    // We need to invalidate more things when live-resizing since we fill with a gradient and stroke
//    if ([self inLiveResize]) {
//        // Redraw everything if we are using a gradient
//        if (self.selected || mouseInside) {
//            [self setNeedsDisplay:YES];
//        } else {
//            // Redraw our horizontal grid line, which is a gradient
////            [self setNeedsDisplayInRect:[self separatorRect]];
//        }
//    }
//}



- (void)resetRowViewProperties {
//	[self printRect:[self convertRect:[row frame] fromView:nil] withTitle:@":::::"];
	mouseInside = NO;
//	[self printRect:[self frame] withTitle:@":::::"];
//	[[NSColor redColor] set];
//	[NSBezierPath fillRect:[self convertRect:[self frame] fromView:nil]];
//	NSLog(@"row selected :::: %d", self.mouseInside);
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
