//
//  ChromMenuUnderlyingView.h
//  Ishimura
//
//  Created by Maksym on 7/3/13.
//  Copyright (c) 2013 Maksym Stefanchuk. All rights reserved.
//

//#import <Cocoa/Cocoa.h>
@class NSView;

@interface ChromeMenuUnderlyingView : NSView
{
	NSArray *_borderRadius;
}

/**
 * @abstract Designated initializer
 * @param radius Array of four radiuses for bottom left, top left, top right and bottom right radiuses.
 */
- (id)initWithFrame:(NSRect)frameRect borderRadius:(NSArray *)radius;


@end
