/*
 Copyright (c) 2008 Matthew Ball - http://www.mattballdesign.com
 
 Permission is hereby granted, free of charge, to any person
 obtaining a copy of this software and associated documentation
 files (the "Software"), to deal in the Software without
 restriction, including without limitation the rights to use,
 copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the
 Software is furnished to do so, subject to the following
 conditions:
 
 The above copyright notice and this permission notice shall be
 included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 OTHER DEALINGS IN THE SOFTWARE.
 */

#import "MBTableGridHeaderCell.h"

#define kMAX_INDICATOR_WIDTH 16

@implementation MBTableGridHeaderCell

@synthesize orientation;

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
	NSRect cellFrameRect = cellFrame;
	
	NSColor *topColor = [NSColor colorWithDeviceWhite:0.95 alpha:1.0];
	NSColor *sideColor = [NSColor colorWithDeviceWhite:1.0 alpha:0.4];
	NSColor *borderColor = [NSColor colorWithDeviceWhite:0.8 alpha:1.0];
		
	if(self.orientation == MBTableHeaderHorizontalOrientation) {
		// Draw the side bevels
		NSRect sideLine = NSMakeRect(NSMinX(cellFrameRect), NSMinY(cellFrameRect), 1.0, NSHeight(cellFrameRect));
		[sideColor set];
		[[NSBezierPath bezierPathWithRect:sideLine] fill];
		sideLine.origin.x = NSMaxX(cellFrameRect)-2.0;
		[[NSBezierPath bezierPathWithRect:sideLine] fill];
		        
		// Draw the right border
		NSRect borderLine = NSMakeRect(NSMaxX(cellFrameRect)-1, NSMinY(cellFrameRect), 1.0, NSHeight(cellFrameRect));
		[borderColor set];
		NSRectFill(borderLine);
		
		// Draw the bottom border
		NSRect bottomLine = NSMakeRect(NSMinX(cellFrameRect), NSMaxY(cellFrameRect)-1.0, NSWidth(cellFrameRect), 1.0);
		NSRectFill(bottomLine);
		
	} else if(self.orientation == MBTableHeaderVerticalOrientation) {
		// Draw the top bevel line
		NSRect topLine = NSMakeRect(NSMinX(cellFrameRect), NSMinY(cellFrameRect), NSWidth(cellFrameRect), 1.0);
		[topColor set];
		NSRectFill(topLine);
		
		// Draw the right border
		[borderColor set];
		NSRect borderLine = NSMakeRect(NSMaxX(cellFrameRect)-1, NSMinY(cellFrameRect), 1.0, NSHeight(cellFrameRect));
		NSRectFill(borderLine);
		
		// Draw the bottom border
		NSRect bottomLine = NSMakeRect(NSMinX(cellFrameRect), NSMaxY(cellFrameRect)-1.0, NSWidth(cellFrameRect), 1.0);
		NSRectFill(bottomLine);
		
		if (self.rowTagColor) {
			NSRect tagLine = NSMakeRect(NSMinX(cellFrameRect) + 2.0, NSMinY(cellFrameRect), 4.0, NSHeight(cellFrameRect) - 1.0);
			[self.rowTagColor set];
			NSRectFill(tagLine);
		}
	}
	
	if([self state] == NSOnState) {
		NSBezierPath *path = [NSBezierPath bezierPathWithRect:cellFrameRect];
		NSColor *overlayColor = [[NSColor alternateSelectedControlColor] colorWithAlphaComponent:0.2];
		[overlayColor set];
		[path fill];
	}
	
	if (self.sortIndicatorImage) {
		NSRect sortIndicatorFrame = cellFrame;
		sortIndicatorFrame.size = self.sortIndicatorImage.size;
		if (sortIndicatorFrame.size.height > cellFrame.size.height) {
			sortIndicatorFrame.size.height = cellFrame.size.height;
		}
		if (sortIndicatorFrame.size.width > kMAX_INDICATOR_WIDTH) {
			sortIndicatorFrame.size.width = kMAX_INDICATOR_WIDTH;
		}
		sortIndicatorFrame.origin.x = cellFrame.origin.x + cellFrame.size.width - sortIndicatorFrame.size.width - 6;
		sortIndicatorFrame.origin.y = sortIndicatorFrame.size.height / 2;
		
		// adjust rect for top border
		sortIndicatorFrame.origin.y += 1;
		
		// draw the accessory image
		
		[self.sortIndicatorImage drawInRect:sortIndicatorFrame
								   fromRect:NSZeroRect
								  operation:NSCompositeSourceOver
								   fraction:1.0
							 respectFlipped:YES
									  hints:nil];
		
		
		// adjust cellFrame to make room for accessory button so it's never overlapped
		// with a little bit of padding.
		
		cellFrameRect.size.width -= kMAX_INDICATOR_WIDTH;
	}

	
	// Draw the text
	[self drawInteriorWithFrame:cellFrameRect inView:controlView];
}

- (NSAttributedString *)attributedStringValue {
	NSFont *font = nil;
	
	if (self.orientation == MBTableHeaderHorizontalOrientation) {
		font = [NSFont boldSystemFontOfSize:[NSFont systemFontSizeForControlSize:NSSmallControlSize]];
	} else {
		font = [NSFont systemFontOfSize:[NSFont systemFontSizeForControlSize:NSSmallControlSize]];
	}
	
	NSColor *color = [NSColor controlTextColor];
	NSDictionary *attributes = @{ NSFontAttributeName: font, NSForegroundColorAttributeName: color };

	return [[NSAttributedString alloc] initWithString:[self stringValue] attributes:attributes];
}

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
	NSRect cellFrameRect = cellFrame;

	static CGFloat TEXT_PADDING = 6;
	NSRect textFrame;
	CGSize stringSize = self.attributedStringValue.size;
	if (self.orientation == MBTableHeaderHorizontalOrientation) {
		textFrame = NSMakeRect(cellFrameRect.origin.x + TEXT_PADDING, cellFrameRect.origin.y + (cellFrameRect.size.height - stringSize.height)/2, cellFrameRect.size.width - TEXT_PADDING, stringSize.height);
	} else {
		textFrame = NSMakeRect(cellFrameRect.origin.x + (cellFrameRect.size.width - stringSize.width)/2, cellFrameRect.origin.y + (cellFrameRect.size.height - stringSize.height)/2, stringSize.width, stringSize.height);
	}

	[[NSGraphicsContext currentContext] saveGraphicsState];

	NSShadow *textShadow = [[NSShadow alloc] init];
	[textShadow setShadowOffset:NSMakeSize(0,-1)];
	[textShadow setShadowBlurRadius:0.0];
	[textShadow setShadowColor:[NSColor colorWithDeviceWhite:1.0 alpha:0.8]];
	[textShadow set];

	[self.attributedStringValue drawWithRect:textFrame options:NSStringDrawingTruncatesLastVisibleLine | NSStringDrawingUsesLineFragmentOrigin];
	
	[[NSGraphicsContext currentContext] restoreGraphicsState];
}

- (NSCellHitResult)hitTestForEvent:(NSEvent *)event inRect:(NSRect)cellFrame ofView:(NSView *)controlView {
	
	NSRect sortButtonFrame = cellFrame;
	sortButtonFrame.size.width = kMAX_INDICATOR_WIDTH;
	sortButtonFrame.size.height = kMAX_INDICATOR_WIDTH;
	sortButtonFrame.origin.x = cellFrame.origin.x + cellFrame.size.width - sortButtonFrame.size.width - 4;
	
	// adjust rect for top border
	sortButtonFrame.origin.y += 1;
	
	CGPoint eventLocationInControlView = [controlView convertPoint:event.locationInWindow fromView:nil];
	return CGRectContainsPoint(sortButtonFrame, eventLocationInControlView) ? NSCellHitContentArea : NSCellHitNone;
}

@end
