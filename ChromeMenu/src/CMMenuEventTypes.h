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
	CMMenuEventDuringScroll = 0x001,				// when mouse event occurred because of scrolling
	CMMenuEventMouseEnteredItem = 0x002,
	CMMenuEventMouseExitedItem = 0x004,
	CMMenuEventMouseItem = 0x006,
	CMMenuEventMouseEnteredMenu = 0x008,
	CMMenuEventMouseExitedMenu = 0x010,
	CMMenuEventMouseMenu = 0x018,
	CMMenuEventMouseEnteredScroller = 0x020,
	CMMenuEventMouseExitedScroller = 0x040,
	CMMenuEventMouseScroller = 0x060
};
typedef NSUInteger CMMenuEventType;


#endif
