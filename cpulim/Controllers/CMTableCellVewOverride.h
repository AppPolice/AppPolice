//
//  CMTableCellVewOverride.h
//  Ishimura
//
//  Created by Maksym on 7/5/13.
//  Copyright (c) 2013 Maksym Stefanchuk. All rights reserved.
//

#import "CMMenuItemView.h"

@interface CMTableCellVewOverride : CMMenuItemView
{
@private
	NSImageView *_statusIcon;
// 	NSImageView *_icon;   <-- this should be taken from parent
	
}

//@property (assign) IBOutlet NSImageView *icon;
@property (assign) IBOutlet NSImageView *statusIcon;

@end
