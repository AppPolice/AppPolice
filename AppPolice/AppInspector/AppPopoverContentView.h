//
//  AppPopoverContentView.h
//  Ishimura
//
//  Created by Maksym on 02/11/13.
//  Copyright (c) 2013 Maksym Stefanchuk. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface AppPopoverContentView : NSView
{
	@private
	IBOutlet NSSlider *_slider;
	IBOutlet NSTextField *_centerTextfield;
	IBOutlet NSTextField *_rightTextfield;
//	IBOutlet NSLayoutConstraint *_centerTextfieldConstraint;
//	IBOutlet NSLayoutConstraint *_rightTextfieldConstraint;
}


@end
