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
@interface CMMenu () <CMMenuKeyEventInterpreterDelegate>
{
	CMWindowController *_underlyingWindowController;
	
	CMMenuItem *_parentItem;
	BOOL _isActive;
	CMMenu *_activeSubmenu;
	BOOL _isTrackingSubmenu;
		
	BOOL _displayedFirstTime;
	BOOL _needsUpdating;
	
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
	CMMenuKeyEventInterpreter *_keyEventInterpreter;
}


- (CMMenuAlignment)horizontalAlignment;
- (CMMenuAlignment)verticalAlignment;
//- (void)setmenuVerticalAlignment:(CMMenuAlignment)aligning;
- (NSRect)frame;
//- (NSRect)frameOfItemRelativeToScreen:(CMMenuItem *)item;
- (void)reloadData;
- (void)showMenu;

/**
 * @function getBestFrameForMenuWindow
 * @abstract Returns the frame in screen coordinates in which menu will be drawn.
 * @discussion Depending on the position of menu's parent item and the proximity to the screen 
 *		menu can be positioned either from the left or from the right of it, aligned to the top or to the bottom.
 * @result Frame in screen coordinates.
 */
- (NSRect)getBestFrameForMenuWindow;

- (void)selectPreviousItemAndShowSubmenu:(BOOL)showSubmenu;
- (void)selectNextItemAndShowSubmenu:(BOOL)showSubmenu;
- (void)selectFirstItemAndShowSubmenu:(BOOL)showSubmenu;
- (void)selectLastItemAndShowSubmenu:(BOOL)showSubmenu;

//- (void)orderFront;
//- (NSInteger)windowNumber;	// may not be needed
//- (void)showMenuAsSubmenuOf:(CMMenuItem *)menuItem; // may not be needed

@end


@implementation CMMenu

- (id)init {
	if (self = [super init]) {
		[NSBundle loadNibNamed:[self className] owner:self];
		_displayedFirstTime = NO;
		_needsUpdating = YES;
		_minimumWidth = 0;
		_menuHorizontalAlignment = CMMenuAlignedLeft;
		_menuVerticalAlignment = CMMenuAlignedTop;
		_menuItems = [[NSMutableArray alloc] init];
//		_registeredCustomNibs = 0;
		
		_borderRadius = 5.0;
			
		// maks: might need to be elaborated: only submenus of menu should be of higher level
		static int level = 0;
//		[_underlyingWindow setLevel:NSPopUpMenuWindowLevel + level];
		++level;
		
//		NSNib *nib = [[NSNib alloc] initWithNibNamed:@"CMTableCellViewId3" bundle:[NSBundle mainBundle]];
//		[_menuTableView registerNib:nib forIdentifier:@"CMTableCellViewId3"];
	}
	return self;
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
	
	[super dealloc];
}

- (void)awakeFromNib {
	NSLog(@"%@ awakeFromNib", [self className]);
}



- (CMMenu *)supermenu {
	return _supermenu;
}




- (void)addItem:(CMMenuItem *)newItem {
	if (newItem == nil)
		[NSException raise:NSInvalidArgumentException format:@"Exception: nil provided as Menu Item object."];
	
	[_menuItems addObject:newItem];
	[newItem setMenu:self];
}


- (CMMenuItem *)itemAtIndex:(NSInteger)index {
	if (index < 0 || index >= [_menuItems count])
		[NSException raise:NSRangeException format:@"No item for -itemAtIndex: %ld", index];
	return [_menuItems objectAtIndex:index];
}


- (CMMenuItem *)itemAtPoint:(NSPoint)aPoint {
	NSViewController *viewController = [_underlyingWindowController viewControllerAtPoint:aPoint];
	if (viewController)
		return [viewController representedObject];
	else
		return nil;
}


- (NSArray *)itemArray {
	return _menuItems;
}


- (NSInteger)numberOfItems {
	return [_menuItems count];
}


- (CMMenuItem *)parentItem {
	return _parentItem;
}

- (NSInteger)indexOfItem:(CMMenuItem *)index {
	// need implement
	return 0;
}


- (void)setSubmenu:(CMMenu *)aMenu forItem:(CMMenuItem *)anItem {
//	if (aMenu == nil || anItem == nil)
	if (anItem == nil)
		[NSException raise:NSInvalidArgumentException format:@"Bad argument in -%@", NSStringFromSelector(_cmd)];
	
	// pass to Menu Item method
	[anItem setSubmenu:aMenu];
}


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


- (void)updateItemsAtIndexes:(NSIndexSet *)indexes {
//	[_menuTableView reloadDataForRowIndexes:indexes columnIndexes:[NSIndexSet indexSetWithIndex:0]];
}


//- (void)update {
//	[_menuTableView reloadData];
//}


- (void)startMenu {
	
	[self showMenu];

}


- (void)showMenu {
	if (!_underlyingWindowController) {
		_underlyingWindowController = [[CMWindowController alloc] initWithOwner:self];
		[self reloadData];
	}
	

	NSRect frame = [self getBestFrameForMenuWindow];

	
	[_underlyingWindowController displayInFrame:frame];
	_isActive = YES;
	
	/* Only the root menu receives interpreted actions and then routes them to according menu.
		Root menu doesn't have supermenu. */
	if (! _supermenu) {
		if (! _keyEventInterpreter)
			_keyEventInterpreter = [[CMMenuKeyEventInterpreter alloc] initWithTarget:self];
		[_keyEventInterpreter start];
	}
	
	
//	if (_needsUpdating) {
//		[self update];
//		_needsUpdating = 0;
//	}

	/* when _underlyingView is initially set to Hidden and instantiating a Menu OSX will NOT draw tableView.
	 Otherwise it will, even if we are not going to show menu yet.
	 First time Menu is displayed we redraw shadows. Otherwise Menu appears without shadows when we use
	 _underlyingView set to Hidden.
	 */
//	if (_displayedFirstTime == 0) {
//		[_underlyingView setHidden:NO];
//		[_underlyingWindow display];
//		[_underlyingWindow setHasShadow:NO];
//		[_underlyingWindow setHasShadow:YES];
//
//		[_underlyingWindow orderFront:self];
//
//	} else
//		[_underlyingWindow orderFront:self];
//	
//	_displayedFirstTime = 1;
}


- (void)showMenuAsSubmenuOf:(CMMenuItem *)menuItem {
	[[menuItem menu] setActiveSubmenu:self];
//	_parentItem = menuItem;
	[self showMenu];
}


//- (void)orderFront {
//	[_underlyingWindow orderFront:self];
//}


- (void)cancelTracking {
	[self cancelTrackingWithoutAnimation];
}


- (void)cancelTrackingWithoutAnimation {
	if (_activeSubmenu) {
		[_activeSubmenu cancelTrackingWithoutAnimation];
	}
	
//	[_underlyingWindow orderOut:self];
	[_underlyingWindowController hide];
	_isActive = NO;
	
	if (_supermenu) {
		[_supermenu setActiveSubmenu:nil];
		[_parentItem deselect];
//		_parentItem = nil;
	}
	
	if (! _supermenu)
		[_keyEventInterpreter stop];
}


- (CMMenuItem *)highlightedItem {
	for (CMMenuItem *item in _menuItems) {
		if ([item isSelected])
			return item;
	}
	
	return nil;
}


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


//- (NSRect)frameOfItemRelativeToScreen:(CMMenuItem *)item {
//	NSRect frame = [item frameRelativeToMenu];
//	return [[_underlyingWindowController window] convertRectToScreen:frame];
//}


- (NSRect)convertRectToScreen:(NSRect)aRect {
	return [[_underlyingWindowController window] convertRectToScreen:aRect];
}



/*
 *
 */
- (NSRect)getBestFrameForMenuWindow {
	NSRect frame;
	NSSize intrinsicSize = [_underlyingWindowController intrinsicContentSize];
	
	// top menu
	if (!_parentItem) {
		frame.origin = NSMakePoint(100, 200);
		frame.size.width = intrinsicSize.width;
		frame.size.height = (intrinsicSize.height > 817) ? 825 : intrinsicSize.height;
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
	//	NSUInteger i;
	//	NSUInteger count = [_menuItems count];
	NSMutableArray *viewControllers = [NSMutableArray array];
	
	for (CMMenuItem *menuItem in _menuItems) {
		
		/* menu item has individual view */
		if ([menuItem viewNibName]) {
			NSViewController *viewController = [[NSViewController alloc] initWithNibName:[menuItem viewNibName] bundle:nil];
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
			
			[menuItem setRepresentedViewController:viewController];
			[viewController setRepresentedObject:menuItem];
			[viewControllers addObject:viewController];
			
		} else if (_itemsViewNibName) { 		/* custom view for all items */
			//			id cellView;
			//			cellView = [tableView makeViewWithIdentifier:_itemsViewIdentifier owner:self];
			
			NSViewController *viewController = [[NSViewController alloc] initWithNibName:_itemsViewNibName bundle:nil];
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
			
			[menuItem setRepresentedViewController:viewController];
			[viewController setRepresentedObject:menuItem];
			[viewControllers addObject:viewController];
			
		} else {
			NSViewController *viewController;
			
			if ([menuItem isSeparatorItem]) {
				viewController = [[NSViewController alloc] initWithNibName:@"CMMenuItemSeparatorView" bundle:nil];
//				CMMenuItemSeparatorView *view =
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
				
				[[view title] setStringValue:[menuItem title]];
				
				if ([menuItem hasSubmenu])
					[view setHasSubmenuIcon:YES];
			}
			

			[menuItem setRepresentedViewController:viewController];
			[viewController setRepresentedObject:menuItem];
			[viewControllers addObject:viewController];
		}
	}
	
	[_underlyingWindowController layoutViews:viewControllers];
	
}




#pragma mark -
#pragma mark ***** CMMenu Internal Methods *****


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


- (CMMenuAlignment)horizontalAlignment {
	return _menuHorizontalAlignment;
}


- (CMMenuAlignment)verticalAlignment {
	return _menuVerticalAlignment;
}


- (NSInteger)windowLevel {
	return (_underlyingWindowController) ? _underlyingWindowController.window.level : 0;
}



#pragma mark -
#pragma mark ***** Menu Tracking *****


- (BOOL)isTrackingSubmenu {
	return _isTrackingSubmenu;
}


- (void)mouseEvent:(NSEvent *)theEvent {
	NSUInteger eventType = [theEvent type];
	NSPoint mouseLocatoin = [theEvent locationInWindow];
	
	/*
	 * Possible Events:
	 * 1. Mouse entered a menu when it is showing a submenu:
	 *		a. mouse hovered submenu's parent item;
	 *		b. mouse hovered other area;
	 * 2. Mouse entered submenu when it was being tracked by the supermenu.
	 */
	
	if (eventType == NSMouseEntered) {
		if (_activeSubmenu) {				// 1.
			CMMenuItem *menuItem = [self itemAtPoint:mouseLocatoin];
			if (menuItem && menuItem == [_activeSubmenu parentItem]) {	// 1.a
				if ([_activeSubmenu activeSubmenu])						// if submenu has active submenus -- close them
					[[_activeSubmenu activeSubmenu] cancelTrackingWithoutAnimation];
			} else
				[_activeSubmenu cancelTrackingWithoutAnimation];		// 1.b.
		} else if (_supermenu && [_supermenu isTrackingSubmenu]) {		// 2.
			[_supermenu stopTrackingSubmenuReasonSuccess:YES];
		}
	} else {
		
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
	_tracking_event->timer = [[NSTimer scheduledTimerWithTimeInterval:interval
															 target:self
														   selector:@selector(trackingLoop:)
														   userInfo:nil
															repeats:YES] retain];
	
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
	
//	NSLog(@"STOP tracking menu: %@, submenu: %@. Timer: %@", self, [self activeSubmenu], _tracking_event->timer);
	
	[_tracking_event->timer invalidate];
	[_tracking_event->timer release];
	_tracking_event->timer = nil;
	free(_tracking_event);
	_tracking_event = NULL;
	
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
			[self stopTrackingSubmenuReasonSuccess:NO];
			NSLog(@"Stop tracking, reason: opposite direction");
			return;
		}
	} else if (mouseLocation.x > event->event_origin.x) {
		[self stopTrackingSubmenuReasonSuccess:NO];
		NSLog(@"Stop tracking, reason: opposite direction");
		return;
	}
	
	
	
	CGFloat mouseTravelDistance = sqrt(pow((event->last_mouse_location.x - mouseLocation.x), 2) + pow((event->last_mouse_location.y - mouseLocation.y), 2));
	CGFloat mouseVelocity = mouseTravelDistance / (timestamp - event->timestamp);

	
	/* when mouse is moving too slowly */
	event->averageVelocity = (event->averageVelocity + mouseVelocity) / 2;
	if (event->averageVelocity < 60) {
		[self stopTrackingSubmenuReasonSuccess:NO];
		NSLog(@"Stop tracking, reason: slow veloctiy");
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
					[self stopTrackingSubmenuReasonSuccess:NO];
					NSLog(@"Stop tracking, reason: bottom left hypotenuse crossed at loc.: %@", NSStringFromPoint(mouseLocation));
					return;
				}
				
				/* we calculate here how fast the mouse pointer is moving towards submenu using Delta X and mouse velocity.
				   Multiplier at the end makes it easier for moving the mouse the closer to menu you get. */
				CGFloat multiplier = (mouseCloseToSubmenu) ? (2.5 * widthLeg / NSWidth(event->item_rect)) : 1;
				CGFloat targetVector = event->averageVelocity * event->averageDeltaX * multiplier;
//				NSLog(@"Val: %f, deltaX: %f, close to submenu: %d", targetVector, event->averageDeltaX, mouseCloseToSubmenu);
				if (ABS(targetVector) < 1000) {
					[self stopTrackingSubmenuReasonSuccess:NO];
					NSLog(@"Stop tracking, reason: moving not enough fast * correct direction.");
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
					[self stopTrackingSubmenuReasonSuccess:NO];
					NSLog(@"Stop tracking, reason: top left hypotenuse crossed at loc.: %@", NSStringFromPoint(mouseLocation));
					return;
				}
				
				CGFloat targetVector = event->averageVelocity * event->averageDeltaX;
//				NSLog(@"Val: %f, deltaX: %f", targetVector, averageDeltaX);
				if (ABS(targetVector) < 4000) {
					[self stopTrackingSubmenuReasonSuccess:NO];
					NSLog(@"Stop tracking, reason: top direction moving not enough fast * correct direction.");
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
				[self stopTrackingSubmenuReasonSuccess:NO];
				NSLog(@"Stop tracking, reason: (menu aligned BOTTOM) hypotenuse crossed at loc.: %@", NSStringFromPoint(mouseLocation));
				return;
			}
			
			/* we calculate here how fast the mouse pointer is moving towards submenu using Delta X and mouse velocity.
			 Multiplier at the end makes it easier for moving the mouse the closer to menu you get. */
			CGFloat multiplier = (mouseCloseToSubmenu) ? (2.5 * widthLeg / NSWidth(event->item_rect)) : 1;
			CGFloat targetVector = event->averageVelocity * event->averageDeltaX * multiplier;
//				NSLog(@"Val: %f, deltaX: %f, close to submenu: %d", targetVector, event->averageDeltaX, mouseCloseToSubmenu);
			if (ABS(targetVector) < 1000) {
				[self stopTrackingSubmenuReasonSuccess:NO];
				NSLog(@"Stop tracking, reason: (menu aligned BOTTOM) moving not enough fast * correct direction.");
				return;
			}

		}

	} else {
		/* mouse left menu bounds, and obviously hasn't entered submenu */
		
//		if (event->submenu_vertical_alignment == CMMenuAlignedTop) {
			if (mouseLocation.y - NSMaxY(event->submenu_rect) > 60 || NSMinY(event->submenu_rect) - mouseLocation.y > 60) {
				[self stopTrackingSubmenuReasonSuccess:NO];
				NSLog(@"Stop tracking, reason: mouse went vertically too far");
				return;
			}
//		} else {
			
//		}
	
		if (event->timeLeftMenuBounds == 0)
			event->timeLeftMenuBounds = timestamp;
		else if (timestamp - event->timeLeftMenuBounds > 0.5) {
			[self stopTrackingSubmenuReasonSuccess:NO];
			NSLog(@"Stop tracking, reason: time elapsed while out of menu bounds.");
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
	NSLog(@"mouse location: %@, velocity: %f, average velocity: %f", NSStringFromPoint(mouseLocation), mouseVelocity, event->averageVelocity);
	
	event->timestamp = timestamp;
	event->last_mouse_location = mouseLocation;
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


- (CMMenu *)menuToInterpretKeyEvent {
	CMMenu *menu = self;
	NSPoint mouseLocation = [NSEvent mouseLocation];
	while (true) {
		if (NSPointInRect(mouseLocation, [menu frame]))
			break;
		
		if (! [menu activeSubmenu])
			break;
		
		menu = [menu activeSubmenu];;
	}
	
	return menu;
}


- (void)moveUp:(id)sender {
	CMMenu *menu = [self menuToInterpretKeyEvent];
	NSLog(@"MOVE UP!!");
	[menu selectPreviousItemAndShowSubmenu:NO];
}


- (void)moveDown:(id)sender {
	
}


- (void)selectPreviousItemAndShowSubmenu:(BOOL)showSubmenu {
	CMMenuItem *previousItem = nil;
	CMMenuItem *selectedItem = nil;
	for (CMMenuItem *item in _menuItems) {
		if ([item isSelected]) {
			selectedItem = item;
			break;
		}
			
		if (! [item isSeparatorItem])
			previousItem = item;
	}
	
	if (! previousItem) {
//		[self selectLastItemAndShowSubmenu:NO];
		return;
	}
	
	[selectedItem deselect];
	
	if (showSubmenu)
		[previousItem selectWithDelayForSubmenu:SUBMENU_POPUP_DELAY_DEFAULT];
	else
		[previousItem select];
}


- (void)selectNextItemAndShowSubmenu:(BOOL)showSubmenu {
	
}


- (void)selectFirstItemAndShowSubmenu:(BOOL)showSubmenu {
	
}


- (void)selectLastItemAndShowSubmenu:(BOOL)showSubmenu {
	
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
