//
//  StatusbarItemView.h
//  Ishimura
//
//  Created by Maksym on 7/3/13.
//  Copyright (c) 2013 Maksym Stefanchuk. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#define StatusbarItemLeftMouseDownNotification @"statusbarItemLeftMouseDownNotification"
#define StatusbarItemRightMouseDownNotification @"statusbarItemRightMouseDownNotification"
#define StatusbarItemMouseUpNotification @"statusbarItemMouseUpNotification"

@interface StatusbarItemView : NSView
{
	@private
	NSImage *_image;
	NSImage *_alternateImage;
	NSImageView *_imageView;
	BOOL _highlighted;
}

- (NSImage* )image;
- (void)setImage:(NSImage*)image;

- (NSImage *)alternateImage;
- (void)setAlternateImage:(NSImage*)image;

- (void)setHighlighted:(BOOL)highlighted;
- (BOOL)highlighted;

@end
