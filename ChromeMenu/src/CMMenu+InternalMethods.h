//
//  CMMenu+InternalMethods.h
//  Ishimura
//
//  Created by Maksym on 7/12/13.
//  Copyright (c) 2013 Maksym Stefanchuk. All rights reserved.
//

//#include "CMMenuEventTypes.h"
#import "CMMenu.h"
#import "CMMenuKeyEventInterpreter.h"

enum {
	CMMenuOptionDefault = 0x000,
	CMMenuOptionIgnoreMouse = 0x001,
	CMMenuOptionTrackMouseMoved = 0x002
};
typedef NSUInteger CMMenuOptions;



@class CMMenuItem, CMMenuScroller;
//@protocol CMMenuKeyEventInterpreterDelegate;


@interface CMMenu (CMMenuInternalMethods) <CMMenuKeyEventInterpreterDelegate>

- (void)setSupermenu:(CMMenu *)aMenu;
- (void)setParentItem:(CMMenuItem *)anItem;
- (BOOL)isActive;
- (void)setIsActive:(BOOL)isActive;
- (CMMenu *)activeSubmenu;
- (void)setActiveSubmenu:(CMMenu *)submenu;

//- (BOOL)isAncestorTo:(CMMenu *)menu;

/**
 * @discussion Returns YES if menu is currently in NSEventTrackingRunLoopMode, NO otherwise.
 */
- (BOOL)isTracking;

/**
 * @discussion Receiving menu begins tracking in NSEventTrackingRunLoopMode if it is not already.
 */
- (void)beginTrackingWithEvent:(NSEvent *)theEvent;

/**
 * @discussion End previously started tracking.
 */
- (void)endTracking;

- (BOOL)isTrackingSubmenu;
- (void)startTrackingSubmenu:(CMMenu *)submenu forItem:(CMMenuItem *)item;
- (void)stopTrackingSubmenuReasonSuccess:(BOOL)reasonSuccess;
//- (void)startTrackingActiveSubmenu;
- (void)updateTrackingAreaWithOptions:(CMMenuOptions)options;

- (BOOL)receivesMouseMovedEvents;
- (void)setReceivesMouseMovedEvents:(BOOL)receiveEvents;

- (void)mouseEvent:(NSEvent *)theEvent;
//- (void)mouseMoved:(NSEvent *)theEvent;

/**
 * @abstract Show menu as submenu of a certain item
 * @discussion All submenus must be started using this method and never call -showWithOptions: directly.
 * @param menuItem Supermenu's item which has the target menu set as a submenu.
 */
- (void)showAsSubmenuOf:(CMMenuItem *)menuItem withOptions:(CMMenuOptions)options;	// may not be needed
//- (void)orderFront;

// TODO: this is temp method
- (NSWindow *)underlyingWindow;
- (NSInteger)windowLevel;

- (NSRect)convertRectToScreen:(NSRect)aRect;
- (NSPoint)convertPointToScreen:(NSPoint)aPoint;
- (NSPoint)convertPointFromScreen:(NSPoint)aPoint;

- (CMMenuScroller *)scrollerAtPoint:(NSPoint)aPoint;
- (void)scrollWithActiveScroller:(CMMenuScroller *)scroller;

@end