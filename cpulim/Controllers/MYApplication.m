//
//  MYApplication.m
//  Ishimura
//
//  Created by Maksym on 07/11/13.
//  Copyright (c) 2013 Maksym Stefanchuk. All rights reserved.
//

#import "MYApplication.h"

@implementation MYApplication

- (void)sendEvent:(NSEvent *)theEvent {
	NSLog(@"applicatoin send event: %@", theEvent);
	[super sendEvent:theEvent];
}

@end
