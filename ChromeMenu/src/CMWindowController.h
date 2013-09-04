//
//  CMMenuWindowController.h
//  Ishimura
//
//  Created by Maksym on 7/12/13.
//  Copyright (c) 2013 Maksym Stefanchuk. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface CMWindowController : NSWindowController


/* The designated initializer. This window controller creates its own custom suggestions window. */
- (id)initWithOwner:(id)owner;

- (void)layoutViews:(NSMutableArray *)viewControllers;

//- (void)display;
- (void)displayInFrame:(NSRect)frame;
- (void)hide;

- (NSSize)intrinsicContentSize;
- (CGFloat)verticalPadding;

/**
 * @function viewController:
 * @abastract Returns the view controller at a given point.
 * @discussion Point should be in Window coordinates.
 * @param aPoint Point in NSWindow coordinates.
 */
- (NSViewController *)viewControllerAtPoint:(NSPoint)aPoint;

@end
