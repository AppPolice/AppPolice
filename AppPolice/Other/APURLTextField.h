//
//  APURLTextField.h
//  AppPolice
//
//  Created by Maksym on 20/11/13.
//  Copyright (c) 2013 Maksym Stefanchuk. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface APURLTextField : NSTextField
{
	NSTrackingRectTag _trackingRect;
	NSMutableAttributedString *_attributedString;
}

@end
