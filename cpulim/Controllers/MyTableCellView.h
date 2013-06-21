//
//  MyTableCellView.h
//  Ishimura
//
//  Created by Maksym on 6/1/13.
//  Copyright (c) 2013 Maksym Stefanchuk. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class MyImageView;

@interface MyTableCellView : NSTableCellView
{
	IBOutlet MyImageView *cellImage;
	IBOutlet NSTextField *cellText;
}

@property (assign) IBOutlet MyImageView *cellImage;
@property (assign) IBOutlet NSTextField *cellText;

@end
