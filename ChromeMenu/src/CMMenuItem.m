//
//  CMMenuItem.m
//  Ishimura
//
//  Created by Maksym on 7/4/13.
//  Copyright (c) 2013 Maksym Stefanchuk. All rights reserved.
//

#import "CMMenuItem.h"
#import <objc/runtime.h>

@implementation CMMenuItem

//@synthesize itemIcon;
//@synthesize itemText;

- (id)initWithTitle:(NSString *)aTitle {
	if (self = [super init]) {
		[self setTitle:aTitle];
		_isSeparatorItem = NO;
	}
	return self;
}


- (void)dealloc {
	[_icon release];
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

- (void)setIcon:(NSImage *)aImage {
	[aImage retain];
	_icon = aImage;
}

- (NSImage *)icon {
	return _icon;
}

- (BOOL)isSeparatorItem {
	return _isSeparatorItem;
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
