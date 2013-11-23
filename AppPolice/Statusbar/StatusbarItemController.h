//
//  StatusbarItemController.h
//  AppPolice
//
//  Created by Maksym on 10/11/13.
//  Copyright (c) 2013 Maksym Stefanchuk. All rights reserved.
//

#import <Cocoa/Cocoa.h>
//#import "ChromeMenu.h"
#import <ChromeMenu/ChromeMenu.h>

@class StatusbarItemView;

@interface StatusbarItemController : NSObject
{
	@private
	NSStatusItem *_statusbarItem;
	CMMenu *_menu;
//	NSImage *_image;
//	NSImage *_alternateImage;
	StatusbarItemView *_view;
	NSTimeInterval _timestamp;
}

- (NSImage* )image;
- (void)setImage:(NSImage*)image;

- (NSImage *)alternateImage;
- (void)setAlternateImage:(NSImage*)image;

//- (void)addItemToStatusbar;
- (void)setStatusbarItemMenu:(CMMenu *)menu;

@end
