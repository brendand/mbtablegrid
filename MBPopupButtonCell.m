//
//  MBPopupButtonCell.m
//  MBTableGrid
//
//  Created by Brendan Duddridge on 2014-10-27.
//
//

#import "MBPopupButtonCell.h"

@implementation MBPopupButtonCell

-(id)initTextCell:(NSString *)aString
{
	self = [super initTextCell:aString];
	
	if (self)
	{
		[self setBackgroundColor:[NSColor clearColor]];
		self.lineBreakMode = NSLineBreakByTruncatingTail;
		_arrowImage = [NSImage imageNamed:@"popup-indicator.pdf"];
		return self;
	}
	
	return nil;
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView withBackgroundColor:(NSColor *)backgroundColor {
	
	[backgroundColor set];
	NSRectFill(cellFrame);
	
	[self drawWithFrame:cellFrame inView:controlView];
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
	NSRect popupFrame = cellFrame;
//	popupFrame.size.width -= 4;
//	popupFrame.origin.y -= 1;
	
//	[super drawWithFrame:popupFrame inView:controlView];
	
	[_arrowImage drawInRect:NSMakeRect(popupFrame.origin.x + popupFrame.size.width - 13, popupFrame.origin.y + 4, 7, 11)
				   fromRect:NSMakeRect(0.0, 0.0, _arrowImage.size.width, _arrowImage.size.height)
				  operation:NSCompositeSourceOver
				   fraction:1.0
			 respectFlipped:YES
					  hints:nil];

	
	NSColor *borderColor = [NSColor colorWithDeviceWhite:0.83 alpha:1.0];
	[borderColor set];
	
	// Draw the right border
	NSRect rightLine = NSMakeRect(NSMaxX(cellFrame)-1.0, NSMinY(cellFrame), 1.0, NSHeight(cellFrame));
	NSRectFill(rightLine);
	
	// Draw the bottom border
	NSRect bottomLine = NSMakeRect(NSMinX(cellFrame), NSMaxY(cellFrame)-1.0, NSWidth(cellFrame), 1.0);
	NSRectFill(bottomLine);
	
	popupFrame.size.width -= 16 + 6;
	popupFrame.origin.x += 4;
	
	[self drawInteriorWithFrame:popupFrame inView:controlView];
}

- (NSColor *)highlightColorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
	// Do not draw any highlight.
	return nil;
}

- (NSInteger)indexOfItemWithTitle:(NSString *)aTitle {
	return [self indexOfItemWithObjectValue:aTitle];
}

- (void)synchronizeTitleAndSelectedItem {
	return;
}

@end
