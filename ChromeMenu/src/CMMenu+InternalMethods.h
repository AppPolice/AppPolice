//
//  CMMenu+InternalMethods.h
//  Ishimura
//
//  Created by Maksym on 7/12/13.
//  Copyright (c) 2013 Maksym Stefanchuk. All rights reserved.
//

//#include "CMMenuEventTypes.h"

enum {
	CMMenuOptionDefault = 0x000,
	CMMenuOptionIgnoreMouse = 0x001,
	CMMenuOptionTrackMouseMoved = 0x002
};

typedef NSUInteger CMMenuOptions;



@class CMMenuItem, CMMenuScroller;

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
- (void)updateTrackingAreaWithOptions:(CMMenuOptions)options;

- (void)mouseEvent:(NSEvent *)theEvent;

/**
 * @abstract Show menu as submenu of a certain item
 * @discussion All submenus must be started using this method and never call -showWithOptions: directly.
 * @param menuItem Supermenu's item which has the target menu set as a submenu.
 */
- (void)showAsSubmenuOf:(CMMenuItem *)menuItem withOptions:(CMMenuOptions)options;	// may not be needed
//- (void)orderFront;
- (NSInteger)windowLevel;

- (NSRect)convertRectToScreen:(NSRect)aRect;
- (NSPoint)convertPointToScreen:(NSPoint)aPoint;
- (NSPoint)convertPointFromScreen:(NSPoint)aPoint;

- (CMMenuScroller *)scrollerAtPoint:(NSPoint)aPoint;
- (void)scrollWithActiveScroller:(CMMenuScroller *)scroller;

@end