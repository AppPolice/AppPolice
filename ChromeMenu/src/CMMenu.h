//
//  ChromeMenu.h
//  Ishimura
//
//  Created by Maksym on 7/3/13.
//  Copyright (c) 2013 Maksym Stefanchuk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CMMenuItem.h"

@class ChromeMenuUnderlyingWindow, ChromeMenuUnderlyingView, CMTableCellView;

@interface CMMenu : NSObject <NSTableViewDataSource, NSTableViewDelegate>
{
@private
	IBOutlet ChromeMenuUnderlyingWindow *_underlyingWindow;
	IBOutlet ChromeMenuUnderlyingView *_underlyingView;
	IBOutlet NSTextField *title;
	IBOutlet NSTableView *_menuTableView;
	
	NSMutableArray *_menuItems;
}

//- (id)initWithItems:(NSArray *)items;

- (void)addItem:(CMMenuItem *)newItem;
- (id)itemAtIndex:(NSInteger)index;
- (void)setDefaultViewForItemsFromNibNamed:(NSString *)nibName withIdentifier:(NSString *)identifier andPropertyNames:(NSArray *)propertyNames;

/* Same as [anItem setSubmenu:aMenu].  anItem may not be nil. */
- (void)setSubmenu:(CMMenu *)aMenu forItem:(CMMenuItem *)anItem;

/* Update only particular menu items */
- (void)updateItemsAtIndexes:(NSIndexSet *)indexes;

/* this is an actual table reload, scary thing. must be taken care of */
//- (void)update;

- (void)showMenu;

/* Dismisses the menu and ends all menu tracking */
- (void)cancelTracking;

/* Dismisses the menu immediately, without any fade or other effect, and ends all menu tracking */
- (void)cancelTrackingWithoutAnimation;



- (IBAction)buttonClick:(id)sender;

@end
