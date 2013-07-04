//
//  CMMenuItem.m
//  Ishimura
//
//  Created by Maksym on 7/4/13.
//  Copyright (c) 2013 Maksym Stefanchuk. All rights reserved.
//

#import "CMMenuItem.h"

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

@end
