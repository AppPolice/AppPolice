//
//  CMMenuItem.h
//  Ishimura
//
//  Created by Maksym on 7/4/13.
//  Copyright (c) 2013 Maksym Stefanchuk. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CMMenuItem : NSObject
{
@private
	NSImage *_icon;
	NSString *_title;
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

- (void)setViewFromNibNamed:(NSString *)nibName withIdentifier:(NSString *)identifier andPropertyNames:(NSArray *)propertyNames;

- (void)setTitle:(NSString *)aString;
- (NSString *)title;
- (void)setIcon:(NSImage *)anImage;
- (NSImage *)icon;
- (BOOL)isSeparatorItem;

@end