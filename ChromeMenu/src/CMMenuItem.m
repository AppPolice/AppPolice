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
#import "CMMenuItemView+InternalMethods.h"
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
	// Mouse can be over item if it is not selected (e.g. during submenu tracking)
	BOOL _mouseOver;
	BOOL _submenuIntervalIsSetToPopup;
	NSViewController *_representedViewController;
	
	NSImage *_offStateImage;
	NSImage *_onStateImage;
	NSImage *_mixedStateImage;
}

- (void)showItemSubmenu;

@end



@implementation CMMenuItem


- (id)initWithTitle:(NSString *)aTitle action:(SEL)aSelector {
	if (self = [super init]) {
		[self setTitle:aTitle];
		_isSeparatorItem = NO;
		_enabled = YES;
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
	[_icon release];
	[_offStateImage release];
	[_onStateImage release];
	[_mixedStateImage release];
	
	[super dealloc];
}


+ (CMMenuItem *)separatorItem {
	CMMenuItem *instance = [[self alloc] init];
	if (instance) {
		instance->_isSeparatorItem = YES;
	}
	return [instance autorelease];
}


- (CMMenu *)menu {
	return _menu;
}


- (void)setTitle:(NSString *)aTitle {
//	if (! aTitle) {
//		[NSException raise:NSInvalidArgumentException format:@"No title provided for a menu item -setTitle:"];
//		return;
//	}
	NSAssert(aTitle != nil, @"Invalid parameter not satisfying: aTitle != nil");
	
	if (_title == aTitle)
		return;
	
	if (_title)
		[_title release];
	_title = [aTitle copy];
	if (_representedViewController)
		[[(CMMenuItemView *)[_representedViewController view] title] setStringValue:aTitle];

//	if ([_menu needsDisplay])	// menu will update item's title itself, no more actions are required.
//		return;
	
	// Update menu's size and position if needed
	[_menu setNeedsDisplay:YES];
}


- (NSString *)title {
	return _title;
}


- (void)setIcon:(NSImage *)anImage {
	if (_icon != anImage) {
		if (_icon)
			[_icon release];
		
		_icon = [anImage copy];
	}
}


- (NSImage *)icon {
	return _icon;
}


- (void)setState:(NSInteger)state {
	if (_state != state) {
		_state = state;
		// If item has never been shown yet it doesn't have |_representedViewController|
		// In that case just skip the part -- icon will be set when item is drawn first time.
		if (_representedViewController) {
			CMMenuItemView *view = (CMMenuItemView *)[_representedViewController view];
			if (state == NSOffState) {
				[[view state] setImage:nil];
			} else if (state == NSOnState) {
				[[view state] setImage:[self onStateImage]];
			} else {
				[[view state] setImage:[self mixedStateImage]];
			}
			[view setNeedsDisplay:YES];
		}
	}
}


- (NSInteger)state {
	return _state;
}


- (NSImage *)offStateImage {
	return (_offStateImage) ? _offStateImage : nil;
}


- (void)setOffStateImage:(NSImage *)image {
	if (_offStateImage == image)
		return;
//
//	if (_offStateImage)
//		[_offStateImage release];
//	if (image)
//		_offStateImage = [image retain];
//	else
//		_offStateImage = nil;
	[_offStateImage release];
	_offStateImage = [image retain];
	if (_representedViewController) {
		CMMenuItemView *view = (CMMenuItemView *)[_representedViewController view];
		[[view state] setImage:[self offStateImage]];
		[view setNeedsDisplay:YES];
	}

}


- (NSImage *)onStateImage {
	return (_onStateImage) ? _onStateImage : [NSImage imageNamed:NSImageNameMenuOnStateTemplate];
}


- (void)setOnStateImage:(NSImage *)image {
	if (_onStateImage == image)
		return;
//
//	if (_onStateImage)
//		[_onStateImage release];
//	if (image)
//		_onStateImage = [image retain];
//	else
//		_onStateImage = nil;

	[_onStateImage release];
	_onStateImage = [image retain];
	if (_representedViewController) {
		CMMenuItemView *view = (CMMenuItemView *)[_representedViewController view];
		[[view state] setImage:[self onStateImage]];
		[view setNeedsDisplay:YES];
	}
}


- (NSImage *)mixedStateImage {
	return (_mixedStateImage) ? _mixedStateImage : [NSImage imageNamed:NSImageNameMenuMixedStateTemplate];
}


- (void)setMixedStateImage:(NSImage *)image {
	if (_mixedStateImage == image)
		return;
//
//	if (_mixedStateImage)
//		[_mixedStateImage release];
//	if (image)
//		_mixedStateImage = [image retain];
//	else
//		_mixedStateImage = nil;
	[_mixedStateImage release];
	_mixedStateImage = [image retain];
	if (_representedViewController) {
		CMMenuItemView *view = (CMMenuItemView *)[_representedViewController view];
		[[view state] setImage:[self mixedStateImage]];
		[view setNeedsDisplay:YES];
	}

}


- (BOOL)isEnabled {
	return _enabled;
}


- (void)setEnabled:(BOOL)flag {
	if (_isSeparatorItem)
		return;
	
	if (_enabled != flag) {
		_enabled = flag;
		CMMenuItemView *view = (CMMenuItemView *)[_representedViewController view];
		[view setEnabled:flag];
		[view setSelected:NO];
		if (flag == NO && [_submenu isActive]) {
			[_submenu cancelTrackingWithoutAnimation];
		}
		[[self menu] updateTrackingPrimitiveForItem:self];
	}
}


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


- (CMMenu *)submenu {
	return _submenu;
}


- (BOOL)hasSubmenu {
	return (_submenu) ? YES : NO;
}


- (BOOL)isSeparatorItem {
	return _isSeparatorItem;
}


- (void)setIndentationLevel:(NSInteger)indentationLevel {
	if (indentationLevel < 0) {
		[NSException raise:NSInvalidArgumentException format:@"CMMenuItem indentationLevel cannot be less then 0"];
		return;
	} else if (indentationLevel > 15)
		indentationLevel = 15;
	
	_indentationLevel = indentationLevel;
	if (_representedViewController) {
		CMMenuItemView *view =  (CMMenuItemView *)[_representedViewController view];
		NSLog(@"item view: %@", view);
		[view setIndentationLevel:indentationLevel];
		// If menu item with new indentation is wider then the menu currently is
		// redraw menu with new size and position
		if ([view fittingSize].width > [_menu frame].size.width)
			[_menu setNeedsDisplay:YES];
	}
}


- (NSInteger)indentationLevel {
	return _indentationLevel;
}


- (void)setTarget:(id)anObject {
	_target = anObject;	// not retained?
}


- (id)target {
	return  _target;
}


- (void)setAction:(SEL)aSelector {
	_action =  aSelector;
}


- (SEL)action {
	return _action;
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
					// TODO: Take care of this part: either provide comment what it does or edit it!
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
				
				if ([self hasSubmenu] && [_submenu numberOfItems]) {
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
//	NSLog(@"show item submenu: %@", _title);
	_submenuIntervalIsSetToPopup = NO;
	[_submenu showAsSubmenuOf:self withOptions:CMMenuOptionDefaults];
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
	if (_isSelected || _isSeparatorItem || !_enabled)
		return;
	
	NSArray *items = [_menu itemArray];
	for (CMMenuItem *item in items) {
		if (self != item && [item isSelected]) {
			[item deselect];
		}
	}
	
	_isSelected = YES;
	[(CMMenuItemView *)[_representedViewController view] setSelected:YES];
}


- (void)selectWithDelayForSubmenu:(NSTimeInterval)delay {
	if (_isSeparatorItem || !_enabled)
		return;

	[self select];

	if ([self hasSubmenu] && [_submenu numberOfItems]) {
//		[self performSelector:@selector(showItemSubmenu) withObject:nil afterDelay:delay inModes:[NSArray arrayWithObject:NSEventTrackingRunLoopMode]];
		[self performSelector:@selector(showItemSubmenu) withObject:nil afterDelay:delay inModes:[NSArray arrayWithObject:NSRunLoopCommonModes]];
		_submenuIntervalIsSetToPopup = YES;
	}
}


- (void)deselect {
	if (! _isSelected)
		return;
	
	_isSelected = NO;
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
