//
//  CMMenuWindowController.h
//  Ishimura
//
//  Created by Maksym on 7/12/13.
//  Copyright (c) 2013 Maksym Stefanchuk. All rights reserved.
//

//#import <Cocoa/Cocoa.h>

@class NSWindowController, NSViewController, NSMutableArray;
@class CMMenu, CMMenuScroller;

@interface CMWindowController : NSWindowController


/* The designated initializer. This window controller creates its own custom suggestions window. */
- (id)initWithOwner:(CMMenu *)owner;

- (void)layoutViews:(NSMutableArray *)viewControllers;

//- (void)display;
- (void)displayInFrame:(NSRect)frame ignoreMouse:(BOOL)ignoreMouse;
- (void)hide;

- (NSSize)intrinsicContentSize;

/**
 * @function verticalPadding
 * @abstract The top and bottom padding for the menu.
 */
- (CGFloat)verticalPadding;

/**
 * @function viewController:
 * @abastract Returns the view controller at a given point.
 * @discussion Point should be coordinates relative to Menu.
 * @param aPoint Point in NSWindow (Menu) coordinates.
 */
- (NSViewController *)viewAtPoint:(NSPoint)aPoint;


- (CMMenuScroller *)scrollerAtPoint:(NSPoint)aPoint;
- (void)scrollWithActiveScroller:(CMMenuScroller *)scroller;


- (void)moveVisibleRectToRect:(NSRect)rect ignoreMouse:(BOOL)ignoreMouse;

- (void)updateContentViewTrackingAreaTrackMouseMoved:(BOOL)trackMouseMoved;

@end
