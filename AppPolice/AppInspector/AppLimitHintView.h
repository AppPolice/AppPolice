//
//  AppLimitHintView.h
//  Ishimura
//
//  Created by Maksym on 10/9/13.
//  Copyright (c) 2013 Maksym Stefanchuk. All rights reserved.
//

#import <AppKit/AppKit.h>

@protocol AppLimitHintViewDelegate;

#define APAppLimitHintMouseDownNotification @"appLimitHintMouseDownNotification"


@interface AppLimitHintView : NSView
{
	@private
	IBOutlet NSImageView *_hintImage;
	NSTrackingArea *_trackingArea;
	BOOL _observingAppInspectorNotifications;
}
@end
