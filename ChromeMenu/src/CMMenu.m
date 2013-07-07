//
//  ChromeMenu.m
//  Ishimura
//
//  Created by Maksym on 7/3/13.
//  Copyright (c) 2013 Maksym Stefanchuk. All rights reserved.
//

//#import <AppKit/NSWindow.h>
#import "CMMenu.h"
#import "CMMenuItemView.h"
#import "CMMenuItemBackgroundView.h"
#import "ChromeMenuUnderlyingWindow.h"
#import "ChromeMenuUnderlyingView.h"

/*
 * Private declarations
 */
@interface CMMenu()
{
	int _displayedFirstTime;
	int _needsUpdating;
	
/* this block of vartiables servers for storing one custom view that's to be used for all menu items */
	NSString *_itemsViewNibName;
	NSString *_itemsViewIdentifier;
	NSArray *_itemsViewPropertyNames;
	NSNib *_itemsViewRegisteredNib;

/* this block of variables servers for storing custom views that certain menu items wish to use */
//	NSMutableArray *_itemViewNibNames;
	NSMutableArray *_itemViewRegesteredNibs;
	int _registeredCustomNibs;
}
@end


@implementation CMMenu

- (id)init {
	if (self = [super init]) {
		[NSBundle loadNibNamed:[self className] owner:self];
		_displayedFirstTime = 0;
		_needsUpdating = 1;
		_menuItems = [[NSMutableArray alloc] init];
		_registeredCustomNibs = 0;
//		NSNib *nib = [[NSNib alloc] initWithNibNamed:@"CMTableCellViewId3" bundle:[NSBundle mainBundle]];
//		[_menuTableView registerNib:nib forIdentifier:@"CMTableCellViewId3"];
	}
	return self;
}

//- (id)initWithItems:(NSArray *)items {
//	if (self = [super init]) {
//		[NSBundle loadNibNamed:[self className] owner:self];
//		menuItems = items;
//		[menuItems retain];
//		[menuTableView reloadData];
//	}
//	return self;
//}

- (void)dealloc {
	[_menuItems release];
	if (_itemsViewRegisteredNib) {
		[_itemsViewRegisteredNib release];
		[_itemsViewNibName release];
		[_itemsViewIdentifier release];
		[_itemsViewPropertyNames release];
	}
	
	if (_itemViewRegesteredNibs)
		[_itemViewRegesteredNibs release];
	
	[_underlyingWindow release];
	
	[super dealloc];
}

- (void)awakeFromNib {
	NSLog(@"%@ awakeFromNib", [self className]);
}





- (void)addItem:(CMMenuItem *)newItem {
	if (newItem == nil)
		[NSException raise:NSInvalidArgumentException format:@"Exception: nil provided as Menu Item object."];
	
	[_menuItems addObject:newItem];
}


- (CMMenuItem *)itemAtIndex:(NSInteger)index {
	if (index < 0 || index >= [_menuItems count])
		[NSException raise:NSRangeException format:@"No item for -itemAtIndex: %ld", index];
	return [_menuItems objectAtIndex:index];
}


- (void)setSubmenu:(CMMenu *)aMenu forItem:(CMMenuItem *)anItem {
	if (aMenu == nil || anItem == nil)
		[NSException raise:NSInvalidArgumentException format:@"Bad argument in -%@", NSStringFromSelector(_cmd)];
	
	[anItem setSubmenu:aMenu];
}


- (void)setDefaultViewForItemsFromNibNamed:(NSString *)nibName withIdentifier:(NSString *)identifier andPropertyNames:(NSArray *)propertyNames {
	if (nibName == nil || [nibName isEqualToString:@""] || identifier == nil || [identifier isEqualToString:@""] || propertyNames == nil)
		[NSException raise:NSInvalidArgumentException format:@"Bad arguments provided in -%@", NSStringFromSelector(_cmd)];

	_itemsViewRegisteredNib = [[NSNib alloc] initWithNibNamed:nibName bundle:[NSBundle mainBundle]];
	if (_itemsViewRegisteredNib == nil)
		return;
	
	_itemsViewNibName = [nibName retain];
	_itemsViewIdentifier = [identifier retain];
	_itemsViewPropertyNames = [propertyNames retain];

	[_menuTableView registerNib:_itemsViewRegisteredNib forIdentifier:identifier];
}


/*
 * Loads and registers nib only if it hasn't already
 */
- (void)loadAndRegisterNibNamed:(NSString *)nibName withIdentifier:(NSString *)identifier {
	/* we already validated variables when added to menuItem */
	
	NSNib *nib = [[NSNib alloc] initWithNibNamed:nibName bundle:[NSBundle mainBundle]];
	if (nib == nil)
		return;
	
	if (_registeredCustomNibs == 0)
		_itemViewRegesteredNibs = [[NSMutableArray alloc] init];
	
	if ([_itemViewRegesteredNibs containsObject:nib] == NO) {
		[_menuTableView registerNib:nib forIdentifier:identifier];
		[_itemViewRegesteredNibs addObject:nib];
		[nib release];
		_registeredCustomNibs = 1;
	}
}


- (void)updateItemsAtIndexes:(NSIndexSet *)indexes {
	[_menuTableView reloadDataForRowIndexes:indexes columnIndexes:[NSIndexSet indexSetWithIndex:0]];
}


- (void)update {
	[_menuTableView reloadData];
}


- (void)showMenu {
	/* when _underlyingView is initially set to Hidden and instantiating a Menu OSX will NOT draw tableView.
		Otherwise it will, even if we are not going to show menu yet. */
	if (_displayedFirstTime == 0) {
		[_underlyingView setHidden:NO];
		_displayedFirstTime = 1;
	}
	
	if (_needsUpdating) {
		[self update];
		_needsUpdating = 0;
	}
	
	[_underlyingWindow orderFront:self];
}


- (void)cancelTracking {
	[self cancelTrackingWithoutAnimation];
}


- (void)cancelTrackingWithoutAnimation {
	[_underlyingWindow orderOut:self];
}


- (IBAction)buttonClick:(id)sender {
	NSLog(@"table: %@", _menuTableView);
	NSRect rect = [_underlyingWindow frame];
	[_underlyingWindow setFrame:NSMakeRect(rect.origin.x, rect.origin.y, rect.size.width + 20, rect.size.height) display:YES];
//	[menuTableView reloadData];
}



#pragma mark -
#pragma mark ***** TableView Delegate & DataSource Methods *****


- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
	NSLog(@"CMMenu: inquired table rows count: %ld", [_menuItems count]);
	return [_menuItems count];
}


int flag2 = 0;
- (NSTableCellView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
	
	if (flag2 == 0) {
		NSLog(@"Menu table draw called");
		flag2 = 1;
	}
	
	//	if (row == [tableContents count] - 1) {
	if (row == [_menuItems count] - 1) {
		flag2 = 0;
	}
	
	//	NSLog(@"table ROW draw called");
	
	//	NSDictionary *dictionary = [tableContents objectAtIndex:row];
	//	MyTableCellView *cellView = [tableView makeViewWithIdentifier:@"AppCellViewId" owner:self];
	//	cellView.cellText.stringValue = [dictionary objectForKey:@"Name"];
	//	[[cellView cellImage] setImage:[dictionary objectForKey:@"Image"]];
	

	id menuItem = [self itemAtIndex:row];
//	NSLog(@"loaded item: %@", menuItem);
	
	/* menu item has individual view */
	if ([menuItem viewIdentifier]) {
		[self loadAndRegisterNibNamed:[menuItem viewNibName] withIdentifier:[menuItem viewIdentifier]];
		id cellView = [tableView makeViewWithIdentifier:[menuItem viewIdentifier] owner:self];
		NSEnumerator *enumerator = [[menuItem viewPropertyNames] objectEnumerator];
		NSString *propertyName;
		while ((propertyName = [enumerator nextObject])) {
			SEL propertySetter = NSSelectorFromString([NSString stringWithFormat:@"set%@Property:", [propertyName	stringByReplacingCharactersInRange:NSMakeRange(0, 1) withString:[[propertyName substringToIndex:1] capitalizedString]]]);
			if ([cellView respondsToSelector:propertySetter])
				[cellView performSelector:propertySetter withObject:[menuItem valueForKey:propertyName]];
		}
		
		NSLog(@"custom item cell view: %@", cellView);
		
		return cellView;
	}
	
	/* custom view for all items */
	if (_itemsViewIdentifier) {
		id cellView;
		cellView = [tableView makeViewWithIdentifier:_itemsViewIdentifier owner:self];
		
		NSEnumerator *enumerator = [_itemsViewPropertyNames objectEnumerator];
		NSString *propertyName;
		while ((propertyName = [enumerator nextObject])) {
//			if ([property isEqualToString:@"title"])
//				cellView.title.stringValue = [menuItem title];
//			else
//				[cellView setValue:[menuItem valueForKey:property] forKey:property];
			
			SEL propertySetter = NSSelectorFromString([NSString stringWithFormat:@"set%@Property:", [propertyName	stringByReplacingCharactersInRange:NSMakeRange(0, 1) withString:[[propertyName substringToIndex:1] capitalizedString]]]);
			if ([cellView respondsToSelector:propertySetter])
				[cellView performSelector:propertySetter withObject:[menuItem valueForKey:propertyName]];
		}
		
//		NSLog(@"cell view: %@", cellView);
		
		return cellView;

	} else {
		CMMenuItemView *defaultCellView;
		
		if ([menuItem icon]) {
			[self loadAndRegisterNibNamed:@"CMMenuItemIconView" withIdentifier:@"CMMenuItemIconViewId"];
			defaultCellView = [tableView makeViewWithIdentifier:@"CMMenuItemIconViewId" owner:self];
			[[defaultCellView icon] setImage:[menuItem icon]];
		} else {
			defaultCellView = [tableView makeViewWithIdentifier:@"CMMenuItemViewId" owner:self];
		}
		
		[[defaultCellView title] setStringValue:[menuItem title]];
		
//		NSLog(@"default cell view: %@", defaultCellView);
		
		return defaultCellView;
	}
}


- (NSTableRowView *)tableView:(NSTableView *)tableView rowViewForRow:(NSInteger)row {
	//	NSLog(@"------------------ ROWView for ROW ----------------");
	CMMenuItemBackgroundView *rowView = [tableView makeViewWithIdentifier:@"CMMenuItemBackgroundViewId" owner:self];
	[rowView resetBackgroundViewProperties];
	return rowView;
}


//- (void)tableView:(NSTableView *)tableView didRemoveRowView:(NSTableRowView *)rowView forRow:(NSInteger)row {
//	NSLog(@"==================================================================");
////	[self setAppSubmenuSizeWithWidth:0 andHeight:0 relative:NO];
//}


//- (BOOL)tableView:(NSTableView *)tableView shouldSelectRow:(NSInteger)row {
//	NSLog(@"should select row %ld", row);
//	return YES;
//}

- (void)tableViewSelectionDidChange:(NSNotification *)notification {
	NSTableView *tableView = [notification object];
	NSTableRowView *rowView = [tableView rowViewAtRow:[tableView selectedRow] makeIfNecessary:NO];
	NSLog(@"tableview selectionDidChange: %@", rowView);
//	[[self appInspectorController] showAppDetailsPopoverRelativeTo:rowView];
}




@end
