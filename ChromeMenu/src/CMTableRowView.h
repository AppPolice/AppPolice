//
//  CMTableRowView.h
//  Ishimura
//
//  Created by Maksym on 7/4/13.
//  Copyright (c) 2013 Maksym Stefanchuk. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface CMTableRowView : NSTableRowView
{
@private
	BOOL mouseInside;
    NSTrackingArea *trackingArea;
}

- (void)resetRowViewProperties;

@end
