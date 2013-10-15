//
//  AppLimitHintView.h
//  Ishimura
//
//  Created by Maksym on 10/9/13.
//  Copyright (c) 2013 Maksym Stefanchuk. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol AppLimitHintViewDelegate;

#define AppLimitHintMouseDownNotification @"appLimitHintMouseDownNotification"


@interface AppLimitHintView : NSView
{
	@private
	IBOutlet NSImageView *_hintImage;
//	IBOutlet id <AppLimitHintViewDelegate> _delegate;
	NSTrackingArea *_trackingArea;
}
@end


//@protocol AppLimitHintViewDelegate <NSObject>

//- (void)mouseUp:(id)sender;

//@end
