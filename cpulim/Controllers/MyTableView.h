//
//  MyTableView.h
//  Ishimura
//
//  Created by Maksym on 5/31/13.
//  Copyright (c) 2013 Maksym Stefanchuk. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class MyTableRowView;

@interface MyTableView : NSTableView
{
//	MyTableRowView *selectedRow;
	MyTableRowView *mouseoverRow;
}

//@property (nonatomic, assign) MyTableRowView *selectedRow;
@property (nonatomic, assign) MyTableRowView *mouseoverRow;

@end
