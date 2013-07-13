//
//  CMMenuWindowController.h
//  Ishimura
//
//  Created by Maksym on 7/12/13.
//  Copyright (c) 2013 Maksym Stefanchuk. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface CMWindowController : NSWindowController


/* The designated initializer. This window controller creates its own custom suggestions window. */
- (id)init;

- (void)layoutViews:(NSMutableArray *)viewControllers;

- (void)display;
- (void)hide;

@end
