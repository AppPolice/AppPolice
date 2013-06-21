//
//  TestTableRowView.h
//  Ishimura
//
//  Created by Maksym on 6/3/13.
//  Copyright (c) 2013 Maksym Stefanchuk. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface TestTableRowView : NSTableRowView
{
@private
	BOOL mouseInside;
   NSTrackingArea *trackingArea;

}
@end
