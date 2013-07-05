//
//  ChromeMenu.m
//  Ishimura
//
//  Created by Maksym on 7/3/13.
//  Copyright (c) 2013 Maksym Stefanchuk. All rights reserved.
//

#import "CMMenu.h"
#import "CMMenuItemView.h"
#import "CMTableRowView.h"

/*
 * Private declarations
 */
@interface CMMenu()
{
	NSString *_itemsViewNibName;
	NSString *_itemsViewIdentifier;
	NSArray *_itemsViewProperties;
	NSNib *_itemsViewRegisteredNib;
}
@end


@implementation CMMenu

- (id)init {
	if (self = [super init]) {
		[NSBundle loadNibNamed:[self className] owner:self];
		_menuItems = [[NSMutableArray alloc] init];
		
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
		[_itemsViewProperties release];
	}
	
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


- (void)update {
	[_menuTableView reloadData];
}

- (void)setDefaultViewForItemsFromNibName:(NSString *)nibName withIdentifier:(NSString *)identifier andPropertyNames:(NSArray *)propertyNames {
	if (nibName == nil || [nibName isEqualToString:@""] || identifier == nil || [identifier isEqualToString:@""] || propertyNames == nil)
		[NSException raise:NSInvalidArgumentException format:@"Bad arguments provided in -%@", NSStringFromSelector(_cmd)];

	_itemsViewRegisteredNib = [[NSNib alloc] initWithNibNamed:nibName bundle:[NSBundle mainBundle]];
	if (_itemsViewRegisteredNib == nil)
		return;
	
	_itemsViewNibName = [nibName retain];
	_itemsViewIdentifier = [identifier retain];
	_itemsViewProperties = [propertyNames retain];

	[_menuTableView registerNib:_itemsViewRegisteredNib forIdentifier:identifier];
}





- (IBAction)buttonClick:(id)sender {
	NSLog(@"table: %@", _menuTableView);
//	[menuTableView reloadData];
}



#pragma mark -
#pragma mark ***** TableView Delegate & DataSource Methods *****


- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
	NSLog(@"Inquired table rows count: %ld", [_menuItems count]);
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
	

	
	if (_itemsViewIdentifier) {
		id cellView;
		cellView = [tableView makeViewWithIdentifier:_itemsViewIdentifier owner:self];
		
		NSEnumerator *enumerator = [_itemsViewProperties objectEnumerator];
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
		defaultCellView = [tableView makeViewWithIdentifier:@"CMMenuItemViewId" owner:self];
		
		
		if ([menuItem icon])
			[[defaultCellView icon] setImage:[menuItem icon]];
		[[defaultCellView title] setStringValue:[menuItem title]];
		
//		NSLog(@"default cell view: %@", defaultCellView);
		
		return defaultCellView;
	}
}

- (NSTableRowView *)tableView:(NSTableView *)tableView rowViewForRow:(NSInteger)row {
	//	NSLog(@"------------------ ROWView for ROW ----------------");
	CMTableRowView *rowView = [tableView makeViewWithIdentifier:@"CMTableRowViewId" owner:self];
	[rowView resetRowViewProperties];
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
