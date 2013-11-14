//
//  CMMenu+InternalMethods.h
//  Ishimura
//
//  Created by Maksym on 7/12/13.
//  Copyright (c) 2013 Maksym Stefanchuk. All rights reserved.
//


#ifndef CMMenu_InternalMethods
#define CMMenu_InternalMethods

#import "CMMenu.h"
#import "CMMenuKeyEventInterpreter.h"


#define SUBMENU_POPUP_DELAY_DEFAULT 0.2
#define SUBMENU_POPUP_DELAY_AFTER_TRACKING 0.15
#define SUBMENU_POPUP_NO_DELAY 0



#ifndef Ishimura_CMMenuEventTypes_h
#define Ishimura_CMMenuEventTypes_h

typedef enum : NSUInteger {
	CMMenuEventDuringTrackingAreaUpdate = 0x001,				// when mouse event occurred because of scrolling
	CMMenuEventMouseEnteredItem = 0x002,
	CMMenuEventMouseExitedItem = 0x004,
	CMMenuEventMouseItem = 0x006,
	CMMenuEventMouseEnteredMenu = 0x008,
	CMMenuEventMouseExitedMenu = 0x010,
	CMMenuEventMouseMenu = 0x018,
	CMMenuEventMouseEnteredScroller = 0x020,
	CMMenuEventMouseExitedScroller = 0x040,
	CMMenuEventMouseScroller = 0x060
} CMMenuEventType;
//typedef NSUInteger CMMenuEventType;

#endif


enum {
	CMMenuOptionDefaults = 0x000,
	CMMenuOptionIgnoreMouse = 0x001,
//	CMMenuOptionTrackMouseMoved = 0x002,
	CMMenuOptionUpdateTrackingPrimitives = 0x004,
	CMMenuOptionUpdateScrollers = 0x008
};
typedef NSUInteger CMMenuOptions;


enum {
	CMMenuAlignedRight = 1,
	CMMenuAlignedLeft = 2,
	CMMenuAlignedTop = 3,
	CMMenuAlignedBottom = 4
};
typedef NSUInteger CMMenuAlignment;


@class CMMenuItem, CMMenuScroller, CMWindowController;


@interface CMMenu (CMMenuInternalMethods) <CMMenuKeyEventInterpreterDelegate>

- (CMMenu *)rootMenu;

- (void)setNeedsDisplay:(BOOL)needsDisplay;
- (BOOL)needsDisplay;
- (void)setSupermenu:(CMMenu *)aMenu;
- (void)setParentItem:(CMMenuItem *)anItem;
- (BOOL)isActive;
- (void)setIsActive:(BOOL)isActive;
- (CMMenu *)activeSubmenu;
- (void)setActiveSubmenu:(CMMenu *)submenu;

- (BOOL)isAttachedToStatusItem;
- (NSRect)statusItemRect;

- (CMMenuAlignment)horizontalAlignment;
- (CMMenuAlignment)verticalAlignment;

/**
 * @discussion Returns YES if menu is currently in NSEventTrackingRunLoopMode, NO otherwise.
 */
- (BOOL)isTracking;

/**
 * @abstract Receiving menu begins tracking in NSEventTrackingRunLoopMode if it is not already.
 */
- (void)beginTrackingWithEvent:(NSEvent *)theEvent options:(CMMenuOptions)options;

/**
 * @abstract End previously started tracking.
 */
- (void)endTracking;

- (BOOL)isTrackingSubmenu;
- (void)startTrackingSubmenu:(CMMenu *)submenu forItem:(CMMenuItem *)item;
- (void)stopTrackingSubmenuReasonSuccess:(BOOL)reasonSuccess;
- (void)updateTrackingPrimitiveForItem:(CMMenuItem *)item;

/* Default 0: no event's are blocked */
- (NSEventMask)eventBlockingMask;
- (void)blockEventsMatchingMask:(NSEventMask)mask;

/**
 * @abstract Returns YES if menu wants to receive Mouse Moved events. This value is checked on RunLoop
 *	to decide whether Moved events will be captured and sent to menu.
 */
- (BOOL)receivesMouseMovedEvents;

/**
 * @abstract Set whether menu will receive Mouse Moved events.
 * @discussion With current implementation of this method it doesn't mean menu will necesseraly begin
 *	receiving moved events. If receiving menu's supermenu is not set to receive moved events, and mouse
 *	is not inside receiving menu's frame the method will simply return. If receiving menu's supermenu is
 *	set to receive moved events and mouse is not withing the menu's frame, menu will receive moved events
 *	but it will not update its tracking area to generate moved events within itself.
 */
- (void)setReceivesMouseMovedEvents:(BOOL)receiveEvents;

/**
 * @abstract Pass mouse event to a menu for a processing.
 */
- (void)mouseEvent:(NSEvent *)theEvent __attribute__ ((deprecated));
- (void)mouseEventAtLocation:(NSPoint)mouseLocation type:(NSEventType)eventType;
- (CMMenu *)menuAtPoint:(NSPoint)location;

/* Perform item's action */
- (void)performActionForItem:(CMMenuItem *)item;

//- (void)mouseMoved:(NSEvent *)theEvent;

/**
 * @abstract Show menu as submenu of a certain item
 * @discussion All submenus must be started using this method and never call -showWithOptions: directly.
 * @param menuItem Supermenu's item which has the target menu set as a submenu.
 */
- (void)showAsSubmenuOf:(CMMenuItem *)menuItem withOptions:(CMMenuOptions)options;	// may not be needed
//- (void)orderFront;

- (NSRect)frame;

- (CMWindowController *)underlyingWindowController;
- (NSInteger)windowLevel;

- (NSRect)convertRectToScreen:(NSRect)aRect;
- (NSPoint)convertPointToScreen:(NSPoint)aPoint;
- (NSPoint)convertPointFromScreen:(NSPoint)aPoint;

- (CMMenuScroller *)scrollerAtPoint:(NSPoint)aPoint;
- (void)scrollWithActiveScroller:(CMMenuScroller *)scroller;

@end

#endif
