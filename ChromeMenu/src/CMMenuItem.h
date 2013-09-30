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
	
	id _target;
    SEL _action;
	
	NSString *_viewNibName;
//	NSString *_viewIdentifier;
	NSArray *_viewPropertyNames;
}

@property (readonly) NSString *viewNibName;
@property (readonly) NSString *viewIdentifier;
@property (readonly) NSArray *viewPropertyNames;

+ (CMMenuItem *)separatorItem;

- (id)initWithTitle:(NSString *)aTitle action:(SEL)aSelector;
- (id)initWithTitle:(NSString *)aTitle icon:(NSImage *)anImage action:(SEL)aSelector;

/* returns menu to which item belongs */
- (CMMenu *)menu;

- (BOOL)hasSubmenu;
- (void)setSubmenu:(CMMenu *)submenu;
- (CMMenu *)submenu;

//- (void)setViewFromNibNamed:(NSString *)nibName withIdentifier:(NSString *)identifier andPropertyNames:(NSArray *)propertyNames;
- (void)setViewFromNibNamed:(NSString *)nibName andPropertyNames:(NSArray *)propertyNames;

- (void)setTitle:(NSString *)aString;
- (NSString *)title;
- (void)setIcon:(NSImage *)anImage;
- (NSImage *)icon;
- (BOOL)isSeparatorItem;

- (void)setTarget:(id)anObject;
- (id)target;
- (void)setAction:(SEL)aSelector;
- (SEL)action;

@end
