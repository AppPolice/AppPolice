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


#define VIEW_SPACING 5


@interface CMWindowController ()
{
	NSScrollView *_scrollView;
//	CMScrollDocumentView *_scrollDocumentView;
	
	BOOL _needsLayoutUpdate;
	CGFloat _maximumViewWidth;
	CGFloat _viewHeight;
	
	NSMutableArray *_viewControllers;
	NSMutableArray *_trackingAreas;
	
	id _localEventMonitor;
}

@property (assign) BOOL needsLayoutUpdate;

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
		
		_scrollView = [[NSScrollView alloc] initWithFrame:rect];
		[_scrollView setBorderType:NSNoBorder];
		[_scrollView setDrawsBackground:NO];
		// activate vertical scroller, but then hide it
		[_scrollView setHasVerticalScroller:YES];
		[_scrollView setHasVerticalScroller:NO];
//		[_scrollView setHasVerticalRuler:YES];
//		_scrollDocumentView = (CMScrollDocumentView *)[[NSView alloc] initWithFrame:rect];
		CMScrollDocumentView *documentView = [[CMScrollDocumentView alloc] initWithFrame:rect];
		[_scrollView setDocumentView:documentView];
		[contentView addSubview:_scrollView];
		// Post a notification when scroll view scrolled
		[[_scrollView contentView] setPostsBoundsChangedNotifications:YES];
		
		[documentView release];
		[contentView release];
		
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


- (void)display {
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


- (void)hide {
	[self.window orderOut:self];

	[[NSNotificationCenter defaultCenter] removeObserver:self];

	[NSEvent removeMonitor:_localEventMonitor];
	_localEventMonitor = nil;

}


- (void)scrollViewContentViewBoundsDidChange:(NSNotification *)notification {
	NSLog(@"Scroll notification: %@, new bounds: %@", notification, NSStringFromRect([[_scrollView contentView] bounds]));
}


- (void)layoutViews:(NSMutableArray *)viewControllers {
	if (!viewControllers)
		return;
	
	if (_viewControllers != viewControllers) {
		[_viewControllers release];
		_viewControllers = [viewControllers retain];
	}
	
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
	CGFloat documentViewHeight = [[documentView subviews] count] * (height + VIEW_SPACING);
	
	[self.window setFrame:CGRectMake(0, 0, width + 30, 500) display:NO];
	[_scrollView setFrame:CGRectMake(0, 0, width + 30, 500)];
	[documentView setFrame:CGRectMake(0, 0, width + 30, documentViewHeight + 20)];
	
	for (NSView *view in [documentView subviews]) {
		CGRect frame = [view frame];
		frame.size = CGSizeMake(width, height);
		frame.origin.y = offset;
		frame.origin.x = 5;
		[view setFrame:frame];
		offset += height + VIEW_SPACING;
	}
}


#pragma mark -
#pragma mark ************** Tracking Areas ***************

- (void)updateTrackingAreasForVisibleRect:(NSRect)visibleRect {
	NSLog(@"Visible RECT: %@", NSStringFromRect(visibleRect));
}



@end
