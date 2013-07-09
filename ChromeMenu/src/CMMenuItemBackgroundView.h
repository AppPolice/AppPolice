//
//  CMTableRowView.h
//  Ishimura
//
//  Created by Maksym on 7/4/13.
//  Copyright (c) 2013 Maksym Stefanchuk. All rights reserved.
//

//#import <Cocoa/Cocoa.h>
#import "CMMenuItem.h"

@class NSTableRowView;
//@class CMMenuItem;

@interface CMMenuItemBackgroundView : NSTableRowView
{
@private
	CMMenuItem *_owner;
}

@property (assign) CMMenuItem *owner;

/* reset view properties after it was returned from -makeViewWithIdentifier: */
- (void)resetBackgroundViewProperties;

@end


@interface CMMenuItem (CMMenuItemEventCommunication)

- (void)mouseEntered:(NSEvent *)theEvent;
- (void)mouseExited:(NSEvent *)theEvent;
- (void)mouseDown:(NSEvent *)theEvent;

@end