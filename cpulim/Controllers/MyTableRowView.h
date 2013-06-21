//
//  MyTableRowView.h
//  Ishimura
//
//  Created by Maksym on 6/1/13.
//  Copyright (c) 2013 Maksym Stefanchuk. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class MyTableView;
//@class MyTableCellView;

@interface MyTableRowView : NSTableRowView
{
//	MyTableCellView *cellView;
	
@private
	BOOL mouseInside;
	MyTableView *table;
//	NSBackgroundStyle interiorBackgroundStyle;
//	BOOL drawingBackground;
    NSTrackingArea *trackingArea;
}

- (void)resetRowViewProperties;

@end
