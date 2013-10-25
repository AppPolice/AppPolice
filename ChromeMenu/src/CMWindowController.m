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
#import "CMMenuItem.h"
#import "CMMenuItem+InternalMethods.h"
#import "CMMenu.h"
#import "CMMenu+InternalMethods.h"
#import "CMMenuScroller.h"
#import "CMMenuKeyEventInterpreter.h"
#import "CMDebug.h"
#include "CMMenuEventTypes.h"
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


typedef struct {
	NSRect rect;
	NSDictionary *userInfo;
	BOOL mouseInside;
} CMTrackingPrimitive;


@interface CMWindowController ()
{
	__weak CMMenu *_owner;
	__strong CMScrollView *_scrollView;
	CGFloat _verticalPadding;
//	CMScrollDocumentView *_scrollDocumentView;
	
//	BOOL _needsLayoutUpdate;
	CGFloat _maximumViewWidth;
	CGFloat _viewHeight;
	CGFloat _separatorViewHeight;
	
	__strong CMMenuScroller *_topScroller;
	__strong CMMenuScroller *_bottomScroller;
	NSTimer *_scrollTimer;
	
	NSMutableArray *_viewControllers;
	NSMutableArray *_trackingAreas;
	NSTrackingArea *_contentViewTrackingArea;
	CMTrackingPrimitive **_trackingPrimitives;
	
	BOOL _keepTracking;
	BOOL _ignoreMouse __attribute__((deprecated));
//	BOOL _ignoreMouseDuringScrollContentViewBoundsChange;
//	id _localEventMonitor;
	CMMenuKeyEventInterpreter *_keyEventInterpreter;
}

//@property (assign) BOOL needsLayoutUpdate;

- (void)setFrame:(NSRect)frame __attribute__((deprecated));

/**
 * @abstract Create Tracking Area for Menu Item view
 * @param viewController ViewController of a view that will be returned in userData in event
 * @param trackingRect Rect for tracking area. It represents only the visible portion of the view.
 */
- (NSTrackingArea *)trackingAreaForItemView:(NSViewController *)viewController inRect:(NSRect)trackingRect;
- (NSTrackingArea *)trackingAreaForScrollerView:(CMMenuScroller *)scroller inRect:(NSRect)trackingRect;

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

//- (void)finishScrollEventAfterTrackingAreasUpdated;
- (void)mouseEventOnItemView:(NSViewController *)viewController eventType:(CMMenuEventType)eventType;

@end

@implementation CMWindowController

//@synthesize needsLayoutUpdate = _needsLayoutUpdate;


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
	NSWindow *window = [[ChromeMenuUnderlyingWindow alloc] initWithContentRect:rect defer:YES];
	
	self = [super initWithWindow:window];
	if (self) {
		_owner = owner;
		
		CGFloat borderRadius = [owner borderRadius];
		NSArray *radiuses;
		if ([owner supermenu]) {
			radiuses = [NSArray arrayWithObjects:
						[NSNumber numberWithDouble:borderRadius],
						[NSNumber numberWithDouble:0.0],
						[NSNumber numberWithDouble:borderRadius],
						[NSNumber numberWithDouble:borderRadius], nil];
		} else {
			radiuses = [NSArray arrayWithObjects:
						[NSNumber numberWithDouble:borderRadius],
						[NSNumber numberWithDouble:borderRadius],
						[NSNumber numberWithDouble:borderRadius],
						[NSNumber numberWithDouble:borderRadius], nil];
		}
		
		ChromeMenuUnderlyingView *contentView = [[ChromeMenuUnderlyingView alloc] initWithFrame:rect borderRadius:radiuses];
		window.contentView = contentView;
		[contentView setAutoresizesSubviews:NO];
		
		static int level = 0;
		[window setLevel:NSPopUpMenuWindowLevel + level];
		++level;
		[window setHidesOnDeactivate:NO];
		
		_scrollView = [[CMScrollView alloc] initWithFrame:rect];
		[_scrollView setBorderType:NSNoBorder];
		[_scrollView setDrawsBackground:NO];
		[_scrollView setLineScroll:19.0 + VERTICAL_SPACING];	// 19 -- is the menu item heigh. Ideally we should not use magical number here.
		// activate vertical scroller, but then hide it
		[_scrollView setHasVerticalScroller:YES];
		[_scrollView setHasVerticalScroller:NO];
		
		CMScrollDocumentView *documentView = [[CMScrollDocumentView alloc] initWithFrame:NSZeroRect];
		[_scrollView setDocumentView:documentView];
		[contentView addSubview:_scrollView];
//		[documentView setListenerForUpdateTrackingAreasEvent:self];
		
		// Post a notification when scroll view scrolled
		[[_scrollView contentView] setPostsBoundsChangedNotifications:YES];
		
		[documentView release];
		[contentView release];
		
		_separatorViewHeight = 12.0;
		_verticalPadding = 4.0;
		_keepTracking = NO;
		_ignoreMouse = NO;
		_trackingPrimitives = NULL;
//		_ignoreMouseDuringScrollContentViewBoundsChange = NO;
		
//		[self setNeedsLayoutUpdate:YES];
	}
	
	[window release];
	
	return self;
}


- (void)dealloc {
	[_viewControllers release];
	[_trackingAreas release];
	[_scrollView release];
	[_keyEventInterpreter release];
	
	[super dealloc];
}



- (void)windowDidLoad {
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}


- (CGFloat)verticalPadding {
	return _verticalPadding;
}


- (NSSize)intrinsicContentSize {
//	return NSMakeSize(_maximumViewWidth, [[[_scrollView documentView] subviews] count] * (_viewHeight + VERTICAL_SPACING) + 2 * _verticalPadding);
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
//	[[self window] setIgnoresMouseEvents:YES];

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
		[self updateTrackingPrimitivesIgnoreMouse:ignoreMouse];
		
		// Flag is set back to NO. Whoever needs it must provide value each time.
//		_ignoreMouse = NO;
		
		if (! isVisible) {
			[[NSNotificationCenter defaultCenter] addObserver:self
													 selector:@selector(scrollViewContentViewBoundsDidChange:)
														 name:NSViewBoundsDidChangeNotification
													   object:[_scrollView contentView]];
		}
	}
}



/*
 *
 */ /*
- (void)updateFrame:(NSRect)frame options:(CMMenuOptions)options {
//	NSLog(@"window prev. frame: %@, new frame: %@", NSStringFromRect([[self window] frame]), NSStringFromRect(frame));
	
	[[self window] disableScreenUpdatesUntilFlush];
//	[[self window] disableFlushWindow];
	[self.window setFrame:frame display:NO animate:NO];
//	[[[self window] contentView] display];
	// Scroll view frame includes the menu top and bottom paddings
	[_scrollView setFrame:NSMakeRect(0, _verticalPadding, frame.size.width, frame.size.height - 2 * _verticalPadding)];
//	[_scrollView display];

//	[[self window] display];
//	[[self window] enableFlushWindow];
	[[self window] flushWindowIfNeeded];
//	[_scrollView setNeedsDisplay:YES];
	
//	CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0, NO);


	
	[self updateMenuScrollersIgnoreMouse];
	
//	if (ignoreMouse)
//		_ignoreMouse = YES;
	if (options & CMMenuOptionIgnoreMouse)
		_ignoreMouse = YES;
	
	[self updateTrackingAreasForVisibleRect:[[_scrollView contentView] bounds]];
	BOOL trackMouseMoved = (options & CMMenuOptionTrackMouseMoved);
	[self updateContentViewTrackingAreaTrackMouseMoved:trackMouseMoved];

	// Flag is set back to NO. Whoever needs it must provide value each time.
	_ignoreMouse = NO;
}
*/

- (BOOL)isTracking {
	return _keepTracking;
}


- (void)beginTrackingWithEvent:(NSEvent *)event {
	if (_keepTracking)
		return;
	
	_keepTracking = YES;
	// Add to a run loop queue so that Cocoa finishes its preparations on the main thread in current loop.
	// Tracking begins in another loop, for example, after tracking areas are properly installed by Cocoa.
	if ([_owner supermenu]) {
		[self performSelector:@selector(_beginTrackingWithEvent:) withObject:event];
	} else {
		[self performSelector:@selector(_beginTrackingWithEvent:) withObject:event afterDelay:0 inModes:[NSArray arrayWithObject:NSRunLoopCommonModes]];
	}
//	[self _beginEventTracking];
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
	// By posting another event we will effectively quit nextEventMatchingMask event tracking
	//	since we set the _keepTracking to NO.
	NSEvent *customEvent = [NSEvent otherEventWithType:NSSystemDefined location:NSMakePoint(1, 1) modifierFlags:0 timestamp:0 windowNumber:0 context:nil subtype:0 data1:0 data2:0];
//	NSEvent *customEvent = [NSEvent mouseEventWithType:NSLeftMouseDown location:NSMakePoint(1, 1) modifierFlags:0 timestamp:0 windowNumber:0 context:nil eventNumber:0 clickCount:1 pressure:0.0];
	NSLog(@"resend last event: %@", customEvent);
	[NSApp postEvent:customEvent atStart:YES];
}



/*
 *
 */
- (void)setFrame:(NSRect)frame {
	[self.window setFrame:frame display:NO];
	// Scroll view frame includes the menu top and bottom paddings
	[_scrollView setFrame:NSMakeRect(0, _verticalPadding, frame.size.width, frame.size.height - 2 * _verticalPadding)];
}


/*
 *
 */
- (void)hide {
	[self discardTrackingPrimitivesIgnoreMouse:YES];
	[[self window] orderOut:self];
	[[NSNotificationCenter defaultCenter] removeObserver:self];

//	[NSEvent removeMonitor:_localEventMonitor];
//	_localEventMonitor = nil;

}


- (void)fadeOutWithComplitionHandler:(void (^)(void))handler {
	NSView *contentView = [[self window] contentView];
	[NSAnimationContext beginGrouping];
	NSAnimationContext *ctx = [NSAnimationContext currentContext];
	[ctx setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn]];
	[ctx setDuration:0.145];
	[ctx setCompletionHandler:^(void) {
		[contentView setAlphaValue:1.0];
		if (handler)
			handler();
	}];
	[[contentView animator] setAlphaValue:0.0];
	[NSAnimationContext endGrouping];
}


/*
 *
 */
- (void)scrollViewContentViewBoundsDidChange:(NSNotification *)notification {
	XLog3("Scroll ContentView BoundsDidChangeNotification with new bounds: %@", NSStringFromRect([[_scrollView contentView] bounds]));
//	[self updateMenuScrollersIgnoreMouse];
//	[self updateTrackingPrimitivesIgnoreMouse:NO/YES];
//	[self updateTrackingAreasForVisibleRect:[self visibleRectExcludingScrollers:YES]];
	
//	[self updateTrackingAreasForVisibleRect:[NSValue valueWithRect:[[_scrollView contentView] bounds]]];
//	[self performSelector:@selector(updateTrackingAreasForVisibleRect:) withObject:[NSValue valueWithRect:[[_scrollView contentView] bounds]] afterDelay:0.0 inModes:[NSArray arrayWithObject:NSEventTrackingRunLoopMode]];
	
	/* When scroll event is fired we upate Tracking Areas. During this time user can move the mouse as well.
	 Tracking areas are not yet active and working. As a result there might be double-selection of
	 different menu items at the same time. We run a finilizing function from another Run Loop
	 after tracking areas are completely set-up. */
//	if (! _ignoreMouseDuringScrollContentViewBoundsChange)
//	if (! _ignoreMouse)
//		[self performSelector:@selector(finishScrollEventAfterTrackingAreasUpdated) withObject:nil afterDelay:0.0];

//	[self updateTrackingAreasForVisibleRect_2:[[_scrollView contentView] bounds]];
	
//	_ignoreMouseDuringScrollContentViewBoundsChange = NO;
	// At the end of event we set variable back. Whoever wants mouse to be ignored must provide a flag each time.
	_ignoreMouse = NO;
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
	
	for (NSViewController *controller in viewControllers) {
		NSView *view = controller.view;
		NSSize size = [view fittingSize];
		if (size.width > maximumWidth)
			maximumWidth = size.width;

		[documentView addSubview:view];
	}
	
	_viewHeight = [[viewControllers objectAtIndex:0] view].frame.size.height;
	_maximumViewWidth = maximumWidth;

	
	[self updateViews];
}



/*
 * TODO: don't like this function. It could be united with the method above, if there is no sence in it.
 */
- (void)updateViews {
	NSArray *viewControllers = _viewControllers;
	NSView *documentView = [_scrollView documentView];
	CGFloat width = _maximumViewWidth;
	CGFloat viewHeight = _viewHeight;
	CGFloat separatorViewHeight = _separatorViewHeight;
	CGFloat offset = 0.0f;

	for (NSViewController *viewController in [viewControllers reverseObjectEnumerator]) {
		CMMenuItem *menuItem = [viewController representedObject];
		NSView *view = [viewController view];
		NSRect frame;
		CGFloat height = ([menuItem isSeparatorItem]) ? separatorViewHeight : viewHeight;
		frame.size = NSMakeSize(width, height);
		offset -= height + VERTICAL_SPACING;
		frame.origin.y = offset;
		frame.origin.x = 0;
		[view setFrame:frame];
	}

	[documentView setFrame:NSMakeRect(0, 0, width, -1 * offset)];
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
	
	NSView *view = [[_viewControllers objectAtIndex:index] view];
	[(CMMenuItemView *)view fadeOutWithComplitionHandler:^(void) {
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
	
	NSLog(@"update scroller");
	
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
	//	if (visibleRect.origin.y < 19) {
	if (visibleRect.origin.y == 0) {
		if (_topScroller && [_topScroller superview]) {
			NSLog(@"should remove top scroler");
			[_topScroller removeFromSuperview];
//			[contentView removeTrackingArea:[_topScroller trackingArea]];
			//			scrollRect.size.height += MENU_SCROLLER_HEIGHT;
			
			/* We keep track on changes to Visible Rect because on it depends the bottom scroller display.
			 Actual scrolling is done in the very end as it generates another Scroll Event and the execution
			 of this function is being interrupted in the middle */
			//			visibleRect.size.height += MENU_SCROLLER_HEIGHT;
			//			visibleRect.origin.y -= MENU_SCROLLER_HEIGHT;
			
			// When we're close enough to top we autoscroll one element higher to the very top,
			// because we are removing the top scroller.
			// 19 is just large enough height to scroll to top
			//			scrollAmount = -19;
			
			if (_scrollTimer && [_scrollTimer isValid]) {
				[_scrollTimer invalidate];
//				[_scrollTimer release];
				_scrollTimer = nil;
			}
		}
	} else {
		if (! _topScroller) {
			_topScroller = [[CMMenuScroller alloc] initWithScrollerType:CMMenuScrollerTop];
			[_topScroller setFrame:NSMakeRect(0, contentView.frame.size.height - MENU_SCROLLER_HEIGHT - _verticalPadding, documentRect.size.width, MENU_SCROLLER_HEIGHT)];
		}
		
		if (! [_topScroller superview]) {
			[contentView addSubview:_topScroller];
//			NSRect frame = [_topScroller frame];
//			trackingArea = [self trackingAreaForScrollerView:_topScroller inRect:
//							NSMakeRect(0, frame.origin.y, frame.size.width, frame.size.height + _verticalPadding)];
//			[contentView addTrackingArea:trackingArea];
//			[_topScroller setTrackingArea:trackingArea];
			//			scrollRect.size.height -= MENU_SCROLLER_HEIGHT;
			//			visibleRect.size.height -= MENU_SCROLLER_HEIGHT;
			//			visibleRect.origin.y += MENU_SCROLLER_HEIGHT;
			//			scrollAmount = 19.0;
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
	//	CGFloat visibleRectHeight = (_bottomScroller && [_bottomScroller superview]) ? visibleRect.size.height + MENU_SCROLLER_HEIGHT :
	//		visibleRect.size.height;
	//	if (visibleRect.origin.y + visibleRectHeight < documentRect.size.height) {
	if (distanceToBottom != 0) {
		if (! _bottomScroller) {
			_bottomScroller = [[CMMenuScroller alloc] initWithScrollerType:CMMenuScrollerBottom];
			NSRect scrollerRect = NSMakeRect(0, _verticalPadding, documentRect.size.width, MENU_SCROLLER_HEIGHT);
			[_bottomScroller setFrame:scrollerRect];
		}
		
		if (! [_bottomScroller superview]) {
			[contentView addSubview:_bottomScroller];
//			NSRect frame = [_bottomScroller frame];
//			trackingArea = [self trackingAreaForScrollerView:_bottomScroller inRect:NSMakeRect(0, 0, frame.size.width, frame.size.height + _verticalPadding)];
//			[contentView addTrackingArea:trackingArea];
//			[_bottomScroller setTrackingArea:trackingArea];
			//			scrollRect.origin.y +=  MENU_SCROLLER_HEIGHT;
			//			scrollRect.size.height -= MENU_SCROLLER_HEIGHT;
		}
		
		// Check similar conditions at top for exmplanation
		if (distanceToBottom < 19 && visibleRect.origin.y != 0 && !ignoreMouse)
			scrollAmount = 19;
		
	} else if (_bottomScroller && [_bottomScroller superview]) {
		[_bottomScroller removeFromSuperview];
//		[contentView removeTrackingArea:[_bottomScroller trackingArea]];
		//		scrollRect.origin.y -= MENU_SCROLLER_HEIGHT;
		//		scrollRect.size.height += MENU_SCROLLER_HEIGHT;
		//		scrollAmount = 19;
		
		if (_scrollTimer && [_scrollTimer isValid]) {
			[_scrollTimer invalidate];
//			[_scrollTimer release];
			_scrollTimer = nil;
		}
	}
	
	//	[_scrollView setFrame:scrollRect];
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
//	NSRect visibleRect = [_scrollView documentVisibleRect];
//	NSRect itemFrame = [[viewController view] frame];
	
//	_ignoreMouseDuringScrollContentViewBoundsChange = ignoreMouse;
	
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
#pragma mark ******** Tracking Areas & Events Handling ********


/*
 *
 */
- (void)updateTrackingAreasForVisibleRect:(NSRect)visibleRect {
//- (void)updateTrackingAreasForVisibleRect:(id)rectValue {
//	NSRect visibleRect = [rectValue rectValue];

	NSLog(@" *********** updating tracking areas for visible rect: %@", NSStringFromRect(visibleRect));
//	NSLog(@"current runloop: %@", [[NSRunLoop currentRunLoop] currentMode]);

	
	NSView *documentView = [_scrollView documentView];
	if (_trackingAreas) {
		for (NSTrackingArea *trackingArea in _trackingAreas) {
			[documentView removeTrackingArea:trackingArea];
//			[[NSRunLoop currentRunLoop] performSelector:@selector(removeTrackingArea:) target:documentView argument:trackingArea order:0 modes:[NSArray arrayWithObject:NSRunLoopCommonModes]];
			
			/* We remove highlighting of the previously selected view */
//			CMMenuItemView *view = [(NSDictionary *)[trackingArea userInfo] objectForKey:kTrackingAreaViewControllerKeyKey];
			NSViewController *viewController = [(NSDictionary *)[trackingArea userInfo] objectForKey:kTrackingAreaViewControllerKey];
//			if ([view isSelected])
//				[view setSelected:NO];
//			if (! _ignoreMouseDuringScrollContentViewBoundsChange)
			if (! _ignoreMouse)
				[self mouseEventOnItemView:viewController eventType:CMMenuEventMouseExitedItem | CMMenuEventDuringTrackingAreaUpdate];
		}
		[_trackingAreas removeAllObjects];
	} else {
		// maks: see if we need to remove tracking areas on window orderOut:
		_trackingAreas = [[NSMutableArray alloc] init];
	}
	
	
	/* When scrolling -mouseEntered and -mouseExited events are not being fired.
	   This is because we have removed them. Event if not -- they fire wrong tracking areas anyway.
	   So at the time of creating of tracking areas we check where the mouse is and
	   highlight according view. */
	NSPoint mouseLocation;
	mouseLocation = [[self window] mouseLocationOutsideOfEventStream];
	mouseLocation = [documentView convertPoint:mouseLocation fromView:nil];

//	if (_topScroller && [_topScroller superview]) {
//		visibleRect.origin.y += MENU_SCROLLER_HEIGHT;
//		visibleRect.size.height -= MENU_SCROLLER_HEIGHT;
//	}
//	if (_bottomScroller && [_bottomScroller superview])
//		visibleRect.size.height -= MENU_SCROLLER_HEIGHT;
	
	CGFloat visibleRectMaxY = visibleRect.origin.y + visibleRect.size.height;
	
	for (NSViewController *viewController in _viewControllers) {
		NSRect frame = [[viewController view] frame];
		if (frame.origin.y + frame.size.height <= visibleRect.origin.y)
			continue;
		
		if (frame.origin.y >= visibleRectMaxY)
			break;
				
		if (! [(CMMenuItemView *)[viewController view] needsTracking])
			continue;
		
		NSRect rect;
		if (frame.origin.y < visibleRect.origin.y) {
			rect = NSMakeRect(frame.origin.x, visibleRect.origin.y, frame.size.width, frame.origin.y + frame.size.height - visibleRect.origin.y);
		} else if (frame.origin.y + frame.size.height > visibleRectMaxY) {
			rect = NSMakeRect(frame.origin.x, frame.origin.y, frame.size.width, visibleRectMaxY - frame.origin.y);
		} else
			rect = frame;
		
//		NSLog(@"tracking rect: %@", NSStringFromRect(rect));
		
		NSTrackingArea *trackingArea = [self trackingAreaForItemView:viewController inRect:rect];
		[documentView addTrackingArea:trackingArea];
//		[[NSRunLoop currentRunLoop] performSelector:@selector(addTrackingArea:) target:documentView argument:trackingArea order:0 modes:[NSArray arrayWithObject:NSRunLoopCommonModes]];

		[_trackingAreas addObject:trackingArea];
		
//		if (NSPointInRect(mouseLocation, [view frame]))
//			[view setSelected:YES];


//		NSPoint currentLocation = [[self window] mouseLocationOutsideOfEventStream];
//		currentLocation = [documentView convertPoint:currentLocation fromView:nil];

//		if ( !_ignoreMouseDuringScrollContentViewBoundsChange && NSPointInRect(mouseLocation, rect)) {
		if ( !_ignoreMouse && NSPointInRect(mouseLocation, rect)) {
//		if (NSPointInRect(currentLocation, frame)) {
			/* debuggin */
//			CMMenuItem *item = [viewController representedObject];
//			NSLog(@"SELECT ITEM DURING SCROLL: %@", item);
//			NSPoint currentLocation = [[self window] mouseLocationOutsideOfEventStream];
//			currentLocation = [documentView convertPoint:currentLocation fromView:nil];
//			NSLog(@"At mouse location: %@, current location: %@", NSStringFromPoint(mouseLocation), NSStringFromPoint(currentLocation));


		
			[self mouseEventOnItemView:viewController eventType:CMMenuEventMouseEnteredItem | CMMenuEventDuringTrackingAreaUpdate];
		}
		

	}
	
//	NSLog(@"last item for areas: %@", [lastController representedObject]);
	
//	NSLog(@"first index: %ld, last: %ld, location: %@, tracking_areas_count:%ld", firstIndex, i, NSStringFromPoint(afterLocation),
//		  [[[_scrollView documentView] trackingAreas] count]);

//	[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
	
	// Let RunLoop run one time in default mode so the AppKit can establish tracking areas
	CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0, NO);
}


/*
 *
 */
- (void)updateItemViewTrackingArea:(NSViewController *)viewController {
	CMMenuItemView *view = (CMMenuItemView *)[viewController view];
	NSView *documentView = [_scrollView documentView];
	NSTrackingArea *currentTrackingArea = nil;

	for (NSTrackingArea *trackingArea in _trackingAreas) {
		NSViewController *trackingAreaViewController = [(NSDictionary *)[trackingArea userInfo] objectForKey:kTrackingAreaViewControllerKey];
		if (viewController == trackingAreaViewController) {
			currentTrackingArea = trackingArea;
			break;
		}
	}

	if ([view needsTracking]) {
		if (currentTrackingArea)
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
			
		NSTrackingArea *trackingArea = [self trackingAreaForItemView:viewController inRect:rect];
		[documentView addTrackingArea:trackingArea];
		[_trackingAreas addObject:trackingArea];
			
		if ( !_ignoreMouse && NSPointInRect(mouseLocation, rect)) {
			[self mouseEventOnItemView:viewController eventType:CMMenuEventMouseEnteredItem | CMMenuEventDuringTrackingAreaUpdate];
		}
	} else if (currentTrackingArea) {
		[documentView removeTrackingArea:currentTrackingArea];
		[_trackingAreas removeObject:currentTrackingArea];
//		for (NSTrackingArea *trackingArea in _trackingAreas) {
//			NSViewController *trackingAreaViewController = [(NSDictionary *)[trackingArea userInfo] objectForKey:kTrackingAreaViewControllerKeyKey];
//			if (viewController == trackingAreaViewController) {
//				[documentView removeTrackingArea:trackingArea];
//				[_trackingAreas removeObject:trackingArea];
//				break;
//			}
//		}
	}

	CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0, NO);
}


/*
 *
 */
/*
- (void)updateTrackingAreasForVisibleRect_2:(NSRect)visibleRect {
	NSView *documentView = [_scrollView documentView];
	NSMutableArray *trackingAreas = [[NSMutableArray alloc] init];
	CGFloat trackingAreaMinY = 999999;		// some largely enough number
	CGFloat trackingAreaMaxY = 0;
	
	// Remove only those tracking areas that are no longer inside the Visible Rect 
	if (_trackingAreas) {
		for (NSTrackingArea *trackingArea in _trackingAreas) {
			NSRect trackingRect = [trackingArea rect];
			if (trackingRect.origin.y + trackingRect.size.height <= visibleRect.origin.y ||
				trackingRect.origin.y >= visibleRect.origin.y + visibleRect.size.height) {
				[documentView removeTrackingArea:trackingArea];
//				[_trackingAreas removeObject:trackingArea];
				
				NSLog(@"Removing tracking area at rect: %@", NSStringFromRect(trackingRect));
				
				continue;
			}
			
			[trackingAreas addObject:trackingArea];
			NSViewController *viewController = [[trackingArea userInfo] objectForKey:kTrackingAreaViewControllerKeyKey];
			[self mouseEventOnItemView:viewController eventType:CMMenuEventMouseExitedItem | CMMenuEventDuringTrackingAreasUpdate];

			
			if (trackingRect.origin.y < trackingAreaMinY)
				trackingAreaMinY = trackingRect.origin.y;
			if (trackingRect.origin.y + trackingRect.size.height > trackingAreaMaxY)
				trackingAreaMaxY = trackingRect.origin.y + trackingRect.size.height;
		}
	}
//	else {
//		_trackingAreas = [[NSMutableArray alloc] init];
//	}
	
	
	NSPoint mouseLocation;
	mouseLocation = [[self window] mouseLocationOutsideOfEventStream];
	mouseLocation = [documentView convertPoint:mouseLocation fromView:nil];
	int i = 0;
	NSUInteger last_i = [_viewControllers count];
	
	for (NSViewController *viewController in _viewControllers) {
		++i;
		NSRect frame = [[viewController view] frame];
		if (frame.origin.y + frame.size.height <= visibleRect.origin.y)
			continue;
		
		if (frame.origin.y >= visibleRect.origin.y + visibleRect.size.height)
			break;
		
		if (! [(CMMenuItemView *)[viewController view] needsTracking])
			continue;
		
		if (i == last_i) {
			NSLog(@"last iteration");
		}

		if (frame.origin.y < trackingAreaMinY || frame.origin.y > trackingAreaMaxY) {	// we don't check frame.size.height as not necessary
			NSTrackingArea *trackingArea = [self trackingAreaForViewController:viewController];
			[documentView addTrackingArea:trackingArea];
//			[_trackingAreas addObject:trackingArea];
			[trackingAreas addObject:trackingArea];
		}
		
		
//		NSPoint currentLocation = [[self window] mouseLocationOutsideOfEventStream];
//		currentLocation = [documentView convertPoint:currentLocation fromView:nil];
		
		if (NSPointInRect(mouseLocation, frame)) {
			
			CMMenuItem *item = [viewController representedObject];
//			NSLog(@"SELECT ITEM DURING SCROLL: %@", item);

			[self mouseEventOnItemView:viewController eventType:CMMenuEventMouseEnteredItem | CMMenuEventDuringTrackingAreasUpdate];
		}
//		else {
//			[self mouseEventOnItemView:viewController eventType:CMMenuEventMouseExitedItem | CMMenuEventDuringTrackingAreasUpdate];
//		}
	}
	
	if (_trackingAreas)
		[_trackingAreas release];
	_trackingAreas = [trackingAreas retain];
	[trackingAreas release];
	
	[self performSelector:@selector(finishScrollEventAfterTrackingAreasUpdated) withObject:nil afterDelay:0.0];
}
*/

/*	// do not delete so easily, it might be needed
- (void)finishScrollEventAfterTrackingAreasUpdated {
//	NSLog(@"finish, areas count: %ld", [[[_scrollView documentView] trackingAreas] count]);

	NSPoint mouseLocation;
	mouseLocation = [[self window] mouseLocationOutsideOfEventStream];
	mouseLocation = [[_scrollView documentView] convertPoint:mouseLocation fromView:nil];

	
	for (NSTrackingArea *trackingArea in _trackingAreas) {
		NSViewController *viewController = [(NSDictionary *)[trackingArea userInfo] objectForKey:kTrackingAreaViewControllerKeyKey];
//		NSRect frame = [[viewController view] frame];
		NSRect frame = [trackingArea rect];

		if (NSPointInRect(mouseLocation, frame)) {
//			CMMenuItem *item = [viewController representedObject];
//			NSLog(@"SELECT ITEM AFTER updating tracking areas: %@", item);
			[self mouseEventOnItemView:viewController eventType:CMMenuEventMouseEnteredItem | CMMenuEventDuringTrackingAreasUpdate];
		} else
			[self mouseEventOnItemView:viewController eventType:CMMenuEventMouseExitedItem | CMMenuEventDuringTrackingAreasUpdate];
//			[(CMMenuItemView *)[viewController view] setSelected:NO];
	}

}
*/

//- (void)shouldUpdateTrackingAreas {
////	NSArray *controllers = _viewControllers;
//	NSPoint mouseLocation;
//	mouseLocation = [[self window] mouseLocationOutsideOfEventStream];
//	mouseLocation = [[_scrollView documentView] convertPoint:mouseLocation fromView:nil];
//	
////	for (NSViewController *viewController in controllers) {
////			
////	}
//
//	
//	for (NSTrackingArea *trackingArea in _trackingAreas) {
//		NSViewController *viewController = [(NSDictionary *)[trackingArea userInfo] objectForKey:kTrackingAreaViewControllerKeyKey];
//		NSRect frame = [[viewController view] frame];
//		
//		if (NSPointInRect(mouseLocation, frame)) {
//			CMMenuItem *item = [viewController representedObject];
//			NSLog(@"SELECT ITEM AFTER updating tracking areas: %@", item);
//			[self mouseEventOnItemView:viewController eventType:CMMenuEventMouseEnteredItem | CMMenuEventDuringTrackingAreasUpdate];
//		} else
//			[(CMMenuItemView *)[viewController view] setSelected:NO];
//	}
//
//	
//	
////	NSPoint currentLocation = [[self window] mouseLocationOutsideOfEventStream];
////	currentLocation = [[_scrollView documentView] convertPoint:currentLocation fromView:nil];
////	NSLog(@"Update Tracking Areas called!! Mouse at: %@", NSStringFromPoint(currentLocation));
//}


/*
 *
 */
- (NSTrackingArea *)trackingAreaForItemView:(NSViewController *)viewController inRect:(NSRect)trackingRect {
//	NSRect trackingRect = [[_scrollView documentView] convertRect:[[viewController view] bounds] fromView:[viewController view]];
	NSTrackingAreaOptions trackingOptions = NSTrackingMouseEnteredAndExited | NSTrackingEnabledDuringMouseDrag | NSTrackingActiveInActiveApp;
	NSDictionary *trackingData = [NSDictionary dictionaryWithObjectsAndKeys:
								  viewController, kTrackingAreaViewControllerKey,
								  [NSNumber numberWithUnsignedInteger:CMMenuEventMouseItem], kUserDataEventTypeKey,
								  nil];
	
	NSTrackingArea *trackingArea = [[NSTrackingArea alloc] initWithRect:trackingRect options:trackingOptions owner:self userInfo:trackingData];

	return [trackingArea autorelease];
}


/*
 *
 */
- (NSTrackingArea *)trackingAreaForScrollerView:(CMMenuScroller *)scroller inRect:(NSRect)trackingRect {
//	NSRect trackingRect = [scroller frame];
	NSTrackingAreaOptions trackingOptions = NSTrackingMouseEnteredAndExited | NSTrackingEnabledDuringMouseDrag | NSTrackingActiveInActiveApp;
	NSDictionary *trackingData = [NSDictionary dictionaryWithObjectsAndKeys:
								  _owner, kUserDataMenuObjKey,
								  scroller, kUserDataScrollerViewKey,
								  [NSNumber numberWithUnsignedInteger:CMMenuEventMouseScroller], kUserDataEventTypeKey, nil];
	NSTrackingArea *trackingArea = [[NSTrackingArea alloc] initWithRect:trackingRect options:trackingOptions owner:self userInfo:trackingData];

//	NSLog(@"creating tracking area for scroller: %@, area: %@", scroller, trackingArea);
	
	return [trackingArea autorelease];
}


/*
 * Tracking Area for Menu Rect
 */
//- (void)updateContentViewTrackingArea {
- (void)updateContentViewTrackingAreaTrackMouseMoved:(BOOL)trackMouseMoved {
	NSView *contentView = self.window.contentView;
	
	NSLog(@" ************ Updating content area tracking area for frame: %@, track mouse moved: %d", NSStringFromRect([[self window] frame]), trackMouseMoved);
	
	if (_contentViewTrackingArea) {
		[contentView removeTrackingArea:_contentViewTrackingArea];
		[_contentViewTrackingArea release];
	}
	
	NSRect trackingRect = [contentView bounds];
	NSTrackingAreaOptions trackingOptions = NSTrackingMouseEnteredAndExited | NSTrackingActiveAlways | NSTrackingEnabledDuringMouseDrag;
	if (trackMouseMoved)
		trackingOptions |= NSTrackingMouseMoved;
	
	NSDictionary *trackingData = [NSDictionary dictionaryWithObjectsAndKeys:
								  _owner, kUserDataMenuObjKey,
								  [NSNumber numberWithUnsignedInteger:CMMenuEventMouseMenu], kUserDataEventTypeKey, nil];
	NSTrackingArea *trackingArea = [[NSTrackingArea alloc] initWithRect:trackingRect options:trackingOptions owner:self userInfo:trackingData];
	[contentView addTrackingArea:trackingArea];
	_contentViewTrackingArea = trackingArea;
	
	CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0, NO);
}



/*
 *
 */
/*
- (void)mouseEntered:(NSEvent *)theEvent {
//	NSLog(@"Mouse Entered %@", theEvent);
	

//	NSPoint mouseLocation = [theEvent locationInWindow];
//	mouseLocation = [[_scrollView documentView] convertPoint:mouseLocation fromView:nil];
//	NSViewController *viewController = [self viewControllerAtPoint:mouseLocation];
//	NSString *text = (viewController) ? [[(CMMenuItemView *)[viewController view] title] stringValue] : @"nil";
//	NSLog(@"loc in win: %@, viewtext: %@", NSStringFromPoint(mouseLocation), text);

	NSDictionary *userData = [theEvent userData];
	CMMenuEventType eventType = [(NSNumber *)[userData objectForKey:kUserDataEventTypeKeyKey] unsignedIntegerValue];

	if (eventType & CMMenuEventMouseItem) {		// mouse entered menu item view
		NSViewController *viewController = [(NSDictionary *)[theEvent userData] objectForKey:kTrackingAreaViewControllerKeyKey];
		// debuggin
//		CMMenuItem *item = [viewController representedObject];
//		fputs("\n", stdout);
//		NSLog(@"Mouse Enter MENU ITEM: %@", item);
		// debuggin
		[self mouseEventOnItemView:viewController eventType:CMMenuEventMouseEnteredItem];
	} else if (eventType & CMMenuEventMouseScroller) {
		CMMenuScroller *scroller = [userData objectForKey:kUserDataScrollerViewKeyKey];
//		NSDictionary *userData = [NSDictionary dictionaryWithObjectsAndKeys:scroller, kUserDataScrollerViewKeyKey, nil];
//		_scrollTimer = [[NSTimer scheduledTimerWithTimeInterval:SCROLL_TIMER_INTERVAL target:self selector:@selector(scrollTimerEvent:) userInfo:userData repeats:YES] retain];
		[self scrollWithActiveScroller:scroller];
	} else if (eventType & CMMenuEventMouseMenu) {
//		NSLog(@"Mouse Enter MENU: %@", theEvent);
		CMMenu *menu = (CMMenu *)_owner;
		[menu mouseEvent:theEvent];
	}

}
*/

/*
 *
 */
//- (void)mouseExited:(NSEvent *)theEvent {
////	NSLog(@"Mouse Exited %@", theEvent);
//	
////	CMMenuItemView *view = [(NSDictionary *)[theEvent userData] objectForKey:kTrackingAreaViewControllerKeyKey];
////	NSViewController *viewController = [(NSDictionary *)[theEvent userData] objectForKey:kTrackingAreaViewControllerKeyKey];
////	[self mouseEventOnItemView:viewController eventType:CMMenuEventMouseExitedItem];
////	[(CMMenuItemView *)[viewController view] setSelected:NO];
//	
//	
//	NSDictionary *userData = [theEvent userData];
//	CMMenuEventType eventType = [(NSNumber *)[userData objectForKey:kUserDataEventTypeKeyKey] unsignedIntegerValue];
//
//	
//	if (eventType & CMMenuEventMouseItem) {
//		// debuggin
////		NSViewController *viewController = [(NSDictionary *)[theEvent userData] objectForKey:kTrackingAreaViewControllerKeyKey];
////		CMMenuItem *item = [viewController representedObject];
////		NSLog(@"Mouse Exit MENU ITEM: %@", item);
//		// debuggin //
//		
//		/*
//		 * We want to redraw currently selected item after newly hovered item has background.
//		 * This technic is used to solve the blinking problem when moving mouse swiftly through the menu items.
//		 */
////		[self performSelector:@selector(delayedMouseExitedEvent:) withObject:theEvent afterDelay:0.0];
//		[self performSelector:@selector(delayedMouseExitedEvent:) withObject:theEvent afterDelay:0 inModes:[NSArray arrayWithObject:NSEventTrackingRunLoopMode]];
////		NSViewController *viewController = [(NSDictionary *)[theEvent userData] objectForKey:kTrackingAreaViewControllerKeyKey];
////		[self mouseEventOnItemView:viewController eventType:CMMenuEventMouseExitedItem];
//	} else if (eventType & CMMenuEventMouseScroller) {
//		[_scrollTimer invalidate];
////		[_scrollTimer release];
//		_scrollTimer = nil;
//	} else if (eventType & CMMenuEventMouseMenu) {
//		CMMenu *menu = (CMMenu *)_owner;
//		[menu mouseEvent:theEvent];
//	}
//}


/*
 *
 */
//- (void)mouseUp:(NSEvent *)theEvent {
////	NSLog(@"UP: %@", theEvent);
//	NSPoint location = [theEvent locationInWindow];
//	location = [[_scrollView documentView] convertPoint:location fromView:nil];
//	NSLog(@"Mouse UP, location: %@", NSStringFromPoint(location));
//	
//	NSLog(@"document: %@, visible view: %@, scroll view: %@", NSStringFromRect([[_scrollView documentView] bounds]),
////		  NSStringFromRect([[_scrollView contentView] bounds])
//		  NSStringFromRect([_scrollView documentVisibleRect]),
//		  NSStringFromRect([_scrollView frame])
//		  //		  NSStringFromSize([_scrollView contentSize])
//		  );
//
////	NSLog(@"window is key: %d", [[self window] isKeyWindow]);
////	[self startEventTracking];
//	
//}



- (void)updateTrackingPrimitivesIgnoreMouse:(BOOL)ignoreMouse {
//	NSLog(@"update primitives");
	if (_trackingPrimitives) {

		// free all objects
		[self discardTrackingPrimitivesIgnoreMouse:NO];
		
	}
	
	
	NSView *documentView = [_scrollView documentView];
	NSRect visibleRect = [self visibleRectExcludingScrollers:YES];
	CGFloat visibleRectMinY = visibleRect.origin.y;
	CGFloat visibleRectMaxY = visibleRect.origin.y + visibleRect.size.height;
	int firstIndex;
	int lastIndex;
	unsigned int numberOfObjects;
	int i;
	

	// In the first loop calculate the number of objects to track
	firstIndex = -1;
	i = -1;
	numberOfObjects = 0;
	for (NSViewController *viewController in _viewControllers) {
		++i;
		NSRect frame = [[viewController view] frame];
		if (frame.origin.y + frame.size.height <= visibleRectMinY)
			continue;
		
		if (frame.origin.y >= visibleRectMaxY)
			break;
		
		if (! [(CMMenuItemView *)[viewController view] needsTracking])
			continue;

		if (firstIndex == -1)
			firstIndex = i;
		
		lastIndex = i;
		++numberOfObjects;
	}
	
	// There are no elements to track
	if (firstIndex == -1)
		return;
	
	BOOL topScrollerIsDisplayed = NO;
	BOOL bottomScrollerIsDisplayed = NO;
	if (_topScroller && [_topScroller superview]) {
		++numberOfObjects;
		topScrollerIsDisplayed = YES;
	}
	if (_bottomScroller && [_bottomScroller superview]) {
		++numberOfObjects;
		bottomScrollerIsDisplayed = YES;
	}
	
	
	
	
	NSPoint mouseLocation;
	if (! ignoreMouse) {
//		NSPoint screenLoc;
		mouseLocation = [[self window] mouseLocationOutsideOfEventStream];
//		screenLoc = mouseLocation;
		mouseLocation = [documentView convertPoint:mouseLocation fromView:nil];
//		screenLoc = [[self window] convertBaseToScreen:screenLoc];
//		NSLog(@"mouse location: %@", NSStringFromPoint(screenLoc));
	}
	CMTrackingPrimitive **trackingPrimitives;
	int index;
	
	// Alloc a buffer for an array of pointers to primitives: number of primitives + 1 for terminating NULL.
	trackingPrimitives = (CMTrackingPrimitive **)malloc((numberOfObjects + 1) * sizeof(CMTrackingPrimitive *));
	if (trackingPrimitives == NULL) {
		fputs("CMMenu: out of memmory", stderr);
		exit(EXIT_FAILURE);
	}
	
	// In the second loop create tracking primitives for displayed views
	index = 0;
	for (i = firstIndex; i <= lastIndex; ++i) {
		NSViewController *viewController = [_viewControllers objectAtIndex:(NSUInteger)i];
		CMMenuItemView *view = (CMMenuItemView *)[viewController view];
		
		if (! [view needsTracking])
			continue;
		
		NSRect frame = [[viewController view] frame];
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
		
		if (mouseInside)
			[self mouseEventOnItemView:viewController eventType:CMMenuEventMouseEnteredItem | CMMenuEventDuringTrackingAreaUpdate];
		
		trackingPrimitives[index] = primitive;
		++index;
	}
	// When the loop ends |index| is already pointing to the next element.
	// Add top scroller rect if needed
	if (topScrollerIsDisplayed) {
		trackingPrimitives[index] = [self trackingPrimitiveForScroller:_topScroller];
		++index;
	}
	// Add bottom scroller rect if needed
	if (bottomScrollerIsDisplayed) {
		trackingPrimitives[index] = [self trackingPrimitiveForScroller:_bottomScroller];
		++index;
	}
	
	// Last element must be NULL
	trackingPrimitives[index] = NULL;
	_trackingPrimitives = trackingPrimitives;
	

//	NSLog(@"size of 1 struct: %lu", sizeof(CMTrackingPrimitive));
	
//	for ( ; *trackingPrimitives != NULL; ++trackingPrimitives) {
//		CMTrackingPrimitive *primitive = *trackingPrimitives;
//		NSLog(@"rect: %@, inside: %d dict: %@, item: %@",
//			  NSStringFromRect(primitive->rect),
//			  primitive->mouseInside,
//			  primitive->userInfo,
//			  [(NSViewController *)[primitive->userInfo objectForKey:kUserDataViewControllerKey] representedObject]);
//	}
//	NSLog(@"primitives number: %d", numberOfObjects);
	
//	for ( ; *trackingPrimitives != NULL; ++trackingPrimitives) {
//		CMTrackingPrimitive *primitive = *trackingPrimitives;
//		if (primitive->mouseInside) {
//			NSLog(@"---- During update mouse is inside: %@, dict: %@",
//			  NSStringFromRect(primitive->rect),
//			  primitive->userInfo);
//		}
//	}
	
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
		
	
	NSPoint mouseLocation = [[self window] mouseLocationOutsideOfEventStream];
	mouseLocation = [[self window] convertBaseToScreen:mouseLocation];

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
- (void)discardTrackingPrimitivesIgnoreMouse:(BOOL)ignoreMouse {
	if (! _trackingPrimitives)
		return;
	
//	NSPoint mouseLocation = [[self window] mouseLocationOutsideOfEventStream];
//	mouseLocation = [[self window] convertBaseToScreen:mouseLocation];

	
	CMTrackingPrimitive **trackingPrimitives = _trackingPrimitives;
	CMTrackingPrimitive *trackingPrimitive;
	for ( ; *trackingPrimitives != NULL; ++trackingPrimitives) {
		trackingPrimitive = *trackingPrimitives;
		if ( !ignoreMouse && trackingPrimitive->mouseInside) {
			NSDictionary *userInfo = trackingPrimitive->userInfo;
			CMMenuEventType eventType = [(NSNumber *)[userInfo objectForKey:kUserDataEventTypeKey] unsignedIntegerValue];
			if (eventType & CMMenuEventMouseItem) {
				NSViewController *viewController = [trackingPrimitive->userInfo objectForKey:kUserDataViewControllerKey];
				[self mouseEventOnItemView:viewController eventType:CMMenuEventMouseExitedItem | CMMenuEventDuringTrackingAreaUpdate];
			}
//			else if (eventType & CMMenuEventMouseScroller) {
//				NSPoint currentMouseLocation = [[self window] mouseLocationOutsideOfEventStream];
//				currentMouseLocation = [[self window] convertBaseToScreen:currentMouseLocation];
//				if (! NSEqualPoints(mouseLocation, currentMouseLocation)) {
//					NSLog(@"MOUSE LOCATIONS ARE DIFFERENT WHILE DELETING PRIMITIVES: %@ AND %@", NSStringFromPoint(mouseLocation), NSStringFromPoint(currentMouseLocation));
//				}
////				CMMenuScroller *scroller = [userInfo objectForKey:kUserDataScrollerViewKey];
////				NSRect frame = [scroller frame];
////				frame = [[self window] convertRectToScreen:frame];
//				if (! NSPointInRect(mouseLocation, trackingPrimitive->rect)) {
//					NSLog(@" *********** WARNING! can loose tracking. rect: %@, mouse: %@", NSStringFromRect(trackingPrimitive->rect), NSStringFromPoint(mouseLocation));
//				} else {
//					NSLog(@" *********** GOOD! mouse is still in rect: %@, mouse: %@", NSStringFromRect(trackingPrimitive->rect), NSStringFromPoint(mouseLocation));
//				}
//			}
		}
		[trackingPrimitive->userInfo release];
		free(trackingPrimitive);
	}
	
	free(_trackingPrimitives);
	_trackingPrimitives = NULL;
}


/*
 *
 */
- (void)eventOnTrackingPrimitiveAtLocation:(NSPoint)mouseLocation mouseInside:(BOOL)mouseInside {
//	NSLog(@"tracking event at loc: %@", NSStringFromPoint(mouseLocation));
	// Find a primitive that had mouse inside before event
	CMTrackingPrimitive *mousedPrimitive = NULL;
	CMTrackingPrimitive **trackingPrimitives = _trackingPrimitives;
	
	if (! trackingPrimitives)
		return;
	
	for ( ; *trackingPrimitives != NULL; ++trackingPrimitives) {
		if ((*trackingPrimitives)->mouseInside) {
			mousedPrimitive = *trackingPrimitives;
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
		CMTrackingPrimitive **trackingPrimitives = _trackingPrimitives;
		CMTrackingPrimitive *trackingPrimitive = NULL;		// find a primitive that currently has mouse inside
		for ( ; *trackingPrimitives != NULL; ++trackingPrimitives) {
			if (NSPointInRect(mouseLocation, (*trackingPrimitives)->rect)) {
				trackingPrimitive = *trackingPrimitives;
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








- (void)_beginTrackingWithEvent:(NSEvent *)event {
	BOOL mouseIsDown = NO;
	BOOL mouseInsideWindow = NO;
	NSEventMask runLoopEventMask = NSMouseEnteredMask | NSMouseExitedMask | NSLeftMouseDownMask | NSLeftMouseUpMask | NSRightMouseDownMask | NSRightMouseUpMask | NSOtherMouseDownMask | NSOtherMouseUpMask | NSScrollWheelMask | NSKeyDownMask | NSMouseMovedMask | NSLeftMouseDraggedMask | NSRightMouseDraggedMask | NSOtherMouseDraggedMask;
	
//	runLoopEventMask |= NSAppKitDefinedMask | NSApplicationDefinedMask | NSSystemDefinedMask;
	runLoopEventMask |= NSSystemDefinedMask;

	/*
	if ([_owner receivesMouseMovedEvents]) {
		// Before we start tracking mouse moved events remove any pending events of this
		// type in queue. Otherwise faux moved events generated previously will disrupt.
		[NSApp discardEventsMatchingMask:NSMouseMovedMask beforeEvent:event];
		runLoopEventMask |= NSMouseMovedMask;
	}
	 */

	XLog2("\n \
	--------------------------------------------------------\n \
	 BEGIN tracking RunLoop mode on menu \"%@\" with frame: %@\n \
	--------------------------------------------------------\n",
		  [_owner title],
		  NSStringFromRect([[self window] frame]));
	

	while (_keepTracking) {
		NSEvent *theEvent = [NSApp nextEventMatchingMask:runLoopEventMask untilDate:[NSDate distantFuture] inMode:NSEventTrackingRunLoopMode dequeue:YES];

		if (! _keepTracking) {
			NSLog(@"a-ha, final event: %@", theEvent);
			break;
		}
		
		
		
		NSWindow *eventWindow = [theEvent window];
		NSEventType eventType = [theEvent type];
		NSEventMask eventMask = NSEventMaskFromType(eventType);
//		NSEventMask blockingMask = [_owner eventBlockingMask];
		
		if (! (eventMask & (NSMouseMovedMask | NSLeftMouseDraggedMask | NSRightMouseDraggedMask | NSOtherMouseDraggedMask))) {
			XLog3("New RunLoop event:\n\tEvent: %@\n\tMenu frame owning RunLoop:\t%@ \"%@\"\n\tMenu frame of occurred event:\t%@",
				  theEvent,
				  NSStringFromRect([[self window] frame]),
				  [_owner title],
				  NSStringFromRect([[theEvent window] frame]));
		}
		
		if (eventType == NSSystemDefined)
			continue;
		
		
		// TODO: verify eventWindowBelongsToAnyMenu for all events
		BOOL eventWindowBelongsToAnyMenu = [self eventWindowBelongsToAnyMenu:theEvent];
//		NSLog(@"event belongs to menu: %d, blocking mask: %llu", eventWindowBelongsToAnyMenu, blockingMask);
		if (eventWindowBelongsToAnyMenu && ![[self window] isEqual:eventWindow]) {
//			NSLog(@"SINCE event outside menu owning loop, find it");
			CMMenu *menu = [self menuThatGeneratedEvent:theEvent];
			if (menu && (eventMask & [menu eventBlockingMask])) {
				NSLog(@"Event has been blocked. Conitnue.");
				continue;
			}
		}

		
		
#pragma mark MouseEntered
		if (eventType == NSMouseEntered && eventWindowBelongsToAnyMenu) {
/*
			NSDictionary *userData = [theEvent userData];
			CMMenuEventType menuEventType = [(NSNumber *)[userData objectForKey:kUserDataEventTypeKey] unsignedIntegerValue];
			
			if (menuEventType & CMMenuEventMouseItem) {
				NSViewController *viewController = [(NSDictionary *)[theEvent userData] objectForKey:kTrackingAreaViewControllerKey];
				[self mouseEventOnItemView:viewController eventType:CMMenuEventMouseEnteredItem];
			} else if (menuEventType & CMMenuEventMouseScroller) {
				CMMenuScroller *scroller = [userData objectForKey:kUserDataScrollerViewKey];
//				CMMenu *menu = [(NSDictionary *)[theEvent userData] objectForKey:kUserDataMenuKey];
				[self scrollWithActiveScroller:scroller];
			} else if (menuEventType & CMMenuEventMouseMenu) {
				CMMenu *menu = [(NSDictionary *)[theEvent userData] objectForKey:kUserDataMenuObjKey];
//				NSLog(@"event blocking masK: %llu", [menu eventBlockingMask]);
//				if ([menu eventBlockingMask] & eventMask) {
//					continue;
//				}
				
				NSPoint mouseLocation = [theEvent locationInWindow];
				mouseLocation = [eventWindow convertBaseToScreen:mouseLocation];
				
				// When mouse moves from submenu to its supermenu, submenu ends its tracking.
				// New menu begins tracking, however if new menu is supermenu the method simply returns,
				// since the tracking was previously set up. If new menu is submenu, tracking begins and
				// new menu is now the receiver of all events.
				NSLog(@"------------------- MOUSE ENTER MENU ------------------------- \n\n");
//				NSLog(@"and this menu is: %@", menu);
//				NSLog(@"now sending event to menu");
				[menu mouseEvent:theEvent];
				if (! NSPointInRect(mouseLocation, [[self window] frame])) {
					if ([_owner supermenu] == menu)
						[_owner endTracking];
					[menu beginTrackingWithEvent:theEvent];
				}
			}
		*/
			
#pragma mark MouseExited
		} else if (eventType == NSMouseExited && eventWindowBelongsToAnyMenu) {
/*			NSDictionary *userData = [theEvent userData];
			CMMenuEventType eventType = [(NSNumber *)[userData objectForKey:kUserDataEventTypeKey] unsignedIntegerValue];
			if (eventType & CMMenuEventMouseItem) {
	
//				  We want to redraw currently selected item after newly hovered item has background.
//				  This technic is used to solve the blinking problem when moving mouse swiftly through the menu items.
	
//				[self performSelector:@selector(delayedMouseExitedEvent:) withObject:theEvent afterDelay:0.0];
//				[self performSelector:@selector(delayedMouseExitedEvent:) withObject:theEvent afterDelay:0.1 inModes:[NSArray arrayWithObject:NSEventTrackingRunLoopMode]];
				NSViewController *viewController = [(NSDictionary *)[theEvent userData] objectForKey:kTrackingAreaViewControllerKey];
				[self mouseEventOnItemView:viewController eventType:CMMenuEventMouseExitedItem];
			} else if (eventType & CMMenuEventMouseScroller) {
				if (_scrollTimer) {
					[_scrollTimer invalidate];
					//		[_scrollTimer release];
					_scrollTimer = nil;
				}
			} else if (eventType & CMMenuEventMouseMenu) {
//				CMMenu *menu = (CMMenu *)_owner;
//				CMMenu *menu = [self menuToReciveEventWithWindow:eventWindow];
				CMMenu *menu = [(NSDictionary *)[theEvent userData] objectForKey:kUserDataMenuObjKey];
				[menu mouseEvent:theEvent];
			}
	*/
			
#pragma mark LeftMouseDown
#pragma mark RightMouseDown
#pragma mark OtherMouseDown
		} else if (eventType == NSLeftMouseDown || eventType == NSRightMouseDown || eventType == NSOtherMouseDown) {

//			NSPoint mouseLocation = [theEvent locationInWindow];
//			NSLog(@"mouse loc: %@", NSStringFromPoint(mouseLocation));
//			NSWindow *window = [theEvent window];
//			if (window != [self window]) {
//				NSLog(@"outside of event. stop event tracking");
//				break;
//			}
			
//			CMMenu *menu = [self menuToReciveEventWithWindow:[theEvent window]];
//			if (! menu) {
//				NSLog(@"Mouse down outside of menus. Stop tracking");
//				[self endTracking];
//			}
			
			
			
			if (eventWindowBelongsToAnyMenu) {
				mouseIsDown = YES;
				[_owner mouseEvent:theEvent];
			}
			
			
			NSPoint mouseLocation = [theEvent locationInWindow];
			mouseLocation = [eventWindow convertBaseToScreen:mouseLocation];
			if (NSPointInRect(mouseLocation, [[self window] frame])) {
//				NSLog(@"key window: %d", [[self window] isKeyWindow]);
//				[[self window] makeKeyWindow];
//				NSLog(@"key window: %d", [[self window] isKeyWindow]);
			} else {
				if ([_owner cancelsTrackingOnMouseEventOutsideMenus] && ![self mouseInsideDisplayedMenusDuringEvent:theEvent]) {
					NSLog(@"mouse is outside any menu during MOUSEDOWN!!!");
					[[_owner rootMenu] cancelTracking];
					goto endEvent;
//					goto endTracking;
				}
			}
			
			
#pragma mark LeftMouseUp
#pragma mark RightMouseUp
#pragma mark OtherMouseUp
		} else if (eventType == NSLeftMouseUp || eventType == NSRightMouseUp || eventType == NSOtherMouseUp) {
			mouseIsDown = NO;
			
			if ([self mouseInsideDisplayedMenusDuringEvent:theEvent]) {
				[_owner mouseEvent:theEvent];
			} else if ([_owner cancelsTrackingOnMouseEventOutsideMenus]) {
				NSLog(@"mouse is outside any menu during MOUSEUP!!!");
				[[_owner rootMenu] cancelTracking];
			}
			
			/* */
			NSPoint mouseLocation = [theEvent locationInWindow];
			mouseLocation = [eventWindow convertBaseToScreen:mouseLocation];
			if (NSPointInRect(mouseLocation, [[self window] frame])) {
				CMMenuItem *item = [_owner itemAtPoint:mouseLocation];
//				if (item)
//					[item performAction];
				
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
					if (item) {
						[_owner removeItem:item animate:YES];
					}

				} else if (modifierFlags & NSCommandKeyMask) {
					[item setEnabled:![item isEnabled]];
				}
			
//				NSLog(@"Added new item: %@ to menu: %@", item, menu);
			} else {
				if ([_owner cancelsTrackingOnMouseEventOutsideMenus] && ![self mouseInsideDisplayedMenusDuringEvent:theEvent]) {
					NSLog(@"mouse is outside any menu during MOUSEUP!!!");
					[[_owner rootMenu] cancelTracking];
				}
			}
		/*	 */
			

//#pragma mark RightMouseDown
//		} else if (eventType == NSRightMouseDown) {
//
//			
//#pragma mark RightMouseUp
//		} else if (eventType == NSRightMouseUp) {
//			NSPoint mouseLocation = [theEvent locationInWindow];
//			mouseLocation = [eventWindow convertBaseToScreen:mouseLocation];
//			CMMenuItem *item = [_owner itemAtPoint:mouseLocation];
//			if (item) {
//				if ([item submenu]) {
//					CMMenuItem *firstItem = [[item submenu] itemAtIndex:0];
//					[firstItem setTitle:@"New title changed while hidden"];
//				}
//			}
			
		

#pragma mark ScrollWheel
		} else if (eventType == NSScrollWheel && eventWindowBelongsToAnyMenu) {
			//			[_scrollView scrollWheel:event];
			//			[[self window] sendEvent:theEvent];
			//			CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0, NO);
			
			//			[NSApp discardEventsMatchingMask:NSPeriodicMask beforeEvent:theEvent];
			NSRect contentRect = [[_scrollView contentView] bounds];
//			NSRect documentRect = [[_scrollView documentView] bounds];
//			if (contentRect.origin.y != 0)
			
//			if (eventWindow) {
//				[eventWindow sendEvent:theEvent];
//			}
			
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

			
#pragma mark MouseMoved
#pragma mark LeftMouseDragged
#pragma mark RightMouseDragged
#pragma mark OtherMouseDragged
		} else if (eventType == NSMouseMoved || eventType == NSLeftMouseDragged || eventType == NSRightMouseDragged || eventType == NSOtherMouseDragged) {
//			NSWindow *window = [theEvent window];
//			NSLog(@"moved in window: %@ with rect: %@", window, NSStringFromRect([window frame]));
			
//			[_owner mouseEvent:theEvent];
			
// TODO: Do not send mouseMoved events to anybody else (other windows)
			
			NSPoint mouseLocation = [theEvent locationInWindow];
			if (eventWindow) {
				mouseLocation = [eventWindow convertBaseToScreen:mouseLocation];
			}
			if (NSPointInRect(mouseLocation, [[self window] frame])) {
				mouseInsideWindow = YES;
				[self eventOnTrackingPrimitiveAtLocation:mouseLocation mouseInside:YES];
			} else {
				if (mouseInsideWindow) {		// mouse left window
					mouseInsideWindow = NO;
					[self eventOnTrackingPrimitiveAtLocation:mouseLocation mouseInside:NO];
				}
				
				// Possibly mouse entered another menu
				CMMenu *menu = [_owner rootMenu];
				do {
					if (menu == _owner)
						continue;
					
					if (NSPointInRect(mouseLocation, [menu frame])) {
						[menu mouseEventAtLocation:mouseLocation type:NSMouseEntered];
						if ([menu supermenu] == _owner) {				// entered submenu
							[menu beginTrackingWithEvent:theEvent];
						} else {										// entered one of the supermenus
							[self endTracking];
//							goto endTracking;
						}
						
						// This goto will be reached only after menu's submenu ends tracking.
						// Menu here just ends the previous event (that started the submenu).
						goto endEvent;
					}
						
				} while ((menu = [menu activeSubmenu]));
			}
		}
		
/*
		if ([_owner receivesMouseMovedEvents]) {
			if (! (runLoopEventMask & NSMouseMovedMask)) {		// if mask is not already set
				// Before we start tracking mouse moved events remove any pending events of this
				// type in queue. Otherwise faux moved events generated previously will disrupt.
				[NSApp discardEventsMatchingMask:NSMouseMovedMask beforeEvent:theEvent];
				runLoopEventMask |= NSMouseMovedMask;
			}
		} else if (runLoopEventMask & NSMouseMovedMask) {
			runLoopEventMask &= (NSEventMask)~NSMouseMovedMask;
		}
*/
		
//		NSLog(@"event loop, and we track mouse moved: %d", ((eventMask & NSMouseMovedMask) != 0));
		
	
		if ( !eventWindowBelongsToAnyMenu && eventType != NSKeyDown && eventWindow && ![_owner cancelsTrackingOnMouseEventOutsideMenus]) {
			if (eventType != NSScrollWheel) {
//			NSLog(@"Sending event to non-menu window");
			[NSApp discardEventsMatchingMask:NSAnyEventMask beforeEvent:theEvent];
			[eventWindow sendEvent:theEvent];
			}
		}

		
//		[[self window] resignKeyWindow];

		
//		NSLog(@"current loop: %@", [[NSRunLoop currentRunLoop] currentMode]);
//		[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0]];
//		CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0, NO);
	
		
	endEvent:
		continue;
		
//	endTracking:
//		if (! _keepTracking) {
//			NSLog(@"WHOAA, ending tracking");
//			break;
//		}
		
	}	// 	while (_keepTracking) {
	
}


// TODO: this is temp method
//- (CMMenu *)menuToReciveEventWithWindow:(NSWindow *)window {
//	CMMenu *menu = _owner;
//	while (menu) {
//		if ([menu underlyingWindow] == window)
//			return menu;
//		menu = [menu activeSubmenu];
//	}
//	
//	return nil;
//}


- (CMMenu *)menuThatGeneratedEvent:(NSEvent *)theEvent {
	NSWindow *window = [theEvent window];
	if (! window)
		return nil;

	CMMenu *menu = _owner;
	do {
		if ([[menu underlyingWindow] isEqual:window])
			return menu;
	} while ((menu = [menu supermenu]));
	
	return nil;
}

- (BOOL)mouseInsideDisplayedMenusDuringEvent:(NSEvent *)theEvent {
	NSPoint mouseLocation = [theEvent locationInWindow];
	mouseLocation = [[theEvent window] convertBaseToScreen:mouseLocation];
	CMMenu *menu = _owner;
	do {
		if (NSPointInRect(mouseLocation, [menu frame]))
			return YES;
	} while ((menu = [menu supermenu]));
	
	return NO;
}


- (BOOL)eventWindowBelongsToAnyMenu:(NSEvent *)theEvent {
	NSWindow *window = [theEvent window];
	CMMenu *menu = ([_owner activeSubmenu]) ? [_owner activeSubmenu] : _owner;
	while (menu) {
		if ([[menu underlyingWindow] isEqual:window])
			return YES;
		menu = [menu supermenu];
	}

	return NO;
}


//- (void)mouseMoved:(NSEvent *)theEvent {
//	NSLog(@"mouse moved: %@", theEvent);
//}

//- (void)mouseDown:(NSEvent *)theEvent {
//	NSLog(@"DOWN: %@", theEvent);
//}


/*
 *
 */
/*
- (void)delayedMouseExitedEvent:(NSEvent *)theEvent {
	NSTrackingArea *trackingArea = [theEvent trackingArea];
	if (! trackingArea) {
		NSLog(@"ACHTUNG! event doesn't have userData: %@", theEvent);
		[NSException raise:NSGenericException format:@"Event doesn't have userData"];
	}

//	NSDictionary *userData = [theEvent userData];
//	NSInteger trackingNumber = [theEvent trackingNumber];
//	NSLog(@"delayed exit\nevent: %@,\nloopmode: %@,\ntrackingNumber: %ld\ntracking area: %@",
//		  theEvent,
//		  [[NSRunLoop currentRunLoop] currentMode],
//		  trackingNumber,
//		  trackingArea);
	
	NSViewController *viewController = [(NSDictionary *)[theEvent userData] objectForKey:kTrackingAreaViewControllerKeyKey];
	[self mouseEventOnItemView:viewController eventType:CMMenuEventMouseExitedItem];
}
*/


/*
 *
 */
- (void)mouseEventOnItemView:(NSViewController *)viewController eventType:(CMMenuEventType)eventType {
	CMMenuItem *menuItem = [viewController representedObject];
	
//	if ([menuItem isSeparatorItem])
//		return;
//	CMMenuItemView *view = (CMMenuItemView *)[viewController view];
//	NSLog(@"ffframe: %@", NSStringFromRect([view frame]));
	
	NSLog(@"Mouse event on item: %@", [menuItem title]);
	
	
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
		CMMenuScroller *activeScroller = [[_scrollTimer userInfo] objectForKey:kUserDataScrollerViewKey];
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
