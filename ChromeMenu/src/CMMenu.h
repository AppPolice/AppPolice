//
//  ChromeMenu.h
//  Ishimura
//
//  Created by Maksym on 7/3/13.
//  Copyright (c) 2013 Maksym Stefanchuk. All rights reserved.
//

//#import <Foundation/Foundation.h>
//#import "CMMenuItem.h"


//@class ChromeMenuUnderlyingWindow, ChromeMenuUnderlyingView, CMTableCellView;
@class NSString, NSArray, NSIndexSet;
@class CMMenuItem;


@interface CMMenu : NSObject
{
	@private
	CMMenu *_supermenu;
//	IBOutlet ChromeMenuUnderlyingWindow *_underlyingWindow;
//	IBOutlet ChromeMenuUnderlyingView *_underlyingView;
//	IBOutlet NSTableView *_menuTableView;
	
	NSMutableArray *_menuItems;
}

//- (id)initWithItems:(NSArray *)items;



/* Returns the menu containing the item that has the receiver as a submenu, or nil if this menu is not the submenu of an item in a menu. */
- (CMMenu *)supermenu;


- (void)addItem:(CMMenuItem *)newItem;

- (void)setDefaultViewForItemsFromNibNamed:(NSString *)nibName andPropertyNames:(NSArray *)propertyNames;

/* Same as [anItem setSubmenu:aMenu].  anItem may not be nil. */
- (void)setSubmenu:(CMMenu *)aMenu forItem:(CMMenuItem *)anItem;


/* Returns an item of supermenu */
- (CMMenuItem *)parentItem;

/* Returns an array containing the receiver's menu items. */
- (NSArray *)itemArray;

/* Returns the number of menu items in the menu. */
- (NSInteger)numberOfItems;

/* Returns the item at the given index, which must be at least zero and less than the number of items. */
- (id)itemAtIndex:(NSInteger)index;

/* Returns the index of the item in the menu, or -1 if the item is not present in the menu */
- (NSInteger)indexOfItem:(CMMenuItem *)index;

/* Returns the item at given point */
- (CMMenuItem *)itemAtPoint:(NSPoint)aPoint;

/* Returns item of a supermenu the menu belongs to. Otherwise returns nil */
//- (CMMenuItem *)parentItem;


/* Update only particular menu items */
- (void)updateItemsAtIndexes:(NSIndexSet *)indexes;

/* this is an actual table reload, scary thing. must be taken care of */
//- (void)update;

- (void)startMenu;
//- (void)showMenu;

/* Dismisses the menu and ends all menu tracking */
- (void)cancelTracking;

/* Dismisses the menu immediately, without any fade or other effect, and ends all menu tracking */
- (void)cancelTrackingWithoutAnimation;

/* Returns the highlighted item in the menu, or nil if no item in the menu is highlighted */
- (CMMenuItem *)highlightedItem;

/* Set the minimum width of the menu, in screen coordinates. The menu will prefer to not draw smaller than its minimum width, but may draw larger if it needs more space. The default value is 0.
 */
- (CGFloat)minimumWidth;
- (void)setMinimumWidth:(CGFloat)width;

/* Returns the size of the menu, in screen coordinates.  The menu may draw at a smaller size when shown, depending on its positioning and display configuration.
 */
- (NSSize)size;

/* Returns Menu border radius */
- (CGFloat)borderRadius;
- (void)setBorderRadius:(CGFloat)radius;


@end
