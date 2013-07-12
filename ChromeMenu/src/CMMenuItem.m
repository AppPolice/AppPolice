//
//  CMMenuItem.m
//  Ishimura
//
//  Created by Maksym on 7/4/13.
//  Copyright (c) 2013 Maksym Stefanchuk. All rights reserved.
//

#import "CMMenuItem.h"
#import "CMMenu.h"
#import <objc/runtime.h>


/*
 * Private declarations
 */
@interface CMMenuItem()
{
	int _submenuIntervalSetToPopup;
}

- (void)setMenu:(CMMenu *)aMenu;
- (void)mouseEntered:(NSEvent *)theEvent;
- (void)mouseExited:(NSEvent *)theEvent;
- (void)mouseDown:(NSEvent *)theEvent;
- (void)showSubmenu;

@end


@interface CMMenu (CMMenuPrivateMethods)
- (void)setSupermenu:(CMMenu *)aMenu;
- (void)showMenuAsSubmenuOf:(CMMenuItem *)menuItem;	// may not be needed
//- (void)orderFront;
- (NSInteger)windowLevel;
@end




@implementation CMMenuItem

@synthesize viewNibName = _viewNibName;
@synthesize viewIdentifier = _viewIdentifier;
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
	if (_viewIdentifier) {
		[_viewIdentifier release];
		[_viewNibName release];
		[_viewPropertyNames release];
	}
	[super dealloc];
}


+ (CMMenuItem *)separatorItem {
	CMMenuItem *instance = [[[self alloc] init] autorelease];
	if (instance) {
		instance->_isSeparatorItem = YES;
	}
	return instance;
}


- (void)setMenu:(CMMenu *)aMenu {
	if (_menu != aMenu)
		_menu = aMenu;
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
	if (submenu == nil)
		[NSException raise:NSInvalidArgumentException format:@"Bad argument provided in -%@", NSStringFromSelector(_cmd)];
	
	_submenu = [submenu retain];
	[_submenu setSupermenu:[self menu]];
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

- (void)setViewFromNibNamed:(NSString *)nibName withIdentifier:(NSString *)identifier andPropertyNames:(NSArray *)propertyNames {
	if (nibName == nil || [nibName isEqualToString:@""] || identifier == nil || [identifier isEqualToString:@""] || propertyNames == nil)
		[NSException raise:NSInvalidArgumentException format:@"Bad arguments provided in -%@", NSStringFromSelector(_cmd)];
	_viewNibName = [nibName retain];
	_viewIdentifier = [identifier retain];
	_viewPropertyNames = [propertyNames retain];
}


- (void)mouseEntered:(NSEvent *)theEvent {
	if (_submenu) {
		[self performSelector:@selector(showSubmenu) withObject:nil afterDelay:0.2];
		_submenuIntervalSetToPopup = 1;
//		[_submenu showMenu];
	}
}


- (void)mouseExited:(NSEvent *)theEvent {
	if (_submenu) {
		if (_submenuIntervalSetToPopup)
			[NSObject cancelPreviousPerformRequestsWithTarget:self];
		else
			[_submenu cancelTrackingWithoutAnimation];
	}
}


- (void)mouseDown:(NSEvent *)theEvent {
	// submenu should always stay on top
//	if (_submenu)
//		[_submenu orderFront];
	
	NSLog(@"submenu window number: %ld, parnet menu WN: %ld", [_submenu windowLevel], [_menu windowLevel]);
}


- (void)showSubmenu {
	_submenuIntervalSetToPopup = 0;
//	[_submenu showMenu];
	[_submenu showMenuAsSubmenuOf:self];
}



- (NSString *)description {
	NSMutableString *description = [[NSMutableString alloc] initWithString:[super description]];
	
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
	
	return description;
}


@end
