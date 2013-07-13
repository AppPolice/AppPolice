//
//  ChromMenuUnderlyingWindow.h
//  Ishimura
//
//  Created by Maksym on 7/3/13.
//  Copyright (c) 2013 Maksym Stefanchuk. All rights reserved.
//

//#import <Cocoa/Cocoa.h>
//#import <Foundation/Foundation.h>
//#import <AppKit/NSPanel.h>

@class NSPanel;

@interface ChromeMenuUnderlyingWindow : NSPanel
{
	@private
	NSPoint initialLocation;
}

- (id)initWithContentRect:(NSRect)contentRect defer:(BOOL)flag;

@end
