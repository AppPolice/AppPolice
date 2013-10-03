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


#define kTrackingAreaViewControllerKey @"viewController"
#define kUserDataScrollerViewKey @"scroller"
#define kUserDataMenuKey @"menu"
#define kUserDataEventTypeKey @"eventType"
#define VERTICAL_SPACING 0		// between menu items
#define MENU_SCROLLER_HEIGHT 15.0
#define SCROLL_TIMER_INTERVAL 0.05


@interface CMWindowController ()
{
	CMMenu *_owner;
	CMScrollView *_scrollView;
	CGFloat _verticalPadding;
//	CMScrollDocumentView *_scrollDocumentView;
	
//	BOOL _needsLayoutUpdate;
	CGFloat _maximumViewWidth;
	CGFloat _viewHeight;
	CGFloat _separatorViewHeight;
	
	CMMenuScroller *_topScroller;
	CMMenuScroller *_bottomScroller;
	NSTimer *_scrollTimer;
	
	NSMutableArray *_viewControllers;
	NSMutableArray *_trackingAreas;
	NSTrackingArea *_contentViewTrackingArea;
	
	BOOL _keepTracking;
	BOOL _ignoreMouse;
//	BOOL _ignoreMouseDuringScrollContentViewBoundsChange;
//	id _localEventMonitor;
	CMMenuKeyEventInterpreter *_keyEventInterpreter;
}

//@property (assign) BOOL needsLayoutUpdate;

- (void)setFrame:(NSRect)frame;
- (void)updateMenuScrollers;

/**
 * @abstract Create Tracking Area for Menu Item view
 * @param viewController ViewController of a view that will be returned in userData in event
 * @param trackingRect Rect for tracking area. It represents only the visible portion of the view.
 */
- (NSTrackingArea *)trackingAreaForItemView:(NSViewController *)viewController inRect:(NSRect)trackingRect;

- (NSTrackingArea *)trackingAreaForScrollerView:(CMMenuScroller *)scroller inRect:(NSRect)trackingRect;

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
//	[[self window] setIgnoresMouseEvents:YES];
	
	if (! isVisible) {
		[[self window] setFrame:frame display:NO];
		// Scroll view frame includes the menu top and bottom paddings
		[_scrollView setFrame:NSMakeRect(0, _verticalPadding, frame.size.width, frame.size.height - 2 * _verticalPadding)];
//	[self setFrame:frame];
		[[self window] orderFront:self];
	} else {
		updateOriginOnly = (NSEqualSizes([[self window] frame].size, frame.size));
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
		}
		NSLog(@"new frame for window: %@", NSStringFromRect(frame));
	}
	

	if (! updateOriginOnly) {
		/* We already knew documentView size, that is the size of all menu items.
			Now we know the actual size of menu (since it depends on the area it is being shown on).
			Let's see whether we need to show top and bottom Scrollers if the content doesn't fit
			in the menu */
		[self updateMenuScrollers];
		
	//	if (ignoreMouse)
	//		_ignoreMouse = YES;
		if (options & CMMenuOptionIgnoreMouse)
			_ignoreMouse = YES;
		
		[self updateTrackingAreasForVisibleRect:[[_scrollView contentView] bounds]];
	//	[self updateTrackingAreasForVisibleRect:[NSValue valueWithRect:[[_scrollView contentView] bounds]]];
		
	//	[self updateTrackingAreasForVisibleRect_2:[[_scrollView contentView] bounds]];
		BOOL trackMouseMoved = (options & CMMenuOptionTrackMouseMoved);
		[self updateContentViewTrackingAreaTrackMouseMoved:trackMouseMoved];
		
		// Flag is set back to NO. Whoever needs it must provide value each time.
		_ignoreMouse = NO;
		
		if (! isVisible) {
			[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(scrollViewContentViewBoundsDidChange:) name:NSViewBoundsDidChangeNotification object:[_scrollView contentView]];
		}
	}
}



/*
 *
 */ /*
- (void)updateFrame:(NSRect)frame options:(CMMenuOptions)options {
	// TODO: window quickjump!
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


	
	[self updateMenuScrollers];
	
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
//	[self performSelector:@selector(_beginEventTracking) withObject:nil afterDelay:0];
	[self performSelector:@selector(_beginTrackingWithEvent:) withObject:event afterDelay:0 inModes:[NSArray arrayWithObject:NSRunLoopCommonModes]];
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
//	NSLog(@"resend last event: %@", [NSApp currentEvent]);
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
	[self.window orderOut:self];
	[[NSNotificationCenter defaultCenter] removeObserver:self];

//	[NSEvent removeMonitor:_localEventMonitor];
//	_localEventMonitor = nil;

}


- (void)fadeOutWithComplitionHandler:(void (^)(void))handler {
	NSView *contentView = [[self window] contentView];
	[NSAnimationContext beginGrouping];
	[[NSAnimationContext currentContext] setDuration:0.125];
	[[NSAnimationContext currentContext] setCompletionHandler:^(void) {
		[contentView setAlphaValue:1.0];
		if (handler)
			handler();
	}];
	[[contentView animator] setAlphaValue:0.3];
	[NSAnimationContext endGrouping];
}


/*
 *
 */
- (void)scrollViewContentViewBoundsDidChange:(NSNotification *)notification {
	XLog3("Scroll ContentView BoundsDidChangeNotification with new bounds: %@", NSStringFromRect([[_scrollView contentView] bounds]));
	[self updateMenuScrollers];
	[self updateTrackingAreasForVisibleRect:[[_scrollView contentView] bounds]];
	
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
 * TODO: don't like this function
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
	
	for (NSView *view in [documentView subviews]) {
		NSSize size = [view fittingSize];
		if (size.width > subviewsWidth)
			subviewsWidth = size.width;
	}
	
	if (documentRect.size.width != subviewsWidth) {
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
	
	[viewController retain];
	[_viewControllers removeObjectAtIndex:index];
	
	BOOL updateSubviewsWidth = NO;
	CGFloat subviewsWidth = documentRect.size.width;
	if (size.width == subviewsWidth) {
		// Need to find next widest view and use its height for other views
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
	// previusly occupied by the old item.
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
- (void)updateMenuScrollers {
	NSRect documentRect = [[_scrollView documentView] bounds];
	NSRect visibleRect = [_scrollView documentVisibleRect];
	
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
	NSTrackingArea *trackingArea;
	
	// TOP scroller
	//	if (visibleRect.origin.y < 19) {
	if (visibleRect.origin.y == 0) {
		if (_topScroller && [_topScroller superview]) {
			[_topScroller removeFromSuperview];
			[contentView removeTrackingArea:[_topScroller trackingArea]];
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
			NSRect frame = [_topScroller frame];
			trackingArea = [self trackingAreaForScrollerView:_topScroller inRect:
							NSMakeRect(0, frame.origin.y, frame.size.width, frame.size.height + _verticalPadding)];
			[contentView addTrackingArea:trackingArea];
			[_topScroller setTrackingArea:trackingArea];
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
		//		- _ignoreMouse: We are ignoring mouse usually during keyboard navigation. When we select the elemnt before
		//			last, the last elemnt is precisely at the scroller.origin.y position. That means the content view has
		//			4pts (19pts item height - 15pts scroller height) of disctance to bottom/top. We surely do not want to autoscroll here.
		if (visibleRect.origin.y < 19 && distanceToBottom != 0 && !_ignoreMouse)
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
			NSRect frame = [_bottomScroller frame];
			trackingArea = [self trackingAreaForScrollerView:_bottomScroller inRect:NSMakeRect(0, 0, frame.size.width, frame.size.height + _verticalPadding)];
			[contentView addTrackingArea:trackingArea];
			[_bottomScroller setTrackingArea:trackingArea];
			//			scrollRect.origin.y +=  MENU_SCROLLER_HEIGHT;
			//			scrollRect.size.height -= MENU_SCROLLER_HEIGHT;
		}
		
		// Check similar conditions at top for exmplanation
		if (distanceToBottom < 19 && visibleRect.origin.y != 0 && !_ignoreMouse)
			scrollAmount = 19;
		
	} else if (_bottomScroller && [_bottomScroller superview]) {
		[_bottomScroller removeFromSuperview];
		[contentView removeTrackingArea:[_bottomScroller trackingArea]];
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
	if (scrollAmount > 0)
		[_scrollView scrollDownByAmount:scrollAmount];
	else if (scrollAmount < 0)
		[_scrollView scrollUpByAmount:-scrollAmount];
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


- (CMMenuScroller *)scrollerAtPoint:(NSPoint)aPoint {
	if (_topScroller && [_topScroller superview] && NSPointInRect(aPoint, [_topScroller frame]))
		return _topScroller;
	
	if (_bottomScroller && [_bottomScroller superview] && NSPointInRect(aPoint, [_bottomScroller frame]))
		return _bottomScroller;
	
	return nil;
}


- (void)moveVisibleRectToRect:(NSRect)rect ignoreMouse:(BOOL)ignoreMouse {
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
		_ignoreMouse = ignoreMouse;
		[contentView setBounds:NSMakeRect(0, contentRect.origin.y + scrollAmount, contentRect.size.width, contentRect.size.height)];
		XLog2("Menu \"%@\" moved visible for new bounds: %@",
			  [_owner title],
			  NSStringFromRect(NSMakeRect(0, contentRect.origin.y + scrollAmount, contentRect.size.width, contentRect.size.height)));
	}
}



#pragma mark -
#pragma mark ******** Tracking Areas & Events Handling ********


/*
 *
 */
- (void)updateTrackingAreasForVisibleRect:(NSRect)visibleRect {
//- (void)updateTrackingAreasForVisibleRect:(id)rectValue {
//	NSRect visibleRect = [rectValue rectValue];

//	NSLog(@"updating tracking areas for visible rect: %@", NSStringFromRect(visibleRect));
//	NSLog(@"current runloop: %@", [[NSRunLoop currentRunLoop] currentMode]);

	
	NSView *documentView = [_scrollView documentView];
	if (_trackingAreas) {
		for (NSTrackingArea *trackingArea in _trackingAreas) {
			[documentView removeTrackingArea:trackingArea];
//			[[NSRunLoop currentRunLoop] performSelector:@selector(removeTrackingArea:) target:documentView argument:trackingArea order:0 modes:[NSArray arrayWithObject:NSRunLoopCommonModes]];
			
			/* We remove highlighting of the previously selected view */
//			CMMenuItemView *view = [(NSDictionary *)[trackingArea userInfo] objectForKey:kTrackingAreaViewControllerKey];
			NSViewController *viewController = [(NSDictionary *)[trackingArea userInfo] objectForKey:kTrackingAreaViewControllerKey];
//			if ([view isSelected])
//				[view setSelected:NO];
//			if (! _ignoreMouseDuringScrollContentViewBoundsChange)
			if (! _ignoreMouse)
				[self mouseEventOnItemView:viewController eventType:CMMenuEventMouseExitedItem | CMMenuEventDuringScroll];
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

	if (_topScroller && [_topScroller superview]) {
		visibleRect.origin.y += MENU_SCROLLER_HEIGHT;
		visibleRect.size.height -= MENU_SCROLLER_HEIGHT;
	}
	if (_bottomScroller && [_bottomScroller superview])
		visibleRect.size.height -= MENU_SCROLLER_HEIGHT;
	
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


		
			[self mouseEventOnItemView:viewController eventType:CMMenuEventMouseEnteredItem | CMMenuEventDuringScroll];
		}
		

	}
	
//	NSLog(@"last item for areas: %@", [lastController representedObject]);
	
//	NSLog(@"first index: %ld, last: %ld, location: %@, tracking_areas_count:%ld", firstIndex, i, NSStringFromPoint(afterLocation),
//		  [[[_scrollView documentView] trackingAreas] count]);

//	[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
	
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
			NSViewController *viewController = [[trackingArea userInfo] objectForKey:kTrackingAreaViewControllerKey];
			[self mouseEventOnItemView:viewController eventType:CMMenuEventMouseExitedItem | CMMenuEventDuringScroll];

			
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

			[self mouseEventOnItemView:viewController eventType:CMMenuEventMouseEnteredItem | CMMenuEventDuringScroll];
		}
//		else {
//			[self mouseEventOnItemView:viewController eventType:CMMenuEventMouseExitedItem | CMMenuEventDuringScroll];
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
		NSViewController *viewController = [(NSDictionary *)[trackingArea userInfo] objectForKey:kTrackingAreaViewControllerKey];
//		NSRect frame = [[viewController view] frame];
		NSRect frame = [trackingArea rect];

		if (NSPointInRect(mouseLocation, frame)) {
//			CMMenuItem *item = [viewController representedObject];
//			NSLog(@"SELECT ITEM AFTER updating tracking areas: %@", item);
			[self mouseEventOnItemView:viewController eventType:CMMenuEventMouseEnteredItem | CMMenuEventDuringScroll];
		} else
			[self mouseEventOnItemView:viewController eventType:CMMenuEventMouseExitedItem | CMMenuEventDuringScroll];
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
//		NSViewController *viewController = [(NSDictionary *)[trackingArea userInfo] objectForKey:kTrackingAreaViewControllerKey];
//		NSRect frame = [[viewController view] frame];
//		
//		if (NSPointInRect(mouseLocation, frame)) {
//			CMMenuItem *item = [viewController representedObject];
//			NSLog(@"SELECT ITEM AFTER updating tracking areas: %@", item);
//			[self mouseEventOnItemView:viewController eventType:CMMenuEventMouseEnteredItem | CMMenuEventDuringScroll];
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
								  _owner, kUserDataMenuKey,
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
	
//	NSLog(@"Updating content area tracking area for frame: %@, track mouse moved: %d", NSStringFromRect([[self window] frame]), trackMouseMoved);
	
	if (_contentViewTrackingArea) {
		[contentView removeTrackingArea:_contentViewTrackingArea];
		[_contentViewTrackingArea release];
	}
	
	NSRect trackingRect = [contentView bounds];
	NSTrackingAreaOptions trackingOptions = NSTrackingMouseEnteredAndExited | NSTrackingActiveInActiveApp | NSTrackingEnabledDuringMouseDrag;
	if (trackMouseMoved)
		trackingOptions |= NSTrackingMouseMoved;
	
	NSDictionary *trackingData = [NSDictionary dictionaryWithObjectsAndKeys:
								  _owner, kUserDataMenuKey,
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
	CMMenuEventType eventType = [(NSNumber *)[userData objectForKey:kUserDataEventTypeKey] unsignedIntegerValue];

	if (eventType & CMMenuEventMouseItem) {		// mouse entered menu item view
		NSViewController *viewController = [(NSDictionary *)[theEvent userData] objectForKey:kTrackingAreaViewControllerKey];
		// debuggin
//		CMMenuItem *item = [viewController representedObject];
//		fputs("\n", stdout);
//		NSLog(@"Mouse Enter MENU ITEM: %@", item);
		// debuggin
		[self mouseEventOnItemView:viewController eventType:CMMenuEventMouseEnteredItem];
	} else if (eventType & CMMenuEventMouseScroller) {
		CMMenuScroller *scroller = [userData objectForKey:kUserDataScrollerViewKey];
//		NSDictionary *userData = [NSDictionary dictionaryWithObjectsAndKeys:scroller, kUserDataScrollerViewKey, nil];
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
////	CMMenuItemView *view = [(NSDictionary *)[theEvent userData] objectForKey:kTrackingAreaViewControllerKey];
////	NSViewController *viewController = [(NSDictionary *)[theEvent userData] objectForKey:kTrackingAreaViewControllerKey];
////	[self mouseEventOnItemView:viewController eventType:CMMenuEventMouseExitedItem];
////	[(CMMenuItemView *)[viewController view] setSelected:NO];
//	
//	
//	NSDictionary *userData = [theEvent userData];
//	CMMenuEventType eventType = [(NSNumber *)[userData objectForKey:kUserDataEventTypeKey] unsignedIntegerValue];
//
//	
//	if (eventType & CMMenuEventMouseItem) {
//		// debuggin
////		NSViewController *viewController = [(NSDictionary *)[theEvent userData] objectForKey:kTrackingAreaViewControllerKey];
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
////		NSViewController *viewController = [(NSDictionary *)[theEvent userData] objectForKey:kTrackingAreaViewControllerKey];
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
- (void)mouseUp:(NSEvent *)theEvent {
//	NSLog(@"UP: %@", theEvent);
	NSPoint location = [theEvent locationInWindow];
	location = [[_scrollView documentView] convertPoint:location fromView:nil];
	NSLog(@"Mouse UP, location: %@", NSStringFromPoint(location));
	
	NSLog(@"document: %@, visible view: %@, scroll view: %@", NSStringFromRect([[_scrollView documentView] bounds]),
//		  NSStringFromRect([[_scrollView contentView] bounds])
		  NSStringFromRect([_scrollView documentVisibleRect]),
		  NSStringFromRect([_scrollView frame])
		  //		  NSStringFromSize([_scrollView contentSize])
		  );

//	NSLog(@"window is key: %d", [[self window] isKeyWindow]);
//	[self startEventTracking];
	
}


- (void)_beginTrackingWithEvent:(NSEvent *)event {
//	BOOL keepOn = YES;
//	BOOL restart = NO;
	// NSSystemDefinedMask | NSApplicationDefinedMask | NSAppKitDefinedMask |
	NSUInteger eventMask = NSMouseEnteredMask | NSMouseExitedMask | NSLeftMouseDownMask | NSLeftMouseUpMask | NSScrollWheelMask | NSKeyDownMask | NSRightMouseUpMask;
	
//	eventMask |= NSAppKitDefinedMask | NSApplicationDefinedMask | NSSystemDefinedMask;
	eventMask |= NSSystemDefinedMask;
	
	if ([_owner receivesMouseMovedEvents]) {
		// Before we start tracking mouse moved events remove any pending events of this
		// type in queue. Otherwise faux moved events generated previously will disrupt.
		[NSApp discardEventsMatchingMask:NSMouseMovedMask beforeEvent:event];
		eventMask |= NSMouseMovedMask;
	}

	XLog2("\n \
	--------------------------------------------------------\n \
	 BEGIN tracking RunLoop mode on menu \"%@\" with frame: %@\n \
	--------------------------------------------------------\n",
		  [_owner title],
		  NSStringFromRect([[self window] frame]));
	
	while (_keepTracking) {
		NSEvent *theEvent = [NSApp nextEventMatchingMask:eventMask untilDate:[NSDate distantFuture] inMode:NSEventTrackingRunLoopMode dequeue:YES];
		
		if (! _keepTracking) {
			NSLog(@"a-ha, final event: %@", theEvent);
			break;
		}
		
		XLog3("New RunLoop event:\n\tEvent: %@\n\tMenu title: %@\n\tMenu frame owning RunLoop: %@\n\tMenu frame of occurred event: %@",
			  theEvent,
			  [_owner title],
			  NSStringFromRect([[self window] frame]),
			  NSStringFromRect([[theEvent window] frame]));
		
		
		
		NSWindow *eventWindow = [theEvent window];
		NSEventType eventType = [theEvent type];
		NSEventMask eventMask = 1 << eventType;
		NSEventMask blockingMask = [_owner eventBlockingMask];
		
		if (eventType == NSSystemDefined)
			continue;
		
//		BOOL eventWindowBelongsToMenu = [self eventWindowBelongsToMenu:theEvent];
		BOOL eventWindowBelongsToMenu = YES;
		
		
#pragma mark MouseEntered
		if (eventType == NSMouseEntered /*&& eventWindowBelongsToMenu && !(eventMask & blockingMask)*/) {
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
				CMMenu *menu = [(NSDictionary *)[theEvent userData] objectForKey:kUserDataMenuKey];
				NSPoint mouseLocation = [theEvent locationInWindow];
				mouseLocation = [eventWindow convertBaseToScreen:mouseLocation];
				
				// When mouse moves from submenu to its supermenu, submenu ends its tracking.
				// New menu begins tracking, however if new menu is supermenu the method simply returns,
				// since the tracking was previously set up. If new menu is submenu, tracking begins and
				// new menu is now the receiver of all events.
				if (! NSPointInRect(mouseLocation, [[self window] frame])) {
					if ([_owner supermenu] == menu)
						[_owner endTracking];
					[menu beginTrackingWithEvent:theEvent];
				}

				[menu mouseEvent:theEvent];
			}
		
			
#pragma mark MouseExited
		} else if (eventType == NSMouseExited /*&& eventWindowBelongsToMenu && !(eventMask & blockingMask)*/) {
			NSDictionary *userData = [theEvent userData];
			CMMenuEventType eventType = [(NSNumber *)[userData objectForKey:kUserDataEventTypeKey] unsignedIntegerValue];
			if (eventType & CMMenuEventMouseItem) {
				/*
				 * We want to redraw currently selected item after newly hovered item has background.
				 * This technic is used to solve the blinking problem when moving mouse swiftly through the menu items.
				 */
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
				CMMenu *menu = [(NSDictionary *)[theEvent userData] objectForKey:kUserDataMenuKey];
				[menu mouseEvent:theEvent];
			}
		
			
#pragma mark LeftMouseDown
		} else if (eventType == NSLeftMouseDown) {
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
			
			
			NSPoint mouseLocation = [theEvent locationInWindow];
			mouseLocation = [eventWindow convertBaseToScreen:mouseLocation];
			if (NSPointInRect(mouseLocation, [[self window] frame])) {
//				NSLog(@"key window: %d", [[self window] isKeyWindow]);
//				[[self window] makeKeyWindow];
//				NSLog(@"key window: %d", [[self window] isKeyWindow]);
			} else {
				if ([_owner cancelsTrackingOnMouseEventOutsideMenus] && ![self mouseInsideMenuTreeDuringEvent:theEvent]) {
					NSLog(@"mouse is outside any menu during MOUSEDOWN!!!");
					[[_owner rootMenu] cancelTracking];
				}
			}
			
			
#pragma mark LeftMouseUp
		} else if (eventType == NSLeftMouseUp) {
			NSPoint mouseLocation = [theEvent locationInWindow];
			mouseLocation = [eventWindow convertBaseToScreen:mouseLocation];
			if (NSPointInRect(mouseLocation, [[self window] frame])) {
				CMMenuItem *item = [_owner itemAtPoint:mouseLocation];
				if (item)
					[item performAction];
				
				NSUInteger modifierFlags = [theEvent modifierFlags];
				if (modifierFlags & NSShiftKeyMask) {
					int i;
					int lim = 15;
					for (i = 0; i < lim; ++i) {
	//					CMMenuItem *item = [[CMMenuItem alloc] initWithTitle:@"New Item"];
						CMMenuItem *item  = [[CMMenuItem alloc] initWithTitle:@"New Item With Image" icon:[NSImage imageNamed:NSImageNameBluetoothTemplate] action:NULL];
	//					[menu addItem:item];
						[_owner insertItem:item atIndex:1 animate:YES];
						[item release];
					}
				} else if (modifierFlags & NSControlKeyMask) {
					item = [_owner itemAtPoint:mouseLocation];
					if (item) {
						[item setTitle:@"New title for item and quite longer.."];
					}

				} else if (modifierFlags & NSAlternateKeyMask) {
					item = [_owner itemAtPoint:mouseLocation];
					if (item) {
						[_owner removeItem:item animate:YES];
					}

				} else if (modifierFlags & NSCommandKeyMask) {
					
				}
			
//				NSLog(@"Added new item: %@ to menu: %@", item, menu);
			} else {
				if ([_owner cancelsTrackingOnMouseEventOutsideMenus] && ![self mouseInsideMenuTreeDuringEvent:theEvent]) {
					NSLog(@"mouse is outside any menu during MOUSEUP!!!");
					[[_owner rootMenu] cancelTracking];
				}
			}
			

#pragma mark RightMouseUp
		} else if (eventType == NSRightMouseUp) {
			NSPoint mouseLocation = [theEvent locationInWindow];
			mouseLocation = [eventWindow convertBaseToScreen:mouseLocation];
			CMMenuItem *item = [_owner itemAtPoint:mouseLocation];
			if (item) {
				if ([item submenu]) {
					CMMenuItem *firstItem = [[item submenu] itemAtIndex:0];
					[firstItem setTitle:@"New title changed while hidden"];
				}
			}
			
//			[[self window] resignKeyWindow];
		

#pragma mark ScrollWheel
		} else if (eventType == NSScrollWheel /*&& eventWindowBelongsToMenu && !(eventMask & blockingMask)*/) {
			//			[_scrollView scrollWheel:event];
			//			[[self window] sendEvent:theEvent];
			//			CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0, NO);
			
			//			[NSApp discardEventsMatchingMask:NSPeriodicMask beforeEvent:theEvent];
			
			if (eventWindow) {
//				NSLog(@"receiving window with rect: %@", NSStringFromRect([eventWindow frame]));
				[eventWindow sendEvent:theEvent];
			}
		
#pragma mark KeyDown
		} else if (eventType == NSKeyDown) {
			// Don't forget that events are being processed only by the root menu, _owner in this case.
			if (! _keyEventInterpreter)
				_keyEventInterpreter = [[CMMenuKeyEventInterpreter alloc] initWithDelegate:_owner];
			
			[_keyEventInterpreter interpretEvent:theEvent];

#pragma mark MouseMoved
		} else if (eventType == NSMouseMoved /* && eventWindowBelongsToMenu */) {
//			NSWindow *window = [theEvent window];
//			NSLog(@"moved in window: %@ with rect: %@", window, NSStringFromRect([window frame]));
			
			[_owner mouseEvent:theEvent];
		}
		
		
		if ([_owner receivesMouseMovedEvents]) {
			if (! (eventMask & NSMouseMovedMask)) {		// if mask is not already set
				// Before we start tracking mouse moved events remove any pending events of this
				// type in queue. Otherwise faux moved events generated previously will disrupt.
				[NSApp discardEventsMatchingMask:NSMouseMovedMask beforeEvent:theEvent];
				eventMask |= NSMouseMovedMask;
			}
		} else if (eventMask & NSMouseMovedMask) {
			eventMask &= ~NSMouseMovedMask;
		}
			
		
//		NSLog(@"event loop, and we track mouse moved: %d", ((eventMask & NSMouseMovedMask) != 0));
		
	
//		[[self window] sendEvent:theEvent];
//		if ( !eventWindowBelongsToMenu && [theEvent window])
		if ([theEvent window])
			[[theEvent window] sendEvent:theEvent];
//		[[self window] resignKeyWindow];

		
//		NSLog(@"current loop: %@", [[NSRunLoop currentRunLoop] currentMode]);
//		[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0]];
//		CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0, NO);
		
	}
	
//	NSLog(@"finish tracking");
//	if (restart) {
//		NSLog(@"restarting tracking");
//		[self performSelector:@selector(startEventTracking) withObject:nil afterDelay:0.0];
//	}
}


// TODO: this is temp method
- (CMMenu *)menuToReciveEventWithWindow:(NSWindow *)window {
	CMMenu *menu = _owner;
	while (menu) {
		if ([menu underlyingWindow] == window)
			return menu;
		menu = [menu activeSubmenu];
	}
	
	return nil;
}


- (BOOL)mouseInsideMenuTreeDuringEvent:(NSEvent *)theEvent {
	NSPoint mouseLocation = [theEvent locationInWindow];
	mouseLocation = [[theEvent window] convertBaseToScreen:mouseLocation];
	CMMenu *menu = _owner;
	do {
		if (NSPointInRect(mouseLocation, [menu frame]))
			return YES;
	} while ((menu = [menu supermenu]));
	
	return NO;
}


- (BOOL)eventWindowBelongsToMenu:(NSEvent *)theEvent {
	NSWindow *window = [theEvent window];
	CMMenu *menu = ([_owner activeSubmenu]) ? [_owner activeSubmenu] : _owner;
	while (menu) {
		if ([menu underlyingWindow] == window)
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
	
	NSViewController *viewController = [(NSDictionary *)[theEvent userData] objectForKey:kTrackingAreaViewControllerKey];
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
	
//	NSLog(@"Mouse event on item: %@", menuItem);
	
	
	BOOL selected;
	BOOL changeSelectionStatus = [menuItem shouldChangeItemSelectionStatusForEvent:eventType];
	
//	NSLog(@"should change: %d", changeSelectionStatus);
	CMMenuItemView *view = (CMMenuItemView *)[viewController view];
	
	if (eventType & CMMenuEventDuringScroll) {
		selected = (eventType & CMMenuEventMouseEnteredItem) ? YES : NO;
		[view setSelected:selected];
	} else {
		
		if (changeSelectionStatus) {
			if (eventType & CMMenuEventMouseEnteredItem) {
	//			selected = YES;
				[view setSelected:YES];
			} else {
	//			selected = NO;
//				[self performSelector:@selector(delayedViewDeselection:) withObject:view afterDelay:0 inModes:[NSArray arrayWithObject:NSEventTrackingRunLoopMode]];
				[self performSelector:@selector(delayedViewDeselection:) withObject:view afterDelay:0 inModes:[NSArray arrayWithObject:NSRunLoopCommonModes]];
			}
		}
		
//		if (changeSelectionStatus && selected == YES)
//		if (changeSelectionStatus)
//			[(CMMenuItemView *)[viewController view] setSelected:selected];
	}
}
	
	
- (void)delayedViewDeselection:(CMMenuItemView *)view {
	[view setSelected:NO];
}


/*
 *
 */
- (void)scrollWithActiveScroller:(CMMenuScroller *)scroller {
//	CMMenuScroller *scroller = [userData objectForKey:kUserDataScrollerViewKey];
	NSDictionary *userData = [NSDictionary dictionaryWithObjectsAndKeys:scroller, kUserDataScrollerViewKey, nil];
//	_scrollTimer = [[NSTimer scheduledTimerWithTimeInterval:SCROLL_TIMER_INTERVAL target:self selector:@selector(scrollTimerEvent:) userInfo:userData repeats:YES] retain];
	
	_scrollTimer = [NSTimer timerWithTimeInterval:SCROLL_TIMER_INTERVAL target:self selector:@selector(scrollTimerEvent:) userInfo:userData repeats:YES];
//	[[NSRunLoop currentRunLoop] addTimer:_scrollTimer forMode:NSEventTrackingRunLoopMode];
	[[NSRunLoop currentRunLoop] addTimer:_scrollTimer forMode:NSRunLoopCommonModes];
}


/*
 *
 */
- (void)scrollTimerEvent:(NSTimer *)timer {
	NSDictionary *userData = [timer userInfo];
	CMMenuScroller *scroller = [userData objectForKey:kUserDataScrollerViewKey];
	if ([scroller scrollerType] == CMMenuScrollerTop) {
		[_scrollView scrollUpByAmount:19.0];
	} else {
		[_scrollView scrollDownByAmount:19.0];
	}
	
//	CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0, NO);
}


@end