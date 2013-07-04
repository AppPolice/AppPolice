//
//  ChromeMenu.m
//  Ishimura
//
//  Created by Maksym on 7/3/13.
//  Copyright (c) 2013 Maksym Stefanchuk. All rights reserved.
//

#import "CMMenu.h"

@implementation CMMenu

- (id)init {
	if (self = [super init]) {
		[NSBundle loadNibNamed:[self className] owner:self];
	}
	return self;
}

- (id)initWithTitle:(NSString *)aTitle {
	if (self = [super init]) {
		[NSBundle loadNibNamed:[self className] owner:self];
		[title setStringValue:aTitle];
	}
	return self;
}

- (void)awakeFromNib {
	NSLog(@"%@ awakeFromNib", [self className]);
}

@end
