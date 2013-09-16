//
//  CMMenuKeyEventInterpreter.h
//  Ishimura
//
//  Created by Maksym on 9/16/13.
//  Copyright (c) 2013 Maksym Stefanchuk. All rights reserved.
//

//#import <Foundation/Foundation.h>

@class NSObject;

@interface CMMenuKeyEventInterpreter : NSObject
{
	@private
	id _target;
	id _localEventMonitor;
}
/**
 * @abstract Create local monitor for Key Events and route interpreted actions to an owning menu.
 * @param target A menu to receive interpreted actions.
 */
- (id)initWithTarget:(id)target;
- (void)setTarget:(id)target;

- (void)start;
- (void)stop;

@end

@protocol CMMenuKeyEventInterpreterDelegate <NSObject>
@optional

- (void)moveUp:(id)sender;
- (void)moveDown:(id)sender;

@end
