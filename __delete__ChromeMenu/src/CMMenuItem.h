//
//  CMMenuItem.h
//  Ishimura
//
//  Created by Maksym on 7/4/13.
//  Copyright (c) 2013 Maksym Stefanchuk. All rights reserved.
//


#import <AppKit/AppKit.h>

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
	
	NSInteger _indentationLevel;
	id _target;
    SEL _action;
}

+ (CMMenuItem *)separatorItem;

- (id)initWithTitle:(NSString *)aTitle action:(SEL)aSelector;
- (id)initWithTitle:(NSString *)aTitle icon:(NSImage *)anImage action:(SEL)aSelector;

/* returns menu to which item belongs */
- (CMMenu *)menu;

- (BOOL)hasSubmenu;
- (void)setSubmenu:(CMMenu *)submenu;
- (CMMenu *)submenu;

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

/*!
	@description Sets the menu item indentation level for the receiver
	@param indentationLevel The value for \p indentationLevel may be from 0 to 15.
		If \p indentationLevel is greater than 15, the value is pinned to the maximum.
		If \p indentationLevel is less than 0, an exception is raised. The default indentation level is 0.
 */
- (void)setIndentationLevel:(NSInteger)indentationLevel;
- (NSInteger)indentationLevel;

- (void)setTarget:(id)anObject;
- (id)target;
- (void)setAction:(SEL)aSelector;
- (SEL)action;

- (void)setRepresentedObject:(id)anObject;
- (id)representedObject;

/* Indicates whether the menu item should be drawn highlighted or not. */
- (BOOL)isHighlighted;


@end
