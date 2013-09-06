//
//  CMMenuEventTypes.h
//  Ishimura
//
//  Created by Maksym on 7/21/13.
//  Copyright (c) 2013 Maksym Stefanchuk. All rights reserved.
//

#ifndef Ishimura_CMMenuEventTypes_h
#define Ishimura_CMMenuEventTypes_h

enum {
	CMMenuEventDuringScroll = 1 << 0,				// when mouse event occurred because of scrolling
	CMMenuEventMouseEnteredItem = 1 << 1,
	CMMenuEventMouseExitedItem = 1 << 2,
	CMMenuEventMouseEnteredMenu = 1 << 3,
	CMMenuEventMouseExitedMenu = 1 << 4
};
typedef NSUInteger CMMenuEventType;


#endif
