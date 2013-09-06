//
//  CMMenuItem+InternalMethods.h
//  Ishimura
//
//  Created by Maksym on 7/12/13.
//  Copyright (c) 2013 Maksym Stefanchuk. All rights reserved.
//

#include "CMMenuEventTypes.h"

@interface CMMenuItem (CMMenuItemInternalMethods)

/* not copied, not retained */
- (void)setRepresentedViewController:(NSViewController *)viewController;

- (void)setMenu:(CMMenu *)aMenu;

//- (void)mouseEventOfTypes:(CMMenuEventType)eventTypes;
- (BOOL)shouldChangeItemSelectionStatusForEvent:(CMMenuEventType)eventType;

- (NSRect)frame;
- (NSRect)frameRelativeToMenu;
- (NSRect)frameRelativeToScreen;

- (BOOL)mouseOver;

- (void)selectWithDelayForSubmenu:(NSTimeInterval)delay;
- (void)deselect;

@end