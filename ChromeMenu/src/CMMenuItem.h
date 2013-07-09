//
//  CMMenuItem.h
//  Ishimura
//
//  Created by Maksym on 7/4/13.
//  Copyright (c) 2013 Maksym Stefanchuk. All rights reserved.
//

#import <Foundation/Foundation.h>
//#import "CMMenu.h"
@class CMMenu;

@interface CMMenuItem : NSObject
{
@private
	CMMenu *_menu;
	NSImage *_icon;
	NSString *_title;
	CMMenu *_submenu;
	BOOL _isSeparatorItem;
	
	NSString *_viewNibName;
	NSString *_viewIdentifier;
	NSArray *_viewPropertyNames;
}

@property (readonly) NSString *viewNibName;
@property (readonly) NSString *viewIdentifier;
@property (readonly) NSArray *viewPropertyNames;

+ (CMMenuItem *)separatorItem;

- (id)initWithTitle:(NSString *)aTitle;
- (id)initWithTitle:(NSString *)aTitle andIcon:(NSImage *)anImage;

/* returns menu to which item belongs */
- (CMMenu *)menu;

- (BOOL)hasSubmenu;
- (void)setSubmenu:(CMMenu *)submenu;
- (CMMenu *)submenu;

- (void)setViewFromNibNamed:(NSString *)nibName withIdentifier:(NSString *)identifier andPropertyNames:(NSArray *)propertyNames;

- (void)setTitle:(NSString *)aString;
- (NSString *)title;
- (void)setIcon:(NSImage *)anImage;
- (NSImage *)icon;
- (BOOL)isSeparatorItem;

@end
