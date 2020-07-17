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
@synthesize defaultCellFont = _defaultCellFont;

- (instancetype)initTextCell:(NSString *)string {
	self = [super initTextCell:string];
	if (!self) return nil;
	
	self.textColor = [NSColor labelColor];
	self.drawsBackground = NO;
	
	return self;
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
	NSRect cellFrameRect = cellFrame;
	
	// background colour
	
	[[NSColor windowBackgroundColor] set];
	NSRect backgroundRect = cellFrameRect;
	backgroundRect.size.height -= 1;
	NSRectFill(backgroundRect);

	
//	NSColor *sideColor = [[NSColor gridColor] colorWithAlphaComponent:0.4];
	NSColor *borderColor = nil;
	if (@available(macOS 10.13, *)) {
		borderColor = [NSColor colorNamed:@"grid-line"];
	} else {
		borderColor = [NSColor gridColor];
	}
	
	[borderColor set];

	if(self.orientation == MBTableHeaderHorizontalOrientation) {
		
		// Draw the right border
		
		NSRect rightLine = NSMakeRect(NSMaxX(cellFrame)-1.0, NSMinY(cellFrame), 1.0, NSHeight(cellFrame));
		NSRectFill(rightLine);
		
	} else if(self.orientation == MBTableHeaderVerticalOrientation) {
		
		// Draw the bottom border
		NSRect bottomLine = NSMakeRect(NSMinX(cellFrameRect), NSMaxY(cellFrameRect)-1.0, NSWidth(cellFrameRect), 1.0);
		NSRectFill(bottomLine);
		
		if (self.rowTagColor) {
			NSRect tagLine = NSMakeRect(NSMinX(cellFrameRect) + 2.0, NSMinY(cellFrameRect), 4.0, NSHeight(cellFrameRect) - 1.0);
			[self.rowTagColor set];
			NSRectFill(tagLine);
		}
	}
	
	if ([self state] == NSOnState) {
		NSRect rect = cellFrame;
		rect.size.height -= 1;
		NSBezierPath *path = [NSBezierPath bezierPathWithRect:rect];
		NSColor *overlayColor = [[NSColor alternateSelectedControlColor] colorWithAlphaComponent:0.25];
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
		if ([[NSApplication sharedApplication] userInterfaceLayoutDirection] == NSUserInterfaceLayoutDirectionRightToLeft) {
			sortIndicatorFrame.origin.x = cellFrame.origin.x + 6;
		} else {
			sortIndicatorFrame.origin.x = cellFrame.origin.x + cellFrame.size.width - sortIndicatorFrame.size.width - 6;
		}
		
		sortIndicatorFrame.origin.y = sortIndicatorFrame.size.height / 2;
		
		// adjust rect for top border
		sortIndicatorFrame.origin.y += 2;
		
		// draw the accessory image
		
		[self.sortIndicatorImage drawInRect:sortIndicatorFrame
								   fromRect:NSZeroRect
								  operation:NSCompositingOperationSourceOver
								   fraction:1.0
							 respectFlipped:YES
									  hints:nil];
		
		
		// adjust cellFrame to make room for accessory button so it's never overlapped
		// with a little bit of padding.
		
		cellFrameRect.size.width -= kMAX_INDICATOR_WIDTH;
	} else {
		cellFrameRect.size.width -= kMAX_INDICATOR_WIDTH / 2;
	}

	
	// Draw the text
	[self drawInteriorWithFrame:cellFrameRect inView:controlView];
}

- (void)setDefaultCellFont:(NSFont *)defaultCellFont {
	_defaultCellFont = defaultCellFont;
	self.font = defaultCellFont;
}

- (NSAttributedString *)attributedStringValue {
	NSFont *font = nil;
	
	if (self.orientation == MBTableHeaderHorizontalOrientation) {
		font = _defaultCellFont;
		if (!font) {
			font = [NSFont boldSystemFontOfSize:[NSFont systemFontSizeForControlSize:NSControlSizeSmall]];
		}
	} else {
		font = [NSFont systemFontOfSize:[NSFont systemFontSizeForControlSize:NSControlSizeSmall]];
	}
	
	NSColor *color = [NSColor controlTextColor];
	NSDictionary *attributes = @{ NSFontAttributeName: font, NSForegroundColorAttributeName: color };

	return [[NSAttributedString alloc] initWithString:[self stringValue] attributes:attributes];
}

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
	NSRect cellFrameRect = cellFrame;

	static CGFloat TEXT_PADDING = 6;
	NSRect textFrame = NSZeroRect;
	CGSize stringSize = self.attributedStringValue.size;
	if (self.orientation == MBTableHeaderHorizontalOrientation) {
		textFrame = NSMakeRect(cellFrameRect.origin.x + TEXT_PADDING, cellFrameRect.origin.y + (cellFrameRect.size.height - stringSize.height)/2, cellFrameRect.size.width - TEXT_PADDING, stringSize.height);
	} else {
		textFrame = NSMakeRect(cellFrameRect.origin.x + TEXT_PADDING - 2 + (cellFrameRect.size.width - stringSize.width)/2, cellFrameRect.origin.y + (cellFrameRect.size.height - stringSize.height)/2, stringSize.width, stringSize.height);
	}

	[[NSGraphicsContext currentContext] saveGraphicsState];

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
