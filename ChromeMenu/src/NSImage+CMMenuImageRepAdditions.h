//
//  NSImage+NSImage_BitmapImageRep.h
//  Ishimura
//
//  Created by Maksym on 9/10/13.
//  Copyright (c) 2013 Maksym Stefanchuk. All rights reserved.
//

//#import <Cocoa/Cocoa.h>

@class NSBitmapImageRep;

@interface NSImage (CMMenuImageRepAdditions)

//- (NSBitmapImageRep *)bitmapImageRepresentation;
- (void)createInvertedImageRepresentation;
- (NSImageRep *)defaultImageRepresentation;
- (NSImageRep *)invertedImageRepresentation;

@end
