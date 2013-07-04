//
//  AppInspectorController.m
//  Ishimura
//
//  Created by Maksym on 7/2/13.
//  Copyright (c) 2013 Maksym Stefanchuk. All rights reserved.
//

#import "AppInspectorController.h"

@implementation AppInspectorController


- (id)init {
	if (self = [super init]) {
		[NSBundle loadNibNamed:@"AppInspector" owner:self];
		[NSBundle loadNibNamed:@"PopoverContentView" owner:self];
	}
	return self;
}


- (void)awakeFromNib {
	NSLog(@"%@ awakeFromNib", [self className]);
	[popoverViewController setView:popoverView];
}


- (void)showAppDetailsPopoverRelativeTo:(NSView *)view {
//	if (popoverViewController == nil) {
//		popoverViewController = [[NSViewController alloc] initWithNibName:@"AppInspector" bundle:[NSBundle mainBundle]];
//	}
	
	
	NSLog(@"called show popover: %@", popoverViewController);
	[popover showRelativeToRect:[view bounds] ofView:view preferredEdge:NSMaxXEdge];
}

@end
