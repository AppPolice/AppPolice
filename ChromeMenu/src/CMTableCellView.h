//
//  CMTableCellView.h
//  Ishimura
//
//  Created by Maksym on 7/3/13.
//  Copyright (c) 2013 Maksym Stefanchuk. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface CMTableCellView : NSTableCellView
{
	NSImageView *_itemIcon;
	NSTextField *_itemText;
	NSImageView *_ownersIcon;
}

@property (assign) IBOutlet NSImageView *itemIcon;
@property (assign) IBOutlet NSTextField *itemText;
@property (assign) IBOutlet NSImageView *ownersIcon;


@end
