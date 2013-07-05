//
//  StatusbarMenuController.m
//  Ishimura
//
//  Created by Maksym on 5/28/13.
//  Copyright (c) 2013 Maksym Stefanchuk. All rights reserved.
//

#import "StatusbarMenuController.h"
#import "MyTableView.h"
#import "MyTableCellView.h"
#import "MyTableRowView.h"
#import "MyImageView.h"

#import "AppInspectorController.h"
#import "ChromeMenu.h"
#import "CMMenuItemOverride.h"

@interface StatusbarMenuController()
{
	CMMenu *menu;
}

- (IBAction)changeMenu:(id)sender;

@end


@implementation StatusbarMenuController

@synthesize statusbarMenu;
@synthesize statusbarItemView;
@synthesize myPanel;

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
//	[appsSubmenu release];
	[tableContents release];
	[appInspectorController release];
	[super dealloc];
}

- (void)awakeFromNib {
	sortApplications = 1;
	NSLog(@"%@ awakeFromNib", [self className]);
}


- (AppInspectorController *)appInspectorController {
	if (appInspectorController == nil) {
		appInspectorController = [[AppInspectorController alloc] init];
	}
	return appInspectorController;
}


/*
 *
 */
- (void)linkStatusbarItemWithMenu {

	// set up Menu first with all submenus
	[self setupMenu];
	
	// now populate it with running applications
	[self populateMenuWithRunningApplications];

}


/*
 *
 */
- (void)setupMenu {
	//	[statusbarMenu setAutoenablesItems:NO];
	//	[[statusbarMenu itemAtIndex:0] setEnabled:YES];
	//	[[statusbarMenu itemAtIndex:0] setTarget:self];
	
	NSMenu *appsSubmenu = [[NSMenu allocWithZone:[NSMenu menuZone]] initWithTitle:@"Running Applications Submenu"];
	// maks: this line kind of creates Tracking Area for all menu, and thus subview receive Events.
	//	[appsSubmenu setAutoenablesItems:NO];
	
	NSMenuItem *submenuItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:@"Running Applications" action:NULL keyEquivalent:@""];
	
	//	[appListTableView becomeFirstResponder];
	//	[appListTableView resignFirstResponder];
	//	[appSubmenuView resignFirstResponder];
	
	//	[submenuItem setRepresentedObject:appSubmenuView];
	//	[submenuItem setEnable:YES];
	
	//	[submenuItem setTarget:self];
	[submenuItem setView:(NSView *)appSubmenuView];
	[appsSubmenu addItem:submenuItem];
	[submenuItem release];
	
	[statusbarMenu setSubmenu:appsSubmenu forItem:[statusbarMenu itemAtIndex:0]];
	//	[appSubmenuView release];
	[appsSubmenu release];
	
	//	[[statusbarMenu itemAtIndex:0] setAction:@selector(someAction:)];
	//	NSLog(@"Action: %s", sel_getName([[statusbarMenu itemAtIndex:0] action]));
	//	[[statusbarMenu itemAtIndex:0] setSubmenu:appsSubmenu];
	
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notificationDeliver:) name:NSMenuWillSendActionNotification object:statusbarMenu];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notificationDeliver:) name:NSMenuDidEndTrackingNotification object:statusbarMenu];
	
	
	
	
	NSMenuItem *newItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:@"new item" action:NULL keyEquivalent:@""];
	[newItem setTarget:self];
	[newItem setView:secondSubmenuView];
	[[[statusbarMenu itemAtIndex:2] submenu] insertItem:newItem atIndex:1];
	
	
	
	
	NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
	[notificationCenter addObserver:self selector:@selector(statusbarItemClick:) name:@"StatusbarItemLMouseClick" object:nil];
}


/*
 *
 */
- (void)populateMenuWithRunningApplications {
	// load contents into table
	tableContents = [NSMutableArray new];
	NSWorkspace *workspace = [NSWorkspace sharedWorkspace];
	runningApplications = [[workspace runningApplications] mutableCopy];
	
	// remove ourselves from applications list
	NSInteger i;
	NSInteger elementsCount = [runningApplications count];
	pid_t shared_pid = getpid();
	
	for (i = 0; i < elementsCount; ++i) {
		if (shared_pid == [[runningApplications objectAtIndex:i] processIdentifier]) {
			[runningApplications removeObjectAtIndex:i];
			break;
		}
	}
	
	if (sortApplications)
		[self sortApplicationsByNameAndReload:NO];
	
	
//	NSLog(@"%@", runningApplications);
//	NSInteger appsCount = [runningApplications count];
//	NSInteger i;
//	
//	for (i = 0; i < appsCount; ++i) {
//		NSRunningApplication *app = [runningApplications objectAtIndex:i];
//		NSDictionary *dictionary = [[[NSDictionary alloc] initWithObjectsAndKeys:
//			[app localizedName], @"Name",
//			[app icon], @"Icon",
//			nil] autorelease];
//		[tableContents addObject:dictionary];
//	}
	
	
	[appListTableView reloadData];
	
	
	NSNotificationCenter *notificationCenter = [workspace notificationCenter];
	[notificationCenter addObserver:self selector:@selector(appLaunchedHandler:) name:NSWorkspaceDidLaunchApplicationNotification object:nil];
	[notificationCenter addObserver:self selector:@selector(appTerminatedHandler:) name:NSWorkspaceDidTerminateApplicationNotification object:nil];
	
	
	
	
/* 
 /
	//	NSSize maximumWidthSize = {0, 0};
	float longestNameWidth;
	float textHeight;
	NSString *tempS;
	NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:
								[NSFont fontWithName:@"Lucida Grande" size:13.0], NSFontAttributeName,
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
		if (size.width > longestNameWidth) {
			longestNameWidth = size.width;
			tempS = name;
		}
		//		NSLog(@"%@ - %f\n", name, size.width);
		
		++data;
	}
	[appListTableView reloadData];
	NSLog(@"populate called");
	
	textHeight = [tableData[0] sizeWithAttributes:attributes].height;
	NSLog(@"Maximum size %f for %@", longestNameWidth, tempS);
	NSLog(@"Text height: %f. Total height: %f", textHeight, [tableContents count] * textHeight);
	
	
	//	maximumWidthSize.height = 500;
	//	maximumWidthSize.width += 60;
	const float leftIconPadding = 60.0;
	longestNameWidth += leftIconPadding;
	//	[appSubmenuView setFrameSize:NSMakeSize(longestNameWidth, 500)];
/ */

//	[self setAppSubmenuSizeWithWidth:longestNameWidth andHeight:0];
//	[self setAppSubmenuSizeWithWidth:0 andHeight:0 relative:NO];
	[self updateAppSubmenuViewSize];
	

	//	[[appListTableView enclosingScrollView] setFrameSize:maximumWidthSize];
	//	[appListTableView sizeToFit];
	//	maxSize = maximumWidthSize;
	//	[[appListTableView column] setWidth:maximumWidthSize.width];
	//	[[appListTableView textField] setFrameSize:maximumWidthSize];
}


/*
 *
 */
- (void)appLaunchedHandler:(NSNotification *)notification {
	NSLog(@"launched %@\n", [[notification userInfo] objectForKey:@"NSApplicationName"]);
	NSRunningApplication *app = [[notification userInfo] objectForKey:NSWorkspaceApplicationKey];
//	NSLog(@"App object: %@", app);

//	[runningApplications addObject:app];
//	NSLog(@"Running apps: %@", runningApplications);
//	[appListTableView reloadData];
//	[self setAppSubmenuSizeWithWidth:0 andHeight:0];
	
	NSUInteger index;
	NSUInteger count = [runningApplications count];
	if (sortApplications) {
		NSString *appName = [app localizedName];
		NSUInteger i = 0;
		while (i < count && [appName compare:[[runningApplications objectAtIndex:i] localizedName]] == NSOrderedDescending)
			++i;
		index = i;
	} else
		index = count;

	[runningApplications insertObject:app atIndex:index];


//	[self setAppSubmenuSizeWithWidth:0 andHeight:0 relative:YES];
	[self updateAppSubmenuViewSize];
	[appListTableView insertRowsAtIndexes:[NSIndexSet indexSetWithIndex:index] withAnimation:NSTableViewAnimationEffectFade];
}


/*
 *
 */
- (void)appTerminatedHandler:(NSNotification *)notification {
	NSLog(@"terminated %@\n", [[notification userInfo] objectForKey:@"NSApplicationName"]);
	NSRunningApplication *app = [[notification userInfo] objectForKey:NSWorkspaceApplicationKey];
	NSUInteger index = [runningApplications indexOfObject:app];
	[runningApplications removeObjectAtIndex:index];
//	NSLog(@"Running apps: %@", runningApplications);


	[appListTableView removeRowsAtIndexes:[NSIndexSet indexSetWithIndex:index] withAnimation:NSTableViewAnimationEffectFade];
	/* We change the Menu View size on animation complete in
	 * - didRemoveRowView:forRow:  method
	 */
//	NSLog(@"----------------------------------------------------------------");
//	[self setAppSubmenuSizeWithWidth:0 andHeight:0 relative:YES];
	[self updateAppSubmenuViewSize];
}


/*
 * Set the Applications List Submenu size.
 * If any of the parameters is passed as 0, we'll try to determine it on our own.
 */
- (void)updateAppSubmenuViewSize {
//- (void)setAppSubmenuSizeWithWidth:(float)width andHeight:(float)height relative:(BOOL)relative {
	float width;
	float height;
	NSInteger elementsCount = [runningApplications count];
	// application names are displayed with these font settings
	NSDictionary *fontAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
									[NSFont fontWithName:@"Lucida Grande" size:13.0], NSFontAttributeName, nil];
	
	// WIDTH
	float appNameWidth;
	NSInteger i;

	for (i = 0; i < elementsCount; ++i) {
		appNameWidth = [[[runningApplications objectAtIndex:i] localizedName] sizeWithAttributes:fontAttributes].width;
		if (appNameWidth > width)
			width = appNameWidth;
	}
	
	const float leftIconPadding = 70.0;
	width += leftIconPadding;
	width = ceil(width);
	
	
	// HEIGHT
	if (elementsCount == 0)
		height = 19;	// at least some height so the elements are visible
	else {
		float textHeight;
			
		textHeight = [[[runningApplications objectAtIndex:0] localizedName] sizeWithAttributes:fontAttributes].height;
		height = textHeight * elementsCount + 2 * elementsCount; // 2 is cell spacing
	}
	
	NSLog(@"Calc height: %f for %ld elements. Taken height: %f. Width: %f", height, elementsCount, [appListTableView frame].size.height, width);
	
	
//	const float bottomPadding = 200.0;
//	NSRect screenFrame = [[NSScreen mainScreen] frame];
//	float maxHeight = screenFrame.size.height - bottomPadding;
//	if (height > maxHeight)
//		height = maxHeight;
	
	
	[appSubmenuView setFrameSize:NSMakeSize(width, height)];
//	[appSubmenuView setNeedsDisplay:YES];
	// we want to redisplay menu with new size immediately
	[appSubmenuView display];
	
//	[[appSubmenuView animator] setFrameSize:NSMakeSize(width, height)];
}


/*
 *
 */
- (void)sortApplicationsByNameAndReload:(BOOL)reload {
	NSSortDescriptor *descriptor = [[NSSortDescriptor alloc] initWithKey:@"localizedName" ascending:YES];
	[runningApplications sortUsingDescriptors:[NSArray arrayWithObject:descriptor]];
	[descriptor release];
	if (reload)
		[appListTableView reloadData];
}



- (void)statusbarItemClick:(NSNotification *)notification {
	NSLog(@"catch click: %@", notification);
}



- (IBAction)someAction:(NSMenuItem *)sender {
	NSLog(@"clicked menu item: %@", sender);
}


- (IBAction)someAction2:(NSMenuItem *)sender {
//	[statusbarMenu itemAtIndex:0]
	[statusbarMenu performActionForItemAtIndex:0];
}


- (IBAction)addMenu:(id)sender {
//	NSMutableArray *items = [[NSMutableArray alloc] init];


//    @"NSSmartBadgeTemplate",
//    @"NSIconViewTemplate",

//	[items addObject:[NSDictionary dictionaryWithObjectsAndKeys:
//					  [NSImage imageNamed:@"NSIChatTheaterTemplate"], @"Icon",
//					  @"Chat Template", @"Text", nil]];
//	[items addObject:[NSDictionary dictionaryWithObjectsAndKeys:
//					  [NSImage imageNamed:@"NSSlideshowTemplate"], @"Icon",
//					  @"Slideshow Template", @"Text", nil]];
//	[items addObject:[NSDictionary dictionaryWithObjectsAndKeys:
//					  [NSImage imageNamed:@""], @"Icon",
//					  @"Without icon", @"Text", nil]];
//	[items addObject:[NSDictionary dictionaryWithObjectsAndKeys:
//					  [NSImage imageNamed:@"NSActionTemplate"], @"Icon",
//					  @"Action Template", @"Text", nil]];

	menu = [[CMMenu alloc] init];
	
//	CMMenuItem *item1 = [[CMMenuItem alloc] initWithTitle:@"Chat Template"];
//	[item1 setIcon:[NSImage imageNamed:@"NSIChatTheaterTemplate"]];
//	
//	CMMenuItem *item2 = [[CMMenuItem alloc] initWithTitle:@"Slideshow Template"];
//	[item2 setIcon:[NSImage imageNamed:@"NSSlideshowTemplate"]];
//	
//	CMMenuItem *item3 = [[CMMenuItem alloc] initWithTitle:@"Without icon"];
//
//	CMMenuItem *item4 = [[CMMenuItem alloc] initWithTitle:@"Actions Template"];
//	[item4 setIcon:[NSImage imageNamed:@"NSActionTemplate"]];
//	
//	
//	[menu addItem:item1];
//	[menu addItem:item2];
//	[menu addItem:item3];
//	[menu addItem:item4];
	
	NSArray *viewProperties = [[NSArray alloc] initWithObjects:@"statusIcon", @"icon", @"title", nil];
	[menu setDefaultViewForItemsFromNibNamed:@"MenuItemView" withIdentifier:@"CMTableCellViewIdOverride" andPropertyNames:viewProperties];
	[viewProperties release];
	
	int i = 0;
	NSString **data = &tableData[0];
	while (*data != nil) {
		NSString *name = *data;
		NSImage *image = [NSImage imageNamed:name];
		NSString *statusImageName = [NSString stringWithString:(i % 2 == 0) ? @"NSStatusAvailable" : @"NSStatusUnavailable"];

//		CMMenuItem *item = [[CMMenuItem alloc] initWithTitle:name];
		CMMenuItemOverride *item = [[CMMenuItemOverride alloc] initWithTitle:name];
//		if (i == 2) {
			
//		} else {
			[item setIcon:image];
			[item setStatusIcon:[NSImage imageNamed:statusImageName]];
//		}
		
		[menu addItem:item];
		[item release];
		
		++data;
		++i;
	}
	
	
//	[item1 release];
//	[item2 release];
//	[item3 release];
//	[item4 release];


	[menu update];
	
//	NSLog(@"Should create menu with items: %@", items);
	NSLog(@"menu: %@", menu);
//	[items release];
}


- (IBAction)changeMenu:(id)sender {
	NSInteger index = 4;
	static int i = 0;
	NSString *statuses[] = {
		@"NSStatusAvailable",
		@"NSStatusUnavailable",
		@"NSStatusPartiallyAvailable",
		@"NSStatusNone"
	};
	
	CMMenuItemOverride *item = [menu itemAtIndex:index];
	[item setStatusIcon:[NSImage imageNamed:statuses[i % 4]]];
	++i;
	[menu updateItemsAtIndexes:[NSIndexSet indexSetWithIndex:index]];
	NSLog(@"Item change: %@", item);
}



- (IBAction)showmenu:(id)sender {
	NSLog(@"BBBBB");
	[statusbarMenu popUpMenuPositioningItem:[statusbarMenu itemAtIndex:0] atLocation:NSMakePoint(200, 200) inView:nil];
//	[statusbarMenu popUpMenuPositioningItem:nil atLocation:NSMakePoint(200, 200) inView:nil];
}



#pragma mark -
#pragma mark ***** TableView Delegate & DataSource Methods *****


- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
	NSLog(@"Inquired table rows count: %lu", [runningApplications count]);
	return [runningApplications count];
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
	
//	if (row == [tableContents count] - 1) {
	if (row == [runningApplications count] - 1) {
		flag = 0;
	}

//	NSLog(@"table ROW draw called");
	
//	NSDictionary *dictionary = [tableContents objectAtIndex:row];
//	MyTableCellView *cellView = [tableView makeViewWithIdentifier:@"AppCellViewId" owner:self];
//	cellView.cellText.stringValue = [dictionary objectForKey:@"Name"];
//	[[cellView cellImage] setImage:[dictionary objectForKey:@"Image"]];

	
	NSRunningApplication *app = [runningApplications objectAtIndex:row];
//	NSLog(@"%@", app);
	MyTableCellView *cellView = [tableView makeViewWithIdentifier:@"AppCellViewId" owner:self];
	cellView.cellImage.image = [app icon];
	cellView.cellText.stringValue = [app localizedName];
	
	return cellView;
}

- (NSTableRowView *)tableView:(NSTableView *)tableView rowViewForRow:(NSInteger)row {
//	NSLog(@"------------------ ROWView for ROW ----------------");
	MyTableRowView *tableRow = [tableView makeViewWithIdentifier:@"MyTableRowViewId" owner:self];
	[tableRow resetRowViewProperties];
	return tableRow;
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
	[[self appInspectorController] showAppDetailsPopoverRelativeTo:rowView];
}


- (void)notificationDeliver:(NSNotification *)notification {
	NSLog(@"notification: %@", notification);
	
}



/*
- (void)tableViewSelectionDidChange:(NSNotification *)notification {
    // Bold the text in the selected items, and unbold non-selected items
    [appListTableView enumerateAvailableRowViewsUsingBlock:^(NSTableRowView *rowView, NSInteger row) {
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


- (IBAction)activateSelf:(id)sender {
	NSApplication *app = [NSApplication sharedApplication];
	NSLog(@"%@", app);
	[app activateIgnoringOtherApps:YES];

}


@end
