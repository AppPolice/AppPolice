//
//  CMMenuItem.m
//  Ishimura
//
//  Created by Maksym on 7/4/13.
//  Copyright (c) 2013 Maksym Stefanchuk. All rights reserved.
//

#import "CMMenuItem.h"
#import "CMMenu.h"
#import "CMMenuItemView.h"
#import "CMMenu+InternalMethods.h"
#import "CMMenuItem+InternalMethods.h"
#import "CMDebug.h"
#import <objc/runtime.h>


/*
 * Private declarations
 */
@interface CMMenuItem()
{
	BOOL _isSelected;
	BOOL _mouseOver;						// this doesn't mean the item is selected (e.g. during submenu tracking)
	BOOL _submenuIntervalIsSetToPopup;
	NSViewController *_representedViewController;
}


//- (void)mouseEntered:(NSEvent *)theEvent;
//- (void)mouseExited:(NSEvent *)theEvent;
//- (void)mouseDown:(NSEvent *)theEvent;
- (void)showItemSubmenu;

@end



@implementation CMMenuItem

@synthesize viewNibName = _viewNibName;
//@synthesize viewIdentifier = _viewIdentifier;
@synthesize viewPropertyNames = _viewPropertyNames;



- (id)initWithTitle:(NSString *)aTitle action:(SEL)aSelector {
	if (self = [super init]) {
		[self setTitle:aTitle];
		_isSeparatorItem = NO;
		_action = aSelector;
	}
	return self;
}

- (id)initWithTitle:(NSString *)aTitle icon:(NSImage *)anImage action:(SEL)aSelector {
	self = [self initWithTitle:aTitle action:aSelector];
	if (self) {
		[self setIcon:anImage];
	}
	return self;
}


- (void)dealloc {
	[_title release];
	if (_icon)
		[_icon release];
	
	if (_viewNibName) {
//		[_viewIdentifier release];
		[_viewNibName release];
		[_viewPropertyNames release];
	}
	[super dealloc];
}


/*
 *
 */
+ (CMMenuItem *)separatorItem {
	CMMenuItem *instance = [[self alloc] init];
	if (instance) {
		instance->_isSeparatorItem = YES;
	}
	return [instance autorelease];
}


/*
 *
 */
- (CMMenu *)menu {
	return _menu;
}


/*
 *
 */
- (void)setTitle:(NSString *)aTitle {
	if (! aTitle) {
		[NSException raise:NSInvalidArgumentException format:@"No title provided for a menu item -setTitle:"];
		return;
	}
	
	if (_title == aTitle)
		return;
	
	if (_title)
		[_title release];
	_title = [aTitle copy];
	if (_representedViewController)
		[[(CMMenuItemView *)[_representedViewController view] title] setStringValue:aTitle];
	
	if ([_menu needsDisplay])	// menu will update item's title itself, no more actions are required.
		return;
	
//	[_menu setFrame:NSZeroRect options:CMMenuOptionDefault display:YES];
	[_menu setNeedsDisplay:YES];
}


/*
 *
 */
- (NSString *)title {
	return _title;
}


/*
 *
 */
- (void)setIcon:(NSImage *)anImage {
//	[anImage retain];
	_icon = [anImage copy];
}


/*
 *
 */
- (NSImage *)icon {
	return _icon;
}


/*
 *
 */
- (void)setSubmenu:(CMMenu *)submenu {
//	if (submenu == nil)
//		[NSException raise:NSInvalidArgumentException format:@"Bad argument provided in -%@", NSStringFromSelector(_cmd)];
	
	if (_isSeparatorItem) {
		[NSException raise:NSInternalInconsistencyException format:@"Menu separator item cannot have submenus."];
		return;
	}
	
	if (_submenu != submenu) {
		[_submenu release];
		if (submenu) {
			_submenu = [submenu retain];
			[_submenu setSupermenu:[self menu]];
			[_submenu setParentItem:self];
		} else
			_submenu = nil;
	}
}


/*
 *
 */
- (CMMenu *)submenu {
	return _submenu;
}


/*
 *
 */
- (BOOL)hasSubmenu {
	return (_submenu) ? YES : NO;
}


/*
 *
 */
- (BOOL)isSeparatorItem {
	return _isSeparatorItem;
}


/*
 *
 */
//- (void)setViewFromNibNamed:(NSString *)nibName withIdentifier:(NSString *)identifier andPropertyNames:(NSArray *)propertyNames {
- (void)setViewFromNibNamed:(NSString *)nibName andPropertyNames:(NSArray *)propertyNames {
//	if (nibName == nil || [nibName isEqualToString:@""] || identifier == nil || [identifier isEqualToString:@""] || propertyNames == nil)
	if (nibName == nil || [nibName isEqualToString:@""] || propertyNames == nil)
		[NSException raise:NSInvalidArgumentException format:@"Bad arguments provided in -%@", NSStringFromSelector(_cmd)];
	_viewNibName = [nibName retain];
//	_viewIdentifier = [identifier retain];
	_viewPropertyNames = [propertyNames retain];
}


/*
 *
 */
- (void)setTarget:(id)anObject {
	_target = anObject;	// not retained?
}


/*
 *
 */
- (id)target {
	return  _target;
}


/*
 *
 */
- (void)setAction:(SEL)aSelector {
	_action =  aSelector;
}


/*
 *
 */
- (SEL)action {
	return _action;
}


/*
 *
 */
- (void)performAction {
	if ([self hasSubmenu])
		return;

	XLog2("Performing action on item: %@", self);
	
	if (_action) {
		id target = _target;
		if (! target) {		// application delegate could be the one to handle it
			target = [NSApp delegate];
		}
		
		if ([target respondsToSelector:_action]) {
			[target performSelector:_action withObject:self];
//			[NSApp sendAction:_action to:target from:self];
		}
	}

	
	if ([[self menu] cancelsTrackingOnAction]) {
		if (! _isSeparatorItem) {
			CMMenuItemView *view = (CMMenuItemView *)[[self representedView] view];
			[view blink];
			[self performSelector:@selector(delayedCancelTracking) withObject:nil afterDelay:0.075 inModes:[NSArray arrayWithObject:NSRunLoopCommonModes]];
		} else {
			[self delayedCancelTracking];
		}
	}
}


- (void)delayedCancelTracking {
	CMMenu *menu = [self menu];
	CMMenu *supermenu = menu;
	while ((menu = [menu supermenu]))
		supermenu = menu;
	
	[supermenu cancelTracking];
}


- (id)representedObject {
	return _representedObject;
}


- (void)setRepresentedObject:(id)anObject {
	if (_representedObject == anObject)
		return;
	
	if (_representedObject) {
		[_representedObject release];
		_representedObject = nil;
	}
	if (anObject)
		_representedObject = [anObject retain];
}


- (BOOL)isHighlighted {
	return _isSelected;
}




#pragma mark -
#pragma mark ***** Events and Tracking methods *****


- (BOOL)shouldChangeItemSelectionStatusForEvent:(CMMenuEventType)eventType {
	BOOL changeStatus = YES;
	
	if (eventType & CMMenuEventMouseEnteredItem) {
		_mouseOver = YES;
		
		if (_isSelected) {
			changeStatus = NO;
//			if ([[self menu] isTrackingSubmenu]) {		// while tracking submenu, mouse returned to parent item
//				[[self menu] stopTrackingSubmenuReasonSuccess:YES];
//			} else if ([self hasSubmenu]) {
//				BOOL alreadyShowingSubmenu = ([[self menu] activeSubmenu] && [[self menu] activeSubmenu] == _submenu);
//					XLog("please show us submenu");
//				[self performSelector:@selector(showItemSubmenu) withObject:nil afterDelay:SUBMENU_POPUP_DELAY_DEFAULT inModes:[NSArray arrayWithObject:NSEventTrackingRunLoopMode]];
//				_submenuIntervalIsSetToPopup = YES;
//			}
			
			if ([self hasSubmenu]) {
				if ([[self menu] isTrackingSubmenu]) {		// while tracking submenu, mouse returned to parent item
					[[self menu] stopTrackingSubmenuReasonSuccess:YES];
				} else {
					CMMenu *activeSubmenu = [[self menu] activeSubmenu];
					if ( !activeSubmenu && activeSubmenu != _submenu) {
//						[self performSelector:@selector(showItemSubmenu) withObject:nil afterDelay:SUBMENU_POPUP_DELAY_DEFAULT inModes:[NSArray arrayWithObject:NSEventTrackingRunLoopMode]];
						[self performSelector:@selector(showItemSubmenu) withObject:nil afterDelay:SUBMENU_POPUP_DELAY_DEFAULT inModes:[NSArray arrayWithObject:NSRunLoopCommonModes]];
						_submenuIntervalIsSetToPopup = YES;
					}
				}
			}
				
		} else {
//			if ([[self menu] activeSubmenu]) {
			if ([[self menu] activeSubmenu] && [[self menu] isTrackingSubmenu]) {
				// must do work here
//				if ([[self menu] isTrackingSubmenu])
					changeStatus = NO;
//				else {
//					_isSelected = YES;
//					if ([self hasSubmenu]) {
//						[self performSelector:@selector(showItemSubmenu) withObject:nil afterDelay:0.2];
//						_submenuIntervalIsSetToPopup = 1;
//					}
//				}
			} else {
				_isSelected = YES;
				
				if ([self hasSubmenu]) {
//					[self performSelector:@selector(showItemSubmenu) withObject:nil afterDelay:SUBMENU_POPUP_DELAY_DEFAULT];
//					[self performSelector:@selector(showItemSubmenu) withObject:nil afterDelay:SUBMENU_POPUP_DELAY_DEFAULT inModes:[NSArray arrayWithObject:NSEventTrackingRunLoopMode]];
					[self performSelector:@selector(showItemSubmenu) withObject:nil afterDelay:SUBMENU_POPUP_DELAY_DEFAULT inModes:[NSArray arrayWithObject:NSRunLoopCommonModes]];
					_submenuIntervalIsSetToPopup = YES;
				}
			}
		}
	} else if (eventType & CMMenuEventMouseExitedItem) {
		_mouseOver = NO;
		
		CMMenu *activeSubmenu = [[self menu] activeSubmenu];
		if (activeSubmenu && activeSubmenu == _submenu) {
			if (! [[self menu] isTrackingSubmenu]) {
				[[self menu] startTrackingSubmenu:_submenu forItem:self];
			}
			changeStatus = NO;
		} else if ([self hasSubmenu]) {
//			if (_submenuIntervalIsSetToPopup) {		// not yet showed a menu
				[NSObject cancelPreviousPerformRequestsWithTarget:self];
				_isSelected = NO;
//			} else {
//				// need to see how exactly we're exiting a menu item
//				[_submenu cancelTrackingWithoutAnimation];
//				changeStatus = YES;
//				_isSelected = NO;
//			}
		} else {
			_isSelected = NO;
		}
	}
	
	/* This block usually handles cases with keyboard item selection:
		mouse movements and keyboard selection could go in opposite directions, as a result two items 
		get selected. */
	if (_isSelected && changeStatus) {
		NSArray *items = [_menu itemArray];
		for (CMMenuItem *item in items) {
			if ([item isSelected] && item != self) {
//				NSLog(@"TRACKINGAREA DE-select item: %@", item);
				[item deselect];
			}
		}
	}
	
//	if (_isSelected && changeStatus)
//		NSLog(@"TRACKINGAREA select item: %@", self);
	
	return changeStatus;
}


/*
 *
 */
- (void)showItemSubmenu {
	_submenuIntervalIsSetToPopup = NO;
//	[_submenu showMenu];
	[_submenu showAsSubmenuOf:self withOptions:CMMenuOptionDefault];
}





#pragma mark -
#pragma mark ***** CMMenuItem Internal Methods *****

- (NSViewController *)representedView {
	return _representedViewController;
}

- (void)setRepresentedView:(NSViewController *)viewController {
	_representedViewController = viewController;
}


- (void)setMenu:(CMMenu *)aMenu {
//	if (_menu != aMenu)
//		_menu = aMenu;
	// If item is already assigned to some menu and aMenu is not nil
	if (_menu && aMenu)
		[NSException raise:NSInvalidArgumentException format:@"Item to be added to menu already is in another menu"];
	
	_menu = aMenu;
}


- (NSRect)frame {
	return [[_representedViewController view] frame];
}


- (NSRect)frameRelativeToMenu {
	NSRect frame = [[_representedViewController view] convertRect:[[_representedViewController view] bounds] toView:nil];
	return frame;
}


- (NSRect)frameRelativeToScreen {
	NSRect frame = [self frameRelativeToMenu];
	return [_menu convertRectToScreen:frame];
}

- (BOOL)isSelected {
	return _isSelected;
}

- (BOOL)mouseOver {
	return _mouseOver;
}


- (void)select {
	if (_isSelected || _isSeparatorItem)
		return;
	
	NSArray *items = [_menu itemArray];
	for (CMMenuItem *item in items) {
		if (self != item && [item isSelected]) {
//			NSLog(@"BEFORE SELECTING, DESELECT: %@", item);
			[item deselect];
		}
	}
	
	_isSelected = YES;
//	NSLog(@"AND NOW SELECTED: %@", self);
	[(CMMenuItemView *)[_representedViewController view] setSelected:YES];
}


- (void)selectWithDelayForSubmenu:(NSTimeInterval)delay {
	if (_isSeparatorItem)
		return;

	//	_isSelected = YES;
//	[(CMMenuItemView *)[_representedViewController view] setSelected:YES];
	
	[self select];

	if ([self hasSubmenu]) {
//		[self performSelector:@selector(showItemSubmenu) withObject:nil afterDelay:delay];
//		[self performSelector:@selector(showItemSubmenu) withObject:nil afterDelay:delay inModes:[NSArray arrayWithObject:NSEventTrackingRunLoopMode]];
		[self performSelector:@selector(showItemSubmenu) withObject:nil afterDelay:delay inModes:[NSArray arrayWithObject:NSRunLoopCommonModes]];
		_submenuIntervalIsSetToPopup = YES;
	}
}


- (void)deselect {
	if (! _isSelected)
		return;
	
	_isSelected = NO;
//	NSLog(@"ITEM DESELECTED: %@", self);
	[(CMMenuItemView *)[_representedViewController view] setSelected:NO];
}


- (NSString *)description {
	NSMutableString *description = [[NSMutableString alloc] initWithString:[super description]];

	/*
	id currentClass = [self class];
	NSString *propertyName;
	unsigned int outCount, i;
	objc_property_t *properties = class_copyPropertyList(currentClass, &outCount);
	for (i = 0; i < outCount; ++i) {
		objc_property_t property = properties[i];
		propertyName = [NSString stringWithCString:property_getName(property) encoding:NSASCIIStringEncoding];
		[description appendFormat:@"\n\t%@: %@", propertyName, [self valueForKey:propertyName]];
    }
	free(properties);
	
	// if object was subclassed, let's print parent's properties
	if (![[self className] isEqualToString:@"CMMenuItem"]) {
		[description appendFormat:@"\n\ttitle: %@", _title];
		[description appendFormat:@"\n\ticon: %@", _icon];
	}
	 */
	if (_isSeparatorItem)
		[description appendFormat:@" -----"];
	else
		[description appendFormat:@" %@", _title];
	
	return [description autorelease];
}


@end
