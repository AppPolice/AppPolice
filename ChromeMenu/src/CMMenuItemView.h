//
//  CMTableCellView.h
//  Ishimura
//
//  Created by Maksym on 7/3/13.
//  Copyright (c) 2013 Maksym Stefanchuk. All rights reserved.
//

//#import <Cocoa/Cocoa.h>
@class NSTableCellView;

@interface CMMenuItemView : NSTableCellView
{
@private
	NSImageView *_icon;
	NSTextField *_title;
	NSImageView *_ownersIcon;
}

@property (assign) IBOutlet NSImageView *icon;
@property (assign) IBOutlet NSTextField *title;
@property (assign) IBOutlet NSImageView *ownersIcon;


@end
