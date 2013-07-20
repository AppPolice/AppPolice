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


#define kTrackingAreaViewControllerKey @"viewController"
#define VERTICAL_SPACING 0		// between menu item views


//enum {
//	CMMenuEventImplicit = 1 << 0,				// when mouse event happend because of scrolling
//	CMMenuEventMouseEnteredItem = 1 << 1,
//	CMMenuEventMouseExitedItem = 1 << 2
//};
//typedef NSUInteger CMMenuEventType;



@interface CMWindowController ()
{
	CMScrollView *_scrollView;
	CGFloat _verticalPadding;
//	CMScrollDocumentView *_scrollDocumentView;
	
	BOOL _needsLayoutUpdate;
	CGFloat _maximumViewWidth;
	CGFloat _viewHeight;
	
	NSMutableArray *_viewControllers;
	NSMutableArray *_trackingAreas;
	
	id _localEventMonitor;
}

@property (assign) BOOL needsLayoutUpdate;

- (void)setSizeWithFrame:(NSRect)frame;
- (NSTrackingArea *)trackingAreaForViewController:(NSViewController *)viewController;
- (void)mouseEventOnViewController:(NSViewController *)viewController eventType:(CMMenuEventType)eventType;

@end

@implementation CMWindowController

@synthesize needsLayoutUpdate = _needsLayoutUpdate;


/*
  ___________
 |  _______ |
 | |	  | |
 | |	  | |
 | |	  | |
 | |	  | |
 | |	  | |
 | |	  | |
 | |	  | |
 | -------- |
 ------------
 
 */


- (id)init {
	NSRect rect = {{0, 0}, {20, 20}};
	NSWindow *window = [[ChromeMenuUnderlyingWindow alloc] initWithContentRect:rect defer:YES];
	
	self = [super initWithWindow:window];
	if (self) {
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
		[_scrollView setLineScroll:19.0 + VERTICAL_SPACING];
		// activate vertical scroller, but then hide it
		[_scrollView setHasVerticalScroller:YES];
		[_scrollView setHasVerticalScroller:NO];
		
		CMScrollDocumentView *documentView = [[CMScrollDocumentView alloc] initWithFrame:rect];
		[_scrollView setDocumentView:documentView];
		[contentView addSubview:_scrollView];
		
		// Post a notification when scroll view scrolled
		[[_scrollView contentView] setPostsBoundsChangedNotifications:YES];
		
		[documentView release];
		[contentView release];
		
		_verticalPadding = 4.0;
		
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

- (void)displayInFrame:(NSRect)frame {
//	[self.window setFrameOrigin:origin];

	[self setSizeWithFrame:frame];
	[self.window orderFront:self];
	
	[self updateTrackingAreasForVisibleRect:[[_scrollView contentView] bounds]];
	
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


- (void)setSizeWithFrame:(NSRect)frame {
	[self.window setFrame:frame display:NO];
	[_scrollView setFrame:NSMakeRect(0, _verticalPadding, frame.size.width, frame.size.height - 2 * _verticalPadding)];
}


- (void)hide {
	[self.window orderOut:self];

	[[NSNotificationCenter defaultCenter] removeObserver:self];

	[NSEvent removeMonitor:_localEventMonitor];
	_localEventMonitor = nil;

}


- (void)scrollViewContentViewBoundsDidChange:(NSNotification *)notification {
	NSLog(@"Scroll notification: %@, new bounds: %@", notification, NSStringFromRect([[_scrollView contentView] bounds]));
	[self updateTrackingAreasForVisibleRect:[[_scrollView contentView] bounds]];
}


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

//		[_scrollDocumentView addSubview:view];
		[documentView addSubview:view];
	}
	
	_maximumViewWidth = maximumWidth;
	_viewHeight = [[viewControllers objectAtIndex:0] view].frame.size.height;
	
	[self updateViews];
}


- (void)updateViews {
	NSView *documentView = [_scrollView documentView];
	CGFloat width = _maximumViewWidth;
	CGFloat height = _viewHeight;
	CGFloat offset = 0.0f;
	CGFloat documentViewHeight = [[documentView subviews] count] * (height + VERTICAL_SPACING);
//	CGFloat heightLimit = 817.0;
//	CGFloat menuHeight;
	
//	menuHeight = (documentViewHeight > heightLimit) ? heightLimit : documentViewHeight;
		
	
//	[self.window setFrame:CGRectMake(0, 0, width, menuHeight + 2 * _verticalPadding) display:NO];
//	[_scrollView setFrame:CGRectMake(0, _verticalPadding, width, menuHeight)];
	[documentView setFrame:NSMakeRect(0, 0, width, documentViewHeight)];
	
	for (NSView *view in [documentView subviews]) {
		CGRect frame = [view frame];
		frame.size = NSMakeSize(width, height);
		frame.origin.y = offset;
		frame.origin.x = 0;
		[view setFrame:frame];
		offset += height + VERTICAL_SPACING;
	}
}


#pragma mark -
#pragma mark ******** Tracking Areas & Events Handling ********

- (void)updateTrackingAreasForVisibleRect:(NSRect)visibleRect {
//	NSLog(@"Visible RECT: %@", NSStringFromRect(visibleRect));
	NSView *documentView = [_scrollView documentView];
	
	if (_trackingAreas) {
		for (NSTrackingArea *trackingArea in _trackingAreas) {
			[documentView removeTrackingArea:trackingArea];
			/* We remove highlighting of the previously selected view */
//			CMMenuItemView *view = [(NSDictionary *)[trackingArea userInfo] objectForKey:kTrackingAreaViewControllerKey];
			NSViewController *viewController = [(NSDictionary *)[trackingArea userInfo] objectForKey:kTrackingAreaViewControllerKey];
//			if ([view isSelected])
//				[view setSelected:NO];
			[self mouseEventOnViewController:viewController eventType:CMMenuEventMouseExitedItem | CMMenuEventImplicit];
		}
		[_trackingAreas removeAllObjects];
	} else {
		// maks: see if we need to remove tracking areas on window orderOut:
		_trackingAreas = [[NSMutableArray alloc] init];
	}
	
	
	NSPoint mouseLocation;
	NSUInteger firstIndex;
	NSUInteger lastIndex;
	NSUInteger i;
	
	/* When scrolling -mouseEntered and -mouseExited events are not being fired.
	   So at the time of creating of tracking areas we check where the mouse is and
	   highlight according view.
	 */
	mouseLocation = [[self window] mouseLocationOutsideOfEventStream];
	mouseLocation = [documentView convertPoint:mouseLocation fromView:nil];
	
	firstIndex = floor(visibleRect.origin.y / (_viewHeight + VERTICAL_SPACING));
	if (VERTICAL_SPACING != 0 && ((visibleRect.origin.y - firstIndex * (_viewHeight + VERTICAL_SPACING)) > _viewHeight))
		++firstIndex;
	lastIndex = floor((visibleRect.origin.y + visibleRect.size.height - 1) / (_viewHeight + VERTICAL_SPACING));
	if (lastIndex >= [_viewControllers count])
		lastIndex = [_viewControllers count] - 1;

//	NSLog(@"First index: %d, last index: %d", firstIndex, lastIndex);
	
//	NSArray *subviews = [documentView subviews];
	for (i = firstIndex; i <= lastIndex; ++i) {
//		CMMenuItemView *view = [subviews objectAtIndex:i];
//		NSTrackingArea *trackingArea = [self trackingAreaForView:view];
		NSViewController *viewController = [_viewControllers objectAtIndex:i];
		NSTrackingArea *trackingArea = [self trackingAreaForViewController:viewController];
		[documentView addTrackingArea:trackingArea];
		[_trackingAreas addObject:trackingArea];
		
//		if (NSPointInRect(mouseLocation, [view frame]))
//			[view setSelected:YES];
		if (NSPointInRect(mouseLocation, [[viewController view] frame]))
			[self mouseEventOnViewController:viewController eventType:CMMenuEventMouseEnteredItem | CMMenuEventImplicit];
	}
}


//- (NSTrackingArea *)trackingAreaForView:(NSView *)view {
- (NSTrackingArea *)trackingAreaForViewController:(NSViewController *)viewController {
	NSRect trackingRect = [[_scrollView documentView] convertRect:[[viewController view] bounds] fromView:[viewController view]];
	NSTrackingAreaOptions trackingOptions = NSTrackingMouseEnteredAndExited | NSTrackingEnabledDuringMouseDrag | NSTrackingActiveInActiveApp;
	NSDictionary *trackingData = [NSDictionary dictionaryWithObjectsAndKeys:viewController, kTrackingAreaViewControllerKey, nil];
	
	NSTrackingArea *trackingArea = [[NSTrackingArea alloc] initWithRect:trackingRect options:trackingOptions owner:self userInfo:trackingData];

	return [trackingArea autorelease];
}


- (void)mouseEntered:(NSEvent *)theEvent {
//	static NSViewController *ctrl = nil;
	
	//	CMMenuItemView *view = [(NSDictionary *)[theEvent userData] objectForKey:kTrackingAreaViewControllerKey];
	NSViewController *viewController = [(NSDictionary *)[theEvent userData] objectForKey:kTrackingAreaViewControllerKey];
	[self mouseEventOnViewController:viewController eventType:CMMenuEventMouseEnteredItem];
//	[(CMMenuItemView *)[viewController view] setSelected:YES];
	
//	if (ctrl == nil) {
//		ctrl = viewController;
//	} else {
////		[self mouseEventOnViewController:ctrl eventType:CMMenuEventMouseExitedItem];
//		[(CMMenuItemView *)[ctrl view] setSelected:NO];
//		ctrl = viewController;
//	}
	
	
//	NSLog(@"Mouse Entered %@", theEvent);
}


- (void)mouseExited:(NSEvent *)theEvent {
//	CMMenuItemView *view = [(NSDictionary *)[theEvent userData] objectForKey:kTrackingAreaViewControllerKey];
//	NSViewController *viewController = [(NSDictionary *)[theEvent userData] objectForKey:kTrackingAreaViewControllerKey];
//	[self mouseEventOnViewController:viewController eventType:CMMenuEventMouseExitedItem];
//	[(CMMenuItemView *)[viewController view] setSelected:NO];
	
//	NSLog(@"Mouse Exited %@", theEvent);
	
	/*
	 * We want to redraw currently selected item after newly hovered item has background.
	 * This technic is used to solve the blinking problem when moving mouse swiftly through the menu items.
	 */
	[self performSelector:@selector(delayedMouseExitedEvent:) withObject:theEvent afterDelay:0.0];
}


- (void)delayedMouseExitedEvent:(NSEvent *)theEvent {
	NSViewController *viewController = [(NSDictionary *)[theEvent userData] objectForKey:kTrackingAreaViewControllerKey];
	[self mouseEventOnViewController:viewController eventType:CMMenuEventMouseExitedItem];
}


- (void)mouseEventOnViewController:(NSViewController *)viewController eventType:(CMMenuEventType)eventType {
	CMMenuItem *menuItem = [viewController representedObject];
	BOOL selected;
	BOOL changeSelectionStatus = [menuItem shouldChangeItemSelectionStatusForEvent:eventType];
	
//	NSLog(@"should change: %d", changeSelectionStatus);
	
	if (eventType & CMMenuEventImplicit) {
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
