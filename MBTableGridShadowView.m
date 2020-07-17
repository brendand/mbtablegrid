//
//  MBTableGridShadowView.m
//  MBTableGrid
//
//  Created by David Sinclair on 2016-09-15.
//

#import "MBTableGridShadowView.h"

@implementation MBTableGridShadowView

- (void)drawRect:(NSRect)dirtyRect
{
    [super drawRect:dirtyRect];
    
    NSColor *startingColor = [NSColor colorWithWhite:0.5 alpha:0.2];
    NSColor *endingColor = [NSColor colorWithWhite:0.5 alpha:0.0];
    
    NSGradient *gradient = [[NSGradient alloc] initWithStartingColor:startingColor endingColor:endingColor];
	
//	if ([[NSApplication sharedApplication] userInterfaceLayoutDirection] == NSUserInterfaceLayoutDirectionRightToLeft) {
//		[gradient drawInRect:self.bounds angle:self.orientation == MBTableHeaderHorizontalOrientation ? 90.0 : 180.0];
//	} else {
		[gradient drawInRect:self.bounds angle:self.orientation == MBTableHeaderHorizontalOrientation ? 90.0 : 0.0];
//	}
}

- (BOOL)isFlipped
{
    return YES;
}

@end

