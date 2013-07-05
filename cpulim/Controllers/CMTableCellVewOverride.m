//
//  CMTableCellVewOverride.m
//  Ishimura
//
//  Created by Maksym on 7/5/13.
//  Copyright (c) 2013 Maksym Stefanchuk. All rights reserved.
//

#import "CMTableCellVewOverride.h"

@implementation CMTableCellVewOverride

@synthesize statusIcon = _statusIcon;

- (void)setStatusIconProperty:(NSImage *)aImage {
	[_statusIcon setImage:aImage];
}

@end
