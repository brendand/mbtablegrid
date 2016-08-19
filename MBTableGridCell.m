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

#import "MBTableGridCell.h"


@implementation MBTableGridCell

-(id)initTextCell:(NSString *)aString
{
    self = [super initTextCell:aString];
    
    if (self)
    {
        [self setBackgroundColor:[NSColor clearColor]];
		self.truncatesLastVisibleLine = YES;
        return self;
    }
    
    return nil;
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView withBackgroundColor:(NSColor *)backgroundColor
{

	[backgroundColor set];
	NSRectFill(cellFrame);
    
    [self drawWithFrame:cellFrame inView:controlView];
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
    
	NSColor *borderColor = [NSColor colorWithDeviceWhite:0.83 alpha:1.0];
	[borderColor set];
	
	// Draw the right border
	NSRect rightLine = NSMakeRect(NSMaxX(cellFrame)-1.0, NSMinY(cellFrame), 1.0, NSHeight(cellFrame));
	NSRectFill(rightLine);
	
	// Draw the bottom border
	NSRect bottomLine = NSMakeRect(NSMinX(cellFrame), NSMaxY(cellFrame)-1.0, NSWidth(cellFrame), 1.0);
	NSRectFill(bottomLine);
	
	if (self.accessoryButtonImage) {
		NSRect accessoryButtonFrame = cellFrame;
		accessoryButtonFrame.size.width = 16.0;
		accessoryButtonFrame.size.height = 16.0;
		accessoryButtonFrame.origin.x = cellFrame.origin.x + cellFrame.size.width - accessoryButtonFrame.size.width - 4;
		
		// adjust rect for top border
		accessoryButtonFrame.origin.y += 1;
		
		// draw the accessory image
		
		[self.accessoryButtonImage drawInRect:accessoryButtonFrame
									 fromRect:NSZeroRect
									operation:NSCompositeSourceOver
									 fraction:1.0
							   respectFlipped:YES
										hints:nil];
		
		
		// adjust cellFrame to make room for accessory button so it's never overlapped
		// with a little bit of padding.
		
		cellFrame.size.width -= accessoryButtonFrame.size.width + 2;
	}

	static CGFloat TEXT_PADDING = 4;
	cellFrame = NSInsetRect(cellFrame, TEXT_PADDING, 0);
	if (self.isGroupRow) {
		cellFrame.origin.y -= 1;
	} else {
		cellFrame.origin.y += 1;
	}
	
	[self drawInteriorWithFrame:cellFrame inView:controlView];
}

- (NSColor *)highlightColorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
	// Do not draw any highlight.
	return nil;
}

- (NSCellHitResult)hitTestForEvent:(NSEvent *)event inRect:(NSRect)cellFrame ofView:(NSView *)controlView {
	
	NSRect accessoryButtonFrame = cellFrame;
	accessoryButtonFrame.size.width = 16.0;
	accessoryButtonFrame.size.height = 16.0;
	accessoryButtonFrame.origin.x = cellFrame.origin.x + cellFrame.size.width - accessoryButtonFrame.size.width - 4;
	
	// adjust rect for top border
	accessoryButtonFrame.origin.y += 1;
	
	CGPoint eventLocationInControlView = [controlView convertPoint:event.locationInWindow fromView:nil];
	return CGRectContainsPoint(accessoryButtonFrame, eventLocationInControlView) ? NSCellHitContentArea : NSCellHitNone;
}

@end
