//
//  CMScrollView.h
//  Ishimura
//
//  Created by Maksym on 7/15/13.
//  Copyright (c) 2013 Maksym Stefanchuk. All rights reserved.
//

//#import <Cocoa/Cocoa.h>

@class NSScrollView;

@interface CMScrollView : NSScrollView

- (void)scrollWithEvent:(NSEvent *)theEvent;
- (void)scrollUpByAmount:(CGFloat)amount;
- (void)scrollDownByAmount:(CGFloat)amount;

@end
