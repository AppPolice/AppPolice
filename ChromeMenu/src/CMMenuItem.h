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
}

//@property (retain) NSImage *itemIcon;
//@property (copy) NSString *itemText;

+ (CMMenuItem *)separatorItem;

- (id)initWithTitle:(NSString *)aTitle;


- (void)setTitle:(NSString *)aString;
- (NSString *)title;

- (BOOL)isSeparatorItem;

- (void)setIcon:(NSImage *)aImage;
- (NSImage *)icon;

@end