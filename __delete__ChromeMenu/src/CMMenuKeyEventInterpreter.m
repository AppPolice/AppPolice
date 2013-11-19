//
//  CMMenuKeyEventInterpreter.m
//  Ishimura
//
//  Created by Maksym on 9/16/13.
//  Copyright (c) 2013 Maksym Stefanchuk. All rights reserved.
//

#import <AppKit/AppKit.h>
#import "CMMenuKeyEventInterpreter.h"


@implementation CMMenuKeyEventInterpreter

- (id)initWithDelegate:(id <CMMenuKeyEventInterpreterDelegate>)delegate {
	self = [super init];
	if (self) {
		if (delegate == nil)
			[NSException raise:NSInvalidArgumentException format:@"Menu key events interpreter target cannot be nil."];
		_delegate = delegate;
	}
	
	return self;
}


- (void)setDelegate:(id <CMMenuKeyEventInterpreterDelegate>)delegate {
	if (_delegate != delegate) {
		_delegate = delegate;
	}
}


- (void)interpretEvent:(NSEvent *)theEvent {
	if (! _delegate)
		return;
			
	NSEventType eventType = [theEvent type];
	NSUInteger modifierFlags = [theEvent modifierFlags];
	
	if (eventType == NSKeyDown) {
		unsigned short keyCode = [theEvent keyCode];
//			NSLog(@"key code: %d, modifier: %lu", keyCode, modifierFlags);
		
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
				
			case 53:		// Esc
				action = @selector(cancelOperation:);
				break;
				
			case 47:		// .
				if (modifierFlags & NSCommandKeyMask) {
					action = @selector(cancelOperation:);
				}
				break;
				
			case 36:		// Enter
				action = @selector(performSelected:);
				break;
				
			default:
				break;
		}
		
		if (action && [_delegate respondsToSelector:action])
			[_delegate performSelector:action withObject:theEvent];
		
//			theEvent = nil;
		
	} else if (eventType == NSFlagsChanged) {
//		NSLog(@"modifier flag changed! : %ld", modifierFlags);
	}
}


@end
