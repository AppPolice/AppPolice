//
//  CMMenuItem+InternalMethods.h
//  Ishimura
//
//  Created by Maksym on 7/12/13.
//  Copyright (c) 2013 Maksym Stefanchuk. All rights reserved.
//

#ifndef CMMenuItem_InternalMethods
#define CMMenuItem_InternalMethods

#import "CMMenu+InternalMethods.h"

@interface CMMenuItem (CMMenuItemInternalMethods)

- (NSViewController *)representedView;
/* not copied, not retained */
- (void)setRepresentedView:(NSViewController *)viewController;

- (void)setMenu:(CMMenu *)aMenu;

- (BOOL)shouldChangeItemSelectionStatusForEvent:(CMMenuEventType)eventType;

- (NSRect)frame;
- (NSRect)frameRelativeToMenu;
- (NSRect)frameRelativeToScreen;

- (BOOL)isSelected;
- (BOOL)mouseOver;

/**
 * @abstract Sets item selected and highlighted accordingly. Submenu, event if the item has it, is not being shown.
 */
- (void)select;
/**
 * @abstract Sets item selected and highlighted accordingly and shows submenu after delay.
 * @param delay Delay after which submenu popups.
 */
- (void)selectWithDelayForSubmenu:(NSTimeInterval)delay;
- (void)deselect;

@end

#endif
