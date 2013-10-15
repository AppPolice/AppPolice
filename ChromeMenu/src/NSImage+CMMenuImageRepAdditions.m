//
//  NSImage+NSImage_BitmapImageRep.m
//  Ishimura
//
//  Created by Maksym on 9/10/13.
//  Copyright (c) 2013 Maksym Stefanchuk. All rights reserved.
//

#import <QuartzCore/CoreImage.h>
#import "NSImage+CMMenuImageRepAdditions.h"

@implementation NSImage (CMMenuImageRepAdditions)

- (NSBitmapImageRep *)bitmapImageRepresentation {
	NSInteger width = (NSInteger)self.size.width;
	NSInteger height = (NSInteger)self.size.height;
	
	if (width < 1 || height < 1)
		return nil;
	
	NSBitmapImageRep *rep = [[NSBitmapImageRep alloc]
							 initWithBitmapDataPlanes:NULL
							 pixelsWide:width
							 pixelsHigh:height
							 bitsPerSample:8
							 samplesPerPixel:4
							 hasAlpha:YES
							 isPlanar:NO
							 colorSpaceName:NSDeviceRGBColorSpace
							 bytesPerRow:width * 4
							 bitsPerPixel:32];
	
	NSGraphicsContext *ctx = [NSGraphicsContext graphicsContextWithBitmapImageRep:rep];
	[NSGraphicsContext saveGraphicsState];
	[NSGraphicsContext setCurrentContext:ctx];
	[self drawAtPoint: NSZeroPoint fromRect:NSZeroRect operation:NSCompositeCopy fraction:1.0];
	[ctx flushGraphics];
	[NSGraphicsContext restoreGraphicsState];
	
	return [rep autorelease];
}


- (void)createInvertedImageRepresentation {
	// We create new Inverted Colors image representation only if it hasn't been created earlier
	// Important. For future reference, if we will want to create more image representations
	// we would need to have more elaboreted checks in this place that a specific ImageRep was
	// indeed created.
	if ([[self representations] count] > 1)
		return;
	
//	NSLog(@"creating image rep of image: %@", self);
	
	NSBitmapImageRep *bitmapImageRep = [self bitmapImageRepresentation];
	//	NSLog(@"bitmap image rep: %@", bitmapImageRep);
	
	CIImage *ciImage = [[CIImage alloc] initWithBitmapImageRep:bitmapImageRep];
	CIFilter *ciFilter = [CIFilter filterWithName:@"CIColorInvert"];
	[ciFilter setValue:ciImage forKey:@"inputImage"];
	CIImage *resultImage = [ciFilter valueForKey:@"outputImage"];
	
	NSImageRep *newImageRep = [NSCIImageRep imageRepWithCIImage:resultImage];
	[self addRepresentation:newImageRep];
}


- (NSImageRep *)defaultImageRepresentation {
	return [[self representations] objectAtIndex:0];
}


- (NSImageRep *)invertedImageRepresentation {
	NSArray *reps = [self representations];
	if ([reps count] < 2)
		[self createInvertedImageRepresentation];
	return [[self representations] objectAtIndex:1];
}

@end
