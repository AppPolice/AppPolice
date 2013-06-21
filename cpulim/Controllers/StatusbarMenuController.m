//
//  StatusbarMenuController.m
//  Ishimura
//
//  Created by Maksym on 5/28/13.
//  Copyright (c) 2013 Maksym Stefanchuk. All rights reserved.
//

#import "StatusbarMenuController.h"
#import "MyTableCellView.h"
#import "MyTableRowView.h"
#import "MyImageView.h"



@implementation StatusbarMenuController

@synthesize statusbarMenu;


static NSString *tableData[] = {
    @"NSQuickLookTemplate",
    @"NSBluetoothTemplate",
    @"NSIChatTheaterTemplate",
    @"NSSlideshowTemplate",
    @"NSActionTemplate",
    @"NSSmartBadgeTemplate",
    @"NSIconViewTemplate",
    @"NSListViewTemplate",
    @"NSColumnViewTemplate",
    @"NSFlowViewTemplate",
    @"NSPathTemplate",
    @"NSInvalidDataFreestandingTemplate",
    @"NSLockLockedTemplate",
    @"NSLockUnlockedTemplate",
    @"NSGoRightTemplate",
    @"NSGoLeftTemplate",
    @"NSRightFacingTriangleTemplate",
    @"NSLeftFacingTriangleTemplate",
    @"NSAddTemplate",
    @"NSRemoveTemplate",
    @"NSRevealFreestandingTemplate",
    @"NSFollowLinkFreestandingTemplate",
    @"NSEnterFullScreenTemplate",
    @"NSExitFullScreenTemplate",
    @"NSStopProgressTemplate",
    @"NSStopProgressFreestandingTemplate",
    @"NSRefreshTemplate",
    @"NSRefreshFreestandingTemplate",
    @"NSBonjour",
    @"NSComputer",
    @"NSFolderBurnable",
    @"NSFolderSmart",
    @"NSFolder",
    @"NSNetwork",
    @"NSMobileMe",
    @"NSMultipleDocuments",
    @"NSUserAccounts",
    @"NSPreferencesGeneral",
    @"NSAdvanced",
    @"NSInfo",
    @"NSFontPanel",
    @"NSColorPanel",
    @"NSUser",
    @"NSUserGroup",
    @"NSEveryone",
    @"NSUserGuest",
    @"NSMenuOnStateTemplate",
    @"NSMenuMixedStateTemplate",
    @"NSApplicationIcon",
    @"NSTrashEmpty",
    @"NSTrashFull",
    @"NSHomeTemplate",
    @"NSBookmarksTemplate",
    @"NSCaution",
    @"NSStatusAvailable",
    @"NSStatusPartiallyAvailable",
    @"NSStatusUnavailable",
    @"NSStatusNone",
    nil };



- (void)dealloc {
	[appsSubmenu release];
	[super dealloc];
}

- (void)populateMenuWithRunningApps {

//	[statusbarMenu setAutoenablesItems:NO];
//	[[statusbarMenu itemAtIndex:0] setEnabled:YES];
//	[[statusbarMenu itemAtIndex:0] setTarget:self];
	
	appsSubmenu = [[NSMenu allocWithZone:[NSMenu menuZone]] initWithTitle:@"Running Applications"];
	// maks: this line kind of creates Tracking Area for all menu, and thus subview receive Events.
//	[appsSubmenu setAutoenablesItems:NO];
	
	NSMenuItem *submenuItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:@"Running Apps Item" action:NULL keyEquivalent:@""];

//	[menuTableView becomeFirstResponder];
//	[menuTableView resignFirstResponder];
//	[appsSubmenuView resignFirstResponder];

//	[submenuItem setRepresentedObject:appsSubmenuView];
//	[submenuItem setEnable:YES];
	[submenuItem setTarget:self];
	[submenuItem setView:appsSubmenuView];
	[appsSubmenu addItem:submenuItem];
	[submenuItem release];
		
	[statusbarMenu setSubmenu:appsSubmenu forItem:[statusbarMenu itemAtIndex:0]];
	[appsSubmenuView release];
	
//	[[statusbarMenu itemAtIndex:0] setAction:@selector(someAction:)];
	NSLog(@"Action: %s", sel_getName([[statusbarMenu itemAtIndex:0] action]));
//	[[statusbarMenu itemAtIndex:0] setSubmenu:appsSubmenu];
	
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notificationDeliver:) name:NSMenuWillSendActionNotification object:statusbarMenu];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notificationDeliver:) name:NSMenuDidEndTrackingNotification object:statusbarMenu];
	
	
	
//	NSMenu *secondSubmenu = [[NSMenu allocWithZone:[NSMenu menuZone]] initWithTitle:@"Demoing"];
//	[secondSubmenu setAutoenablesItems:NO];
//	
//	NSMenuItem *secondSubmenuItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:@"Demoing Item" action:@selector(someAction:) keyEquivalent:@""];
//	
//	[secondSubmenuItem setEnabled:YES];
//	[secondSubmenuItem setTarget:self];
//	[secondSubmenuItem setView:secondSubmenuView];
//	[secondSubmenu addItem:secondSubmenuItem];
////	[secondSubmenuItem release];
//	
//	[statusbarMenu setSubmenu:secondSubmenu forItem:[statusbarMenu itemAtIndex:2]];
////	[secondSubmenu release];
	
	
	NSMenuItem *newItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:@"new item" action:NULL keyEquivalent:@""];
	[newItem setTarget:self];
	[newItem setView:secondSubmenuView];
	[[[statusbarMenu itemAtIndex:2] submenu] insertItem:newItem atIndex:1];
	
	// load contents into table
	tableContents = [NSMutableArray new];
	NSSize maximumWidthSize = {0, 0};
	NSString *tempS;
	NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:
		NSFontAttributeName, @"Helvetica 13-point",
		nil];
	NSString **data = &tableData[0];
	while (*data != nil) {
		NSString *name = *data;
		NSImage *image = [NSImage imageNamed:name];
		NSDictionary *dictionary = [[[NSDictionary alloc] initWithObjectsAndKeys:
			name, @"Name",
			image, @"Image",
			nil] autorelease];
		[tableContents addObject:dictionary];
		
		NSSize size = [name sizeWithAttributes:attributes];
		if (size.width > maximumWidthSize.width) {
			maximumWidthSize = size;
			tempS = name;
		}
		
		++data;
	}
	[menuTableView reloadData];
	NSLog(@"populate called");
	
	NSLog(@"Maximum size %f for %@", maximumWidthSize.width, tempS);
	

	maximumWidthSize.height = 500;
	maximumWidthSize.width += 100;
	[appsSubmenuView setFrameSize:NSMakeSize(maximumWidthSize.width, maximumWidthSize.height)];
//	[[menuTableView enclosingScrollView] setFrameSize:maximumWidthSize];
//	[menuTableView sizeToFit];
//	maxSize = maximumWidthSize;
//	[[menuTableView column] setWidth:maximumWidthSize.width];
//	[[menuTableView textField] setFrameSize:maximumWidthSize];
}


- (IBAction)someAction:(NSMenuItem *)sender {
	NSLog(@"clicked menu item: %@", sender);
}


- (IBAction)someAction2:(NSMenuItem *)sender {
//	[statusbarMenu itemAtIndex:0]
	[statusbarMenu performActionForItemAtIndex:0];
}


- (IBAction)showmenu:(id)sender {
	NSLog(@"BBBBB");
	[statusbarMenu popUpMenuPositioningItem:[statusbarMenu itemAtIndex:0] atLocation:NSMakePoint(200, 200) inView:nil];
//	[statusbarMenu popUpMenuPositioningItem:nil atLocation:NSMakePoint(200, 200) inView:nil];
}


- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
	return [tableContents count];
}

int flag = 0;
- (NSTableCellView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
	
	if (flag == 0) {
		NSLog(@"table draw called");
//		NSLog(@"%@", [NSApp windows]);
//		int i;
//		for (i = 0; i < [[NSApp windows] count]; ++i) {
//			[[[NSApp windows] objectAtIndex:i] becomeKeyWindow];
//			[[[NSApp windows] objectAtIndex:i] becomeFirstResponder];
//			[[[NSApp windows] objectAtIndex:i] becomeMainWindow];
//		}
		flag = 1;
	}
	
	if (row == [tableContents count] - 1) {
		flag = 0;
	}
	
	NSDictionary *dictionary = [tableContents objectAtIndex:row];
//	NSTableCellView *cellView = [tableView makeViewWithIdentifier:@"AppCellView" owner:self];
//	[[cellView textField] setStringValue:[dictionary objectForKey:@"Name"]];
////	[[cellView imageView] setObjectValue:[dictionary objectForKey:@"Image"]];
//	[[cellView imageView] setImage:[dictionary objectForKey:@"Image"]];
	
	MyTableCellView *cellView = [tableView makeViewWithIdentifier:@"AppCellViewId" owner:self];
	cellView.cellText.stringValue = [dictionary objectForKey:@"Name"];
//	[cellView.cellText setFrameSize:NSMakeSize(300, 50)];
	[[cellView cellImage] setImage:[dictionary objectForKey:@"Image"]];
	
	
	return cellView;
}

- (NSTableRowView *)tableView:(NSTableView *)tableView rowViewForRow:(NSInteger)row {
	MyTableRowView *tableRow = [tableView makeViewWithIdentifier:@"MyTableRowViewId" owner:self];
	[tableRow resetRowViewProperties];
	return tableRow;
}


//- (BOOL)tableView:(NSTableView *)tableView shouldSelectRow:(NSInteger)row {
//	NSLog(@"should select row %ld", row);
//	return YES;
//}


- (void)notificationDeliver:(NSNotification *)notification {
	NSLog(@"notification: %@", notification);
}


- (IBAction)clickButton1:(id)sender {
//	NSLog(@"%ld", [menuTableView selectionHighlightStyle]);
//	NSLog(@"accepts FR: %d", [menuTableView acceptsFirstResponder]);
//	[appsSubmenu awakeFromNib];
//	[appsSubmenuView setNextResponder:menuTableView];
//	[NSApp setNextResponder:appsSubmenuView];
//	NSLog(@"%@", [NSApp mainWindow]);
//	NSLog(@"1: %d", [[[NSApp windows] objectAtIndex:0] isKeyWindow]);
//	NSLog(@"2: %d", [[[NSApp windows] objectAtIndex:1] isKeyWindow]);
//	NSLog(@"3: %d", [[[NSApp windows] objectAtIndex:2] isKeyWindow]);
//	NSLog(@"%@", [appsSubmenuView superview]);
//	[[[NSApp windows] objectAtIndex:0] becomeKeyWindow];
//	[[menuTableView superview] becomeFirstResponder];
//	
////	[appsSubmenuView awakeFromNib];
//	
//	[[[NSApp windows] objectAtIndex:1] setLevel:NSStatusWindowLevel];
	
//	[[[NSApp windows] objectAtIndex:0] becomeKeyWindow];
//	[[[NSApp windows] objectAtIndex:0] makeKeyWindow];
//	[[[NSApp windows] objectAtIndex:0] orderFront:self];
//	[NSApp activateIgnoringOtherApps:YES];
//	[[[NSApp windows] objectAtIndex:0] makeFirstResponder:appsSubmenuView];
	
	
//	[[[NSApp windows] objectAtIndex:0] makeKeyAndOrderFront:self];
//	[[[NSApp windows] objectAtIndex:0] setLevel:NSStatusWindowLevel];
	
	
}


/*
- (void)tableViewSelectionDidChange:(NSNotification *)notification {
    // Bold the text in the selected items, and unbold non-selected items
    [menuTableView enumerateAvailableRowViewsUsingBlock:^(NSTableRowView *rowView, NSInteger row) {
        // Enumerate all the views, and find the NSTableCellViews.
        // This demo could hard-code things, as it knows that the first cell is always an
        // NSTableCellView, but it is better to have more abstract code that works
        // in more locations.
        //
        for (NSInteger column = 0; column < rowView.numberOfColumns; column++) {
            NSView *cellView = [rowView viewAtColumn:column];
            // Is this an NSTableCellView?
            if ([cellView isKindOfClass:[NSTableCellView class]]) {
                MyTableCellView *tableCellView = (MyTableCellView *)cellView;
                // It is -- grab the text field and bold the font if selected
//                NSTextField *textField = tableCellView.textField;
				NSTextField *textField = [tableCellView cellText];
                NSInteger fontSize = [textField.font pointSize];
                if (rowView.selected) {
                    textField.font = [NSFont boldSystemFontOfSize:fontSize];
					NSLog(@"%@", rowView);
                } else {
                    textField.font = [NSFont systemFontOfSize:fontSize];
                }
            }
        }
    }];
}
*/

//- (void)mouseDown:(NSEvent *)event {
//	NSLog(@"down");
//}


//- (BOOL)validateMenuItem:(NSMenuItem *)menuItem {
//	NSLog(@"clicked menu item: %@", [menuItem title]);
//	return NO;
//}

//- (BOOL)validateUserInterfaceItem:(id <NSValidatedUserInterfaceItem>)anItem {
//	return NO;
//}

//- (void)menuDidClose:(NSMenu *)menu {
//	NSLog(@"Done");
//}


@end
