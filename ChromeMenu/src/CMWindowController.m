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


#define kTrackingAreaViewControllerKey @"viewController"
#define kUserDataScrollerViewKey @"scroller"
#define kUserDataEventTypeKey @"eventType"
#define VERTICAL_SPACING 0		// between menu items
#define MENU_SCROLLER_HEIGHT 15.0
#define SCROLL_TIMER_INTERVAL 0.05


@interface CMWindowController ()
{
	id _owner;
	CMScrollView *_scrollView;
	CGFloat _verticalPadding;
//	CMScrollDocumentView *_scrollDocumentView;
	
	BOOL _needsLayoutUpdate;
	CGFloat _maximumViewWidth;
	CGFloat _viewHeight;
	CGFloat _separatorViewHeight;
	
	CMMenuScroller *_topScroller;
	CMMenuScroller *_bottomScroller;
	NSTimer *_scrollTimer;
	
	NSMutableArray *_viewControllers;
	NSMutableArray *_trackingAreas;
	NSTrackingArea *_contentViewTrackingArea;
	
	BOOL _ignoreMouse;
//	BOOL _ignoreMouseDuringScrollContentViewBoundsChange;
//	id _localEventMonitor;
}

@property (assign) BOOL needsLayoutUpdate;

- (void)setFrame:(NSRect)frame;
- (void)updateMenuScrollers;

/**
 * @abstract Create Tracking Area for Menu Item view
 * @param viewController ViewController of a view that will be returned in userData in event
 * @param trackingRect Rect for tracking area. It represents only the visible portion of the view.
 */
- (NSTrackingArea *)trackingAreaForItemView:(NSViewController *)viewController inRect:(NSRect)trackingRect;

- (NSTrackingArea *)trackingAreaForScrollerView:(CMMenuScroller *)scroller inRect:(NSRect)trackingRect;

- (void)finishScrollEventAfterTrackingAreasUpdated;
- (void)mouseEventOnItemView:(NSViewController *)viewController eventType:(CMMenuEventType)eventType;

@end

@implementation CMWindowController

@synthesize needsLayoutUpdate = _needsLayoutUpdate;


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
		_ignoreMouse = NO;
//		_ignoreMouseDuringScrollContentViewBoundsChange = NO;
		
		[self setNeedsLayoutUpdate:YES];
	}
	
	[window release];
	
	return self;
}


- (void)dealloc {
	[_viewControllers release];
	[_trackingAreas release];
	[_scrollView release];
	
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
	return NSMakeSize(_maximumViewWidth, [[[_scrollView documentView] subviews] count] * (_viewHeight + VERTICAL_SPACING) + 2 * _verticalPadding);
}


//- (void)display {
//	[self displayInFrame:NSMakeRect(100, 200, 200, 200)];
//}


/*
 *
 */
- (void)displayInFrame:(NSRect)frame ignoreMouse:(BOOL)ignoreMouse {
//	[self.window setFrameOrigin:origin];

	[self setFrame:frame];
	[self.window orderFront:self];
	
	/* We already knew documentView size, that is the size of all menu items.
		Now we know the actual size of menu (since it depends on the area it is being shown on).
		Let's see whether we need to show top and bottom Scrollers if the content doesn't fit
		in the menu */
	[self updateMenuScrollers];
	
	if (ignoreMouse)
		_ignoreMouse = YES;
	
	[self updateTrackingAreasForVisibleRect:[[_scrollView contentView] bounds]];
//	[self updateTrackingAreasForVisibleRect_2:[[_scrollView contentView] bounds]];
	[self updateContentViewTrackingAreaTrackMouseMoved:NO];
	
	_ignoreMouse = NO;
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(scrollViewContentViewBoundsDidChange:) name:NSViewBoundsDidChangeNotification object:[_scrollView contentView]];
}



/*
 *
 */
- (void)setFrame:(NSRect)frame {
	[self.window setFrame:frame display:NO];
	// scroll view frame includes the menu top and bottom paddings
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


/*
 *
 */
- (void)scrollViewContentViewBoundsDidChange:(NSNotification *)notification {
	NSLog(@"Scroll notification: %@, new bounds: %@", notification, NSStringFromRect([[_scrollView contentView] bounds]));
	[self updateMenuScrollers];
	[self updateTrackingAreasForVisibleRect:[[_scrollView contentView] bounds]];
	
	/* When scroll event is fired we upate Tracking Areas. During this time user can move the mouse as well.
	 Tracking areas are not yet active and working. As a result there might be double-selection of
	 different menu items at the same time. We run a finilizing function from another Run Loop
	 after tracking areas are completely set-up. */
//	if (! _ignoreMouseDuringScrollContentViewBoundsChange)
	if (! _ignoreMouse)
		[self performSelector:@selector(finishScrollEventAfterTrackingAreasUpdated) withObject:nil afterDelay:0.0];

//	[self updateTrackingAreasForVisibleRect_2:[[_scrollView contentView] bounds]];
	
//	_ignoreMouseDuringScrollContentViewBoundsChange = NO;
	_ignoreMouse = NO;
}


/*
 *
 */
- (void)layoutViews:(NSMutableArray *)viewControllers {
	if (!viewControllers)
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
 *
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
		CGRect frame;
		CGFloat height = ([menuItem isSeparatorItem]) ? separatorViewHeight : viewHeight;
		frame.size = NSMakeSize(width, height);
		offset -= height + VERTICAL_SPACING;
		frame.origin.y = offset;
		frame.origin.x = 0;
		[view setFrame:frame];
	}

	[documentView setFrame:NSMakeRect(0, 0, width, -1 * offset)];
}


/**
 * Update top and/or bottom menu scrollers. If needed -- create them, if not -- hide.
 */
- (void)updateMenuScrollers {
	NSRect documentRect = [[_scrollView documentView] bounds];
	NSRect visibleRect = [_scrollView documentVisibleRect];
	
	// Menu does not need to be scrolled
	if (documentRect.size.height == visibleRect.size.height)
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
				[_scrollTimer release];
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
			[_scrollTimer release];
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
	}
}



#pragma mark -
#pragma mark ******** Tracking Areas & Events Handling ********


/*
 *
 */
- (void)updateTrackingAreasForVisibleRect:(NSRect)visibleRect {
	NSView *documentView = [_scrollView documentView];
	
	if (_trackingAreas) {
		for (NSTrackingArea *trackingArea in _trackingAreas) {
			[documentView removeTrackingArea:trackingArea];
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
	
	if (_contentViewTrackingArea) {
		[contentView removeTrackingArea:_contentViewTrackingArea];
		[_contentViewTrackingArea release];
	}
	
	NSRect trackingRect = [contentView bounds];
	NSTrackingAreaOptions trackingOptions = NSTrackingMouseEnteredAndExited | NSTrackingActiveInActiveApp | NSTrackingEnabledDuringMouseDrag;
	if (trackMouseMoved)
		trackingOptions |= NSTrackingMouseMoved;
	
	NSDictionary *trackingData = [NSDictionary dictionaryWithObjectsAndKeys:
								  [NSNumber numberWithUnsignedInteger:CMMenuEventMouseMenu], kUserDataEventTypeKey, nil];
	NSTrackingArea *trackingArea = [[NSTrackingArea alloc] initWithRect:trackingRect options:trackingOptions owner:self userInfo:trackingData];
	[contentView addTrackingArea:trackingArea];
	_contentViewTrackingArea = trackingArea;
}



/*
 *
 */
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
		/* debuggin */
//		CMMenuItem *item = [viewController representedObject];
//		fputs("\n", stdout);
//		NSLog(@"Mouse Enter MENU ITEM: %@", item);
		/* debuggin */
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


/*
 *
 */
- (void)mouseExited:(NSEvent *)theEvent {
//	NSLog(@"Mouse Exited %@", theEvent);
	
//	CMMenuItemView *view = [(NSDictionary *)[theEvent userData] objectForKey:kTrackingAreaViewControllerKey];
//	NSViewController *viewController = [(NSDictionary *)[theEvent userData] objectForKey:kTrackingAreaViewControllerKey];
//	[self mouseEventOnItemView:viewController eventType:CMMenuEventMouseExitedItem];
//	[(CMMenuItemView *)[viewController view] setSelected:NO];
	
	
	NSDictionary *userData = [theEvent userData];
	CMMenuEventType eventType = [(NSNumber *)[userData objectForKey:kUserDataEventTypeKey] unsignedIntegerValue];

	
	if (eventType & CMMenuEventMouseItem) {
		/* debuggin */
//		NSViewController *viewController = [(NSDictionary *)[theEvent userData] objectForKey:kTrackingAreaViewControllerKey];
//		CMMenuItem *item = [viewController representedObject];
//		NSLog(@"Mouse Exit MENU ITEM: %@", item);
		/* debuggin */
		
		/*
		 * We want to redraw currently selected item after newly hovered item has background.
		 * This technic is used to solve the blinking problem when moving mouse swiftly through the menu items.
		 */
		[self performSelector:@selector(delayedMouseExitedEvent:) withObject:theEvent afterDelay:0.0];
//		NSViewController *viewController = [(NSDictionary *)[theEvent userData] objectForKey:kTrackingAreaViewControllerKey];
//		[self mouseEventOnItemView:viewController eventType:CMMenuEventMouseExitedItem];
	} else if (eventType & CMMenuEventMouseScroller) {
		[_scrollTimer invalidate];
		[_scrollTimer release];
		_scrollTimer = nil;
	} else if (eventType & CMMenuEventMouseMenu) {
		CMMenu *menu = (CMMenu *)_owner;
		[menu mouseEvent:theEvent];
	}
}


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

}


- (void)mouseMoved:(NSEvent *)theEvent {
	NSLog(@"mouse moved: %@", theEvent);
}

//- (void)mouseDown:(NSEvent *)theEvent {
//	NSLog(@"DOWN: %@", theEvent);
//}


/*
 *
 */
- (void)delayedMouseExitedEvent:(NSEvent *)theEvent {
	NSViewController *viewController = [(NSDictionary *)[theEvent userData] objectForKey:kTrackingAreaViewControllerKey];
	[self mouseEventOnItemView:viewController eventType:CMMenuEventMouseExitedItem];
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
	
	
	BOOL selected;
	BOOL changeSelectionStatus = [menuItem shouldChangeItemSelectionStatusForEvent:eventType];
	
//	NSLog(@"should change: %d", changeSelectionStatus);
	
	if (eventType & CMMenuEventDuringScroll) {
		selected = (eventType & CMMenuEventMouseEnteredItem) ? YES : NO;
		[(CMMenuItemView *)[viewController view] setSelected:selected];
	} else {
		// we must calculate wheather item wants to lose Selected status
		if (eventType & CMMenuEventMouseEnteredItem) {
			selected = YES;
		} else {
			selected = NO;
		}
		
//		if (changeSelectionStatus && selected == YES)
		if (changeSelectionStatus)
			[(CMMenuItemView *)[viewController view] setSelected:selected];
	}

}


/*
 *
 */
- (void)scrollWithActiveScroller:(CMMenuScroller *)scroller {
//	CMMenuScroller *scroller = [userData objectForKey:kUserDataScrollerViewKey];
	NSDictionary *userData = [NSDictionary dictionaryWithObjectsAndKeys:scroller, kUserDataScrollerViewKey, nil];
	_scrollTimer = [[NSTimer scheduledTimerWithTimeInterval:SCROLL_TIMER_INTERVAL target:self selector:@selector(scrollTimerEvent:) userInfo:userData repeats:YES] retain];
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
}


@end