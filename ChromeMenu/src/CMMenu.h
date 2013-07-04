//
//  ChromeMenu.h
//  Ishimura
//
//  Created by Maksym on 7/3/13.
//  Copyright (c) 2013 Maksym Stefanchuk. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ChromMenuUnderlyingWindow;

@interface CMMenu : NSObject
{
@private
	IBOutlet ChromMenuUnderlyingWindow *underlyingWindow;
	IBOutlet NSTextField *title;
}

- (id)initWithTitle:(NSString *)aTitle;

@end
