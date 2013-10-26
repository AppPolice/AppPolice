//
//  ChromeMenu.m
//  Ishimura
//
//  Created by Maksym on 7/3/13.
//  Copyright (c) 2013 Maksym Stefanchuk. All rights reserved.
//

#include <stdlib.h>		// malloc

//#import <AppKit/NSWindow.h>
#import "CMMenu.h"
#import "CMMenuItem.h"
#import "CMMenuItemView.h"
#import "CMMenu+InternalMethods.h"
#import "CMMenuItem+InternalMethods.h"
#import "CMMenuItemView+InternalMethods.h"
#import "CMWindowController.h"
#import "CMMenuKeyEventInterpreter.h"
#import "CMDebug.h"
//#import "CMMenuItemBackgroundView.h"
//#import "ChromeMenuUnderlyingWindow.h"
//#import "ChromeMenuUnderlyingView.h"


#define MENU_BOTTOM_PADDING_TO_SCREEN 7


enum {
	CMMenuAlignedRight = 1,
	CMMenuAlignedLeft = 2,
	CMMenuAlignedTop = 3,
	CMMenuAlignedBottom = 4
};
typedef NSUInteger CMMenuAlignment;



struct __submenu_tracking_event {
	int active;
	NSPoint event_origin;
	NSRect item_rect;
	NSRect menu_rect;
	NSRect submenu_rect;
//	NSRect tracking_area_rect;
	CMMenuAlignment menu_horizontal_alignment;		// left or right
	CMMenuAlignment submenu_vertical_alignment;
//	CMMenuItem *selectedItem;
//	int mouse_over_other_item;
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
	
};

typedef struct __submenu_tracking_event tracking_event_t;



/*
 * Private class declarations
 */
@interface CMMenu ()
{
	CMWindowController *_underlyingWindowController;
	
	CMMenuItem *_parentItem;
	BOOL _isActive;
	CMMenu *_activeSubmenu;
	BOOL _isTrackingSubmenu;
	BOOL _cancelsTrackingOnAction;
	BOOL _cancelsTrackingOnMouseEventOutsideMenus;
	NSUInteger _eventBlockingMask;
		
//	BOOL _displayedFirstTime;
	BOOL _needsDisplay;		// flag used in context of full menu update.
	
	CMMenuAlignment _menuHorizontalAlignment;
	CMMenuAlignment _menuVerticalAlignment;
	CGFloat _minimumWidth;
	NSSize _size;
	CGFloat _borderRadius;
	
/* this block of vartiables servers for storing one custom view that's to be used for all menu items */
	NSString *_itemsViewNibName;
//	NSString *_itemsViewIdentifier;
	NSArray *_itemsViewPropertyNames;
//	NSNib *_itemsViewRegisteredNib;

/* this block of variables servers for storing custom views that certain menu items wish to use */
//	NSMutableArray *_itemViewNibNames;
	NSMutableArray *_itemViewRegesteredNibs;
	int _registeredCustomNibs;
	
	tracking_event_t *_tracking_event;
	BOOL _receiveMouseMovedEvents;
	BOOL _generateMouseMovedEvents;
//	id _localMouseMoveEventMonitor;
	id _globalEventMonitor;
	
	NSMutableArray *_popovers;
}


- (CMMenuAlignment)horizontalAlignment;
- (CMMenuAlignment)verticalAlignment;
//- (void)setmenuVerticalAlignment:(CMMenuAlignment)aligning;

//- (NSRect)frameOfItemRelativeToScreen:(CMMenuItem *)item;
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

- (void)selectPreviousItemAndShowSubmenu:(BOOL)showSubmenu;
- (void)selectNextItemAndShowSubmenu:(BOOL)showSubmenu;
- (void)selectFirstItemAndShowSubmenu:(BOOL)showSubmenu;
//- (void)selectLastItemAndShowSubmenu:(BOOL)showSubmenu;
//- (void)installLocalMonitorForMouseMovedEvent;

//- (void)orderFront;
//- (NSInteger)windowNumber;	// may not be needed
//- (void)showMenuAsSubmenuOf:(CMMenuItem *)menuItem; // may not be needed

@end


@implementation CMMenu

- (id)initWithTitle:(NSString *)aTitle {
	if (aTitle == nil) {
		[NSException raise:NSInvalidArgumentException format:@"nil provided as title for menu."];
		return nil;
	}
	
	self = [super init];
	if (self) {
//		[NSBundle loadNibNamed:[self className] owner:self];
//		_displayedFirstTime = NO;
		_title = [aTitle copy];
		_needsDisplay = YES;
		_cancelsTrackingOnAction = YES;
		_cancelsTrackingOnMouseEventOutsideMenus = YES;
//		_eventBlockingMask = 0;
//		_minimumWidth = 0;
		_menuHorizontalAlignment = CMMenuAlignedLeft;
		_menuVerticalAlignment = CMMenuAlignedTop;
		_menuItems = [[NSMutableArray alloc] init];
//		_registeredCustomNibs = 0;
		
		_borderRadius = 5.0;
			
		// maks: might need to be elaborated: only submenus of menu should be of higher level
//		static int level = 0;
//		[_underlyingWindow setLevel:NSPopUpMenuWindowLevel + level];
//		++level;
		
//		NSNib *nib = [[NSNib alloc] initWithNibNamed:@"CMTableCellViewId3" bundle:[NSBundle mainBundle]];
//		[_menuTableView registerNib:nib forIdentifier:@"CMTableCellViewId3"];
		
		_receiveMouseMovedEvents = NO;
		_generateMouseMovedEvents = NO;
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
//	if (_itemsViewRegisteredNib) {
//		[_itemsViewRegisteredNib release];
		[_itemsViewNibName release];
//		[_itemsViewIdentifier release];
		[_itemsViewPropertyNames release];
//	}
	
//	if (_itemViewRegesteredNibs)
//		[_itemViewRegesteredNibs release];
	
//	[_underlyingWindow release];
	
	if (_popovers) {
		[_popovers removeAllObjects];
		[_popovers release];
	}
	
	[super dealloc];
}

- (void)awakeFromNib {
	XLog3("%@ awakeFromNib", [self className]);
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
//	NSRect frame = [self getBestFrameForMenuWindow];
//	[_underlyingWindowController updateFrame:frame options:CMMenuOptionDefault];
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
	//			NSRect frame = [self getBestFrameForMenuWindow];
	//			[_underlyingWindowController updateFrame:frame options:CMMenuOptionDefault];
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
- (void)setDefaultViewForItemsFromNibNamed:(NSString *)nibName andPropertyNames:(NSArray *)propertyNames {
	if (nibName == nil || [nibName isEqualToString:@""] || propertyNames == nil)
		[NSException raise:NSInvalidArgumentException format:@"Bad arguments provided in -%@", NSStringFromSelector(_cmd)];

//	_itemsViewRegisteredNib = [[NSNib alloc] initWithNibNamed:nibName bundle:[NSBundle mainBundle]];
//	if (_itemsViewRegisteredNib == nil)
//		return;
	
	_itemsViewNibName = [nibName copy];
//	_itemsViewIdentifier = [identifier copy];
	_itemsViewPropertyNames = [propertyNames copy];

//	[_menuTableView registerNib:_itemsViewRegisteredNib forIdentifier:identifier];
}


/*
 * Loads and registers nib only if it hasn't already
 */
//- (void)loadAndRegisterNibNamed:(NSString *)nibName withIdentifier:(NSString *)identifier {
//	/* we already validated variables when added to menuItem */
//	
//	NSNib *nib = [[NSNib alloc] initWithNibNamed:nibName bundle:[NSBundle mainBundle]];
//	if (nib == nil)
//		return;
//	
//	if (_registeredCustomNibs == 0)
//		_itemViewRegesteredNibs = [[NSMutableArray alloc] init];
//	
//	if ([_itemViewRegesteredNibs containsObject:nib] == NO) {
//		[_menuTableView registerNib:nib forIdentifier:identifier];
//		[_itemViewRegesteredNibs addObject:nib];
//		[nib release];
//		_registeredCustomNibs = 1;
//	}
//}



//- (void)update {
//	[_menuTableView reloadData];
//}


/*
 *
 */
- (void)start {
	if (_isActive)
		return;
	
	[self showWithOptions:CMMenuOptionDefault];
}


/*
 *
 */
- (void)showWithOptions:(CMMenuOptions)options {
	if (! _underlyingWindowController) {
		_underlyingWindowController = [[CMWindowController alloc] initWithOwner:self];
		[self reloadData];
		_needsDisplay = NO;
	}
	
//	BOOL isRootMenu = !_supermenu;
//	BOOL ignoreMouse = (options & CMMenuOptionIgnoreMouse);
//	NSRect frame = [self getBestFrameForMenuWindow];
//	[_underlyingWindowController displayInFrame:frame options:options];
	[self displayInFrame:NSZeroRect options:options display:NO];
	
	// Root menu begins tracking itself.
	// Root menu doesn't have supermenu.
	if (! _supermenu) {
		[self beginTrackingWithEvent:nil];
		
		_globalEventMonitor = [NSEvent addGlobalMonitorForEventsMatchingMask:NSLeftMouseDownMask | NSRightMouseDownMask handler:^(NSEvent *theEvent) {
			[self cancelTracking];
		}];

		// Use workspace to monitor if app gets deactived (e.g. by Command + Tab)
		// Cannot use NSApplicationDidResignActiveNotification as it doesn't work in NSEventTRackingRunLoopMode
//		[[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self selector:@selector(didDeactivateApplicationNotificationHandler:) name:NSWorkspaceDidDeactivateApplicationNotification object:nil];

		
		
//		[self performSelector:@selector(registerObserver) withObject:nil afterDelay:0 inModes:[NSArray arrayWithObject:NSEventTrackingRunLoopMode]];
	}
	
	_isActive = YES;
	
	/* Only the root menu receives interpreted actions and then routes them to according menu.
		Root menu doesn't have supermenu. */
//	if (isRootMenu) {
//		[_underlyingWindowController beginEventTracking];
//		if (! _keyEventInterpreter)
//			_keyEventInterpreter = [[CMMenuKeyEventInterpreter alloc] initWithTarget:self];
//		[_keyEventInterpreter start];
		
		
		
//		id monitor = [NSEvent addLocalMonitorForEventsMatchingMask:NSLeftMouseDownMask | NSLeftMouseUpMask handler:^(NSEvent *theEvent) {
//			NSEventType eventType = [theEvent type];
//			if (eventType == NSLeftMouseDown) {
//				NSLog(@"monitored left mouse DOWN click");
//			} else {
//				NSLog(@"monitored left mouse UP click");
//				theEvent = nil;
//			}
//			return theEvent;
//		}];
		
//		[self startEventTracking];
//		NSLog(@"window is key: %d", [[_underlyingWindowController window] isKeyWindow]);
//	}
}


//- (void)tempObserver:(NSNotification *)notification {
//	NSLog(@"----- observer notification, app resigned active status");
//}
//
//- (void)registerObserver {
//	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(tempObserver:) name:NSApplicationDidResignActiveNotification object:nil];
//}



//- (void)startEventTracking {
//	BOOL keepOn = true;
//	NSUInteger eventMask = NSSystemDefinedMask | NSApplicationDefinedMask | NSAppKitDefinedMask |
//		NSMouseEnteredMask | NSMouseExitedMask | NSLeftMouseDownMask | NSLeftMouseUpMask | NSScrollWheelMask;
//	
//	NSLog(@"starting tracking");
//	while (keepOn) {
//		NSEvent *event = [NSApp nextEventMatchingMask:eventMask untilDate:[NSDate dateWithTimeIntervalSinceNow:5] inMode:NSEventTrackingRunLoopMode dequeue:YES];
//		NSLog(@"track event: %@", event);
//		if (event)
//			[[_underlyingWindowController window] sendEvent:event];
//	}
//}


/*
 *
 */
- (void)showAsSubmenuOf:(CMMenuItem *)menuItem withOptions:(CMMenuOptions)options {
	[[menuItem menu] setActiveSubmenu:self];
//	_parentItem = menuItem;
	[self showWithOptions:options];
}


//- (void)orderFront {
//	[_underlyingWindow orderFront:self];
//}


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
		}
	}];

	_isActive = NO;
	
	if (! _supermenu) {
		if (_globalEventMonitor) {
			[NSEvent removeMonitor:_globalEventMonitor];
			_globalEventMonitor = nil;
		}
		
		[[[NSWorkspace sharedWorkspace] notificationCenter] removeObserver:self name:NSWorkspaceDidDeactivateApplicationNotification object:self];
	}
	
	if (_popovers) {
		for (NSPopover *popover in _popovers) {
			if ([popover isShown])
				[popover close];
		}
		[_popovers removeAllObjects];
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
	
	CMMenuItem *selectedItem = [self highlightedItem];
	if (selectedItem)
		[selectedItem deselect];
	
	if (_supermenu) {
		[_supermenu setActiveSubmenu:nil];
		[_parentItem deselect];
//		_parentItem = nil;
	}
	
	if (! _supermenu) {
		if (_globalEventMonitor) {
			[NSEvent removeMonitor:_globalEventMonitor];
			_globalEventMonitor = nil;
		}
		
		[[[NSWorkspace sharedWorkspace] notificationCenter] removeObserver:self name:NSWorkspaceDidDeactivateApplicationNotification object:self];
	}
	
	if (_popovers) {
		for (NSPopover *popover in _popovers) {
			if ([popover isShown])
				[popover close];
		}
		[_popovers removeAllObjects];
	}
	
	// Reset event blocking mask back to zero
	_eventBlockingMask = 0;
}


- (void)didDeactivateApplicationNotificationHandler:(NSNotification *)notification {
	NSRunningApplication *deactivatedApp = [[notification userInfo] objectForKey:NSWorkspaceApplicationKey];
	if ([[NSRunningApplication currentApplication] isEqual:deactivatedApp]) {
		[self cancelTrackingWithoutAnimation];
	}
}


/*
 *
 */
- (BOOL)cancelsTrackingOnAction {
	return _cancelsTrackingOnAction;
}


/*
 *
 */
- (void)setCancelsTrackingOnAction:(BOOL)cancels {
	_cancelsTrackingOnAction = cancels;
}


/*
 *
 */
- (BOOL)cancelsTrackingOnMouseEventOutsideMenus {
	return _cancelsTrackingOnMouseEventOutsideMenus;
}


/*
 *
 */
- (void)setCancelsTrackingOnMouseEventOutsideMenus:(BOOL)cancels {
	_cancelsTrackingOnMouseEventOutsideMenus = cancels;
}


/*
 *
 */
//- (BOOL)crystallizedSupermenus {
//	return ([self supermenu] && [[self supermenu] eventBlockingMask] != 0);
//}


- (BOOL)menusSuspended {
	if (_eventBlockingMask)
		return YES;
	return ([self supermenu] && [[self supermenu] eventBlockingMask] != 0);
}


/*
 *
 */
//- (void)setCrystallizeSupermenus:(BOOL)crystallize {
- (void)setSuspendMenus:(BOOL)suspend {
	if (suspend) {
		// Receiving menu doesn't block itself. All others do.
		[self blockEventsMatchingMask:0];
		CMMenu *menu = [self supermenu];
		while (menu) {
			[menu blockEventsMatchingMask:NSLeftMouseDownMask | NSMouseEnteredMask | NSMouseExitedMask | NSScrollWheelMask];
			menu = [menu supermenu];
		}
	} else {
		CMMenu *menu = [self rootMenu];
		do {
			[menu blockEventsMatchingMask:0];
		} while ((menu = [menu activeSubmenu]));
	}
}

/*
 *
 */
- (NSEventMask)eventBlockingMask {
	return _eventBlockingMask;
}


/*
 *
 */
- (void)blockEventsMatchingMask:(NSEventMask)mask {
	_eventBlockingMask = mask;
}


/*
 *
 */
- (CMMenuItem *)highlightedItem {
	for (CMMenuItem *item in _menuItems) {
		if ([item isSelected])
			return item;
	}
	
	return nil;
}


/*
 *
 */
- (void)showPopover:(NSPopover *)popover forItem:(CMMenuItem *)item {
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
	
//	if ([popover isShown]) {
//		[popover close];
//		return;
//	}
	
	if (! _popovers) {
		_popovers = [[NSMutableArray alloc] init];
	}
	
	if ([_popovers indexOfObject:popover] == NSNotFound) {
		[_popovers addObject:popover];
	}
	NSView *view = [(NSViewController *)[item representedView] view];
	[popover showRelativeToRect:[view bounds] ofView:view preferredEdge:NSMaxXEdge];
}


/*
 *
 */
- (CGFloat)minimumWidth {
	return _minimumWidth;
}


/*
 *
 */
- (void)setMinimumWidth:(CGFloat)width {
	_minimumWidth = width;
}


/*
 *
 */
- (NSSize)size {
	return (_underlyingWindowController) ? _underlyingWindowController.window.frame.size : NSMakeSize(0, 0);
}


/*
 *
 */
- (CGFloat)borderRadius {
	return _borderRadius;
}


/*
 *
 */
- (void)setBorderRadius:(CGFloat)radius {
	_borderRadius = radius;
}


/*
 *
 */
- (NSRect)frame {
	return (_underlyingWindowController) ? _underlyingWindowController.window.frame : NSMakeRect(0, 0, 10, 10);
}


//- (NSRect)frameOfItemRelativeToScreen:(CMMenuItem *)item {
//	NSRect frame = [item frameRelativeToMenu];
//	return [[_underlyingWindowController window] convertRectToScreen:frame];
//}


/*
 *
 */
- (NSRect)convertRectToScreen:(NSRect)aRect {
	return [[_underlyingWindowController window] convertRectToScreen:aRect];
}


/*
 *
 */
- (NSPoint)convertPointToScreen:(NSPoint)aPoint {
	return [[_underlyingWindowController window] convertBaseToScreen:aPoint];
}


/*
 *
 */
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
	
	// top menu
	if (! _parentItem) {
		NSScreen *screen = [[_underlyingWindowController window] screen];
		NSRect screenFrame = [screen frame];


		frame.size.width = intrinsicSize.width;
		frame.size.height = (intrinsicSize.height > 817) ? 825 : intrinsicSize.height;
		frame.origin = NSMakePoint(70, screenFrame.size.height - frame.size.height - 50);
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
		if ((screenFrame.size.width - NSMaxX(supermenuFrame)) < intrinsicSize.width) {
			origin.x = supermenuFrame.origin.x - intrinsicSize.width;
			_menuHorizontalAlignment = CMMenuAlignedRight;
		} else {
			origin.x = supermenuFrame.origin.x + supermenuFrame.size.width;
			_menuHorizontalAlignment = CMMenuAlignedLeft;
		}
	} else {
		if ((NSMinX(supermenuFrame) - intrinsicSize.width) < NSMinX(screenFrame)) {
			origin.x = supermenuFrame.origin.x + supermenuFrame.size.width;
			_menuHorizontalAlignment = CMMenuAlignedLeft;
		} else {
			origin.x = supermenuFrame.origin.x - intrinsicSize.width;
			_menuHorizontalAlignment = CMMenuAlignedRight;
		}
	}
	
	// Menu Y coordinate
	if (NSMaxY(parentItemFrame) - intrinsicSize.height + menuPadding >= screenFrame.origin.y) {		// default menu alignment at top of parent item
		origin.y = parentItemFrame.origin.y + parentItemFrame.size.height - intrinsicSize.height + menuPadding;
		size.height = intrinsicSize.height;
		_menuVerticalAlignment = CMMenuAlignedTop;
	}
	// else if (parentItemFrame.origin.y < 27) {
	else {
//		origin.y = parentItemFrame.origin.y - menuPadding;		// TODO: also need to scroll content to bottom
		origin.y = MENU_BOTTOM_PADDING_TO_SCREEN;
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



//- (IBAction)buttonClick:(id)sender {
//	NSLog(@"table: %@", _menuTableView);
//	NSRect rect = [_underlyingWindow frame];
//	[_underlyingWindow setFrame:NSMakeRect(rect.origin.x, rect.origin.y, rect.size.width + 20, rect.size.height) display:YES];
////	[menuTableView reloadData];
//}



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
	
	/* menu item has individual view */
	if ([menuItem viewNibName]) {
		viewController = [[NSViewController alloc] initWithNibName:[menuItem viewNibName] bundle:nil];
		id view = viewController.view;
		
		//			NSEnumerator *enumerator = [[menuItem viewPropertyNames] objectEnumerator];
		//			NSString *propertyName;
		//			while ((propertyName = [enumerator nextObject])) {
		for (NSString *propertyName in [menuItem viewPropertyNames]) {
			SEL propertySetter = NSSelectorFromString([NSString stringWithFormat:@"set%@Property:", [propertyName	stringByReplacingCharactersInRange:NSMakeRange(0, 1) withString:[[propertyName substringToIndex:1] capitalizedString]]]);
			if ([view respondsToSelector:propertySetter])
				[view performSelector:propertySetter withObject:[menuItem valueForKey:propertyName]];
		}
		
		//			NSLog(@"custom item cell view: %@", view);
		
//		[menuItem setRepresentedViewController:viewController];
//		[viewController setRepresentedObject:menuItem];
//		[viewControllers addObject:viewController];
		
	} else if (_itemsViewNibName) { 		/* custom view for all items */
		//			id cellView;
		//			cellView = [tableView makeViewWithIdentifier:_itemsViewIdentifier owner:self];
		
		viewController = [[NSViewController alloc] initWithNibName:_itemsViewNibName bundle:nil];
		id view = viewController.view;
		
		//			NSEnumerator *enumerator = [_itemsViewPropertyNames objectEnumerator];
		//			NSString *propertyName;
		//			while ((propertyName = [enumerator nextObject])) {
		for (NSString *propertyName in [menuItem viewPropertyNames]) {
			SEL propertySetter = NSSelectorFromString([NSString stringWithFormat:@"set%@Property:", [propertyName	stringByReplacingCharactersInRange:NSMakeRange(0, 1) withString:[[propertyName substringToIndex:1] capitalizedString]]]);
			if ([view respondsToSelector:propertySetter])
				[view performSelector:propertySetter withObject:[menuItem valueForKey:propertyName]];
		}
		
		//		NSLog(@"cell view: %@", cellView);
		
//		[menuItem setRepresentedViewController:viewController];
//		[viewController setRepresentedObject:menuItem];
//		[viewControllers addObject:viewController];
		
	} else {
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

			[view setEnabled:[menuItem isEnabled]];
		}
		
		
//		[menuItem setRepresentedViewController:viewController];
//		[viewController setRepresentedObject:menuItem];
//		[viewControllers addObject:viewController];
	}
	
	return viewController;
}




#pragma mark -
#pragma mark ***** CMMenu Internal Methods *****


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
		
	if (needsDisplay && _isActive)
		[self displayInFrame:NSZeroRect options:CMMenuOptionDefault display:YES];
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


- (void)displayInFrame:(NSRect)frameRect options:(CMMenuOptions)options display:(BOOL)display {
	if (display || _needsDisplay) {
		[_underlyingWindowController updateDocumentView];
		_needsDisplay = NO;
	}
	
	if (NSEqualRects(frameRect, NSZeroRect)) {
//		if (_isActive) {
			NSRect frame = [self getBestFrameForMenuWindow];
//			[_underlyingWindowController updateFrame:frame options:options];
			[_underlyingWindowController displayInFrame:frame options:options];
//		}
	} else {
//		if(_isActive) {
//			[_underlyingWindowController updateFrame:frameRect options:options];
			[_underlyingWindowController displayInFrame:frameRect options:options];
//		}
	}
	
	if ([self activeSubmenu])
		[[self activeSubmenu] displayInFrame:NSZeroRect options:CMMenuOptionDefault display:NO];
}


/*
 *
 */
//- (void)updateItemsAtIndexes:(NSIndexSet *)indexes {
//	[_underlyingWindowController updateViewsAtIndexes:indexes];
//	// This will update views itself. If during this update the documentView bounds change
//	//	-updateViewsAtIndexes: will call menu's -updateFrame method.
//}
//
//
//- (void)updateFrame {
//	if (! _isActive) {
//		NSRect frame = [self getBestFrameForMenuWindow];
//		[_underlyingWindowController updateFrame:frame options:CMMenuOptionDefault];
//	}
//}

//- (BOOL)isAncestorTo:(CMMenu *)menu {
//	CMMenu *supermenu = [menu supermenu];
//	while (supermenu) {
//		if (self == supermenu)
//			return YES;
//		supermenu = [supermenu supermenu];
//	}
//	
//	return NO;
//}


- (CMMenuAlignment)horizontalAlignment {
	return _menuHorizontalAlignment;
}


- (CMMenuAlignment)verticalAlignment {
	return _menuVerticalAlignment;
}


// TODO: temp method
- (NSWindow *)underlyingWindow {
	return [_underlyingWindowController window];
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


- (void)beginTrackingWithEvent:(NSEvent *)theEvent {
//	if (! _supermenu)
//		[NSApp performSelector:@selector(beginEventTracking) target:_underlyingWindowController argument:nil order:0 modes:nil];
	[_underlyingWindowController beginTrackingWithEvent:theEvent];
}


- (void)endTracking {
	[_underlyingWindowController endTracking];
}


- (BOOL)isTrackingSubmenu {
	return _isTrackingSubmenu;
}


- (void)mouseEvent:(NSEvent *)theEvent {
	NSUInteger eventType = [theEvent type];
//	NSPoint mouseLocation = [theEvent locationInWindow];	// relative to menu's window
//	mouseLocation = [self convertPointToScreen:mouseLocation];
	NSPoint mouseLocation = [theEvent locationInWindow];
	NSPoint mouseLocationOnScreen = ([theEvent window]) ? [[theEvent window] convertBaseToScreen:mouseLocation] : mouseLocation;


	
	if (eventType == NSMouseEntered) {
		NSLog(@"mouse ENTER menu: %@", self);
		
		/*
		 * Possible Events:
		 * 1. Mouse entered a menu when it is showing a submenu:
		 *		a. mouse hovered submenu's parent item (returned from submenu);
		 *		b. mouse hovered other area;
		 * 2. Mouse entered submenu when it was being tracked by the supermenu.
		 */
		
		CMMenuItem *mousedItem = [self itemAtPoint:mouseLocationOnScreen];
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
			if (NSPointInRect(mouseLocationOnScreen, [menu frame]))
				break;
		} while ((menu = [menu supermenu]));
		[menu rearrangeStateForNewMouse:mouseLocationOnScreen];
		
		// debug: cycle isEnabled
//		{
//			CMMenuItem *item = [menu itemAtPoint:mouseLocationOnScreen];
//			[item setEnabled:(![item isEnabled])];
//		}
	
		
	} else if (eventType == NSLeftMouseUp || eventType == NSRightMouseUp || eventType == NSOtherMouseUp) {
		// Find a menu of event
		CMMenu *menu = self;
		do {
			if (NSPointInRect(mouseLocationOnScreen, [menu frame]))
				break;
		} while ((menu = [menu supermenu]));
		
		// debug: cycle state
//		{
//			CMMenuItem *item = [menu itemAtPoint:mouseLocationOnScreen];
//			NSInteger state = [item state];
//			NSInteger nextState = state + 1;
//			if (nextState > 1)
//				nextState = -1;
//			[item setState:nextState];
//		}
		
		
		if ([menu eventBlockingMask]) {
			[menu setSuspendMenus:NO];
			[menu rearrangeStateForNewMouse:mouseLocationOnScreen];
		} else {
			CMMenuItem *item = [menu itemAtPoint:mouseLocationOnScreen];
			if (item)
				[item performAction];
		}
		
		
	} else if (eventType == NSMouseMoved) {
//		CMMenu *menu = self;
//		do {
//			[menu setReceivesMouseMovedEvents:NO];
//			if (NSPointInRect(mouseLocationOnScreen, [menu frame]))
//				break;
//		} while ((menu = [menu supermenu]));

//		CMMenu *menu = self;
		
//		XLog3("Mouse MOVED in menu:\n\tMenu frame that owns RunLoop: %@,\n\tMenu frame with mouse: %@, \n\tMouse location: %@, \n\tMouse location on screen: %@",
//			  NSStringFromRect([self frame]),
//			  NSStringFromRect([menu frame]),
//			  NSStringFromPoint(mouseLocation),
//			  NSStringFromPoint(mouseLocationOnScreen));
		
		
//		[menu rearrangeStateForNewMouse:mouseLocationOnScreen];
	}
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
		
// debug: cycle isEnabled
//		{
//			CMMenuItem *item = [menu itemAtPoint:mouseLocationOnScreen];
//			[item setEnabled:(![item isEnabled])];
//		}
		
		
	} else if (eventType == NSLeftMouseUp || eventType == NSRightMouseUp || eventType == NSOtherMouseUp) {
		// Find a menu of event
		CMMenu *menu = self;
		do {
			if (NSPointInRect(mouseLocation, [menu frame]))
				break;
		} while ((menu = [menu supermenu]));
		
// debug: cycle state
//		{
//			CMMenuItem *item = [menu itemAtPoint:mouseLocationOnScreen];
//			NSInteger state = [item state];
//			NSInteger nextState = state + 1;
//			if (nextState > 1)
//				nextState = -1;
//			[item setState:nextState];
//		}
		
		
		if ([menu eventBlockingMask]) {
			[menu setSuspendMenus:NO];
			[menu rearrangeStateForNewMouse:mouseLocation];
		} else {
			CMMenuItem *item = [menu itemAtPoint:mouseLocation];
			if (item)
				[item performAction];
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
		if (mousedItem && ![mousedItem isSeparatorItem]) {
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
//	_tracking_event->item_rect = [self frameOfItemRelativeToScreen:item];
	_tracking_event->item_rect = [item frameRelativeToScreen];
	_tracking_event->menu_rect = [self frame];
	_tracking_event->submenu_rect = [submenu frame];
	_tracking_event->menu_horizontal_alignment = [submenu horizontalAlignment];
	_tracking_event->submenu_vertical_alignment = [submenu verticalAlignment];
//	submenu__tracking_event->selectedItem = item;
//	_tracking_event->mouse_over_other_item = 0;
	_tracking_event->timestamp = [NSDate timeIntervalSinceReferenceDate];
//	_tracking_event->active = 1;
	
//	CGFloat heightLeg;
//	if (_tracking_event->submenu_vertical_alignment == CMMenuAlignedTop)
//		heightLeg = NSMinY(_tracking_event->item_rect) - NSMinY(_tracking_event->submenu_rect);
//	else
//		heightLeg = NSMaxY(_tracking_event->submenu_rect) - NSMaxY(_tracking_event->item_rect);
	
//	if (heightLeg < 80)
//		heightLeg *= 1.2;
//	else if (heightLeg < 200)
//		heightLeg *= 1.1;
//	else
//		heightLeg *=1.005;
	
	
	// We extend area a little to give users space for maneuver
	CGFloat extendHeight = 20;
//	heightLeg += 20;
	
//	_tracking_event->tanAlpha = heightLeg / NSWidth(_tracking_event->item_rect);
//	_tracking_event->tanBeta = 30 / NSWidth(_tracking_event->item_rect);
	_tracking_event->tanAlpha = (NSMinY(_tracking_event->item_rect) - NSMinY(_tracking_event->submenu_rect) +
							extendHeight) / NSWidth(_tracking_event->item_rect);
	_tracking_event->tanBeta = (NSMaxY(_tracking_event->submenu_rect) - NSMaxY(_tracking_event->item_rect) +
							extendHeight) / NSWidth(_tracking_event->item_rect);

	_tracking_event->averageVelocity = 0;
	_tracking_event->averageDeltaX = 0;
	_tracking_event->timeLeftMenuBounds = 0;
	
	NSTimeInterval interval = 0.07;
//	_tracking_event->timer = [[NSTimer scheduledTimerWithTimeInterval:interval
//															 target:self
//														   selector:@selector(trackingLoop:)
//														   userInfo:nil
//															repeats:YES] retain];
	NSLog(@" --------------------- CREATING SUBMENU TIMER ---------------------------- \n\n");
	_tracking_event->timer = [NSTimer timerWithTimeInterval:interval target:self selector:@selector(trackingLoop:) userInfo:nil repeats:YES];
//	[[NSRunLoop currentRunLoop] addTimer:_tracking_event->timer forMode:NSEventTrackingRunLoopMode];
	[[NSRunLoop currentRunLoop] addTimer:_tracking_event->timer forMode:NSRunLoopCommonModes];

	
//	NSLog(@"START tracking menu: %@, submenu: %@. Timer: %@", self, submenu,_tracking_event->timer);
}


/**
 * Discussion.
 * Method can be called from locations:
 *	[self trackingLoop:] -- when any of the tracking criteria is satisfied;
 *	[CMMenuItem shouldChangeItemSelectionStatusForEvent:] -- when mouse returns to the original menu item.
 *	// to be cont.
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


- (void)trackingLoop:(NSTimer *)timer {
//	static CGFloat averageVelocity = 0;
//	static CGFloat averageDeltaX = 0;
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
	
	
	
	
//	if (NSPointInRect(mouseLocation, event->submenu_rect)) {
//		[self stopTrackingSubmenuReasonSuccess:YES];
//		NSLog(@"Stop tracking, reason: success!");
//		return;
//	}
	
	
		
//	NSLog(@"time: %f", timestamp - submenu_event->timestamp);
//	NSLog(@"origin: %@", NSStringFromPoint(submenu_event->event_origin));
	XLog3("Submenu tracking loop stats:\n\tMouse location: %@\n\tVelocity: %f\n\tAverage velocity: %f",
		  NSStringFromPoint(mouseLocation),
		  mouseVelocity,
		  event->averageVelocity);
	
	event->timestamp = timestamp;
	event->last_mouse_location = mouseLocation;
}


- (void)updateTrackingAreaUsingOptions:(CMMenuOptions)options {
	[_underlyingWindowController updateContentViewTrackingAreaTrackMouseMoved:(options & CMMenuOptionTrackMouseMoved)];
}


- (void)updateTrackingAreaForItem:(CMMenuItem *)item {
	[_underlyingWindowController updateItemViewTrackingArea:[item representedView]];
}


- (void)updateTrackingPrimitiveForItem:(CMMenuItem *)item {
	[_underlyingWindowController updateTrackingPrimitiveForView:[item representedView] ignoreMouse:NO];
}


//- (void)startTrackingActiveSubmenu {
//	CMMenu *activeSubmenu = _activeSubmenu;
//	CMMenuItem *selectedItem = _parentItem;
//}


//- (NSWindow *)window {
//	return (_underlyingWindowController) ? _underlyingWindowController.window : nil;
//}

//- (NSInteger)windowNumber {
//	return (_underlyingWindowController) ? [_underlyingWindowController.window windowNumber] : 0;
//}


#pragma mark -
#pragma mark ****** Actions from Key Interpreter ******


- (CMMenu *)menuToReceiveKeyEvent {
	CMMenu *menu = self;
//	NSPoint mouseLocation = [NSEvent mouseLocation];
	while (true) {
//		if (NSPointInRect(mouseLocation, [menu frame]))
//			break;
		
		if (! [menu activeSubmenu])
			break;
		
		menu = [menu activeSubmenu];;
	}
	
	return menu;
}


/*
 * This selector is only called upon root menu, which dispatches according actions to other menus
 */
- (void)moveUp:(NSEvent *)originalEvent {
//	CMMenu *menu = [self menuToReceiveKeyEvent];
//	NSLog(@"MOVE UP!!");
//	[self installLocalMonitorForMouseMovedEvent];
	[self setReceivesMouseMovedEvents:YES];
//	[menu selectPreviousItemAndShowSubmenu:NO];
	if ([self activeSubmenu]) {
		CMMenuItem *selectedItem = [self highlightedItem];
		[[self activeSubmenu] cancelTrackingWithoutAnimation];
		[selectedItem select];
	}
	[self selectPreviousItemAndShowSubmenu:NO];
}


/*
 * This selector is only called upon root menu, which dispatches according actions to other menus
 */
//- (void)moveDown:(id)sender {
- (void)moveDown:(NSEvent *)originalEvent {
//	CMMenu *menu = [self menuToReceiveKeyEvent];
//	NSLog(@"MOVE DOWN!!");
//	[self installLocalMonitorForMouseMovedEvent];
	[self setReceivesMouseMovedEvents:YES];
//	[menu selectNextItemAndShowSubmenu:NO];
	if ([self activeSubmenu]) {
		CMMenuItem *selectedItem = [self highlightedItem];
		[[self activeSubmenu] cancelTrackingWithoutAnimation];
		[selectedItem select];
	}
	[self selectNextItemAndShowSubmenu:NO];
}


/*
 * This selector is only called upon root menu, which dispatches according actions to other menus
 */
- (void)moveLeft:(NSEvent *)originalEvent {
//	CMMenu *menu = [self menuToReceiveKeyEvent];
//	if ([menu supermenu]) {
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


/*
 * This selector is only called upon root menu, which dispatches according actions to other menus
 */
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
			[submenu beginTrackingWithEvent:originalEvent];
		}
	} else {
		[self selectFirstItemAndShowSubmenu:NO];
		[self setReceivesMouseMovedEvents:YES];
	}
}


/*
 *
 */
- (void)selectPreviousItemAndShowSubmenu:(BOOL)showSubmenu {
	CMMenuItem *previousItem = nil;
	CMMenuItem *selectedItem = nil;
	for (CMMenuItem *item in _menuItems) {
		if ([item isSelected]) {
			selectedItem = item;
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
//	[selectedItem deselect];
//	[_underlyingWindowController moveVisibleRectToRect:[previousItem frame] ignoreMouse:YES];
	[self moveVisibleAreaToDisplayItem:previousItem ignoreMouse:YES updateTrackingPrimitives:YES];
}


- (void)selectNextItemAndShowSubmenu:(BOOL)showSubmenu {
	CMMenuItem *previousItem = nil;
	CMMenuItem *selectedItem = nil;
	for (CMMenuItem *item in [_menuItems reverseObjectEnumerator]) {
		if ([item isSelected]) {
			selectedItem = item;
			break;
		}
		
		if ( ![item isSeparatorItem] && [item isEnabled])
			previousItem = item;
	}
	
	if (! previousItem)
		return;
	
//	NSLog(@"deselecting selected item: %@ and selecting: %@", selectedItem, previousItem);
//	[selectedItem deselect];
	if (showSubmenu)
		[previousItem selectWithDelayForSubmenu:SUBMENU_POPUP_DELAY_DEFAULT];
	else
		[previousItem select];
//	[_underlyingWindowController moveVisibleRectToRect:[previousItem frame] ignoreMouse:YES];
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
//
//
//- (void)selectLastItemAndShowSubmenu:(BOOL)showSubmenu {
//	
//}


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
			[submenu beginTrackingWithEvent:originalEvent];
		} else {
			[item performAction];
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

//	NSLog(@"setting new value for recieve mouse moved events: %d", receiveEvents);
//	
//	CMMenuOptions trackMouseMoved = (receiveEvents) ? CMMenuOptionTrackMouseMoved : CMMenuOptionDefault;
//	CMMenu *menu = self;
//	while (menu) {
//		[menu updateTrackingAreaUsingOptions:trackMouseMoved];
//		menu = [menu activeSubmenu];
//	}
	
	if (receiveEvents) {
		BOOL mouseInMenu = (NSPointInRect([NSEvent mouseLocation], [self frame]));
		if (([self supermenu] && [[self supermenu] receivesMouseMovedEvents]) || mouseInMenu) {
			_receiveMouseMovedEvents = YES;
//			if (mouseInMenu) {
//				[self updateTrackingAreaUsingOptions:CMMenuOptionTrackMouseMoved];
//				_generateMouseMovedEvents = YES;
//			}
		}
	} else {
//		if (_generateMouseMovedEvents) {
//			[self updateTrackingAreaUsingOptions:CMMenuOptionDefault];
//		}
			
		_receiveMouseMovedEvents = NO;
//		_generateMouseMovedEvents = NO;
	}
		
	
	
//	[self updateTrackingAreaUsingOptions:trackMouseMoved];
	
//	_receiveMouseMovedEvents = receiveEvents;
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
