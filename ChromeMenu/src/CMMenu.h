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


enum {
	CMMenuAnimationEffectNone = 0x0,
	CMMenuAnimationEffectFade = 0x01
};
typedef NSUInteger CMMenuAnimationOptions;


@interface CMMenu : NSObject
{
	@private
	NSString *_title;
	CMMenu *_supermenu;
//	IBOutlet ChromeMenuUnderlyingWindow *_underlyingWindow;
//	IBOutlet ChromeMenuUnderlyingView *_underlyingView;
//	IBOutlet NSTableView *_menuTableView;
	
	NSMutableArray *_menuItems;
}


/* Designated initializer.  If this menu is used as a submenu of an item in the application's main menu, then the title is what appears in the menu bar.  Otherwise, the title is ignored.  Do not pass nil (an exception will result), but you may pass an empty string.
 */
- (id)initWithTitle:(NSString *)aTitle;

/* Set and get the menu's title.  The titles of the submenus of the application's main menu items appear in the menu bar. */
- (void)setTitle:(NSString *)aString;
- (NSString *)title;



/* Returns the menu containing the item that has the receiver as a submenu, or nil if this menu is not the submenu of an item in a menu. */
- (CMMenu *)supermenu;


//- (void)addItem:(CMMenuItem *)newItem;

- (void)setDefaultViewForItemsFromNibNamed:(NSString *)nibName andPropertyNames:(NSArray *)propertyNames;

/* Same as [anItem setSubmenu:aMenu].  anItem may not be nil. */
- (void)setSubmenu:(CMMenu *)aMenu forItem:(CMMenuItem *)anItem;


/* Returns an array containing the receiver's menu items. */
- (NSArray *)itemArray;

/* Returns the number of menu items in the menu. */
- (NSInteger)numberOfItems;

/* Returns the item at the given index, which must be at least zero and less than the number of items. */
- (id)itemAtIndex:(NSInteger)index;

/* Returns the index of the item in the menu, or -1 if the item is not present in the menu */
- (NSInteger)indexOfItem:(CMMenuItem *)item;

/* Returns the item at given point */
- (CMMenuItem *)itemAtPoint:(NSPoint)aPoint;

/* Returns item of a supermenu the menu belongs to. Otherwise returns nil */
- (CMMenuItem *)parentItem;

/* Inserts a menu item at the given index, which must be at least zero and no more than the receiver's item count.  If newItem is nil, this raises an exception. */
- (void)insertItem:(CMMenuItem *)newItem atIndex:(NSUInteger)index animate:(BOOL)animate;

/* Appends an item to the end of the menu.  A nil item will raise an exception. */
- (void)addItem:(CMMenuItem *)newItem;
- (void)addItem:(CMMenuItem *)newItem animate:(BOOL)animate;


/* Removes the item at the given index, which must be at least zero and less than the number of items.  All subsequent items will shift down one index. */
- (void)removeItemAtIndex:(NSInteger)index animate:(BOOL)animate;

/* Removes the item from the menu.  If the item is nil, or is not present in the receiver, an exception will be raised. */
- (void)removeItem:(CMMenuItem *)item animate:(BOOL)animate;


/* this is an actual table reload, scary thing. must be taken care of */
//- (void)update;

- (void)start;
//- (void)showMenu;

/* Dismisses the menu and ends all menu tracking */
- (void)cancelTracking;

/* Dismisses the menu immediately, without any fade or other effect, and ends all menu tracking */
- (void)cancelTrackingWithoutAnimation;

/* Default YES */
- (BOOL)cancelsTrackingOnAction;
- (void)setCancelsTrackingOnAction:(BOOL)cancels;
/* Default YES */
- (BOOL)cancelsTrackingOnMouseEventOutsideMenus;
- (void)setCancelsTrackingOnMouseEventOutsideMenus:(BOOL)cancels;
/* Reciever's parent menus (supermenus) will stop tracking mouse, allowing to make mouse movements outside of menu withough closing its tracking. */
//- (BOOL)crystallizedSupermenus;
- (BOOL)menusSuspended;
//- (void)setCrystallizeSupermenus:(BOOL)crystallize;
- (void)setSuspendMenus:(BOOL)suspend;


/* Returns the highlighted item in the menu, or nil if no item in the menu is highlighted */
- (CMMenuItem *)highlightedItem;


- (void)showPopover:(NSPopover *)popover forItem:(CMMenuItem *)item;


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
