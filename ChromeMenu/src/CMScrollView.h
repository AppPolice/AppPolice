//
//  CMScrollView.h
//  Ishimura
//
//  Created by Maksym on 7/15/13.
//  Copyright (c) 2013 Maksym Stefanchuk. All rights reserved.
//

#import <AppKit/AppKit.h>

@interface CMScrollView : NSScrollView

- (void)scrollWithEvent:(NSEvent *)theEvent;
- (void)scrollUpByAmount:(CGFloat)amount;
- (void)scrollDownByAmount:(CGFloat)amount;

@end
