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
#import <objc/runtime.h>


/*
 * Private declarations
 */
@interface CMMenuItem()
{
	BOOL _isSelected;
	BOOL _mouseOver;						// this doesn't mean the item is selected (e.g. during submenu tracking)
	int _submenuIntervalIsSetToPopup;
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



- (id)initWithTitle:(NSString *)aTitle {
	if (self = [super init]) {
		[self setTitle:aTitle];
		_isSeparatorItem = NO;
	}
	return self;
}

- (id)initWithTitle:(NSString *)aTitle andIcon:(NSImage *)anImage {
	self = [self initWithTitle:aTitle];
	if (self) {
		[self setIcon:anImage];
	}
	return self;
}


- (void)dealloc {
	[_icon release];
	if (_viewNibName) {
//		[_viewIdentifier release];
		[_viewNibName release];
		[_viewPropertyNames release];
	}
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
	_title = aTitle;
}

- (NSString *)title {
	return _title;
}

- (void)setIcon:(NSImage *)anImage {
	[anImage retain];
	_icon = anImage;
}

- (NSImage *)icon {
	return _icon;
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

//- (void)setViewFromNibNamed:(NSString *)nibName withIdentifier:(NSString *)identifier andPropertyNames:(NSArray *)propertyNames {
- (void)setViewFromNibNamed:(NSString *)nibName andPropertyNames:(NSArray *)propertyNames {
//	if (nibName == nil || [nibName isEqualToString:@""] || identifier == nil || [identifier isEqualToString:@""] || propertyNames == nil)
	if (nibName == nil || [nibName isEqualToString:@""] || propertyNames == nil)
		[NSException raise:NSInvalidArgumentException format:@"Bad arguments provided in -%@", NSStringFromSelector(_cmd)];
	_viewNibName = [nibName retain];
//	_viewIdentifier = [identifier retain];
	_viewPropertyNames = [propertyNames retain];
}


#pragma mark -
#pragma mark ***** Events and Tracking methods *****



//- (void)mouseEntered:(NSEvent *)theEvent {
//	if (_submenu) {
//		[self performSelector:@selector(showSubmenu) withObject:nil afterDelay:0.2];
//		_submenuIntervalSetToPopup = 1;
////		[_submenu showMenu];
//	}
//}
//
//
//- (void)mouseExited:(NSEvent *)theEvent {
//	if (_submenu) {
//		if (_submenuIntervalSetToPopup)
//			[NSObject cancelPreviousPerformRequestsWithTarget:self];
//		else
//			[_submenu cancelTrackingWithoutAnimation];
//	}
//}


//- (void)mouseDown:(NSEvent *)theEvent {
//	// submenu should always stay on top
////	if (_submenu)
////		[_submenu orderFront];
//	
//	NSLog(@"submenu window number: %ld, parnet menu WN: %ld", [_submenu windowLevel], [_menu windowLevel]);
//}


- (BOOL)shouldChangeItemSelectionStatusForEvent:(CMMenuEventType)eventType {
	BOOL changeStatus = YES;
	
	if (eventType & CMMenuEventMouseEnteredItem) {
		_mouseOver = YES;
		
		if (_isSelected) {
			changeStatus = NO;
			if ([[self menu] isTrackingSubmenu])
				[[self menu] stopTrackingSubmenuReasonSuccess:YES];
		} else {
			if ([[self menu] activeSubmenu]) {
				// must do work here
				changeStatus = NO;
			} else {
				_isSelected = YES;
				
				if ([self hasSubmenu]) {
					[self performSelector:@selector(showItemSubmenu) withObject:nil afterDelay:0.2];
					_submenuIntervalIsSetToPopup = 1;
				}
			}
		}
	} else if (eventType & CMMenuEventMouseExitedItem) {
		_mouseOver = NO;
		
		if ([[self menu] activeSubmenu]) {
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
	
	return changeStatus;
}


- (void)showItemSubmenu {
	_submenuIntervalIsSetToPopup = 0;
//	[_submenu showMenu];
	[_submenu showMenuAsSubmenuOf:self];
}





#pragma mark -
#pragma mark ***** CMMenuItem Internal Methods *****


- (void)setRepresentedViewController:(NSViewController *)viewController {
	_representedViewController = viewController;
}


- (void)setMenu:(CMMenu *)aMenu {
	if (_menu != aMenu)
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


- (BOOL)mouseOver {
	return _mouseOver;
}


- (void)selectWithDelayForSubmenu:(NSTimeInterval)delay {
	_isSelected = YES;
	[(CMMenuItemView *)[_representedViewController view] setSelected:YES];
//	BOOL res = [self shouldChangeItemSelectionStatusForEvent:CMMenuEventMouseEnteredItem];
//	NSLog(@"res: %d", res);
	if ([self hasSubmenu]) {
		[self performSelector:@selector(showItemSubmenu) withObject:nil afterDelay:delay];
		_submenuIntervalIsSetToPopup = 1;
	}
}


- (void)deselect {
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
	
	[description appendFormat:@"\nTitle: %@", _title];
	
	return description;
}


@end
