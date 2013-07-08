//
//  CMTableRowView.h
//  Ishimura
//
//  Created by Maksym on 7/4/13.
//  Copyright (c) 2013 Maksym Stefanchuk. All rights reserved.
//

//#import <Cocoa/Cocoa.h>

@class NSTableRowView;
@class CMMenuItem;

@interface CMMenuItemBackgroundView : NSTableRowView
{
@private
	BOOL mouseInside;
    NSTrackingArea *trackingArea;
	CMMenuItem *_owner;
}

/* reset view properties after it was returned from -makeViewWithIdentifier: */
- (void)resetBackgroundViewProperties;

@end
