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
#define VERTICAL_SPACING 0		// between menu items
#define MENU_SCROLLER_HEIGHT 15


//enum {
//	CMMenuEventImplicit = 1 << 0,				// when mouse event happend because of scrolling
//	CMMenuEventMouseEnteredItem = 1 << 1,
//	CMMenuEventMouseExitedItem = 1 << 2
//};
//typedef NSUInteger CMMenuEventType;



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
	
	NSMutableArray *_viewControllers;
	NSMutableArray *_trackingAreas;
	NSTrackingArea *_contentViewTrackingArea;
	
	id _localEventMonitor;
}

@property (assign) BOOL needsLayoutUpdate;

- (void)setFrame:(NSRect)frame;
- (void)updateMenuScrollers;
- (NSTrackingArea *)trackingAreaForViewController:(NSViewController *)viewController;
- (void)finishScrollEventAfterTrackingAreasUpdated;
- (void)mouseEventOnViewController:(NSViewController *)viewController eventType:(CMMenuEventType)eventType;

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


- (id)initWithOwner:(id)owner {
	NSRect rect = {{0, 0}, {20, 20}};
	NSWindow *window = [[ChromeMenuUnderlyingWindow alloc] initWithContentRect:rect defer:YES];
	
	self = [super initWithWindow:window];
	if (self) {
		_owner = owner;
		ChromeMenuUnderlyingView *contentView = [[ChromeMenuUnderlyingView alloc] initWithFrame:rect];
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
		_verticalPadding = 5.0;
		
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
- (void)displayInFrame:(NSRect)frame {
//	[self.window setFrameOrigin:origin];

	[self setFrame:frame];
	[self.window orderFront:self];
	
	/* We already knew documentView size, that is the size of all menu items.
		Now we know the actual size of menu (since it depends on the area it is being shown on).
		Let's see whether we need to show top and bottom Scrollers if the content doesn't fit
		in the menu */
	[self updateMenuScrollers];
	
	
	
	[self updateTrackingAreasForVisibleRect:[[_scrollView contentView] bounds]];
//	[self updateTrackingAreasForVisibleRect_2:[[_scrollView contentView] bounds]];
	[self updateContentViewTrackingArea];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(scrollViewContentViewBoundsDidChange:) name:NSViewBoundsDidChangeNotification object:[_scrollView contentView]];
	
	_localEventMonitor = [NSEvent addLocalMonitorForEventsMatchingMask:NSKeyDownMask handler:^(NSEvent *theEvent) {
		unsigned short keyCode = [theEvent keyCode];
		
		NSLog(@"key code: %d", keyCode);
		if (keyCode == 126 || keyCode == 125) {
			//			[_menuTableView keyDown:theEvent];
			theEvent = nil;
		}
		
		return theEvent;
	}];
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

	[NSEvent removeMonitor:_localEventMonitor];
	_localEventMonitor = nil;

}


/*
 *
 */
- (void)scrollViewContentViewBoundsDidChange:(NSNotification *)notification {
	NSLog(@"Scroll notification: %@, new bounds: %@", notification, NSStringFromRect([[_scrollView contentView] bounds]));
	[self updateMenuScrollers];
	[self updateTrackingAreasForVisibleRect:[[_scrollView contentView] bounds]];
//	[self updateTrackingAreasForVisibleRect_2:[[_scrollView contentView] bounds]];
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


/*
 *
 */
- (NSViewController *)viewControllerAtPoint:(NSPoint)aPoint {
	aPoint = [[_scrollView documentView] convertPoint:aPoint fromView:nil];
	NSRect documentViewFrame = [[_scrollView documentView] frame];;
	if (aPoint.x < documentViewFrame.origin.x || aPoint.x > documentViewFrame.origin.x + documentViewFrame.size.width
		|| aPoint.y < documentViewFrame.origin.y || aPoint.y > documentViewFrame.origin.y + documentViewFrame.size.height)
		return nil;
	
	NSArray *viewControllers = _viewControllers;
	for (NSViewController *viewController in viewControllers) {
		NSRect frame = [[viewController view] frame];
		if (frame.origin.y + frame.size.height >= aPoint.y)
			return viewController;
	}
	
	return nil;
}


// TODO: Comb me!
/**
 * Update top and/or bottom menu scrollers. If needed -- create them, if not -- hide.
 */
- (void)updateMenuScrollers {
	NSRect documentRect = [[_scrollView documentView] bounds];
	NSRect visibleRect = [_scrollView documentVisibleRect];

	// Menu does not need to be scrolled
	if (documentRect.size.height == visibleRect.size.height)
		return;
	
	NSRect scrollRect = [_scrollView frame];
	NSView *contentView = [self.window contentView];
	CGFloat scrollAmount = 0;
	// TOP scroller
//	if (visibleRect.origin.y != 0) {
	if (visibleRect.origin.y < 19) {
		if (_topScroller && [_topScroller superview]) {
			[_topScroller removeFromSuperview];
			scrollRect.size.height += MENU_SCROLLER_HEIGHT;
//			NSLog(@"scrolling up by 19px");

			/* We keep track on changes to Visible Rect because on it depends the bottom scroller display.
				Actual scrolling is done in the very end as it generates another Scroll Event and the execution
				of this function is being interrupted in the middle */
			visibleRect.size.height += MENU_SCROLLER_HEIGHT;
			visibleRect.origin.y -= MENU_SCROLLER_HEIGHT;

			scrollAmount = -19;
//			[_scrollView scrollUpByAmount:19];		// 19 -- just large enough height to scroll to top
		}
	} else {
		if (! _topScroller) {
			_topScroller = [[CMMenuScroller alloc] initWithScrollerType:CMMenuScrollerTop];
			[_topScroller setFrame:NSMakeRect(0, contentView.frame.size.height - MENU_SCROLLER_HEIGHT - _verticalPadding, documentRect.size.width, MENU_SCROLLER_HEIGHT)];
		}
			
//		NSLog(@"updatin top scroller: %@", _topScroller);
		if (! [_topScroller superview]) {
			[contentView addSubview:_topScroller];
			scrollRect.size.height -= MENU_SCROLLER_HEIGHT;
			visibleRect.size.height -= MENU_SCROLLER_HEIGHT;
			visibleRect.origin.y += MENU_SCROLLER_HEIGHT;
//			NSLog(@"scrolling bottom by 15px");
//			[_scrollView scrollBottomByAmount:MENU_SCROLLER_HEIGHT];
			scrollAmount = MENU_SCROLLER_HEIGHT;
		}
		
	}
//	else if (_topScroller && [_topScroller superview]) {
//		[_topScroller removeFromSuperview];
//		scrollRect.size.height += MENU_SCROLLER_HEIGHT;
//	}

	// BOTTOM scroller
	CGFloat visibleRectHeight = (_bottomScroller && [_bottomScroller superview]) ? visibleRect.size.height + MENU_SCROLLER_HEIGHT :
		visibleRect.size.height;
//	visibleRectHeight = visibleRect.size.height;
//	NSLog(@"visible rect %@, and height (imagining): %f", NSStringFromRect(visibleRect), visibleRectHeight);
	if (visibleRect.origin.y + visibleRectHeight < documentRect.size.height) {
		if (! _bottomScroller) {
			_bottomScroller = [[CMMenuScroller alloc] initWithScrollerType:CMMenuScrollerBottom];
			NSRect scrollerRect = NSMakeRect(0, _verticalPadding, documentRect.size.width, MENU_SCROLLER_HEIGHT);
			[_bottomScroller setFrame:scrollerRect];
		}
		
		if (! [_bottomScroller superview]) {
			[contentView addSubview:_bottomScroller];
			scrollRect.origin.y +=  MENU_SCROLLER_HEIGHT;
			scrollRect.size.height -= MENU_SCROLLER_HEIGHT;
		}
//		NSRect scrollViewFrame = [_scrollView frame];
//		CGFloat bottom = contentView.frame.size.height;
//		NSRect scrollerRect = NSMakeRect(0, bottom - MENU_SCROLLER_HEIGHT - 100, documentRect.size.width, MENU_SCROLLER_HEIGHT);
//		NSLog(@"updating bottom scroller: ", _bottomScroller);
	} else if (_bottomScroller && [_bottomScroller superview]) {
//		NSLog(@"removing bottom scroller");
		[_bottomScroller removeFromSuperview];
		scrollRect.origin.y -= MENU_SCROLLER_HEIGHT;
		scrollRect.size.height += MENU_SCROLLER_HEIGHT;
	}

//	NSLog(@"new scroll frame: %@", NSStringFromRect(scrollRect));
	[_scrollView setFrame:scrollRect];
	if (scrollAmount > 0)
		[_scrollView scrollBottomByAmount:scrollAmount];
	else if (scrollAmount < 0)
		[_scrollView scrollUpByAmount:-scrollAmount];
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
			[self mouseEventOnViewController:viewController eventType:CMMenuEventMouseExitedItem | CMMenuEventDuringScroll];
		}
		[_trackingAreas removeAllObjects];
	} else {
		// maks: see if we need to remove tracking areas on window orderOut:
		_trackingAreas = [[NSMutableArray alloc] init];
	}
	
//	NSArray *controllers = _viewControllers;

//	NSUInteger firstIndex;
//	NSUInteger lastIndex;
//	NSUInteger i;
	
	/* When scrolling -mouseEntered and -mouseExited events are not being fired.
	   This is because we have removed them. Event if not -- they fire wrong tracking areas anyway.
	   So at the time of creating of tracking areas we check where the mouse is and
	   highlight according view. */
	NSPoint mouseLocation;
	mouseLocation = [[self window] mouseLocationOutsideOfEventStream];
	mouseLocation = [documentView convertPoint:mouseLocation fromView:nil];
	
//	firstIndex = floor(visibleRect.origin.y / (_viewHeight + VERTICAL_SPACING));
//	if (VERTICAL_SPACING != 0 && ((visibleRect.origin.y - firstIndex * (_viewHeight + VERTICAL_SPACING)) > _viewHeight))
//		++firstIndex;
//	lastIndex = floor((visibleRect.origin.y + visibleRect.size.height - 1) / (_viewHeight + VERTICAL_SPACING));
//	if (lastIndex >= [_viewControllers count])
//		lastIndex = [_viewControllers count] - 1;

//	NSLog(@"First index: %d, last index: %d", firstIndex, lastIndex);
	
//	NSArray *subviews = [documentView subviews];
//	for (i = firstIndex; i <= lastIndex; ++i) {
	
//	firstIndex = -1;
//	i = -1;
//	NSViewController *lastController;
//	NSLog(@"visible rect: %@", NSStringFromRect(visibleRect));
		
	for (NSViewController *viewController in _viewControllers) {
//		++i;
		
		NSRect frame = [[viewController view] frame];
		if (frame.origin.y + frame.size.height <= visibleRect.origin.y)
			continue;
		
		if (frame.origin.y >= visibleRect.origin.y + visibleRect.size.height)
			break;
		
//		if (firstIndex == -1) {
//			firstIndex = i;
//			CMMenuItem *itemfirst = [viewController representedObject];
//			NSLog(@"start tracking areas from: %@", itemfirst);
//		}
//		lastController = viewController;
		
		if (! [(CMMenuItemView *)[viewController view] needsTracking])
			continue;
	
		
//		CMMenuItemView *view = [subviews objectAtIndex:i];
//		NSTrackingArea *trackingArea = [self trackingAreaForView:view];
//		NSViewController *viewController = [_viewControllers objectAtIndex:i];
		NSTrackingArea *trackingArea = [self trackingAreaForViewController:viewController];
		[documentView addTrackingArea:trackingArea];
		[_trackingAreas addObject:trackingArea];
		
//		if (NSPointInRect(mouseLocation, [view frame]))
//			[view setSelected:YES];


//		NSPoint currentLocation = [[self window] mouseLocationOutsideOfEventStream];
//		currentLocation = [documentView convertPoint:currentLocation fromView:nil];

		if (NSPointInRect(mouseLocation, frame)) {
//		if (NSPointInRect(currentLocation, frame)) {
			/* debuggin */
//			CMMenuItem *item = [viewController representedObject];
//			NSLog(@"SELECT ITEM DURING SCROLL: %@", item);
//			NSPoint currentLocation = [[self window] mouseLocationOutsideOfEventStream];
//			currentLocation = [documentView convertPoint:currentLocation fromView:nil];
//			NSLog(@"At mouse location: %@, current location: %@", NSStringFromPoint(mouseLocation), NSStringFromPoint(currentLocation));


		
			[self mouseEventOnViewController:viewController eventType:CMMenuEventMouseEnteredItem | CMMenuEventDuringScroll];
		}
		

	}
	
//	NSLog(@"last item for areas: %@", [lastController representedObject]);
	
//	NSLog(@"first index: %ld, last: %ld, location: %@, tracking_areas_count:%ld", firstIndex, i, NSStringFromPoint(afterLocation),
//		  [[[_scrollView documentView] trackingAreas] count]);

	/* When scroll event is fired we upate Tracking Areas. During this time user can move the mouse as well.
		Tracking areas are not yet active and working. As a result there might be double-selection of 
		different menu items at the same time. We run a finilizing function from another Run Loop 
		after tracking areas are completely set-up. */
	[self performSelector:@selector(finishScrollEventAfterTrackingAreasUpdated) withObject:nil afterDelay:0.0];
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
			[self mouseEventOnViewController:viewController eventType:CMMenuEventMouseExitedItem | CMMenuEventDuringScroll];

			
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

			[self mouseEventOnViewController:viewController eventType:CMMenuEventMouseEnteredItem | CMMenuEventDuringScroll];
		}
//		else {
//			[self mouseEventOnViewController:viewController eventType:CMMenuEventMouseExitedItem | CMMenuEventDuringScroll];
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
		NSRect frame = [[viewController view] frame];

		if (NSPointInRect(mouseLocation, frame)) {
//			CMMenuItem *item = [viewController representedObject];
//			NSLog(@"SELECT ITEM AFTER updating tracking areas: %@", item);
			[self mouseEventOnViewController:viewController eventType:CMMenuEventMouseEnteredItem | CMMenuEventDuringScroll];
		} else
			[self mouseEventOnViewController:viewController eventType:CMMenuEventMouseExitedItem | CMMenuEventDuringScroll];
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
//			[self mouseEventOnViewController:viewController eventType:CMMenuEventMouseEnteredItem | CMMenuEventDuringScroll];
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
- (NSTrackingArea *)trackingAreaForViewController:(NSViewController *)viewController {
	NSRect trackingRect = [[_scrollView documentView] convertRect:[[viewController view] bounds] fromView:[viewController view]];
	NSTrackingAreaOptions trackingOptions = NSTrackingMouseEnteredAndExited | NSTrackingEnabledDuringMouseDrag | NSTrackingActiveInActiveApp;
	NSDictionary *trackingData = [NSDictionary dictionaryWithObjectsAndKeys:viewController, kTrackingAreaViewControllerKey, nil];
	
	NSTrackingArea *trackingArea = [[NSTrackingArea alloc] initWithRect:trackingRect options:trackingOptions owner:self userInfo:trackingData];

	return [trackingArea autorelease];
}



/*
 * Tracking Area for Menu Rect
 */
- (void)updateContentViewTrackingArea {
	NSView *contentView = self.window.contentView;
	
	if (_contentViewTrackingArea) {
		[contentView removeTrackingArea:_contentViewTrackingArea];
		[_contentViewTrackingArea release];
	}
	
	NSRect trackingRect = [contentView bounds];
	NSTrackingAreaOptions trackingOptions = NSTrackingMouseEnteredAndExited | NSTrackingActiveInActiveApp | NSTrackingEnabledDuringMouseDrag;
//	NSDictionary *trackingData = [NSDictionary];
	
	NSTrackingArea *trackingArea = [[NSTrackingArea alloc] initWithRect:trackingRect options:trackingOptions owner:self userInfo:nil];
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


	if ([theEvent userData]) {		// mouse entered menu item view
		NSViewController *viewController = [(NSDictionary *)[theEvent userData] objectForKey:kTrackingAreaViewControllerKey];
		/* debuggin */
//		CMMenuItem *item = [viewController representedObject];
//		fputs("\n", stdout);
//		NSLog(@"Mouse Enter MENU ITEM: %@", item);
		/* debuggin */
		[self mouseEventOnViewController:viewController eventType:CMMenuEventMouseEnteredItem];
	} else {						// mouse entered menu itself
//		NSLog(@"Mouse Enter MENU: %@", theEvent);
		CMMenu *menu = (CMMenu *)_owner;
		[menu mouseEvent:theEvent];
	}

}


/*
 *
 */
- (void)mouseExited:(NSEvent *)theEvent {
//	CMMenuItemView *view = [(NSDictionary *)[theEvent userData] objectForKey:kTrackingAreaViewControllerKey];
//	NSViewController *viewController = [(NSDictionary *)[theEvent userData] objectForKey:kTrackingAreaViewControllerKey];
//	[self mouseEventOnViewController:viewController eventType:CMMenuEventMouseExitedItem];
//	[(CMMenuItemView *)[viewController view] setSelected:NO];
	
//	NSLog(@"Mouse Exited %@", theEvent);
	
	if ([theEvent userData]) {
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
	} else {
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


//- (void)mouseDown:(NSEvent *)theEvent {
//	NSLog(@"DOWN: %@", theEvent);
//}


/*
 *
 */
- (void)delayedMouseExitedEvent:(NSEvent *)theEvent {
	NSViewController *viewController = [(NSDictionary *)[theEvent userData] objectForKey:kTrackingAreaViewControllerKey];
	[self mouseEventOnViewController:viewController eventType:CMMenuEventMouseExitedItem];
}


/*
 *
 */
- (void)mouseEventOnViewController:(NSViewController *)viewController eventType:(CMMenuEventType)eventType {
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
		
		if (changeSelectionStatus)
			[(CMMenuItemView *)[viewController view] setSelected:selected];
	}

}



@end
