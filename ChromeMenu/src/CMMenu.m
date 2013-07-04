//
//  ChromeMenu.m
//  Ishimura
//
//  Created by Maksym on 7/3/13.
//  Copyright (c) 2013 Maksym Stefanchuk. All rights reserved.
//

#import "CMMenu.h"
#import "CMTableCellView.h"
#import "CMTableRowView.h"


@implementation CMMenu

- (id)init {
	if (self = [super init]) {
		[NSBundle loadNibNamed:[self className] owner:self];
		_menuItems = [[NSMutableArray alloc] init];
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




- (IBAction)buttonClick:(id)sender {
	NSLog(@"table: %@", _menuTableView);
//	[menuTableView reloadData];
}



#pragma mark -
#pragma mark ***** TableView Delegate & DataSource Methods *****


- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
	NSLog(@"Inquired table rows count: %@", _menuItems);
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
	

	CMMenuItem *menuItem = [self itemAtIndex:row];
	NSLog(@"loaded item: %@", menuItem);
	CMTableCellView *cellView;
	if (row == 1) {
		cellView = [tableView makeViewWithIdentifier:@"CMTableCellViewId2" owner:self];
	} else {
		cellView = [tableView makeViewWithIdentifier:@"CMTableCellViewId" owner:self];
	}
	
	NSLog(@"cell view: %@", cellView);
	
	if ([menuItem icon])
		[[cellView itemIcon] setImage:[menuItem icon]];
	[[cellView itemText] setStringValue:[menuItem title]];

	return cellView;
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
