//
//  CMMenuItem+InternalMethods.h
//  Ishimura
//
//  Created by Maksym on 7/12/13.
//  Copyright (c) 2013 Maksym Stefanchuk. All rights reserved.
//

enum {
	CMMenuEventImplicit = 1 << 0,				// when mouse event happend because of scrolling
	CMMenuEventMouseEnteredItem = 1 << 1,
	CMMenuEventMouseExitedItem = 1 << 2
};
typedef NSUInteger CMMenuEventType;


@interface CMMenuItem (CMMenuItemInternalMethods)

/* not copied, not retained */
- (void)setRepresentedViewController:(NSViewController *)viewController;

- (void)setMenu:(CMMenu *)aMenu;

//- (void)mouseEventOfTypes:(CMMenuEventType)eventTypes;
- (BOOL)shouldChangeItemSelectionStatusForEvent:(CMMenuEventType)eventType;

- (NSRect)frame;
- (NSRect)frameRelativeToWindow;

- (BOOL)mouseOver;

- (void)selectWithDelayForSubmenu:(NSTimeInterval)delay;
- (void)deselect;

@end