//
//  ChromeMenu.m
//  Ishimura
//
//  Created by Maksym on 7/3/13.
//  Copyright (c) 2013 Maksym Stefanchuk. All rights reserved.
//

#import "CMMenu.h"
#import "CMMenuItem.h"
#import "CMMenuItemView.h"
#import "CMMenu+InternalMethods.h"
#import "CMMenuItem+InternalMethods.h"
#import "CMMenuItemView+InternalMethods.h"
#import "CMWindowController.h"
#import "CMMenuKeyEventInterpreter.h"
#import "CMDebug.h"
#include <stdlib.h>		// malloc

#define CMMENU_PADDING_TO_SCREEN_EDGES 6

// Posting notification types
NSString * const CMMenuDidBeginTrackingNotification = @"CMMenuDidBeginTrackingNotification";
NSString * const CMMenuDidEndTrackingNotification = @"CMMenuDidEndTrackingNotification";
NSString * const CMMenuSuspendStatusDidChangeNotification = @"CMMenuSuspendStatusDidChangeNotification";



typedef struct {
	int active;
	NSPoint event_origin;
	NSRect item_rect;
	NSRect menu_rect;
	NSRect submenu_rect;
	CMMenuAlignment menu_horizontal_alignment;		// left or right
	CMMenuAlignment submenu_vertical_alignment;
	NSPoint last_mouse_location;
	NSTimeInterval timestamp;
	NSTimeInterval timeLeftMenuBounds;
	NSTimer *timer;
	/* Alpha - corner of triangle lying in direction the menu is aligned. For example,
		if menu is aligned top the triangle will be at the bottom of the Parent Menu Item. */
	CGFloat tanAlpha;
	/* Beta - corner of the triangle at the opposite side */
	CGFloat tanBeta;
	CGFloat averageVelocity;
	CGFloat averageDeltaX;
	
} tracking_event_t;



/*
 * Private class declarations
 */
@interface CMMenu ()
{
	CMWindowController *_underlyingWindowController;
	
	CMMenuItem *_parentItem;
	BOOL _isActive;
	BOOL _isAttachedToStatusItem;
	BOOL _isPopUpMenu;
	NSRect _statusItemRect;
	NSPoint _popupLocation;
	CMMenu *_activeSubmenu;
	BOOL _needsDisplay;		// underlying window with item views will be recalculated
	
	CMMenuAlignment _menuHorizontalAlignment;
	CMMenuAlignment _menuVerticalAlignment;
	CGFloat _minimumWidth;
	NSSize _size;
	CGFloat _borderRadius;
	
	BOOL _isTrackingSubmenu;
	BOOL _cancelsTrackingOnAction;
	BOOL _cancelsTrackingOnMouseEventOutsideMenus;
	BOOL _receiveMouseMovedEvents;
	NSUInteger _eventBlockingMask;
	tracking_event_t *_tracking_event;

	id _globalEventMonitor;
	id<CMMenuDelegate> _delegate;
}


- (void)reloadData;
- (void)showWithOptions:(CMMenuOptions)options;

/**
 * @abstract Display menu in frame
 * @param frameRect Frame for a menu. Use NSZeroRect for a menu to automatically
 *	calculate best frame.
 * @param options Options to display menu with.
 * @param display (BOOL) Specified whether any of the underlying views has changed
 *	and the underlying Document View of NSScrollView needs to be updated.
 */
- (void)displayInFrame:(NSRect)frameRect options:(CMMenuOptions)options display:(BOOL)display;

/**
 * @function getBestFrameForMenuWindow
 * @abstract Returns the frame in screen coordinates in which menu will be drawn.
 * @discussion Depending on the position of menu's parent item and the proximity to the screen 
 *		menu can be positioned either from the left or from the right of it, aligned to the top or to the bottom.
 * @result Frame in screen coordinates.
 */
- (NSRect)getBestFrameForMenuWindow;

/**
 * @discussion If provided item is not in menu's visible area, move it so the item becomes completely visible.
 * @param item Menu item to make visible.
 * @param ignoreMouse When menu visible area is moved into new position this option defines whether the item
 *	currently lying underneath mouse cursor should be selected. More info on this option is in
 *	[CMWindownController moveVisibleRectToRect:ignoreMouse:].
 * @see [CMWindownController moveVisibleRectToRect:ignoreMouse:]
 */
- (void)moveVisibleAreaToDisplayItem:(CMMenuItem *)item ignoreMouse:(BOOL)ignoreMouse updateTrackingPrimitives:(BOOL)updateTrackingPrimitives;

- (void)submenuTrackingLoop:(NSTimer *)timer;

- (void)selectPreviousItemAndShowSubmenu:(BOOL)showSubmenu;
- (void)selectNextItemAndShowSubmenu:(BOOL)showSubmenu;
- (void)selectFirstItemAndShowSubmenu:(BOOL)showSubmenu;
//- (void)selectLastItemAndShowSubmenu:(BOOL)showSubmenu;

@end


@implementation CMMenu

// Dedicated initializer method
- (id)initWithTitle:(NSString *)aTitle {
	if (aTitle == nil) {
		[NSException raise:NSInvalidArgumentException format:@"nil provided as title for menu."];
		return nil;
	}
	
	self = [super init];
	if (self) {
		_title = [aTitle copy];
		_needsDisplay = YES;
		_cancelsTrackingOnAction = YES;
		_cancelsTrackingOnMouseEventOutsideMenus = YES;
		_menuHorizontalAlignment = CMMenuAlignedLeft;
		_menuVerticalAlignment = CMMenuAlignedTop;
		_menuItems = [[NSMutableArray alloc] init];
		_borderRadius = 5.0;	// default border radius

		_receiveMouseMovedEvents = NO;
	}
	return self;
}


- (id)init {
	return [self initWithTitle:@""];
}

//- (id)initWithItems:(NSArray *)items {
//	if (self = [super init]) {
//		[NSBundle loadNibNamed:[self className] owner:self];
//		menuItems = items;
//		[menuItems retain];
//		[menuTableView reloadData];
//	}
//	return self;
//}


- (void)dealloc {
	[_title release];
	[_menuItems release];
	[_underlyingWindowController release];
	
	[super dealloc];
}


- (NSString *)title {
	return _title;
}


- (void)setTitle:(NSString *)aString {
	_title = [aString copy];
}


- (CMMenu *)supermenu {
	return _supermenu;
}


- (CMMenuItem *)itemAtIndex:(NSInteger)index {
	if ( !_menuItems || index < 0 || (NSUInteger)index >= [_menuItems count])
		return nil;
	
//	if (index < 0 || index >= [_menuItems count])
//		[NSException raise:NSRangeException format:@"No item for -itemAtIndex: %ld", index];
	return [_menuItems objectAtIndex:(NSUInteger)index];
}


- (CMMenuItem *)itemAtPoint:(NSPoint)aPoint {
	aPoint = [self convertPointFromScreen:aPoint];
	NSViewController *viewController = [_underlyingWindowController viewAtPoint:aPoint];
	if (viewController)
		return [viewController representedObject];
	else
		return nil;
}


- (NSArray *)itemArray {
	return _menuItems;
}


- (NSInteger)numberOfItems {
	return (NSInteger)[_menuItems count];
}


- (CMMenuItem *)parentItem {
	return (_parentItem) ? _parentItem : nil;
}

- (NSInteger)indexOfItem:(CMMenuItem *)item {
	if (! item)
		return -1;
	
	NSUInteger i;
	NSUInteger count = [_menuItems count];
	
	if (! count)
		return -1;
	
	for (i = 0; i < count; ++i) {
		if (item == [_menuItems objectAtIndex:i]) {
			return (NSInteger)i;
		}
	}
	
	return -1;
}


/*
 *
 */
- (void)insertItem:(CMMenuItem *)newItem atIndex:(NSUInteger)index animate:(BOOL)animate {
	if (newItem == nil)
		[NSException raise:NSInvalidArgumentException format:@"nil provided as Menu Item object."];

	if (index > [_menuItems count])
		[NSException raise:NSInvalidArgumentException format:@"Provided index is greater then the number of elements in Menu during -insertItem:atIndex:"];
	
	XLog3("Adding menu item: %@", newItem);
	
	[_menuItems insertObject:newItem atIndex:index];
	[newItem setMenu:self];
	if ([newItem hasSubmenu])
		[[newItem submenu] setSupermenu:self];
	
	// Menu will update our newly added item itself
	if (_needsDisplay)
		return;
	
	// ..otherwise, we need to update it ourselves.
	NSViewController *viewController = [self viewForItem:newItem];
	[newItem setRepresentedView:viewController];
	[viewController setRepresentedObject:newItem];
	
	if (! _isActive)
		animate = NO;
	
	[_underlyingWindowController insertView:viewController atIndex:index animate:animate];
	if (_isActive)
		[self displayInFrame:NSZeroRect options:CMMenuOptionUpdateScrollers | CMMenuOptionUpdateTrackingPrimitives display:NO];
}


/*
 *
 */
- (void)addItem:(CMMenuItem *)newItem {
	if (newItem == nil)
		[NSException raise:NSInvalidArgumentException format:@"nil provided as Menu Item object."];
	
	[self insertItem:newItem atIndex:[_menuItems count] animate:NO];
}


/*
 *
 */
- (void)addItem:(CMMenuItem *)newItem animate:(BOOL)animate {
	if (newItem == nil)
		[NSException raise:NSInvalidArgumentException format:@"nil provided as Menu Item object."];

	[self insertItem:newItem atIndex:[_menuItems count] animate:animate];
}


/*
 *
 */
- (void)removeItemAtIndex:(NSInteger)index animate:(BOOL)animate {
	NSUInteger itemsCount = [_menuItems count];
	if (index < 0 || (NSUInteger)index >= itemsCount) {
		[NSException raise:NSInvalidArgumentException format:@"Provided index out of bounds for Menu's -removeItemAtIndex:"];
		return;
	}
	
	NSUInteger i = (NSUInteger)index;
	CMMenuItem *item = [_menuItems objectAtIndex:i];
	if ([item hasSubmenu]) {
		if ([[item submenu] isActive])
			[[item submenu] cancelTrackingWithoutAnimation];
		[[item submenu] setParentItem:nil];
		[[item submenu] setSupermenu:nil];
		[item setSubmenu:nil];
	}
	XLog3("Removing menu item: %@", item);
	[_menuItems removeObjectAtIndex:i];
	--itemsCount;
	
	// Menu will update items itself
	if (_needsDisplay)
		return;

	if (animate && _isActive) {
		[_underlyingWindowController removeViewAtIndex:i animate:YES complitionHandler:^(void) {
			if (! itemsCount) {		// no items left in menu, hide it
				[self cancelTrackingWithoutAnimation];
			} else {
				if (_isActive)		// if menu hasn't been hidden during animation
					[self displayInFrame:NSZeroRect options:CMMenuOptionUpdateScrollers | CMMenuOptionUpdateTrackingPrimitives display:NO];
			}
		}];
	} else {
		[_underlyingWindowController removeViewAtIndex:i];
		if (_isActive) {
			if (! itemsCount) {
				[self cancelTrackingWithoutAnimation];
			} else {
//				if (_isActive)
				[self displayInFrame:NSZeroRect options:CMMenuOptionUpdateScrollers | CMMenuOptionUpdateTrackingPrimitives display:NO];
			}
		}

	}
}


/*
 *
 */
- (void)removeItem:(CMMenuItem *)item animate:(BOOL)animate {
	if (! item) {
		[NSException raise:NSInvalidArgumentException format:@"nil provided for Menu -removeItem:"];
		return;
	}
	
	NSUInteger i;
	NSUInteger count = [_menuItems count];
	
	if (! count)
		return;
	
	for (i = 0; i < count; ++i) {
		if (item == [_menuItems objectAtIndex:i]) {
			[self removeItemAtIndex:(NSInteger)i animate:animate];
			break;
		}
	}
}


/*
 *
 */
- (void)removeItemsAtIndexes:(NSIndexSet *)indexes {
	__block NSUInteger itemsCount = [_menuItems count];
	if (! itemsCount) {
		[NSException raise:NSInvalidArgumentException format:@"Removing items from empty Menu at -removeItemsAtIndexes:"];
		return;
	}
	if ([indexes indexGreaterThanOrEqualToIndex:itemsCount] != NSNotFound) {
		[NSException raise:NSRangeException format:@"Indexes out of bounds at CMMenu -removeItemsAtIndexes:"];
		return;
	}
	
	
	[indexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
		// See if any of the removing items has submenus
		--itemsCount;
		CMMenuItem *item = [_menuItems objectAtIndex:idx];
		if ([item hasSubmenu]) {
			if ([[item submenu] isActive])
				[[item submenu] cancelTrackingWithoutAnimation];
			[[item submenu] setParentItem:nil];
			[[item submenu] setSupermenu:nil];
			[item setSubmenu:nil];
		}
		XLog3("Removing menu item: %@", item);
	}];
	
	[_menuItems removeObjectsAtIndexes:indexes];

	
	// Menu will update items itself
	if (_needsDisplay)
		return;
	
	__block NSUInteger offset = 0;
	[indexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
		[_underlyingWindowController removeViewAtIndex:(idx - offset)];
		++offset;
	}];
	
	if (_isActive) {
		if (! itemsCount)
			[self cancelTrackingWithoutAnimation];
		else
			[self displayInFrame:NSZeroRect options:CMMenuOptionUpdateScrollers | CMMenuOptionUpdateTrackingPrimitives display:NO];
	}
}


/*
 *
 */
- (void)setSubmenu:(CMMenu *)aMenu forItem:(CMMenuItem *)anItem {
//	if (aMenu == nil || anItem == nil)
	if (anItem == nil)
		[NSException raise:NSInvalidArgumentException format:@"Bad argument in -%@", NSStringFromSelector(_cmd)];
	
	// pass to Menu Item method
	[anItem setSubmenu:aMenu];
}


/*
 *
 */
- (void)showWithOptions:(CMMenuOptions)options {
	// Check if menu delegate want to update menu
	if (_delegate) {
		if ([_delegate respondsToSelector:@selector(menuNeedsUpdate:)]) {
			[_delegate performSelector:@selector(menuNeedsUpdate:) withObject:self];
		}
	}
	
	if (! _underlyingWindowController) {
		_underlyingWindowController = [[CMWindowController alloc] initWithOwner:self];
		[self reloadData];
		_needsDisplay = NO;
	}
	
	[self displayInFrame:NSZeroRect options:options display:NO];
	_isActive = YES;
	
	if (! _supermenu) {
		_globalEventMonitor = [NSEvent addGlobalMonitorForEventsMatchingMask:NSLeftMouseDownMask | NSRightMouseDownMask | NSOtherMouseDownMask handler:^(NSEvent *theEvent) {
			[self cancelTracking];
		}];
		

		if (! [NSApp isActive]) {		// otherwise NSApp will not recieve events
			[NSApp activateIgnoringOtherApps:YES];
		}
		
		// Use workspace to monitor if app gets deactived (e.g. by Command + Tab)
		// Cannot use NSApplicationDidResignActiveNotification as it doesn't work in NSEventTRackingRunLoopMode
		[[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self
															   selector:@selector(didDeactivateApplicationNotificationHandler:)
																   name:NSWorkspaceDidDeactivateApplicationNotification
																 object:nil];
		
		[[NSNotificationCenter defaultCenter] postNotificationName:CMMenuDidBeginTrackingNotification object:self];

		// root menu begins tracking immediately as it appears.
		// Submenus begin tracking only after the mouse enters its rect in tracking loop or
		// on other occasions, primarily when navigation with keyboard.
		[self beginTrackingWithEvent:nil options:CMMenuOptionDefaults];
	}
}


/*
 *
 */
- (void)showAsSubmenuOf:(CMMenuItem *)menuItem withOptions:(CMMenuOptions)options {
	[[menuItem menu] setActiveSubmenu:self];
//	_parentItem = menuItem;
	[self showWithOptions:options];
}



/*
 *
 */
- (void)popUpMenuForStatusItemWithRect:(NSRect)rect {
	if (_isActive)
		return;

	_isAttachedToStatusItem = YES;
	_statusItemRect = rect;
	[self showWithOptions:CMMenuOptionDefaults];
}


- (BOOL)popUpMenuPositioningItem:(NSMenuItem *)item atLocation:(NSPoint)location inView:(NSView *)view {
	// this method needs to be properly implemented
	// for now it's a temporary quick use
	_isPopUpMenu = YES;
	_popupLocation = location;
	[self showWithOptions:CMMenuOptionDefaults];
	return NO;
}



/*
 *
 */
- (void)cancelTracking {
	if (_activeSubmenu) {
		[_activeSubmenu cancelTracking];
	}
	
	[self endTracking];

	
	[_underlyingWindowController fadeOutWithComplitionHandler:^(void) {
		if ([_menuItems count])
			[self moveVisibleAreaToDisplayItem:[_menuItems objectAtIndex:0] ignoreMouse:YES updateTrackingPrimitives:NO];
		
		[_underlyingWindowController hide];
		
		CMMenuItem *selectedItem = [self highlightedItem];
		if (selectedItem)
			[selectedItem deselect];
		
		if (_supermenu) {
			[_supermenu setActiveSubmenu:nil];
			[_parentItem deselect];
		} else {	// root menu
//			NSNotification *notification = [NSNotification notificationWithName:CMMenuDidEndTrackingNotification object:self];
			[[NSNotificationCenter defaultCenter] postNotificationName:CMMenuDidEndTrackingNotification object:self];
		}
	}];

	_isActive = NO;
	_isAttachedToStatusItem = NO;
	_isPopUpMenu = NO;
	// Reset event blocking mask back to zero
	_eventBlockingMask = 0;
	
	if (! _supermenu) {
		if (_globalEventMonitor) {
			[NSEvent removeMonitor:_globalEventMonitor];
			_globalEventMonitor = nil;
		}
		
//		[[[NSWorkspace sharedWorkspace] notificationCenter] removeObserver:self name:NSWorkspaceDidDeactivateApplicationNotification object:self];
		[[[NSWorkspace sharedWorkspace] notificationCenter] removeObserver:self];
	}
}


/*
 *
 */
- (void)cancelTrackingWithoutAnimation {
	if (_activeSubmenu) {
		[_activeSubmenu cancelTrackingWithoutAnimation];
	}
	
	[self endTracking];
	
	if ([_menuItems count])
		[self moveVisibleAreaToDisplayItem:[_menuItems objectAtIndex:0] ignoreMouse:YES updateTrackingPrimitives:NO];

	[_underlyingWindowController hide];
	_isActive = NO;
	_isAttachedToStatusItem = NO;
	_isPopUpMenu = NO;
	// Reset event blocking mask back to zero
	_eventBlockingMask = 0;
	
	CMMenuItem *selectedItem = [self highlightedItem];
	if (selectedItem)
		[selectedItem deselect];
	
	if (_supermenu) {
		[_supermenu setActiveSubmenu:nil];
		[_parentItem deselect];
	} else {
		if (_globalEventMonitor) {
			[NSEvent removeMonitor:_globalEventMonitor];
			_globalEventMonitor = nil;
		}
		
//		[[[NSWorkspace sharedWorkspace] notificationCenter] removeObserver:self name:NSWorkspaceDidDeactivateApplicationNotification object:self];
		[[[NSWorkspace sharedWorkspace] notificationCenter] removeObserver:self];
		[[NSNotificationCenter defaultCenter] postNotificationName:CMMenuDidEndTrackingNotification object:self];
	}
}


/*
 *
 */
- (void)didDeactivateApplicationNotificationHandler:(NSNotification *)notification {
	NSRunningApplication *deactivatedApp = [[notification userInfo] objectForKey:NSWorkspaceApplicationKey];
	NSLog(@"did deactive application, current: %@, deactivated: %@", [NSRunningApplication currentApplication], deactivatedApp);
	if ([[NSRunningApplication currentApplication] isEqual:deactivatedApp]) {
		[self cancelTracking];
	}
}


- (BOOL)cancelsTrackingOnAction {
	return _cancelsTrackingOnAction;
}


- (void)setCancelsTrackingOnAction:(BOOL)cancels {
	_cancelsTrackingOnAction = cancels;
}


- (BOOL)cancelsTrackingOnMouseEventOutsideMenus {
	return _cancelsTrackingOnMouseEventOutsideMenus;
}


- (void)setCancelsTrackingOnMouseEventOutsideMenus:(BOOL)cancels {
	_cancelsTrackingOnMouseEventOutsideMenus = cancels;
}


- (BOOL)menusSuspended {
	if (_eventBlockingMask)
		return YES;
	return ([self supermenu] && [[self supermenu] eventBlockingMask] != 0);
}


- (void)setSuspendMenus:(BOOL)suspend {
	BOOL changedStatus = NO;
	if (suspend) {
		// Receiving menu doesn't block itself. All others do.
		[self blockEventsMatchingMask:0];
		CMMenu *menu = [self supermenu];
		while (menu) {
			if (! [menu eventBlockingMask]) {
				[menu blockEventsMatchingMask:NSLeftMouseDownMask | NSRightMouseDownMask | NSOtherMouseDownMask | NSScrollWheelMask | NSMouseMovedMask | NSLeftMouseDraggedMask | NSRightMouseDraggedMask | NSOtherMouseDraggedMask];
				changedStatus = YES;
			}
			// These three additional event masks define whether menu exits suspend status
			// on mouse move/dragged
			// | NSLeftMouseDraggedMask | NSRightMouseDraggedMask | NSOtherMouseDraggedMask
			menu = [menu supermenu];
		}
	} else {
		CMMenu *menu = [self rootMenu];
		do {
			if ([menu eventBlockingMask]) {
				[menu blockEventsMatchingMask:0];
				changedStatus = YES;
			}
		} while ((menu = [menu activeSubmenu]));
	}
	
	if (changedStatus) {
		[[NSNotificationCenter defaultCenter] postNotificationName:CMMenuSuspendStatusDidChangeNotification
															object:self
														  userInfo:@{ @"newStatus" : [NSNumber numberWithBool:suspend] }];
	}
}

/*
 *
 */
- (NSEventMask)eventBlockingMask {
	return _eventBlockingMask;
}


- (void)blockEventsMatchingMask:(NSEventMask)mask {
	_eventBlockingMask = mask;
}

- (CMMenuItem *)highlightedItem {
	for (CMMenuItem *item in _menuItems) {
		if ([item isSelected])
			return item;
	}
	return nil;
}


- (id<CMMenuDelegate>)delegate {
	return _delegate;
}


- (void)setDelegate:(id<CMMenuDelegate>)anObject {
	[_delegate autorelease];
	_delegate = [anObject retain];
}


/*
 *
 */
- (void)showPopover:(NSPopover *)popover forItem:(CMMenuItem *)item preferredEdge:(NSRectEdge)preferredEdge {
	if (! popover) {
		[NSException raise:NSInvalidArgumentException format:@"nil provided for popover in -showPopover:forItem:"];
		return;
	}
	if (! item) {
		[NSException raise:NSInvalidArgumentException format:@"nil provided for item in -showPopover:forItem:"];
		return;
	}
	if ([_menuItems indexOfObject:item] == NSNotFound) {
		[NSException raise:NSInvalidArgumentException format:@"Provided item doesn't belong to the reciever's menu at -showPopover:forItem:"];
		return;
	}
	
	NSView *view = [(NSViewController *)[item representedView] view];
	[popover showRelativeToRect:[view bounds] ofView:view preferredEdge:preferredEdge];
}


/*
 *
 */
- (CGFloat)minimumWidth {
	return _minimumWidth;
}


- (void)setMinimumWidth:(CGFloat)width {
	_minimumWidth = width;
}


- (NSSize)size {
	return (_underlyingWindowController) ? _underlyingWindowController.window.frame.size : NSMakeSize(0, 0);
}


- (CGFloat)borderRadius {
	return _borderRadius;
}


- (void)setBorderRadius:(CGFloat)radius {
	_borderRadius = radius;
}


- (NSRect)frame {
	return (_underlyingWindowController) ? _underlyingWindowController.window.frame : NSMakeRect(0, 0, 10, 10);
}


- (NSRect)convertRectToScreen:(NSRect)aRect {
	return [[_underlyingWindowController window] convertRectToScreen:aRect];
}


- (NSPoint)convertPointToScreen:(NSPoint)aPoint {
	return [[_underlyingWindowController window] convertBaseToScreen:aPoint];
}


- (NSPoint)convertPointFromScreen:(NSPoint)aPoint {
	return [[_underlyingWindowController window] convertScreenToBase:aPoint];
}


/*
 *
 */
- (NSRect)getBestFrameForMenuWindow {
	NSRect frame;
	NSSize intrinsicSize = [_underlyingWindowController intrinsicContentSize];
	
//	NSLog(@"intrinsic size: %@", NSStringFromSize(intrinsicSize));
	
	// root menu
	if (! _parentItem) {
		// Root menu can be started only with a family of -popUpMenu.. methods.
		// Thus either location or positioning item is provided.
		NSScreen *screen = [[_underlyingWindowController window] screen];
		NSRect screenFrame = [screen frame];
		
		if (_isAttachedToStatusItem) {
			frame.size = intrinsicSize;
			frame.origin.y = _statusItemRect.origin.y - intrinsicSize.height;
			if (_statusItemRect.origin.x + intrinsicSize.width > NSMaxX(screenFrame)) {
				frame.origin.x = NSMaxX(screenFrame) - intrinsicSize.width;
			} else {
				frame.origin.x = _statusItemRect.origin.x;
			}
		} else {		// _isPopUpMenu
			// TODO: this part needs to be replaced with proper code
			// that will take into account screen size and paddings to screen
			// edge.
			frame.size = intrinsicSize;
			frame.origin = _popupLocation;
			if (NSMaxX(frame) > NSMaxX(screenFrame))
				frame.origin.x = NSMaxX(screenFrame) - intrinsicSize.width;
		}


//		frame.size.width = intrinsicSize.width;
//		frame.size.height = (intrinsicSize.height > 817) ? 825 : intrinsicSize.height;
//		frame.origin = NSMakePoint(70, screenFrame.size.height - frame.size.height - 50);
//		frame.size.height = 65;
		return frame;
	}
	
	
	NSPoint origin;
	NSSize size;
//	NSRect menuFrame = [self frame];
	NSRect supermenuFrame = [_supermenu frame];
//	NSRect parentItemFrame = [_supermenu frameOfItemRelativeToScreen:_parentItem];
	NSRect parentItemFrame = [_parentItem frameRelativeToScreen];
	NSScreen *screen = [[_underlyingWindowController window] screen];
	CGFloat menuPadding = [_underlyingWindowController verticalPadding];
	NSRect screenFrame = [screen frame];
	
	// Menu X coordinate
	if ([_supermenu horizontalAlignment] == CMMenuAlignedLeft) {
//		if ((screenFrame.size.width - NSMaxX(supermenuFrame)) < intrinsicSize.width) {
		if (NSMaxX(supermenuFrame) + intrinsicSize.width + CMMENU_PADDING_TO_SCREEN_EDGES > NSMaxX(screenFrame)) {
			origin.x = supermenuFrame.origin.x - intrinsicSize.width;
			_menuHorizontalAlignment = CMMenuAlignedRight;
		} else {
			origin.x = NSMaxX(supermenuFrame);
			_menuHorizontalAlignment = CMMenuAlignedLeft;
		}
	} else {
		if (NSMinX(supermenuFrame) - intrinsicSize.width - CMMENU_PADDING_TO_SCREEN_EDGES < NSMinX(screenFrame)) {
			origin.x = NSMaxX(supermenuFrame);
			_menuHorizontalAlignment = CMMenuAlignedLeft;
		} else {
			origin.x = supermenuFrame.origin.x - intrinsicSize.width;
			_menuHorizontalAlignment = CMMenuAlignedRight;
		}
	}
	
	// Menu Y coordinate
	// default menu alignment at top of parent item
	if (NSMaxY(parentItemFrame) - intrinsicSize.height + menuPadding >= screenFrame.origin.y) {
		origin.y = NSMaxY(parentItemFrame) - intrinsicSize.height + menuPadding;
		size.height = intrinsicSize.height;
		_menuVerticalAlignment = CMMenuAlignedTop;
	}
	// else if (parentItemFrame.origin.y < 27) {
	else {
//		origin.y = parentItemFrame.origin.y - menuPadding;		// TODO: also need to scroll content to bottom
		origin.y = CMMENU_PADDING_TO_SCREEN_EDGES;
		CGFloat statusBarThickness = [[NSStatusBar systemStatusBar] thickness];
		if (origin.y + intrinsicSize.height > screenFrame.size.height - statusBarThickness)
			size.height = screenFrame.size.height - statusBarThickness - origin.y;
		else
			size.height = intrinsicSize.height;
		_menuVerticalAlignment = CMMenuAlignedBottom;
	}
		
/*	else {
		origin.y = screenFrame.origin.y;
		size.height = parentItemFrame.origin.y + parentItemFrame.size.height + menuPadding;
		_menuVerticalAlignment = CMMenuAlignedTop;
	} */
	
	
	size.width = intrinsicSize.width;
	frame.origin = origin;
	frame.size = size;
	
	return frame;
}


/*
 * Based on Menu Items we create View Controllers and give them for drawing to Window Controller
 */
- (void)reloadData {
	NSMutableArray *viewControllers = [NSMutableArray array];
	
	for (CMMenuItem *menuItem in _menuItems) {
		NSViewController *viewController = [self viewForItem:menuItem];
		[menuItem setRepresentedView:viewController];
		[viewController setRepresentedObject:menuItem];
		[viewControllers addObject:viewController];

	}
	
	[_underlyingWindowController layoutViews:viewControllers];
}


/*
 *
 */
- (NSViewController *)viewForItem:(CMMenuItem *)menuItem {
	NSViewController *viewController;
	
	if ([menuItem isSeparatorItem]) {
		viewController = [[NSViewController alloc] initWithNibName:@"CMMenuItemSeparatorView" bundle:nil];
	} else {
		CMMenuItemView *view;
		
		if ([menuItem icon]) {
			viewController = [[NSViewController alloc] initWithNibName:@"CMMenuItemIconView" bundle:nil];
			view = (CMMenuItemView *)viewController.view;
			[[view icon] setImage:[menuItem icon]];
		} else {
			viewController = [[NSViewController alloc] initWithNibName:@"CMMenuItemView" bundle:nil];
			view = (CMMenuItemView *)viewController.view;
		}
		
		if ([menuItem state] != NSOffState) {
			NSImage *stateImage = ([menuItem state] == NSOnState) ? [menuItem onStateImage] : [menuItem mixedStateImage];
			[[view state] setImage:stateImage];
		}
		
		[[view title] setStringValue:[menuItem title]];
		
		if ([menuItem hasSubmenu])
			[view setHasSubmenuIcon:YES];

		if ([menuItem indentationLevel])
			[view setIndentationLevel:[menuItem indentationLevel]];
		
		[view setEnabled:[menuItem isEnabled]];
	}

	return [viewController autorelease];
}




#pragma mark -
#pragma mark ***** CMMenu Internal Methods *****


- (void)performActionForItem:(CMMenuItem *)item {
	if ([item hasSubmenu])
		return;
	
	SEL action = [item action];
	if (action && [item isEnabled]) {
		id target = [item target];
		if (! target) {		// application delegate could be the one to handle it
			target = [(NSApplication *)NSApp delegate];
		}
		
		if ([target respondsToSelector:action]) {
			XLog2("Performing action on item: %@", item);
			//			[target performSelector:action withObject:item afterDelay:0.15 inModes:[NSArray arrayWithObject:NSRunLoopCommonModes]];
			[NSApp sendAction:action to:target from:item];
		}
	}
	
	
	if ([self cancelsTrackingOnAction]) {
		if ( ![item isSeparatorItem] && [item isEnabled]) {
			CMMenu *menu = self;
			CMMenu *rootMenu;
			do {
				[menu endTracking];
				rootMenu = menu;
			} while ((menu = [menu supermenu]));
			
			CMMenuItemView *view = (CMMenuItemView *)[[item representedView] view];
			[view blink];
			[rootMenu performSelector:@selector(cancelTracking) withObject:nil afterDelay:0.075 inModes:[NSArray arrayWithObject:NSRunLoopCommonModes]];
		} else {
			[[self rootMenu] cancelTracking];
		}
	}
}


- (CMMenu *)rootMenu {
	CMMenu *menu = self;
	CMMenu *supermenu = menu;
	while ((menu = [menu supermenu]))
		supermenu = menu;
	
	return supermenu;
}


- (void)setNeedsDisplay:(BOOL)needsDisplay {
	if (_needsDisplay == needsDisplay)
		return;
	
	CMMenuOptions options = CMMenuOptionDefaults;
	if ([self isTracking])
		options |= CMMenuOptionUpdateTrackingPrimitives;
		
	if (needsDisplay && _isActive)
		[self displayInFrame:NSZeroRect options:options display:YES];
}


- (BOOL)needsDisplay {
	return _needsDisplay;
}


- (void)setSupermenu:(CMMenu *)aMenu {
	_supermenu = aMenu;
}


- (void)setParentItem:(CMMenuItem *)anItem {
	_parentItem = anItem;
}


- (BOOL)isActive {
	return _isActive;
}


- (void)setIsActive:(BOOL)isActive {
	_isActive = isActive;
}


- (CMMenu *)activeSubmenu {
	return _activeSubmenu;
}


- (void)setActiveSubmenu:(CMMenu *)submenu {
	_activeSubmenu = submenu;
}


- (BOOL)isAttachedToStatusItem {
	return _isAttachedToStatusItem;
}


- (NSRect)statusItemRect {
	return _statusItemRect;
}


- (void)displayInFrame:(NSRect)frameRect options:(CMMenuOptions)options display:(BOOL)display {
	if (display || _needsDisplay) {
		[_underlyingWindowController updateDocumentView];
		_needsDisplay = NO;
	}
	
	if (NSEqualRects(frameRect, NSZeroRect)) {
		// Store current horizontal alignment. For example, if menu was aligning to
		// parent menu with its left side and after -getBestFrameForMenuWindow
		// method call (if there was not enough room on screen) the menu changed to
		// align with its right side, it is necessary in such a situation to redraw
		// underlying window view to account new corner positions.
		CMMenuAlignment horizontalAlignement = _menuHorizontalAlignment;
		NSRect frame = [self getBestFrameForMenuWindow];
		NSNumber *radius = [NSNumber numberWithDouble:_borderRadius];
		
		if (_isAttachedToStatusItem) {
			// Do not worry if menu was previously drawn with correct corners.
			// View will be re-drawn only when radiuses indeed change.
			[_underlyingWindowController setBorderRadiuses:@[radius, @0, @0, radius]];
		} else if (_isPopUpMenu) {
			[_underlyingWindowController setBorderRadiuses:@[radius, radius, radius, radius]];
		} else if (horizontalAlignement != _menuHorizontalAlignment) {
			if (_menuHorizontalAlignment == CMMenuAlignedLeft)
				[_underlyingWindowController setBorderRadiuses:@[radius, @0, radius, radius]];	// top left corner is square
			else
				[_underlyingWindowController setBorderRadiuses:@[radius, radius, @0, radius, radius]];	// top right corner is square
		}
		
		[_underlyingWindowController displayInFrame:frame options:options];
	} else {
		[_underlyingWindowController displayInFrame:frameRect options:options];
	}
	
	if ([self activeSubmenu])
		[[self activeSubmenu] displayInFrame:NSZeroRect options:CMMenuOptionDefaults display:NO];
}


/*
 *
 */
- (CMMenu *)menuAtPoint:(NSPoint)location {
	CMMenu *menu = [self rootMenu];
	do {
		if (NSPointInRect(location, [menu frame])) {
			return menu;
		}
	} while ((menu = [menu activeSubmenu]));
	
	return  nil;
}


- (CMMenuAlignment)horizontalAlignment {
	return _menuHorizontalAlignment;
}


- (CMMenuAlignment)verticalAlignment {
	return _menuVerticalAlignment;
}


- (CMWindowController *)underlyingWindowController {
	return _underlyingWindowController;
}


- (NSInteger)windowLevel {
	return (_underlyingWindowController) ? _underlyingWindowController.window.level : 0;
}


- (CMMenuScroller *)scrollerAtPoint:(NSPoint)aPoint {
	aPoint = [self convertPointFromScreen:aPoint];
	return [_underlyingWindowController scrollerAtPoint:aPoint];
}


- (void)scrollWithActiveScroller:(CMMenuScroller *)scroller {
	[_underlyingWindowController scrollWithActiveScroller:scroller];
}


- (void)moveVisibleAreaToDisplayItem:(CMMenuItem *)item ignoreMouse:(BOOL)ignoreMouse updateTrackingPrimitives:(BOOL)updateTrackingPrimitives {
	[_underlyingWindowController moveVisibleRectToRect:[item frame] ignoreMouse:ignoreMouse updateTrackingPrimitives:updateTrackingPrimitives];
}


#pragma mark -
#pragma mark ***** Menu Tracking *****


- (BOOL)isTracking {
	return [_underlyingWindowController isTracking];
}


- (void)beginTrackingWithEvent:(NSEvent *)theEvent options:(CMMenuOptions)options {
	[_underlyingWindowController beginTrackingWithEvent:theEvent options:options];
}


- (void)endTracking {
	[_underlyingWindowController endTracking];
}


- (BOOL)isTrackingSubmenu {
	return _isTrackingSubmenu;
}


/*
 *
 */
- (void)mouseEventAtLocation:(NSPoint)mouseLocation type:(NSEventType)eventType {

	if (eventType == NSMouseEntered) {
		NSLog(@"mouse ENTER menu: %@", [self title]);
		
		/*
		 * Possible Events:
		 * 1. Mouse entered a menu when it is showing a submenu:
		 *		a. mouse hovered submenu's parent item (returned from submenu);
		 *		b. mouse hovered other area;
		 * 2. Mouse entered submenu when it was being tracked by the supermenu.
		 */
		
		CMMenuItem *mousedItem = [self itemAtPoint:mouseLocation];
		NSLog(@"moused item %@", mousedItem);
		if (_activeSubmenu) {				// 1.
			if (mousedItem && mousedItem == [_activeSubmenu parentItem]) {	// 1.a
				if ([_activeSubmenu activeSubmenu])							// if submenu has active submenus -- close them
					[[_activeSubmenu activeSubmenu] cancelTrackingWithoutAnimation];
			} else
				[_activeSubmenu cancelTrackingWithoutAnimation];		// 1.b.
		} else if (_supermenu && [_supermenu isTrackingSubmenu]) {		// 2.
			[_supermenu stopTrackingSubmenuReasonSuccess:YES];
		} else {
			CMMenuItem *selectedItem = [self highlightedItem];
			if (selectedItem && selectedItem != mousedItem)
				[selectedItem deselect];
		}
		
		
	} else if (eventType == NSMouseExited) {
		
		
	} else if (eventType == NSLeftMouseDown || eventType == NSRightMouseDown || eventType == NSOtherMouseDown) {
		// Find a menu of event
		CMMenu *menu = self;
		do {
			if (NSPointInRect(mouseLocation, [menu frame]))
				break;
		} while ((menu = [menu supermenu]));
		[menu rearrangeStateForNewMouse:mouseLocation];
		
	} else if (eventType == NSLeftMouseUp || eventType == NSRightMouseUp || eventType == NSOtherMouseUp) {
		// Find a menu of event
		CMMenu *menu = self;
		do {
			if (NSPointInRect(mouseLocation, [menu frame]))
				break;
		} while ((menu = [menu supermenu]));
		
		
		if ([menu eventBlockingMask]) {
			[menu setSuspendMenus:NO];
			[menu rearrangeStateForNewMouse:mouseLocation];
		} else {
			CMMenuItem *item = [menu itemAtPoint:mouseLocation];
			if (item)
				[menu performActionForItem:item];
		}
		
		
	} else if (eventType == NSMouseMoved) {
		CMMenu *menu = self;
		do {
			[menu setReceivesMouseMovedEvents:NO];
			if (NSPointInRect(mouseLocation, [menu frame]))
				break;
		} while ((menu = [menu supermenu]));

		XLog3("Mouse MOVED in menu:\n\tMenu frame that owns RunLoop: %@,\n\tMenu frame with mouse: %@, \n\tMouse location: %@",
			  NSStringFromRect([self frame]),
			  NSStringFromRect([menu frame]),
			  NSStringFromPoint(mouseLocation));

		[menu rearrangeStateForNewMouse:mouseLocation];
	}
	
}


/*
 *
 */
- (void)rearrangeStateForNewMouse:(NSPoint)mouseLocation {
	CMMenuItem *selectedItem = [self highlightedItem];
	CMMenuItem *mousedItem = [self itemAtPoint:mouseLocation];

	
	if ([self activeSubmenu]) {
		if (mousedItem == [[self activeSubmenu] parentItem]) {
			CMMenu *activeSubmenuOfSubmenu = [[self activeSubmenu] activeSubmenu];
			if (activeSubmenuOfSubmenu) {
				[activeSubmenuOfSubmenu cancelTrackingWithoutAnimation];
			} else {
				CMMenuItem *item = [[self activeSubmenu] highlightedItem];
				if (item)
					[item deselect];
			}
			[[self activeSubmenu] endTracking];
		} else {
			[[self activeSubmenu] cancelTrackingWithoutAnimation];
			if (mousedItem != selectedItem)
				[mousedItem selectWithDelayForSubmenu:SUBMENU_POPUP_DELAY_DEFAULT];
		}
	} else {
		if (mousedItem && ![mousedItem isSeparatorItem] && [mousedItem isEnabled]) {
			CGFloat delay = (mousedItem == selectedItem) ? SUBMENU_POPUP_NO_DELAY : SUBMENU_POPUP_DELAY_DEFAULT;
			[mousedItem selectWithDelayForSubmenu:delay];
		} else
			[selectedItem deselect];
	}
	
	if (! mousedItem) {
		CMMenuScroller *scroller = [self scrollerAtPoint:mouseLocation];
		if (scroller)
			[self performSelector:@selector(scrollWithActiveScroller:) withObject:scroller afterDelay:0.15 inModes:[NSArray arrayWithObject:NSRunLoopCommonModes]];
	}
}




- (void)startTrackingSubmenu:(CMMenu *)submenu forItem:(CMMenuItem *)item {
	_isTrackingSubmenu = YES;
	
	_tracking_event = (tracking_event_t *)malloc(sizeof(tracking_event_t));
	if (_tracking_event == 0) {
		fputs("Memory exhausted", stderr);
		exit(EXIT_FAILURE);
	}
	
	
	NSPoint mouseLocation = [NSEvent mouseLocation];
	_tracking_event->event_origin = mouseLocation;
	_tracking_event->last_mouse_location = mouseLocation;
	_tracking_event->item_rect = [item frameRelativeToScreen];
	_tracking_event->menu_rect = [self frame];
	_tracking_event->submenu_rect = [submenu frame];
	_tracking_event->menu_horizontal_alignment = [submenu horizontalAlignment];
	_tracking_event->submenu_vertical_alignment = [submenu verticalAlignment];
	_tracking_event->timestamp = [NSDate timeIntervalSinceReferenceDate];
	
	// We extend area a little to give users space for maneuver
	CGFloat extendHeight = 20;
	
	_tracking_event->tanAlpha = (NSMinY(_tracking_event->item_rect) - NSMinY(_tracking_event->submenu_rect) +
							extendHeight) / NSWidth(_tracking_event->item_rect);
	_tracking_event->tanBeta = (NSMaxY(_tracking_event->submenu_rect) - NSMaxY(_tracking_event->item_rect) +
							extendHeight) / NSWidth(_tracking_event->item_rect);

	_tracking_event->averageVelocity = 0;
	_tracking_event->averageDeltaX = 0;
	_tracking_event->timeLeftMenuBounds = 0;
	
	NSTimeInterval interval = 0.07;
//	NSLog(@" --------------------- CREATING SUBMENU TIMER ---------------------------- \n\n");
	_tracking_event->timer = [NSTimer timerWithTimeInterval:interval
													 target:self
												   selector:@selector(submenuTrackingLoop:)
												   userInfo:nil
													repeats:YES];
	[[NSRunLoop currentRunLoop] addTimer:_tracking_event->timer forMode:NSRunLoopCommonModes];
}


/**
 * Discussion.
 * Method can be called from locations:
 *	[self trackingLoop:] -- when any of the tracking criteria is satisfied;
 *	[CMMenuItem shouldChangeItemSelectionStatusForEvent:] -- when mouse returns to the original menu item.
 *
 */
- (void)stopTrackingSubmenuReasonSuccess:(BOOL)reasonSuccess {
	_isTrackingSubmenu = NO;
	
//	NSLog(@"STOP tracking menu: %@, submenu: %@. reason: %d", self, [self activeSubmenu], reasonSuccess);
	
	if (_tracking_event->timer) {
		[_tracking_event->timer invalidate];
//	[_tracking_event->timer release];
		_tracking_event->timer = nil;
	}
	
	if (_tracking_event) {
		free(_tracking_event);
		_tracking_event = NULL;
	}
	
	if (reasonSuccess == NO) {
		[_activeSubmenu cancelTrackingWithoutAnimation];
		if (NSPointInRect([NSEvent mouseLocation], [self frame])) {
			for (CMMenuItem *item in _menuItems)
				if ([item mouseOver]) {
					[item selectWithDelayForSubmenu:SUBMENU_POPUP_DELAY_AFTER_TRACKING];
					break;
				}
		}
	}
}


- (void)submenuTrackingLoop:(NSTimer *)timer {
	NSPoint mouseLocation = [NSEvent mouseLocation];
	NSTimeInterval timestamp = [NSDate timeIntervalSinceReferenceDate];

	tracking_event_t *event = _tracking_event;
	
	/* Mouse moved in the opposite direction to the submenu */
	if (event->menu_horizontal_alignment == CMMenuAlignedLeft) {
		if (mouseLocation.x < event->event_origin.x) {
			XLog2("Stop submenu tracking, reason: opposite direction");
			[self stopTrackingSubmenuReasonSuccess:NO];
			return;
		}
	} else if (mouseLocation.x > event->event_origin.x) {
		XLog2("Stop submenu tracking, reason: opposite direction");
		[self stopTrackingSubmenuReasonSuccess:NO];
		return;
	}
	
	
	
	CGFloat mouseTravelDistance = sqrt(pow((event->last_mouse_location.x - mouseLocation.x), 2) + pow((event->last_mouse_location.y - mouseLocation.y), 2));
	CGFloat mouseVelocity = mouseTravelDistance / (timestamp - event->timestamp);

	
	/* when mouse is moving too slowly */
	event->averageVelocity = (event->averageVelocity + mouseVelocity) / 2;
	if (event->averageVelocity < 60) {
		XLog2("Stop submenu tracking, reason: slow veloctiy");
		[self stopTrackingSubmenuReasonSuccess:NO];
		return;
	}
	
	
	/* mouse pointer has not left bounds of original menu */
	if ((event->menu_horizontal_alignment == CMMenuAlignedLeft && mouseLocation.x < NSMinX(event->submenu_rect)) || (event->menu_horizontal_alignment == CMMenuAlignedRight && mouseLocation.x > NSMaxX(event->submenu_rect))) {
		
		if (event->submenu_vertical_alignment == CMMenuAlignedTop) {
			if (mouseLocation.y < NSMinY(event->item_rect)) {				/* mouse went BELOW menu item */

				CGFloat widthLeg;
				BOOL mouseCloseToSubmenu;
				if (event->menu_horizontal_alignment == CMMenuAlignedLeft) {
					widthLeg = mouseLocation.x - NSMinX(event->item_rect);
					event->averageDeltaX = (mouseLocation.x - event->last_mouse_location.x + event->averageDeltaX) / 2;
					/* When mouse starts moving down closely to the submenu we can't expect much change in deltaX.
					   Let's give here some freedom */
					if ((mouseCloseToSubmenu = (NSMaxX(event->item_rect) - mouseLocation.x < 50)))
						event->averageDeltaX += 2;
				} else {
					widthLeg = NSMaxX(event->item_rect) - mouseLocation.x;
					event->averageDeltaX = (event->last_mouse_location.x - mouseLocation.x + event->averageDeltaX) / 2;
					if ((mouseCloseToSubmenu = (NSMinX(event->item_rect) - mouseLocation.x < 50)))
						event->averageDeltaX += 2;
				}
				
				if (((NSMinY(event->item_rect) - mouseLocation.y) / widthLeg) > event->tanAlpha) {
					XLog2("Stop submenu tracking, reason: bottom left hypotenuse crossed at loc.: %@", NSStringFromPoint(mouseLocation));
					[self stopTrackingSubmenuReasonSuccess:NO];
					return;
				}
				
				/* we calculate here how fast the mouse pointer is moving towards submenu using Delta X and mouse velocity.
				   Multiplier at the end makes it easier for moving the mouse the closer to menu you get. */
				CGFloat multiplier = (mouseCloseToSubmenu) ? (2.5 * widthLeg / NSWidth(event->item_rect)) : 1;
				CGFloat targetVector = event->averageVelocity * event->averageDeltaX * multiplier;
//				NSLog(@"Val: %f, deltaX: %f, close to submenu: %d", targetVector, event->averageDeltaX, mouseCloseToSubmenu);
				if (ABS(targetVector) < 1000) {
					XLog2("Stop submenu tracking, reason: moving not enough fast * correct direction.");
					[self stopTrackingSubmenuReasonSuccess:NO];
					return;
				}

			} else {				/* mouse went ABOVE menu item */
			
				CGFloat widthLeg;
				if (event->menu_horizontal_alignment == CMMenuAlignedLeft) {
					widthLeg = mouseLocation.x - NSMinX(event->item_rect);
					event->averageDeltaX = (mouseLocation.x - event->last_mouse_location.x + event->averageDeltaX) / 2;
				} else {
					widthLeg = NSMaxX(event->item_rect) - mouseLocation.x;
					event->averageDeltaX = (event->last_mouse_location.x - mouseLocation.x + event->averageDeltaX) / 2;
				}
				
				if ((mouseLocation.y  - NSMaxY(event->item_rect)) / widthLeg > event->tanBeta) {
					XLog2("Stop submenu tracking, reason: top left hypotenuse crossed at loc.: %@", NSStringFromPoint(mouseLocation));
					[self stopTrackingSubmenuReasonSuccess:NO];
					return;
				}
				
				CGFloat targetVector = event->averageVelocity * event->averageDeltaX;
//				NSLog(@"Val: %f, deltaX: %f", targetVector, averageDeltaX);
				if (ABS(targetVector) < 4000) {
					XLog2("Stop submenu tracking, reason: top direction moving not enough fast * correct direction.");
					[self stopTrackingSubmenuReasonSuccess:NO];
					return;
				}
			}

		} else {		// Menu aligned BOTTOM

			CGFloat widthLeg;
			BOOL mouseCloseToSubmenu;
			if (event->menu_horizontal_alignment == CMMenuAlignedLeft) {
				widthLeg = mouseLocation.x - NSMinX(event->item_rect);
				event->averageDeltaX = (mouseLocation.x - event->last_mouse_location.x + event->averageDeltaX) / 2;
				/* When mouse starts moving down closely to the submenu we can't expect much change in deltaX.
				 Let's give here some freedom */
				if ((mouseCloseToSubmenu = (NSMaxX(event->item_rect) - mouseLocation.x < 50)))
					event->averageDeltaX += 2;
			} else {
				widthLeg = NSMaxX(event->item_rect) - mouseLocation.x;
				event->averageDeltaX = (event->last_mouse_location.x - mouseLocation.x + event->averageDeltaX) / 2;
				if ((mouseCloseToSubmenu = (NSMinX(event->item_rect) - mouseLocation.x < 50)))
					event->averageDeltaX += 2;
			}
			
			BOOL mouseCrossedHypotenuse;
			if (mouseLocation.y < NSMinY(event->item_rect)) {		/* mouse went BELOW menu item */
				mouseCrossedHypotenuse = (((NSMinY(event->item_rect) - mouseLocation.y) / widthLeg) > event->tanAlpha);
			} else {
				mouseCrossedHypotenuse = (((mouseLocation.y - NSMaxY(event->item_rect)) / widthLeg) > event->tanBeta);
			}
			if (mouseCrossedHypotenuse) {
				XLog2("Stop submenu tracking, reason: (menu aligned BOTTOM) hypotenuse crossed at loc.: %@", NSStringFromPoint(mouseLocation));
				[self stopTrackingSubmenuReasonSuccess:NO];
				return;
			}
			
			/* we calculate here how fast the mouse pointer is moving towards submenu using Delta X and mouse velocity.
			 Multiplier at the end makes it easier for moving the mouse the closer to menu you get. */
			CGFloat multiplier = (mouseCloseToSubmenu) ? (2.5 * widthLeg / NSWidth(event->item_rect)) : 1;
			CGFloat targetVector = event->averageVelocity * event->averageDeltaX * multiplier;
//				NSLog(@"Val: %f, deltaX: %f, close to submenu: %d", targetVector, event->averageDeltaX, mouseCloseToSubmenu);
			if (ABS(targetVector) < 1000) {
				XLog2("Stop submenu tracking, reason: (menu aligned BOTTOM) moving not enough fast * correct direction.");
				[self stopTrackingSubmenuReasonSuccess:NO];
				return;
			}

		}

	} else {
		/* mouse left menu bounds, and obviously hasn't entered submenu */
		
//		if (event->submenu_vertical_alignment == CMMenuAlignedTop) {
			if (mouseLocation.y - NSMaxY(event->submenu_rect) > 60 || NSMinY(event->submenu_rect) - mouseLocation.y > 60) {
				XLog2("Stop submenu tracking, reason: mouse went vertically too far");
				[self stopTrackingSubmenuReasonSuccess:NO];
				return;
			}
//		} else {
			
//		}
	
		if (event->timeLeftMenuBounds == 0)
			event->timeLeftMenuBounds = timestamp;
		else if (timestamp - event->timeLeftMenuBounds > 0.5) {
			XLog2("Stop submenu tracking, reason: time elapsed while out of menu bounds.");
			[self stopTrackingSubmenuReasonSuccess:NO];
			return;
		}
	}

	XLog3("Submenu tracking loop stats:\n\tMouse location: %@\n\tVelocity: %f\n\tAverage velocity: %f",
		  NSStringFromPoint(mouseLocation),
		  mouseVelocity,
		  event->averageVelocity);
	
	event->timestamp = timestamp;
	event->last_mouse_location = mouseLocation;
}


- (void)updateTrackingPrimitiveForItem:(CMMenuItem *)item {
	[_underlyingWindowController updateTrackingPrimitiveForView:[item representedView] ignoreMouse:NO];
}



#pragma mark -
#pragma mark ****** Actions from Key Interpreter ******


- (void)moveUp:(NSEvent *)originalEvent {
	[self setReceivesMouseMovedEvents:YES];
//	[menu selectPreviousItemAndShowSubmenu:NO];
	if ([self activeSubmenu]) {
		CMMenuItem *selectedItem = [self highlightedItem];
		[[self activeSubmenu] cancelTrackingWithoutAnimation];
		[selectedItem select];
	}
	[self selectPreviousItemAndShowSubmenu:NO];
}


- (void)moveDown:(NSEvent *)originalEvent {
	[self setReceivesMouseMovedEvents:YES];
//	[menu selectNextItemAndShowSubmenu:NO];
	if ([self activeSubmenu]) {
		CMMenuItem *selectedItem = [self highlightedItem];
		[[self activeSubmenu] cancelTrackingWithoutAnimation];
		[selectedItem select];
	}
	[self selectNextItemAndShowSubmenu:NO];
}


- (void)moveLeft:(NSEvent *)originalEvent {
	if ([self supermenu]) {
		CMMenuItem *parentItem = [[self supermenu] highlightedItem];
		[self cancelTrackingWithoutAnimation];
		// Cancel tracking also deseclects submenu parent item. Let us select it back
		[parentItem select];
	} else if ([self activeSubmenu]) {
		[self setReceivesMouseMovedEvents:YES];
		CMMenuItem *parentItem = [self highlightedItem];
		[[self activeSubmenu] cancelTrackingWithoutAnimation];
		// Cancel tracking also deseclect submenu parent item. Let us select it back
		[parentItem select];
	}
}


- (void)moveRight:(NSEvent *)originalEvent {
	CMMenuItem *selectedItem = [self highlightedItem];
	if (selectedItem) {
		if ([selectedItem hasSubmenu]) {
			CMMenu *submenu = [selectedItem submenu];
			[submenu showAsSubmenuOf:selectedItem withOptions:CMMenuOptionIgnoreMouse];
			CMMenuItem *firstItem = [submenu itemAtIndex:0];
			if (firstItem) {
				[firstItem select];
			}
			
			// TODO: submenu?
			[self setReceivesMouseMovedEvents:YES];
			[submenu setReceivesMouseMovedEvents:YES];
			[submenu beginTrackingWithEvent:originalEvent options:CMMenuOptionIgnoreMouse];
		}
	} else {
		[self selectFirstItemAndShowSubmenu:NO];
		[self setReceivesMouseMovedEvents:YES];
	}
}


- (void)selectPreviousItemAndShowSubmenu:(BOOL)showSubmenu {
	CMMenuItem *previousItem = nil;
//	CMMenuItem *selectedItem = nil;
	for (CMMenuItem *item in _menuItems) {
		if ([item isSelected]) {
//			selectedItem = item;
			break;
		}
			
		if ( ![item isSeparatorItem] && [item isEnabled])
			previousItem = item;
	}
	
	if (! previousItem)
		return;

//	[selectedItem deselect];
	
	if (showSubmenu)
		[previousItem selectWithDelayForSubmenu:SUBMENU_POPUP_DELAY_DEFAULT];
	else
		[previousItem select];
//	[selectedItem deselect];
//	[_underlyingWindowController moveVisibleRectToRect:[previousItem frame] ignoreMouse:YES];
	[self moveVisibleAreaToDisplayItem:previousItem ignoreMouse:YES updateTrackingPrimitives:YES];
}


- (void)selectNextItemAndShowSubmenu:(BOOL)showSubmenu {
	CMMenuItem *previousItem = nil;
//	CMMenuItem *selectedItem = nil;
	for (CMMenuItem *item in [_menuItems reverseObjectEnumerator]) {
		if ([item isSelected]) {
//			selectedItem = item;
			break;
		}
		
		if ( ![item isSeparatorItem] && [item isEnabled])
			previousItem = item;
	}
	
	if (! previousItem)
		return;
	
	if (showSubmenu)
		[previousItem selectWithDelayForSubmenu:SUBMENU_POPUP_DELAY_DEFAULT];
	else
		[previousItem select];
	[self moveVisibleAreaToDisplayItem:previousItem ignoreMouse:YES updateTrackingPrimitives:YES];
}


- (void)selectFirstItemAndShowSubmenu:(BOOL)showSubmenu {
	CMMenuItem *firstItem = [self itemAtIndex:0];
	if (! firstItem)
		return;
	
	if (showSubmenu)
		[firstItem selectWithDelayForSubmenu:SUBMENU_POPUP_DELAY_DEFAULT];
	else
		[firstItem select];
}


- (void)cancelOperation:(NSEvent *)originalEvent {
	[[self rootMenu] cancelTracking];
}


- (void)performSelected:(NSEvent *)originalEvent {
	CMMenuItem *item = [self highlightedItem];
	if (item) {
		if ([item hasSubmenu]) {
			CMMenu *submenu = [item submenu];
			[submenu showAsSubmenuOf:item withOptions:CMMenuOptionIgnoreMouse];
			CMMenuItem *firstItem = [submenu itemAtIndex:0];
			if (firstItem)
				[firstItem select];
			
			[self setReceivesMouseMovedEvents:YES];
			[submenu setReceivesMouseMovedEvents:YES];
			[submenu beginTrackingWithEvent:originalEvent options:CMMenuOptionIgnoreMouse];
		} else {
			[self performActionForItem:item];
		}
	} else {
		[[self rootMenu] cancelTracking];
	}
}


- (BOOL)receivesMouseMovedEvents {
	return _receiveMouseMovedEvents;
}


- (void)setReceivesMouseMovedEvents:(BOOL)receiveEvents {
	if (_receiveMouseMovedEvents == receiveEvents)
		return;
	
	if (receiveEvents) {
		BOOL mouseInMenu = (NSPointInRect([NSEvent mouseLocation], [self frame]));
		if (([self supermenu] && [[self supermenu] receivesMouseMovedEvents]) || mouseInMenu) {
			_receiveMouseMovedEvents = YES;
		}
	} else {
		_receiveMouseMovedEvents = NO;
	}
}


- (NSString *)description {
	NSMutableString *description = [[NSMutableString alloc] initWithString:[super description]];
	
	[description appendString:@"\n\tItems \t(\n"];
	for (CMMenuItem *item in _menuItems) {
		[description appendString:@"\t"];
		[description appendString:[item description]];
		[description appendString:@"\n"];
	}
	[description appendString:@")"];
	
	return [description autorelease];
}


@end
