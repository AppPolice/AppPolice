//
//  CMScrollView.h
//  Ishimura
//
//  Created by Maksym on 7/15/13.
//  Copyright (c) 2013 Maksym Stefanchuk. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface CMScrollView : NSScrollView

- (void)scrollUpByAmount:(CGFloat)amount;
- (void)scrollBottomByAmount:(CGFloat)amount;

@end
