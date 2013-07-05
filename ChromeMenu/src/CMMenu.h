//
//  ChromeMenu.h
//  Ishimura
//
//  Created by Maksym on 7/3/13.
//  Copyright (c) 2013 Maksym Stefanchuk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CMMenuItem.h"

@class ChromeMenuUnderlyingWindow, CMTableCellView;

@interface CMMenu : NSObject <NSTableViewDataSource, NSTableViewDelegate>
{
@private
	IBOutlet ChromeMenuUnderlyingWindow *_underlyingWindow;
	IBOutlet NSTextField *title;
	IBOutlet NSTableView *_menuTableView;
	
	NSMutableArray *_menuItems;
}

//- (id)initWithItems:(NSArray *)items;

- (void)addItem:(CMMenuItem *)newItem;
- (id)itemAtIndex:(NSInteger)index;
- (void)setDefaultViewForItemsFromNibNamed:(NSString *)nibName withIdentifier:(NSString *)identifier andPropertyNames:(NSArray *)propertyNames;


/* Update only particular menu items */
- (void)updateItemsAtIndexes:(NSIndexSet *)indexes;

/* this is an actual table reload, scary thing. must be taken care of */
- (void)update;



- (IBAction)buttonClick:(id)sender;

@end
