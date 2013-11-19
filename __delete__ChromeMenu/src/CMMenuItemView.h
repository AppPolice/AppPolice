//
//  CMTableCellView.h
//  Ishimura
//
//  Created by Maksym on 7/3/13.
//  Copyright (c) 2013 Maksym Stefanchuk. All rights reserved.
//

#import <AppKit/AppKit.h>

@interface CMMenuItemView : NSView
{
@private
	NSImageView *_state;
	NSImageView *_icon;
	NSTextField *_title;
}

@property (assign) IBOutlet NSImageView *state;
@property (assign) IBOutlet NSImageView *icon;
@property (assign) IBOutlet NSTextField *title;

@end
