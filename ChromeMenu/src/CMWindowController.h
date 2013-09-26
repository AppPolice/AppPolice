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

/**
 * @function displayInFrame: ignoreMouse:
 * @abstract Show underlying window in frame.
 * @param frame Rect in which to show a menu.
 * @param ignoreMouse When menu is first displayed, tracking areas for its menu items are being created.
 *	This option regulates whether we will capture the current mouse position and highlight according menu item
 *	underneath it. In some situations, for example when use keyboard navigation and open submenu with right arrow,
 *	you do not expect a menu item underneath mouse to be selected. It will get selected if mouse moves however.
 */
- (void)displayInFrame:(NSRect)frame ignoreMouse:(BOOL)ignoreMouse;
- (void)updateFrame:(NSRect)frame ignoreMouse:(BOOL)ignoreMouse;
- (void)hide;

- (void)insertView:(NSViewController *)viewController atIndex:(NSUInteger)index;
- (void)addView:(NSViewController *)viewController;

- (void)beginEventTracking;
- (void)endEventTracking;

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
