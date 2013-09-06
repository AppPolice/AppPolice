//
//  CMMenu+InternalMethods.h
//  Ishimura
//
//  Created by Maksym on 7/12/13.
//  Copyright (c) 2013 Maksym Stefanchuk. All rights reserved.
//

//#include "CMMenuEventTypes.h"

@interface CMMenu (CMMenuInternalMethods)

- (void)setSupermenu:(CMMenu *)aMenu;
- (void)setParentItem:(CMMenuItem *)anItem;
- (BOOL)isActive;
- (void)setIsActive:(BOOL)isActive;
- (CMMenu *)activeSubmenu;
- (void)setActiveSubmenu:(CMMenu *)submenu;

- (BOOL)isTrackingSubmenu;
- (void)startTrackingSubmenu:(CMMenu *)submenu forItem:(CMMenuItem *)item;
- (void)stopTrackingSubmenuReasonSuccess:(BOOL)reasonSuccess;
//- (void)startTrackingActiveSubmenu;

- (void)mouseEvent:(NSEvent *)theEvent;

- (void)showMenuAsSubmenuOf:(CMMenuItem *)menuItem;	// may not be needed
//- (void)orderFront;
- (NSInteger)windowLevel;

- (NSRect)convertRectToScreen:(NSRect)aRect;

@end