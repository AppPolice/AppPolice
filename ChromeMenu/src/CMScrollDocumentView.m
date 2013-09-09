//
//  CMMenuScrollDocumentView.m
//  Ishimura
//
//  Created by Maksym on 7/12/13.
//  Copyright (c) 2013 Maksym Stefanchuk. All rights reserved.
//

#import "CMScrollDocumentView.h"

@implementation CMScrollDocumentView

//- (id)initWithFrame:(NSRect)frame
//{
//    self = [super initWithFrame:frame];
//    if (self) {
//        // Initialization code here.
//    }
//    
//    return self;
//}

//- (void)drawRect:(NSRect)dirtyRect {
//    // Drawing code here.
//}


- (BOOL)isFlipped {
	return YES;
}

//- (void)updateTrackingAreas {
////	NSPoint currentLocation = [[self window] mouseLocationOutsideOfEventStream];
////	currentLocation = [self convertPoint:currentLocation fromView:nil];
////	NSLog(@"Update Tracking Areas called!! Mouse at: %@", NSStringFromPoint(currentLocation));
//	if (_updateTrackingAreasListener &&
//		[_updateTrackingAreasListener respondsToSelector:@selector(shouldUpdateTrackingAreas)])
//		[_updateTrackingAreasListener performSelector:@selector(shouldUpdateTrackingAreas)];
//	
//	[super updateTrackingAreas];
//}
//
//
//- (void)setListenerForUpdateTrackingAreasEvent:(id)anObject {
//	_updateTrackingAreasListener = anObject;
//}

@end
