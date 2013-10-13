//
//  CMMenuItem.h
//  Ishimura
//
//  Created by Maksym on 7/4/13.
//  Copyright (c) 2013 Maksym Stefanchuk. All rights reserved.
//

//#import <Foundation/Foundation.h>
//#import "CMMenu.h"
@class NSObject, NSImage, NSString, NSArray;
@class CMMenu;

@interface CMMenuItem : NSObject
{
@private
	CMMenu *_menu;
	BOOL _enabled;
	NSImage *_icon;
	NSString *_title;
	CMMenu *_submenu;
	id _representedObject;
	BOOL _isSeparatorItem;
	NSInteger _state;
	
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
//- (void)setViewFromNibNamed:(NSString *)nibName andPropertyNames:(NSArray *)propertyNames;

- (void)setTitle:(NSString *)aString;
- (NSString *)title;
- (void)setIcon:(NSImage *)anImage;
- (NSImage *)icon;

// An integer constant representing a state; it should be one of NSOffState, NSOnState, or NSMixedState.
- (void)setState:(NSInteger)state;
- (NSInteger)state;
- (void)setOnStateImage:(NSImage *)image;  // checkmark by default
- (NSImage *)onStateImage;
- (void)setOffStateImage:(NSImage *)image;  // none by default
- (NSImage *)offStateImage;
- (void)setMixedStateImage:(NSImage *)image;  // horizontal line by default?
- (NSImage *)mixedStateImage;

- (void)setEnabled:(BOOL)flag;
- (BOOL)isEnabled;

- (BOOL)isSeparatorItem;

- (void)setTarget:(id)anObject;
- (id)target;
- (void)setAction:(SEL)aSelector;
- (SEL)action;

- (void)setRepresentedObject:(id)anObject;
- (id)representedObject;

/* Indicates whether the menu item should be drawn highlighted or not. */
- (BOOL)isHighlighted;


@end
