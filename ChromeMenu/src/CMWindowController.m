//
//  CMMenuWindowController.m
//  Ishimura
//
//  Created by Maksym on 7/12/13.
//  Copyright (c) 2013 Maksym Stefanchuk. All rights reserved.
//


#import "CMWindowController.h"
#import "ChromeMenuUnderlyingWindow.h"
#import "ChromeMenuUnderlyingView.h"
#import "CMScrollDocumentView.h"
#import "CMScrollView.h"
#import "CMMenuItemView.h"
#import "CMMenuItemView+InternalMethods.h"
#import "CMMenuItem.h"
#import "CMMenuItem+InternalMethods.h"
#import "CMMenu.h"
#import "CMMenu+InternalMethods.h"
#import "CMMenuScroller.h"
#import "CMMenuKeyEventInterpreter.h"
#import "CMDebug.h"
#import <QuartzCore/CAMediaTimingFunction.h>


#define kTrackingAreaViewControllerKey @"viewController"
#define kUserDataViewControllerKey @"viewController"
#define kUserDataScrollerViewKey @"scroller"
#define kUserDataMenuObjKey @"menu"
#define kUserDataEventTypeKey @"eventType"
#define VERTICAL_SPACING 0		// between menu items
#define MENU_SCROLLER_HEIGHT 15.0
#define SCROLL_TIMER_INTERVAL 0.05
#define LINE_SCROLL_AMOUNT 19.0


typedef struct tracking_primitive_s {
	NSRect rect;
	NSDictionary *userInfo;
	BOOL mouseInside;
	struct tracking_primitive_s *next;
} CMTrackingPrimitive;


@interface CMWindowController ()
{
	__weak CMMenu *_owner;
	__strong CMScrollView *_scrollView;
	CGFloat _verticalPadding;
//	CMScrollDocumentView *_scrollDocumentView;
	
//	BOOL _needsLayoutUpdate;
	CGFloat _maximumViewWidth;
	CGFloat _defaultViewHeight;
	CGFloat _defaultSeparatorViewHeight;
	
	__strong CMMenuScroller *_topScroller;
	__strong CMMenuScroller *_bottomScroller;
	NSTimer *_scrollTimer;
	
	NSMutableArray *_viewControllers;
	CMTrackingPrimitive **_trackingPrimitives;
	CMTrackingPrimitive *_trackingPrimitivesList;
	
	BOOL _keepTracking;
	CMMenuKeyEventInterpreter *_keyEventInterpreter;
}


/**
 * @abstract Create Tracking Area for Menu Item view
 * @param viewController ViewController of a view that will be returned in userData in event
 * @param trackingRect Rect for tracking area. It represents only the visible portion of the view.
 */
//- (NSTrackingArea *)trackingAreaForItemView:(NSViewController *)viewController inRect:(NSRect)trackingRect;
//- (NSTrackingArea *)trackingAreaForScrollerView:(CMMenuScroller *)scroller inRect:(NSRect)trackingRect;

- (void)updateMenuScrollersIgnoreMouse:(BOOL)ignoreMouse;
/**
 * @abstract Update tracking rectangles
 * @param ignoreMouse Situations when ignoring a mouse while updating tracking areas is required:
 *		1. When navigating menus with keyboard with submenus poping up, mouse position is irrelevant;
 *		2. When calling -moveVisibleRectToRect:ignoreMouse:updateTrackingPrimitives
 */
- (void)updateTrackingPrimitivesIgnoreMouse:(BOOL)ignoreMouse;
- (void)discardTrackingPrimitivesIgnoreMouse:(BOOL)ignoreMouse;
/**
 * @abstract Method loops through tracking primitives and fires appropriate events
 *	(mouse enter or mouse exit) on objects provided with userInfo.
 * @discussion Method is called from inside NSEventTrackingRunLoop every time there
 *	is an NSMouseMoved event.
 * @param mouseLocation Current mouse location in screen coordinates.
 * @param mouseInside Tells whether the mouse cursor is inside the receiving window frame.
 *	If mouse is not inside -- this paramter is used as a hint to short cut the loop through
 *	all primitives and instead just process the mouse exit events on all primitives previously selected.
 */
- (void)eventOnTrackingPrimitiveAtLocation:(NSPoint)mouseLocation mouseInside:(BOOL)mouseInside;

- (void)mouseEventOnItemView:(NSViewController *)viewController eventType:(CMMenuEventType)eventType;

@end

@implementation CMWindowController


/*
  ___________
 |  _______ |
 | |   v  | |
 | |------| |
 | |------| |
 | |------| |
 | |------| |
 | |------| |
 | |   ^  | |
 | -------- |
 ------------
 
 */


- (id)initWithOwner:(CMMenu *)owner {
	NSRect rect = {{0, 0}, {20, 20}};
	ChromeMenuUnderlyingWindow *window = [[ChromeMenuUnderlyingWindow alloc] initWithContentRect:rect defer:YES];
	
	self = [super initWithWindow:window];
	if (self) {
		_owner = owner;
		_defaultViewHeight = 19.0;
		_defaultSeparatorViewHeight = 12.0;
		_verticalPadding = 4.0;
		
		NSNumber *radius = [NSNumber numberWithDouble:[owner borderRadius]];
		NSArray *radiuses;
		if ([owner supermenu]) {
			radiuses = @[radius, @0, radius, radius];
		} else if ([owner isAttachedToStatusItem]) {
			radiuses = @[radius, @0, @0, radius];
		} else {
			radiuses = @[radius, radius, radius, radius];
		}
		
		ChromeMenuUnderlyingView *contentView = [[ChromeMenuUnderlyingView alloc] initWithFrame:rect borderRadiuses:radiuses];
		window.contentView = contentView;
		[contentView setAutoresizesSubviews:NO];
		
		static int level = 0;
		[window setLevel:NSPopUpMenuWindowLevel + level];
		++level;
		[window setHidesOnDeactivate:NO];
//		[window setAcceptsMouseMovedEvents:YES];
		
		_scrollView = [[CMScrollView alloc] initWithFrame:rect];
		[_scrollView setBorderType:NSNoBorder];
		[_scrollView setDrawsBackground:NO];
		[_scrollView setLineScroll:_defaultViewHeight + VERTICAL_SPACING];
		// activate vertical scroller, but then hide it
		[_scrollView setHasVerticalScroller:YES];
		[_scrollView setHasVerticalScroller:NO];
		
		CMScrollDocumentView *documentView = [[CMScrollDocumentView alloc] initWithFrame:NSZeroRect];
		[_scrollView setDocumentView:documentView];
		[contentView addSubview:_scrollView];
		
		// Post a notification when scroll view scrolled
//		[[_scrollView contentView] setPostsBoundsChangedNotifications:YES];
		
		[documentView release];
		[contentView release];
		
//		_keepTracking = NO;
//		_trackingPrimitives = NULL;
	}
	
	[window release];
	
	return self;
}


- (void)dealloc {
	[_viewControllers release];
	[_topScroller release];
	[_bottomScroller release];
	[_scrollView release];
	[_keyEventInterpreter release];
	
	[super dealloc];
}


- (CGFloat)verticalPadding {
	return _verticalPadding;
}


- (NSSize)intrinsicContentSize {
	NSSize documentSize = [[_scrollView documentView] bounds].size;
	return NSMakeSize(documentSize.width, documentSize.height + 2 * _verticalPadding);
}


/*
 *
 */
- (void)displayInFrame:(NSRect)frame options:(CMMenuOptions)options {
	BOOL isVisible = [[self window] isVisible];
	BOOL updateOriginOnly = NO;
	BOOL ignoreMouse = options & CMMenuOptionIgnoreMouse;

	if (! isVisible) {
		[[self window] setFrame:frame display:NO];
		// Scroll view frame includes the menu top and bottom paddings
		[_scrollView setFrame:NSMakeRect(0, _verticalPadding, frame.size.width, frame.size.height - 2 * _verticalPadding)];
		[[self window] orderFront:self];
		[[self window] setAcceptsMouseMovedEvents:YES];
	} else {
		updateOriginOnly = NSEqualSizes([[self window] frame].size, frame.size);
		[[self window] disableScreenUpdatesUntilFlush];
//		[[self window] disableFlushWindow];
//		[[[self window] contentView] setNeedsDisplay:YES];
//		[[self window] enableFlushWindow];
		if (updateOriginOnly) {
			[[self window] setFrameOrigin:NSMakePoint(frame.origin.x, frame.origin.y)];
			[[self window] flushWindow];
		} else {
			[[self window] setFrame:frame display:NO animate:NO];
			// Scroll view frame includes the menu top and bottom paddings
			[_scrollView setFrame:NSMakeRect(0, _verticalPadding, frame.size.width, frame.size.height - 2 * _verticalPadding)];
			[[self window] flushWindowIfNeeded];
			NSLog(@"new frame for window: %@", NSStringFromRect(frame));
		}
	}
	
	
	if (updateOriginOnly) {
		if (options & CMMenuOptionUpdateScrollers) {
			[self updateMenuScrollersIgnoreMouse:ignoreMouse];
		}
		if (options & CMMenuOptionUpdateTrackingPrimitives) {
			[self updateTrackingPrimitivesIgnoreMouse:ignoreMouse];
		}
	} else {
		/* We already knew documentView size, that is the size of all menu items.
			Now we know the actual size of menu (since it depends on the area it is being shown on).
			Let's see whether we need to show top and bottom Scrollers if the content doesn't fit
			in the menu */
		[self updateMenuScrollersIgnoreMouse:ignoreMouse];
				
//		[self updateTrackingAreasForVisibleRect:[[_scrollView contentView] bounds]];
//		BOOL trackMouseMoved = (options & CMMenuOptionTrackMouseMoved);
//		[self updateContentViewTrackingAreaTrackMouseMoved:trackMouseMoved];
//		[self updateContentViewTrackingAreaTrackMouseMoved:YES];
		if (options & CMMenuOptionUpdateTrackingPrimitives)
			[self updateTrackingPrimitivesIgnoreMouse:ignoreMouse];
		
//		if (! isVisible) {
//			[[NSNotificationCenter defaultCenter] addObserver:self
//													 selector:@selector(scrollViewContentViewBoundsDidChange:)
//														 name:NSViewBoundsDidChangeNotification
//													   object:[_scrollView contentView]];
//		}
	}
}


- (BOOL)isTracking {
	return _keepTracking;
}


- (void)beginTrackingWithEvent:(NSEvent *)event options:(CMMenuOptions)options {
	if (_keepTracking)
		return;
	
	_keepTracking = YES;

	[self updateTrackingPrimitivesIgnoreMouse:(BOOL)(options & CMMenuOptionIgnoreMouse)];
	
	// Add to a run loop queue so that Cocoa finishes its preparations on the main thread in current loop.
//	if ([_owner supermenu]) {
//		[self performSelector:@selector(_beginTrackingWithEvent:) withObject:event];
		[self _beginTrackingWithEvent:event];
//	} else {
//		[self performSelector:@selector(_beginTrackingWithEvent:) withObject:event afterDelay:0 inModes:[NSArray arrayWithObject:NSRunLoopCommonModes]];
//	}
}


- (void)endTracking {
	if (! _keepTracking)
		return;
	
	XLog2("\n \
	--------------------------------------------------------\n \
	 END tracking RunLoop mode on menu \"%@\" with frame: %@\n \
	--------------------------------------------------------\n",
		  [_owner title],
		  NSStringFromRect([[self window] frame]));

	_keepTracking = NO;
	[self discardTrackingPrimitivesIgnoreMouse:YES];
	// By posting another event we will effectively quit nextEventMatchingMask event tracking
	//	since we set the _keepTracking to NO.
	NSEvent *customEvent = [NSEvent otherEventWithType:NSSystemDefined location:NSMakePoint(1, 1) modifierFlags:0 timestamp:0 windowNumber:0 context:nil subtype:0 data1:0 data2:0];
//	NSEvent *customEvent = [NSEvent mouseEventWithType:NSLeftMouseDown location:NSMakePoint(1, 1) modifierFlags:0 timestamp:0 windowNumber:0 context:nil eventNumber:0 clickCount:1 pressure:0.0];
//	NSLog(@"resend last event: %@", customEvent);
//	[NSApp discardEventsMatchingMask:NSAnyEventMask beforeEvent:[NSApp currentEvent]];
	[NSApp postEvent:customEvent atStart:YES];
}


/*
 *
 */
- (void)hide {
//	[self discardTrackingPrimitivesIgnoreMouse:YES];
	[[self window] orderOut:self];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (void)fadeOutWithComplitionHandler:(void (^)(void))handler {
	[NSAnimationContext beginGrouping];
	NSAnimationContext *ctx = [NSAnimationContext currentContext];
	[ctx setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn]];
	[ctx setDuration:0.155];
	[ctx setCompletionHandler:^(void) {
		[[self window] setAlphaValue:1.0];
		if (handler)
			handler();
	}];
	[[[self window] animator] setAlphaValue:0.0];
	[NSAnimationContext endGrouping];
}


- (void)setBorderRadiuses:(NSArray *)radiuses {
	[(ChromeMenuUnderlyingView *)[[self window] contentView] setBorderRadiuses:radiuses];
}


/*
 *
 */
- (void)layoutViews:(NSMutableArray *)viewControllers {
	if (! viewControllers)
		return;
	
	
//	if (_viewControllers != viewControllers) {
	if (_viewControllers) {
		for (NSViewController *viewController in _viewControllers)
			[viewController.view removeFromSuperview];

		[_viewControllers release];
	}
	_viewControllers = [viewControllers retain];
//	}

	
	NSView *documentView = [_scrollView documentView];
	CGFloat maximumWidth = 0.0f;
	// On first pass add views to the documentView and find the
	// maximum width
	for (NSViewController *controller in viewControllers) {
		NSView *view = controller.view;
		NSSize size = [view fittingSize];
		if (size.width > maximumWidth)
			maximumWidth = size.width;

		[documentView addSubview:view];
	}
	
//	_viewHeight = [[viewControllers objectAtIndex:0] view].frame.size.height;
//	_maximumViewWidth = maximumWidth;

	CGFloat offset = 0.0f;
	// On second pass align views properly
	for (NSViewController *viewController in [viewControllers reverseObjectEnumerator]) {
		CMMenuItem *menuItem = [viewController representedObject];
		NSView *view = [viewController view];
		NSRect frame = [view frame];
		CGFloat height = frame.size.height;
		if (! height) {
			height = ([menuItem isSeparatorItem]) ? _defaultSeparatorViewHeight : _defaultViewHeight;
			frame.size.height = height;
		}
//		CGFloat height = ([menuItem isSeparatorItem]) ? separatorViewHeight : viewHeight;
//		frame.size = NSMakeSize(width, height);
		frame.size.width = maximumWidth;
		offset -= height + VERTICAL_SPACING;
		frame.origin.y = offset;
		frame.origin.x = 0;
		[view setFrame:frame];
	}
	
	[documentView setFrame:NSMakeRect(0, 0, maximumWidth, -1 * offset)];
	
//	[self updateViews];
}


/*
 *
 */
- (void)updateDocumentView {
	NSView *documentView = [_scrollView documentView];
	NSRect documentRect = [documentView bounds];
	CGFloat subviewsWidth = 0;
	
	// Find the widest element
	for (NSView *view in [documentView subviews]) {
		NSSize size = [view fittingSize];
		if (size.width > subviewsWidth)
			subviewsWidth = size.width;
	}
	
	if (documentRect.size.width != subviewsWidth) {
		// Update other elements' and documentView's widths
		for (NSView *view in [documentView subviews]) {
			NSRect frame = [view frame];
			[view setFrame:NSMakeRect(0, frame.origin.y, subviewsWidth, frame.size.height)];
		}
		
		[documentView setFrame:NSMakeRect(0, 0, subviewsWidth, documentRect.size.height)];
	}
}


/*
 *
 */
- (void)insertView:(NSViewController *)viewController atIndex:(NSUInteger)index animate:(BOOL)animate {
	NSView *view = [viewController view];
	NSSize size = [view fittingSize];
	NSView *documentView = [_scrollView documentView];
	NSRect documentRect = [documentView bounds];
	
	if (index == 0) {
		NSView *relativeView = [(NSViewController *)[_viewControllers objectAtIndex:0] view];
		[documentView addSubview:view positioned:NSWindowBelow relativeTo:relativeView];
	} else {
		NSView *relativeView = [(NSViewController *)[_viewControllers objectAtIndex:(index - 1)] view];
		[documentView addSubview:view positioned:NSWindowAbove relativeTo:relativeView];
	}
	
	if (animate)
		[(CMMenuItemView *)view fadeIn];
	
	// See if the new item is wider then the menu previously was.
	BOOL updateSubviewsWidth = NO;
	CGFloat subviewsWidth = documentRect.size.width;
	if (size.width > subviewsWidth) {
		subviewsWidth = size.width;
		updateSubviewsWidth = YES;
	}
	
	[documentView setFrame:NSMakeRect(0, 0, subviewsWidth, documentRect.size.height + size.height)];
	
	CGFloat offset = size.height;
	CGFloat yOrigin = 0.0;
	for (NSView *subview in [documentView subviews]) {
		if (subview == view) {
			[view setFrame:NSMakeRect(0, yOrigin, subviewsWidth, size.height)];
			// Once we updated the Y offset of all items before the new item, and
			// the width doesn't have to be updated for other items -- exit the loop.
			// Otherwise continue with zero Y offset and update just the width.
			if (updateSubviewsWidth)
				offset = 0;
			else
				break;
		} else {
			NSRect frame = [subview frame];
			[subview setFrame:NSMakeRect(0, frame.origin.y - offset, subviewsWidth, frame.size.height)];
			yOrigin += frame.size.height;
		}
	}
	
	[_viewControllers insertObject:viewController atIndex:index];
	_maximumViewWidth = subviewsWidth;
	
//	NSLog(@"new document frame: %@", NSStringFromRect([documentView frame]));
}


/*
 *
 */
- (void)addView:(NSViewController *)viewController animate:(BOOL)animate {
	[self insertView:viewController atIndex:[_viewControllers count] animate:animate];
}


/*
 *
 */
- (void)removeViewAtIndex:(NSUInteger)index {
	NSViewController *viewController = [_viewControllers objectAtIndex:index];
	NSView *view = [viewController view];
	NSSize size = [view fittingSize];
	NSView *documentView = [_scrollView documentView];
	NSRect documentRect = [documentView bounds];
	
	// Retain object before removing from an Array
	[viewController retain];
	[_viewControllers removeObjectAtIndex:index];
	
	BOOL updateSubviewsWidth = NO;
	CGFloat subviewsWidth = documentRect.size.width;
	if (size.width == subviewsWidth) {
		// Need to find next widest view and use its width for other views
		updateSubviewsWidth = YES;
		subviewsWidth = 0;
		for (NSViewController *controller in _viewControllers) {
			NSView *view = controller.view;
			NSSize size = [view fittingSize];
			if (size.width > subviewsWidth)
				subviewsWidth = size.width;
		}
		
		_maximumViewWidth = subviewsWidth;
	}
	
	// Issue warning if the view has zero height.
	// This is prone to visual defects, like menu items will not move up to take the space
	// previusly occupied by the item whose view has zero height.
	// This issue can show itself if the view created in Interface Builder doesn't have
	// height set either explicitly or via Constraints.
	if (size.height == 0)
		NSLog(@"Warning: the being removed menu item has zero height.");
	
	CGFloat offset = size.height;
	for (NSView *subview in [documentView subviews]) {
		if (view == subview) {
			if (updateSubviewsWidth) {
				offset = 0;
				continue;
			} else
				break;
		}
		
		NSRect frame = [subview frame];
		[subview setFrame:NSMakeRect(0, frame.origin.y + offset, subviewsWidth, frame.size.height)];
	}
	[view removeFromSuperview];
	[documentView setFrame:NSMakeRect(0, 0, subviewsWidth, documentRect.size.height - size.height)];
	[viewController release];
}


/*
 *
 */
- (void)removeViewAtIndex:(NSUInteger)index animate:(BOOL)animate complitionHandler:(void (^)(void))handler {
	if (! animate) {
		[self removeViewAtIndex:index];
		return;
	}
	
	CMMenuItemView *view = (CMMenuItemView *)[(NSViewController *)[_viewControllers objectAtIndex:index] view];
	[view fadeOutWithComplitionHandler:^(void) {
//		NSLog(@"animation finished, now remove");
		[self removeViewAtIndex:index];
		if (handler)
			handler();
	}];
}



/**
 * Update top and/or bottom menu scrollers. If needed -- create them, if not -- hide.
 */
- (void)updateMenuScrollersIgnoreMouse:(BOOL)ignoreMouse {
	NSRect documentRect = [[_scrollView documentView] bounds];
	NSRect visibleRect = [_scrollView documentVisibleRect];
	
//	NSLog(@"update scroller");
	
	// Return from the function if:
	//	1. visible rect is the same as document rect; AND
	//	2. none of the scrollers are already showing (because if they are, we may want to remove them).
	if (documentRect.size.height == visibleRect.size.height
		&& !( (_topScroller && [_topScroller superview]) || (_bottomScroller && [_bottomScroller superview]) )
		)
		return;
	
	// We will adjust the Scroll frame to provide area for top/bottom scrollers
	//	NSRect scrollRect = [_scrollView frame];
	NSView *contentView = [self.window contentView];
	CGFloat scrollAmount = 0;
	CGFloat distanceToBottom = documentRect.size.height - visibleRect.origin.y - visibleRect.size.height;
//	NSTrackingArea *trackingArea;
	
	// TOP scroller
	if (visibleRect.origin.y == 0) {
		if (_topScroller && [_topScroller superview]) {
//			NSLog(@"should remove top scroler");
			[_topScroller removeFromSuperview];
			
			if (_scrollTimer && [_scrollTimer isValid]) {
				[_scrollTimer invalidate];
				_scrollTimer = nil;
			}
		}
	} else {
		if (! _topScroller) {
			// Keep scroller view retained up until the [CMWindowController dealloc],
			// because the view can be added and removed from superview multiple times
			// during menu scrolling.
			_topScroller = [[CMMenuScroller alloc] initWithScrollerType:CMMenuScrollerTop];
			[_topScroller setFrame:NSMakeRect(0, contentView.frame.size.height - MENU_SCROLLER_HEIGHT - _verticalPadding, documentRect.size.width, MENU_SCROLLER_HEIGHT)];
		}
		
		if (! [_topScroller superview]) {
			[contentView addSubview:_topScroller];
		}
		
		// In regular conditions, when we use mouse during scrolling, we autoscroll when the distance
		//	to top or bottom is less then one element high.
		// We check conditions however when we do not want such behavior:
		//		- distanceToBottom: when the menu is not high enough to show all elements and either top or bottom
		//			element is always partially hidden. When we scroll to top or bottom we do not want manu to autoscroll
		//			back in opposite direction.
		//		- _ignoreMouse: We are ignoring mouse usually during keyboard navigation. When we select the element before
		//			last, the last elemnt is precisely at the scroller.origin.y position. That means the content view has
		//			4pts (19pts item height - 15pts scroller height) of disctance to bottom/top. We surely do not want to autoscroll here.
		if (visibleRect.origin.y < 19 && distanceToBottom != 0 && !ignoreMouse)
			scrollAmount = -19;
	}
	
	// BOTTOM scroller
	if (distanceToBottom != 0) {
		if (! _bottomScroller) {
			// Same retain policy as _topScroller
			_bottomScroller = [[CMMenuScroller alloc] initWithScrollerType:CMMenuScrollerBottom];
			NSRect scrollerRect = NSMakeRect(0, _verticalPadding, documentRect.size.width, MENU_SCROLLER_HEIGHT);
			[_bottomScroller setFrame:scrollerRect];
		}
		
		if (! [_bottomScroller superview]) {
			[contentView addSubview:_bottomScroller];
		}
		
		// Check similar conditions at top for exmplanation
		if (distanceToBottom < 19 && visibleRect.origin.y != 0 && !ignoreMouse)
			scrollAmount = 19;
		
	} else if (_bottomScroller && [_bottomScroller superview]) {
		[_bottomScroller removeFromSuperview];
		
		if (_scrollTimer && [_scrollTimer isValid]) {
			[_scrollTimer invalidate];
			_scrollTimer = nil;
		}
	}
	
	if (scrollAmount > 0) {
		[_scrollView scrollDownByAmount:scrollAmount];
		[self updateMenuScrollersIgnoreMouse:ignoreMouse];
//		[self updateTrackingPrimitivesIgnoreMouse:ignoreMouse];
	} else if (scrollAmount < 0) {
		[_scrollView scrollUpByAmount:-scrollAmount];
		[self updateMenuScrollersIgnoreMouse:ignoreMouse];
//		[self updateTrackingPrimitivesIgnoreMouse:ignoreMouse];
	}
}



/*
 *
 */
- (NSViewController *)viewAtPoint:(NSPoint)aPoint {
	aPoint = [[_scrollView documentView] convertPoint:aPoint fromView:nil];
//	NSRect rect = [[_scrollView documentView] frame];;
	NSRect rect = [[_scrollView contentView] bounds];
	
	if (_topScroller && [_topScroller superview]) {
		rect.origin.y += MENU_SCROLLER_HEIGHT;
		rect.size.height -= MENU_SCROLLER_HEIGHT;
	}
	if (_bottomScroller && [_bottomScroller superview])
		rect.size.height -= MENU_SCROLLER_HEIGHT;
	
	if (aPoint.x < rect.origin.x || aPoint.x > rect.origin.x + rect.size.width
		|| aPoint.y < rect.origin.y || aPoint.y > rect.origin.y + rect.size.height)
		return nil;
	
//	NSArray *viewControllers = _viewControllers;
	for (NSViewController *viewController in _viewControllers) {
		NSRect frame = [[viewController view] frame];
		if (frame.origin.y + frame.size.height >= aPoint.y)
			return viewController;
	}
	
	return nil;
}


/*
 *
 */
- (CMMenuScroller *)scrollerAtPoint:(NSPoint)aPoint {
	if (_topScroller && [_topScroller superview] && NSPointInRect(aPoint, [_topScroller frame]))
		return _topScroller;
	
	if (_bottomScroller && [_bottomScroller superview] && NSPointInRect(aPoint, [_bottomScroller frame]))
		return _bottomScroller;
	
	return nil;
}


/*
 *
 */
- (void)moveVisibleRectToRect:(NSRect)rect ignoreMouse:(BOOL)ignoreMouse updateTrackingPrimitives:(BOOL)updateTrackingPrimitives {
	NSView *contentView = [_scrollView contentView];
	NSRect visibleRect;		// vivisbleRect may be smaller because of displayed Scrollers
	NSRect contentRect;
	NSRect documentRect = [[_scrollView documentView] bounds];
	visibleRect = contentRect = [contentView bounds];

//	NSLog(@"window rect: %@", NSStringFromRect([[self window] frame]));
//	NSLog(@"item rect: %@", NSStringFromRect(rect));
//	NSLog(@"visible rect: %@", NSStringFromRect(visibleRect));
//	NSLog(@"content rect: %@", NSStringFromRect([contentView bounds]));
	
	if (_topScroller && [_topScroller superview]) {
		visibleRect.origin.y += MENU_SCROLLER_HEIGHT;
		visibleRect.size.height -= MENU_SCROLLER_HEIGHT;
	}
	if (_bottomScroller && [_bottomScroller superview])
		visibleRect.size.height -= MENU_SCROLLER_HEIGHT;

	CGFloat scrollAmount = 0;
	if (rect.origin.y < visibleRect.origin.y) {
		scrollAmount = rect.origin.y - visibleRect.origin.y;
		if (contentRect.origin.y + scrollAmount < 0)
			scrollAmount = -contentRect.origin.y;
	} else if (rect.origin.y + rect.size.height > visibleRect.origin.y + visibleRect.size.height) {
		scrollAmount = rect.origin.y + rect.size.height - visibleRect.origin.y - visibleRect.size.height;
		if (contentRect.origin.y + contentRect.size.height + scrollAmount > documentRect.size.height)
			scrollAmount = documentRect.size.height - contentRect.origin.y - contentRect.size.height;
	}

//	NSLog(@"scroll amount: %f", scrollAmount);
//	NSLog(@"previous rect: %@, new rect: %@", NSStringFromRect(contentRect), NSStringFromRect(NSMakeRect(0, contentRect.origin.y + scrollAmount, contentRect.size.width, contentRect.size.height)));

	if (scrollAmount != 0) {
//		_ignoreMouse = ignoreMouse;
		[contentView setBounds:NSMakeRect(0, contentRect.origin.y + scrollAmount, contentRect.size.width, contentRect.size.height)];
		[self updateMenuScrollersIgnoreMouse:ignoreMouse];
		if (updateTrackingPrimitives)
			[self updateTrackingPrimitivesIgnoreMouse:ignoreMouse];
		XLog2("Menu \"%@\" moved visible for new bounds: %@",
			  [_owner title],
			  NSStringFromRect(NSMakeRect(0, contentRect.origin.y + scrollAmount, contentRect.size.width, contentRect.size.height)));
	}
}


/*
 *
 */
- (NSRect)visibleRectExcludingScrollers:(BOOL)countScrollers {
	NSRect visibleRect = [[_scrollView contentView] bounds];
	if (countScrollers) {
		if (_topScroller && [_topScroller superview]) {
			visibleRect.origin.y += MENU_SCROLLER_HEIGHT;
			visibleRect.size.height -= MENU_SCROLLER_HEIGHT;
		}
		if (_bottomScroller && [_bottomScroller superview])
			visibleRect.size.height -= MENU_SCROLLER_HEIGHT;
	}
	
	return visibleRect;
}



#pragma mark -
#pragma mark ******** Tracking Primitives & Events Handling ********


- (void)updateTrackingPrimitivesIgnoreMouse:(BOOL)ignoreMouse {
//	NSLog(@"update primitives");
	if (_trackingPrimitivesList) {
		// free all objects
		[self discardTrackingPrimitivesIgnoreMouse:NO];
	}
	
	NSView *documentView = [_scrollView documentView];
	NSRect visibleRect = [self visibleRectExcludingScrollers:YES];
	CGFloat visibleRectMinY = visibleRect.origin.y;
	CGFloat visibleRectMaxY = visibleRect.origin.y + visibleRect.size.height;
	NSPoint mouseLocation;
	if (! ignoreMouse) {
		mouseLocation = [[self window] mouseLocationOutsideOfEventStream];
		mouseLocation = [documentView convertPoint:mouseLocation fromView:nil];
	}
	

	CMTrackingPrimitive *trackingPrimitivesList = NULL;
	for (NSViewController *viewController in _viewControllers) {
		NSRect frame = [[viewController view] frame];
		if (frame.origin.y + frame.size.height <= visibleRectMinY)
			continue;
		
		if (frame.origin.y >= visibleRectMaxY)
			break;
		
		CMMenuItemView *view = (CMMenuItemView *)[viewController view];
		if (! [view needsTracking])
			continue;
		
		
		NSRect rect;
		// Visible rect of menu item could be smaller then its frame if its hidden by the scrollers
		if (frame.origin.y < visibleRectMinY) {
			rect = NSMakeRect(frame.origin.x, visibleRectMinY, frame.size.width, frame.origin.y + frame.size.height - visibleRectMinY);
		} else if (frame.origin.y + frame.size.height > visibleRectMaxY) {
			rect = NSMakeRect(frame.origin.x, frame.origin.y, frame.size.width, visibleRectMaxY - frame.origin.y);
		} else {
			rect = frame;
		}
		
		BOOL mouseInside = NO;
		if ( !ignoreMouse && NSPointInRect(mouseLocation, rect))
			mouseInside = YES;
		
		CMTrackingPrimitive *primitive = (CMTrackingPrimitive *)malloc(sizeof(CMTrackingPrimitive));
		if (primitive == NULL) {
			fputs("CMMenu: out of memmory", stderr);
			exit(EXIT_FAILURE);
		}
		
		rect = [documentView convertRect:rect toView:nil];
		rect = [[self window] convertRectToScreen:rect];
		primitive->rect = rect;
		primitive->userInfo = [[NSDictionary alloc] initWithObjectsAndKeys:
							   viewController, kUserDataViewControllerKey,
							   [NSNumber numberWithUnsignedInteger:CMMenuEventMouseItem], kUserDataEventTypeKey,
							   nil];
		primitive->mouseInside = mouseInside;
		primitive->next = trackingPrimitivesList;
		trackingPrimitivesList = primitive;
		
		if (mouseInside)
			[self mouseEventOnItemView:viewController eventType:CMMenuEventMouseEnteredItem | CMMenuEventDuringTrackingAreaUpdate];
	}
	
	if (_topScroller && [_topScroller superview]) {
		CMTrackingPrimitive *primitive = [self trackingPrimitiveForScroller:_topScroller];
		primitive->next = trackingPrimitivesList;
		trackingPrimitivesList = primitive;
	}
	if (_bottomScroller && [_bottomScroller superview]) {
		CMTrackingPrimitive *primitive = [self trackingPrimitiveForScroller:_bottomScroller];
		primitive->next = trackingPrimitivesList;
		trackingPrimitivesList = primitive;
	}
	
	_trackingPrimitivesList = trackingPrimitivesList;
}


/*
 *
 */
- (CMTrackingPrimitive *)trackingPrimitiveForScroller:(CMMenuScroller *)scroller {
	if (! scroller)
		return NULL;

	CMTrackingPrimitive *primitive = (CMTrackingPrimitive *)malloc(sizeof(CMTrackingPrimitive));
	if (primitive == NULL) {
		fputs("CMMenu: out of memmory", stderr);
		exit(EXIT_FAILURE);
	}
		
	
//	NSPoint mouseLocation = [[self window] mouseLocationOutsideOfEventStream];
//	mouseLocation = [[self window] convertBaseToScreen:mouseLocation];

	NSRect frame = [scroller frame];
	NSRect rect;
	// Top and bottom scrollers extend tracking rect to the border of the menu
	if ([scroller scrollerType] == CMMenuScrollerTop)
		rect = NSMakeRect(0, frame.origin.y, frame.size.width, frame.size.height + _verticalPadding);
	else
		rect = NSMakeRect(0, 0, frame.size.width, frame.size.height + _verticalPadding);
	

	rect = [[self window] convertRectToScreen:rect];
	primitive->rect = rect;
	primitive->userInfo = [[NSDictionary alloc] initWithObjectsAndKeys:
						   scroller, kUserDataScrollerViewKey,
						   [NSNumber numberWithUnsignedInteger:CMMenuEventMouseScroller], kUserDataEventTypeKey,
						   nil];
	// Mark all scroller tracking primitives as mouse is not inside event if it is at the time.
	// When mouse is moved -scrollWithActiveScroller: method verifies whether the timer is already
	// running and exit if it is. However if the timer was not active -- start a new one.
	// This logic takes care of behavior when mouse was positioned at the bottom of the menu when
	// scroller was not visible. Then scroll menu up with wheel and scroller appears. Now when mouse
	// moves -- scroller is able to fire its event.
	primitive->mouseInside = NO;
//	primitive->mouseInside = NSPointInRect(mouseLocation, rect) ? YES : NO;
	
	return primitive;
}


/*
 *
 */
- (void)updateTrackingPrimitiveForView:(NSViewController *)viewController ignoreMouse:(BOOL)ignoreMouse {
	CMMenuItemView *view = (CMMenuItemView *)[viewController view];
	NSView *documentView = [_scrollView documentView];
	CMTrackingPrimitive *currentTrackingPrimitive = NULL;
	
	if (_trackingPrimitivesList) {
		CMTrackingPrimitive *primitive;
		for (primitive = _trackingPrimitivesList; primitive != NULL; primitive = primitive->next) {
			NSViewController *vc = [primitive->userInfo objectForKey:kTrackingAreaViewControllerKey];
			if (viewController == vc) {
				currentTrackingPrimitive = primitive;
				break;
			}
		}
	}
	
	if ([view needsTracking]) {
		if (currentTrackingPrimitive)
			return;
		
		NSRect visibleRect = [self visibleRectExcludingScrollers:YES];
		NSPoint mouseLocation;
		mouseLocation = [[self window] mouseLocationOutsideOfEventStream];
		mouseLocation = [documentView convertPoint:mouseLocation fromView:nil];
		
		CGFloat visibleRectMaxY = visibleRect.origin.y + visibleRect.size.height;
		NSRect frame = [view frame];
		NSRect rect;
		if (frame.origin.y < visibleRect.origin.y) {
			rect = NSMakeRect(frame.origin.x, visibleRect.origin.y, frame.size.width, frame.origin.y + frame.size.height - visibleRect.origin.y);
		} else if (frame.origin.y + frame.size.height > visibleRectMaxY) {
			rect = NSMakeRect(frame.origin.x, frame.origin.y, frame.size.width, visibleRectMaxY - frame.origin.y);
		} else
			rect = frame;
		
		BOOL mouseInside = NO;
		if ( !ignoreMouse && NSPointInRect(mouseLocation, rect))
			mouseInside = YES;
		
		CMTrackingPrimitive *primitive = (CMTrackingPrimitive *)malloc(sizeof(CMTrackingPrimitive));
		if (primitive == NULL) {
			fputs("CMMenu: out of memmory", stderr);
			exit(EXIT_FAILURE);
		}
		
		rect = [documentView convertRect:rect toView:nil];
		rect = [[self window] convertRectToScreen:rect];
		primitive->rect = rect;
		primitive->userInfo = [[NSDictionary alloc] initWithObjectsAndKeys:
							   viewController, kUserDataViewControllerKey,
							   [NSNumber numberWithUnsignedInteger:CMMenuEventMouseItem], kUserDataEventTypeKey,
							   nil];
		primitive->mouseInside = mouseInside;
		primitive->next = _trackingPrimitivesList;
		_trackingPrimitivesList = primitive;
		
//		NSLog(@"created new tracking primitive: %@", primitive->userInfo);
		
		if (mouseInside)
			[self mouseEventOnItemView:viewController eventType:CMMenuEventMouseEnteredItem | CMMenuEventDuringTrackingAreaUpdate];
		
	} else if (currentTrackingPrimitive) {
		if (currentTrackingPrimitive == _trackingPrimitivesList) {
			_trackingPrimitivesList = currentTrackingPrimitive->next;
		} else {
			CMTrackingPrimitive *prev_primitive;
			for (prev_primitive = _trackingPrimitivesList; prev_primitive != NULL; prev_primitive = prev_primitive->next) {
				if (prev_primitive->next == currentTrackingPrimitive) {
					prev_primitive->next = currentTrackingPrimitive->next;
					break;
				}
			}
		}
		
//		NSLog(@"removing tracking primitive for item: %@", currentTrackingPrimitive->userInfo);
		
		[currentTrackingPrimitive->userInfo release];
		free(currentTrackingPrimitive);
	}
	
}


/*
 *
 */
- (void)discardTrackingPrimitivesIgnoreMouse:(BOOL)ignoreMouse {
	if (! _trackingPrimitivesList)
		return;

	CMTrackingPrimitive *primitive;
	CMTrackingPrimitive *next;
	for (primitive = _trackingPrimitivesList ; primitive != NULL; primitive = next) {
		if ( !ignoreMouse && primitive->mouseInside) {
			NSDictionary *userInfo = primitive->userInfo;
			CMMenuEventType eventType = [(NSNumber *)[userInfo objectForKey:kUserDataEventTypeKey] unsignedIntegerValue];
			if (eventType & CMMenuEventMouseItem) {

				NSViewController *viewController = [primitive->userInfo objectForKey:kUserDataViewControllerKey];
				[self mouseEventOnItemView:viewController eventType:CMMenuEventMouseExitedItem | CMMenuEventDuringTrackingAreaUpdate];
			}
		}
		[primitive->userInfo release];
		next = primitive->next;
		free(primitive);
	}
	_trackingPrimitivesList = NULL;
}


/*
 *
 */
- (void)eventOnTrackingPrimitiveAtLocation:(NSPoint)mouseLocation mouseInside:(BOOL)mouseInside {
//	NSLog(@"tracking event at loc: %@", NSStringFromPoint(mouseLocation));
	
	if (! _trackingPrimitivesList)
		return;
	
	
	// Find a primitive that had mouse inside before event
	CMTrackingPrimitive *mousedPrimitive = NULL;
	CMTrackingPrimitive *primitive;
	
	for (primitive = _trackingPrimitivesList ; primitive != NULL; primitive = primitive->next) {
		if (primitive->mouseInside) {
			mousedPrimitive = primitive;
			break;
		}
	}

	
	if (! mouseInside) {
		if (mousedPrimitive) {
			NSDictionary *userInfo = mousedPrimitive->userInfo;
			CMMenuEventType eventType = [(NSNumber *)[userInfo objectForKey:kUserDataEventTypeKey] unsignedIntegerValue];
			if (eventType & CMMenuEventMouseItem) {
				NSViewController *viewController = [userInfo objectForKey:kUserDataViewControllerKey];
				[self mouseEventOnItemView:viewController eventType:CMMenuEventMouseExitedItem];
			} else if (eventType & CMMenuEventMouseScroller) {
				if (_scrollTimer) {
					[_scrollTimer invalidate];
					_scrollTimer = nil;
				}
			}
			mousedPrimitive->mouseInside = NO;
		}
	} else {
		CMTrackingPrimitive *trackingPrimitive = NULL;		// find a primitive that currently has mouse inside
		for (primitive = _trackingPrimitivesList ; primitive != NULL; primitive = primitive->next) {
			if (NSPointInRect(mouseLocation, primitive->rect)) {
				trackingPrimitive = primitive;
				break;
			}
		}
		
		if (mousedPrimitive == trackingPrimitive) {		// do nothing
			return;
		}
		
		
		// Mouse exit from previous primitive
		if (mousedPrimitive) {
			mousedPrimitive->mouseInside = NO;
			NSDictionary *userInfo = mousedPrimitive->userInfo;
			CMMenuEventType eventType = [(NSNumber *)[userInfo objectForKey:kUserDataEventTypeKey] unsignedIntegerValue];
			if (eventType & CMMenuEventMouseItem) {
				NSViewController *viewController = [userInfo objectForKey:kUserDataViewControllerKey];
				[self mouseEventOnItemView:viewController eventType:CMMenuEventMouseExitedItem];
			} else if (eventType & CMMenuEventMouseScroller) {
				if (_scrollTimer) {
					[_scrollTimer invalidate];
					_scrollTimer = nil;
				}
			}
		}

		// Mouse enter new primitive
		if (trackingPrimitive) {
			trackingPrimitive->mouseInside = YES;
			NSDictionary *userInfo = trackingPrimitive->userInfo;
			CMMenuEventType eventType = [(NSNumber *)[userInfo objectForKey:kUserDataEventTypeKey] unsignedIntegerValue];
			if (eventType & CMMenuEventMouseItem) {
				NSViewController *viewController = [userInfo objectForKey:kTrackingAreaViewControllerKey];
				[self mouseEventOnItemView:viewController eventType:CMMenuEventMouseEnteredItem];
			} else if (eventType & CMMenuEventMouseScroller) {
				CMMenuScroller *scroller = [userInfo objectForKey:kUserDataScrollerViewKey];
//				NSLog(@"Mouse enter scroller: %@", scroller);
				[self scrollWithActiveScroller:scroller];
			}
		}
	}
}


// The center method of event tracking
- (void)_beginTrackingWithEvent:(NSEvent *)event {
	BOOL mouseIsDown = NO;
	BOOL mouseInsideWindow;
	NSEventMask runLoopEventMask = NSMouseEnteredMask | NSMouseExitedMask | NSLeftMouseDownMask | NSLeftMouseUpMask | NSRightMouseDownMask | NSRightMouseUpMask | NSOtherMouseDownMask | NSOtherMouseUpMask | NSScrollWheelMask | NSKeyDownMask | NSMouseMovedMask | NSLeftMouseDraggedMask | NSRightMouseDraggedMask | NSOtherMouseDraggedMask;
	
//	runLoopEventMask |= NSAppKitDefinedMask | NSApplicationDefinedMask | NSSystemDefinedMask;
	runLoopEventMask |= NSSystemDefinedMask;

//	NSPoint mouseLocation = [event locationInWindow];
//	if ([event window])
//		mouseLocation = [[event window] convertBaseToScreen:mouseLocation];
//	mouseInsideWindow = NSPointInRect(mouseLocation, [[self window] frame]);
//	NSLog(@"at beginning of tracking mouse is inside menu: %d, loc: %@, win: %@", mouseInsideWindow, NSStringFromPoint(mouseLocation), NSStringFromRect([[event window] frame]));
	
	
// temp var for moving menu
//	NSPoint initialLocation;

	XLog2("\n \
	--------------------------------------------------------\n \
	 BEGIN tracking RunLoop mode on menu \"%@\" with frame: %@\n \
	--------------------------------------------------------\n",
		  [_owner title],
		  NSStringFromRect([[self window] frame]));
	

	while (_keepTracking) {
		NSEvent *theEvent = [NSApp nextEventMatchingMask:runLoopEventMask
											   untilDate:[NSDate distantFuture]
												  inMode:NSEventTrackingRunLoopMode
												 dequeue:YES];

		if (! _keepTracking) {
//			NSLog(@"a-ha, final event: %@", theEvent);
			break;
		}
		
		
		
		NSWindow *eventWindow = [theEvent window];
		NSEventType eventType = [theEvent type];
		NSEventMask eventMask = NSEventMaskFromType(eventType);
//		NSPoint mouseLocation = [theEvent locationInWindow];
//		if (eventWindow)
//			mouseLocation = [eventWindow convertBaseToScreen:mouseLocation];
		NSPoint mouseLocation = [NSEvent mouseLocation];
		mouseInsideWindow = NSPointInRect(mouseLocation, [[self window] frame]);

//		NSLog(@"mouse loc: %@, global: %@, win: %@", NSStringFromPoint(mouseLocation), NSStringFromPoint([NSEvent mouseLocation]), eventWindow);
//		NSEventMask blockingMask = [_owner eventBlockingMask];
		
		// NSSystemDefinedMask
		// Added NSScrollWheelMask to suppres AppKit's:
		// -_continuousScroll is deprecated for NSScrollWheel. Please use -hasPreciseScrollingDeltas
		if (! (eventMask & (NSMouseMovedMask | NSLeftMouseDraggedMask | NSRightMouseDraggedMask | NSOtherMouseDraggedMask | NSScrollWheelMask))) {
			XLog3("New RunLoop event:\n\tEvent: %@\n\tMenu frame owning RunLoop:\t%@ \"%@\"\n\tMenu frame of occurred event:\t%@",
				  theEvent,
				  NSStringFromRect([[self window] frame]),
				  [_owner title],
				  NSStringFromRect([[theEvent window] frame]));
		}
		
		if (eventType == NSSystemDefined)
			continue;
		
		
		// Currently we calculate if there are any windows above menu only
		// for %down and %up events. If we ever need to know it also for
		// mouseMoved then we'd have to use these windows info.
		// https://developer.apple.com/library/mac/documentation/Carbon/Reference/CGWindow_Reference/Reference/Functions.html
//		CGWindowID windowID = (CGWindowID)[[self window] windowNumber];
//		CFArrayRef windows = CGWindowListCopyWindowInfo(kCGWindowListOptionOnScreenAboveWindow, windowID);
//		CFStringRef description = CFCopyDescription(windows);
//		NSLog(@"CF windows: %@", description);
//		CFRelease(description);
//		CFRelease(windows);
		
		
		CMMenu *candidateMenu = nil;
		if (! mouseInsideWindow) {
			candidateMenu = [self candidateMenuForEvent:theEvent];
			
			// Mouse moved events are handled separately below because
			// even if the candidate menu blocks this event, current menu
			// needs to process moved event through tracking primitives.
			if ( !(eventMask & (NSMouseMovedMask | NSLeftMouseDraggedMask | NSRightMouseDraggedMask | NSOtherMouseDraggedMask))
					&& candidateMenu
					&& (eventMask & [candidateMenu eventBlockingMask])) {
//				NSLog(@"Event has been blocked. Conitnue.");
				continue;
			}
		}

		BOOL mouseInsideDisplayedMenusDuringEvent = mouseInsideWindow;
		if ( !mouseInsideDisplayedMenusDuringEvent && candidateMenu)
			mouseInsideDisplayedMenusDuringEvent = YES;
		
				
#pragma mark MouseMoved
//#pragma mark LeftMouseDragged
//#pragma mark RightMouseDragged
//#pragma mark OtherMouseDragged
		if (eventMask & (NSMouseMovedMask | NSLeftMouseDraggedMask | NSRightMouseDraggedMask | NSOtherMouseDraggedMask)) {
			if (mouseInsideWindow) {
				// If menu has subscribed to receive mouse moved event -- send it to it
				if ([_owner receivesMouseMovedEvents])
					[_owner mouseEventAtLocation:mouseLocation type:NSMouseMoved];
				// Process tracking primitive event
				[self eventOnTrackingPrimitiveAtLocation:mouseLocation mouseInside:YES];
				
				/* temp *//* {
					NSUInteger modifierFlags = [theEvent modifierFlags];
					if ((modifierFlags & NSShiftKeyMask) != 0) {
						NSRect screenVisibleFrame = [[NSScreen mainScreen] visibleFrame];
						NSRect windowFrame = [[self window] frame];
						NSPoint newOrigin = windowFrame.origin;
						
						// Get the mouse location in window coordinates.
						NSPoint currentLocation = [theEvent locationInWindow];
						// Update the origin with the difference between the new mouse location and the old mouse location.
						newOrigin.x += (currentLocation.x - initialLocation.x);
						newOrigin.y += (currentLocation.y - initialLocation.y);
						
						// Don't let window get dragged up under the menu bar
						if ((newOrigin.y + windowFrame.size.height) > (screenVisibleFrame.origin.y + screenVisibleFrame.size.height)) {
							newOrigin.y = screenVisibleFrame.origin.y + (screenVisibleFrame.size.height - windowFrame.size.height);
						}
						
						// Move the window to the new location
						[[self window] setFrameOrigin:newOrigin];
					}
				} */ // temp
			} else {
				[self eventOnTrackingPrimitiveAtLocation:mouseLocation mouseInside:NO];
				
				if (candidateMenu && (eventMask & [candidateMenu eventBlockingMask])) {
//					NSLog(@"Event has been blocked. Conitnue.");
					goto endEvent;
				}
				
				// Possibly mouse entered another menu
				if (candidateMenu) {
					// If menu has subscribed to receive mouse moved event -- send it to it
					if ([candidateMenu receivesMouseMovedEvents])
						[candidateMenu mouseEventAtLocation:mouseLocation type:NSMouseMoved];
					
					[candidateMenu mouseEventAtLocation:mouseLocation type:NSMouseEntered];
					[[candidateMenu underlyingWindowController] eventOnTrackingPrimitiveAtLocation:mouseLocation mouseInside:YES];
					if ([candidateMenu supermenu] == _owner) {				// entered submenu
						[candidateMenu beginTrackingWithEvent:theEvent options:CMMenuOptionDefaults];
					} else {												// entered one of the supermenus
						[self endTracking];
					}
					
					// This goto will be reached only after menu's submenu ends tracking.
					// Menu here just ends the previous event (that started the submenu).
					goto endEvent;
				}
			}
			// MouseMoved events are not passed to other windows
			goto endEvent;
			
			
#pragma mark MouseDown
//#pragma mark RightMouseDown
//#pragma mark OtherMouseDown
		} else if (eventMask & (NSLeftMouseDownMask | NSRightMouseDownMask | NSOtherMouseDownMask)) {
			if (mouseInsideDisplayedMenusDuringEvent) {
				mouseIsDown = YES;
				[_owner mouseEventAtLocation:mouseLocation type:eventType];
				// temp
//				initialLocation = [theEvent locationInWindow];
				goto endEvent;
			} else {
				CMMenu *rootMenu = [_owner rootMenu];
				if ([rootMenu isAttachedToStatusItem] && NSPointInRect(mouseLocation, [rootMenu statusItemRect])) {
					[rootMenu cancelTracking];
					goto endEvent;
				}
			}
						
			if ([_owner cancelsTrackingOnMouseEventOutsideMenus] && !mouseInsideDisplayedMenusDuringEvent) {
//				NSLog(@"mouse is outside any menu during MOUSEDOWN!!!, mouseloc: %@", NSStringFromPoint(mouseLocation));
				[[_owner rootMenu] cancelTracking];
				goto endEvent;
			}
			
			
#pragma mark MouseUp
//#pragma mark RightMouseUp
//#pragma mark OtherMouseUp
		} else if (eventMask & (NSLeftMouseUpMask | NSRightMouseUpMask | NSOtherMouseUpMask)) {
			mouseIsDown = NO;
			
			if (mouseInsideDisplayedMenusDuringEvent) {
				[_owner mouseEventAtLocation:mouseLocation type:eventType];
			} else if ([_owner isAttachedToStatusItem] && NSPointInRect(mouseLocation, [_owner statusItemRect])) {
//				NSLog(@"status window: %@", [theEvent window]);
//				[NSApp discardEventsMatchingMask:NSAnyEventMask beforeEvent:theEvent];
//				[eventWindow sendEvent:theEvent];
				goto endEvent;
			} else if ([_owner cancelsTrackingOnMouseEventOutsideMenus]) {
//				NSLog(@"mouse is outside any menu during MOUSEUP!!!");
				// this may not be needed, since menus are cancelled on mouseDown
				[[_owner rootMenu] cancelTracking];
				goto endEvent;
			}
			
			
			/* temp */ { /*
				if (NSPointInRect(mouseLocation, [[self window] frame])) {
					CMMenuItem *item = [_owner itemAtPoint:mouseLocation];
					
					NSUInteger modifierFlags = [theEvent modifierFlags];
					if (modifierFlags & NSShiftKeyMask) {
						int i;
						int lim = 1;
						for (i = 0; i < lim; ++i) {
		//					CMMenuItem *item = [[CMMenuItem alloc] initWithTitle:@"New Item"];
							CMMenuItem *item  = [[CMMenuItem alloc] initWithTitle:@"New Item With Image" icon:[NSImage imageNamed:NSImageNameBluetoothTemplate] action:NULL];
							[_owner insertItem:item atIndex:1 animate:YES];
							[item release];
						}
					} else if (modifierFlags & NSControlKeyMask) {
						item = [_owner itemAtPoint:mouseLocation];
						if (item) {
							if (modifierFlags & NSAlternateKeyMask)
								[item setTitle:@"Shrt ttl"];
							else
								[item setTitle:@"New title for item and quite longer.."];
						}

					} else if (modifierFlags & NSAlternateKeyMask) {
						item = [_owner itemAtPoint:mouseLocation];
//						NSUInteger idx = (NSUInteger)[_owner indexOfItem:item];
						if (item) {
						[_owner removeItem:item animate:YES];
//							NSMutableIndexSet *indexes = [NSMutableIndexSet indexSet];
//							[indexes addIndex:(idx - 1)];
//							[indexes addIndex:idx];
//							[indexes addIndex:(idx + 2)];
//							[_owner removeItemsAtIndexes:indexes];
//							NSInteger indent = [item indentationLevel];
//							++indent;
//							if (indent > 15)
//								indent = 0;
//							[item setIndentationLevel:indent];
						}

					} else if (modifierFlags & NSCommandKeyMask) {
						if (eventType == NSRightMouseUp) {
							NSInteger state = [item state];
							NSInteger nextState = state + 1;
							if (nextState > 1)
								nextState = -1;
							[item setState:nextState];
						} else {
							[item setEnabled:![item isEnabled]];
						}
					}
				
	//				NSLog(@"Added new item: %@ to menu: %@", item, menu);
				} else {
//					if ([_owner cancelsTrackingOnMouseEventOutsideMenus] && ![self mouseInsideDisplayedMenusDuringEvent:theEvent]) {
//						NSLog(@"mouse is outside any menu during MOUSEUP!!!");
//						[[_owner rootMenu] cancelTracking];
//					}
				}
		*/	} /* temp */

#pragma mark ScrollWheel
		} else if (eventType == NSScrollWheel && mouseInsideWindow) {
			NSRect contentRect = [[_scrollView contentView] bounds];
			[_scrollView scrollWithEvent:theEvent];
			NSRect contentRectAfter = [[_scrollView contentView] bounds];
			if (! NSEqualRects(contentRect, contentRectAfter)) {	// scrollView's contentView changed its bounds
				[self updateMenuScrollersIgnoreMouse:NO];
				[self updateTrackingPrimitivesIgnoreMouse:NO];
			}

			
#pragma mark KeyDown
		} else if (eventType == NSKeyDown && !mouseIsDown) {
			if (! _keyEventInterpreter)
				_keyEventInterpreter = [[CMMenuKeyEventInterpreter alloc] initWithDelegate:_owner];
			
			[_keyEventInterpreter interpretEvent:theEvent];

		}
		
		if ( !mouseInsideDisplayedMenusDuringEvent
			&& eventType != NSKeyDown
			&& eventWindow
			&& ![_owner cancelsTrackingOnMouseEventOutsideMenus])
		{
//			NSLog(@"Sending event to non-menu window");
			[NSApp discardEventsMatchingMask:NSAnyEventMask beforeEvent:theEvent];
			[eventWindow sendEvent:theEvent];
		}

		
	endEvent:
		continue;
		
	}	// 	while (_keepTracking)
	
}


- (BOOL)mouseInsideDisplayedMenusDuringEvent:(NSEvent *)theEvent {
	NSPoint mouseLocation = [NSEvent mouseLocation];
	CMMenu *menu = _owner;
	do {
		if (NSPointInRect(mouseLocation, [menu frame]))
			return YES;
	} while ((menu = [menu supermenu]));
	
	return NO;
}


- (CMMenu *)candidateMenuForEvent:(NSEvent *)theEvent {
	NSPoint mouseLocation = [NSEvent mouseLocation];
	NSEventMask mask = NSEventMaskFromType([theEvent type]);
	CMMenu *menu = [_owner menuAtPoint:mouseLocation];

	if (mask & (NSLeftMouseDownMask | NSRightMouseDownMask | NSOtherMouseDownMask | NSLeftMouseUpMask | NSRightMouseUpMask | NSOtherMouseUpMask)) {
		if ([[[menu underlyingWindowController] window] isEqual:[theEvent window]])
			return menu;
		else
			return nil;
	} else {
		return menu;
	}
}


/*
 *
 */
- (void)mouseEventOnItemView:(NSViewController *)viewController eventType:(CMMenuEventType)eventType {
	CMMenuItem *menuItem = [viewController representedObject];
	
//	if ([menuItem isSeparatorItem])
//		return;
//	CMMenuItemView *view = (CMMenuItemView *)[viewController view];
//	NSLog(@"ffframe: %@", NSStringFromRect([view frame]));
	
//	NSLog(@"Mouse event on item: %@", [menuItem title]);
	
	
	BOOL selected;
	BOOL changeSelectionStatus = [menuItem shouldChangeItemSelectionStatusForEvent:eventType];
	
//	NSLog(@"should change: %d", changeSelectionStatus);
	CMMenuItemView *view = (CMMenuItemView *)[viewController view];
	
	if (eventType & CMMenuEventDuringTrackingAreaUpdate) {
		selected = (eventType & CMMenuEventMouseEnteredItem) ? YES : NO;
		[view setSelected:selected];
	} else {
		if (changeSelectionStatus) {
			if (eventType & CMMenuEventMouseEnteredItem) {
				[view setSelected:YES];
			} else {
				// Delay drawing deselection to get rid of flickering while moving mouse
				// over menu. (New: may not be needed with our own TrackingPrimitives,
				// unlike AppKit's TrackingAreas)
//				[self performSelector:@selector(delayedViewDeselection:) withObject:view afterDelay:0 inModes:[NSArray arrayWithObject:NSEventTrackingRunLoopMode]];
				[view setSelected:NO];
			}
		}
	}
}
	
	
- (void)delayedViewDeselection:(CMMenuItemView *)view {
	[view setSelected:NO];
}


/*
 *
 */
- (void)scrollWithActiveScroller:(CMMenuScroller *)scroller {
	if (_scrollTimer) {
		CMMenuScroller *activeScroller = [(NSDictionary *)[_scrollTimer userInfo] objectForKey:kUserDataScrollerViewKey];
		if (scroller == activeScroller) {	//	same scroller. exit
			return;
		} else {							// start new timer
			[_scrollTimer invalidate];
			_scrollTimer = nil;
		}
	}
//	NSDictionary *userData = [NSDictionary dictionaryWithObjectsAndKeys:scroller, kUserDataScrollerViewKey, nil];
	NSDictionary *userData = @{ kUserDataScrollerViewKey : scroller };
	_scrollTimer = [NSTimer timerWithTimeInterval:SCROLL_TIMER_INTERVAL target:self selector:@selector(scrollTimerEvent:) userInfo:userData repeats:YES];
	[[NSRunLoop currentRunLoop] addTimer:_scrollTimer forMode:NSRunLoopCommonModes];
}


/*
 *
 */
- (void)scrollTimerEvent:(NSTimer *)timer {
	NSDictionary *userData = [timer userInfo];
	CMMenuScroller *scroller = [userData objectForKey:kUserDataScrollerViewKey];
	
	// During tracking primitives update mouse can sneak out of tracking rect
	// in a fraction of time when old and new primitives are swapped.
	// This operation concernes only the scroller (and not other views) because
	// during tracking primitive removal Exit event is not fired.
	// It's timer responsibility to check whether mouse is still inside scroller.
	NSPoint mouseLocation = [[self window] mouseLocationOutsideOfEventStream];
	NSRect frame = [scroller frame];
	NSRect rect;
	// Top and bottom scrollers extend tracking rect to the border of the menu
	if ([scroller scrollerType] == CMMenuScrollerTop)
		rect = NSMakeRect(0, frame.origin.y, frame.size.width, frame.size.height + _verticalPadding);
	else
		rect = NSMakeRect(0, 0, frame.size.width, frame.size.height + _verticalPadding);
	
	if (! NSPointInRect(mouseLocation, rect)) {
		[timer invalidate];
		_scrollTimer = nil;
		return;
	}
	
	
	
	if ([scroller scrollerType] == CMMenuScrollerTop) {
		[_scrollView scrollUpByAmount:LINE_SCROLL_AMOUNT];
	} else {
		[_scrollView scrollDownByAmount:LINE_SCROLL_AMOUNT];
	}
	
	[self updateMenuScrollersIgnoreMouse:NO];
	[self updateTrackingPrimitivesIgnoreMouse:NO];
}


@end
