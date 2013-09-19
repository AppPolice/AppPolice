//
//  CMMenuKeyEventInterpreter.m
//  Ishimura
//
//  Created by Maksym on 9/16/13.
//  Copyright (c) 2013 Maksym Stefanchuk. All rights reserved.
//

#import "CMMenuKeyEventInterpreter.h"

@implementation CMMenuKeyEventInterpreter

- (id)initWithTarget:(id)target {
	self = [super init];
	if (self) {
		if (target == nil)
			[NSException raise:NSInvalidArgumentException format:@"Menu key events interpreter target cannot be nil."];
		_target = target;
	}
	
	return self;
}


- (void)dealloc {
	[NSEvent removeMonitor:_localEventMonitor];
	
	[super dealloc];
}


- (void)setTarget:(id)target {
	if (_target != target) {
		_target = target;
	}
}


- (void)start {
	if (! _target || _localEventMonitor)
		return;
	
	_localEventMonitor = [NSEvent addLocalMonitorForEventsMatchingMask:(NSKeyDownMask | NSFlagsChangedMask) handler:^(NSEvent *theEvent) {
		NSLog(@"key event: %@", theEvent);
		
		NSEventType eventType = [theEvent type];
		
		if (eventType == NSKeyDown) {
			unsigned short keyCode = [theEvent keyCode];
//			NSLog(@"key code: %d", keyCode);
			
			SEL action = nil;
			
			switch (keyCode) {
				case 123:
					action = @selector(moveLeft:);
					break;
					
				case 124:
					action = @selector(moveRight:);
					break;

				case 125:
					action = @selector(moveDown:);
					break;

				case 126:
					action = @selector(moveUp:);
					break;
					
				default:
					break;
			}
			
			if (action && [_target respondsToSelector:action])
				[_target performSelector:action withObject:self];
			
			theEvent = nil;
			
		} else if (eventType == NSFlagsChanged) {
			NSUInteger modifierFlags = [theEvent modifierFlags];
			NSLog(@"modifier flag changed! : %ld", modifierFlags);
		}
		
	

		
		
	
		
		return theEvent;
	}];
}


- (void)stop {
	if (! _localEventMonitor)
		return;
	
	[NSEvent removeMonitor:_localEventMonitor];
	_localEventMonitor = nil;
}

@end
