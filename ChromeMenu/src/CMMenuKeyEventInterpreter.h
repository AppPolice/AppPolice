//
//  CMMenuKeyEventInterpreter.h
//  Ishimura
//
//  Created by Maksym on 9/16/13.
//  Copyright (c) 2013 Maksym Stefanchuk. All rights reserved.
//

//#import <Foundation/Foundation.h>

@class NSObject, NSEvent;
@protocol CMMenuKeyEventInterpreterDelegate, NSObject;


@interface CMMenuKeyEventInterpreter : NSObject
{
	@private
	id _delegate;
}
/**
 * @abstract Create local monitor for Key Events and route interpreted actions to an owning menu.
 * @param target A menu to receive interpreted actions.
 */
- (id)initWithDelegate:(id <CMMenuKeyEventInterpreterDelegate>)delegate;
- (void)setDelegate:(id <CMMenuKeyEventInterpreterDelegate>)delegate;

- (void)interpretEvent:(NSEvent *)theEvent;


@end

@protocol CMMenuKeyEventInterpreterDelegate <NSObject>
@optional

- (void)moveUp:(NSEvent *)originalEvent;
- (void)moveDown:(NSEvent *)originalEvent;
- (void)moveLeft:(NSEvent *)originalEvent;
- (void)moveRight:(NSEvent *)originalEvent;
- (void)cancelOperation:(NSEvent *)originalEvent;
- (void)performSelected:(NSEvent *)originalEvent;

@end
