//
//  CMMenuItemView+InternalMethods.h
//  Ishimura
//
//  Created by Maksym on 7/20/13.
//  Copyright (c) 2013 Maksym Stefanchuk. All rights reserved.
//


@interface CMMenuItemView (CMMenuItemViewInternalMethods)

- (void)setHasSubmenuIcon:(BOOL)hasIcon;

- (BOOL)isSelected;
- (void)setSelected:(BOOL)selected;

- (BOOL)isEnabled;
- (void)setEnabled:(BOOL)enabled;

- (void)fadeIn;
- (void)fadeOutWithComplitionHandler:(void (^)(void))handler;
- (void)blink;

- (void)setIndentationLevel:(NSInteger)indentationLevel;
- (NSInteger)indentationLevel;

/**
 * @function needsTracking
 * @abstract Tells whether a view will have a tracking area created.
 * @discussion This method is meant to be overridden by the Separator View.
 */
- (BOOL)needsTracking;

@end
