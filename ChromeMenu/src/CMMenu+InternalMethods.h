//
//  CMMenu+InternalMethods.h
//  Ishimura
//
//  Created by Maksym on 7/12/13.
//  Copyright (c) 2013 Maksym Stefanchuk. All rights reserved.
//

@interface CMMenu (CMMenuInternalMethods)
- (void)setSupermenu:(CMMenu *)aMenu;
- (void)showMenuAsSubmenuOf:(CMMenuItem *)menuItem;	// may not be needed
//- (void)orderFront;
- (NSInteger)windowLevel;
@end