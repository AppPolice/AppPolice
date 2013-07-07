//
//  CMMenuItem.m
//  Ishimura
//
//  Created by Maksym on 7/4/13.
//  Copyright (c) 2013 Maksym Stefanchuk. All rights reserved.
//

#import "CMMenuItem.h"
#import <objc/runtime.h>

/*
 * Private declarations
 */
@interface CMMenuItem()
{
	
}
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
