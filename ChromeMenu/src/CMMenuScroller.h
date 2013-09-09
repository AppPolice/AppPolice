//
//  CMMenuScroller.h
//  Ishimura
//
//  Created by Maksym on 9/7/13.
//  Copyright (c) 2013 Maksym Stefanchuk. All rights reserved.
//

#import <Cocoa/Cocoa.h>

enum {
	CMMenuScrollerTop = 1,
	CMMenuScrollerBottom = 2
};
typedef NSUInteger CMMenuScrollerType;



@interface CMMenuScroller : NSView
{
	CMMenuScrollerType _scrollerType;
}

- (id)initWithScrollerType:(CMMenuScrollerType)scrollerType;

@end
