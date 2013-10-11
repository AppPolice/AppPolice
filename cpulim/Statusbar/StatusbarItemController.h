//
//  StatusbarItemController.h
//  Ishimura
//
//  Created by Maksym on 10/11/13.
//  Copyright (c) 2013 Maksym Stefanchuk. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CMMenu;

@interface StatusbarItemController : NSObject

- (void)addItemToStatusbar;
- (void)setStatusbarItemMenu:(CMMenu *)menu;

@end
