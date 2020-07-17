//
//  MBPopupButtonCell.m
//  MBTableGrid
//
//  Created by Brendan Duddridge on 2014-10-27.
//
//

#import "MBPopupButtonCell.h"

@interface MBPopupButtonCell()
@property (nonatomic, strong) NSColor *borderColor;
@end

@implementation MBPopupButtonCell

-(id)initTextCell:(NSString *)aString
{
	self = [super initTextCell:aString];
	
	if (self)
	{
//		[self setBackgroundColor:[NSColor clearColor]];
		self.drawsBackground = NO;
		self.lineBreakMode = NSLineBreakByTruncatingTail;
		self.arrowImage = [NSImage imageNamed:@"popup-indicator"];
		
		if (@available(macOS 10.13, *)) {
			self.borderColor = [NSColor colorNamed:@"grid-line"];
		} else {
			self.borderColor = [NSColor gridColor];
		}
		
		return self;
	}
	
	return nil;
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView withBackgroundColor:(NSColor *)backgroundColor textColor:(NSColor *)textColor {
	
	[backgroundColor set];
	NSRectFill(cellFrame);
	
	self.textColor = textColor;
	
	[self drawWithFrame:cellFrame inView:controlView];
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
	NSRect popupFrame = cellFrame;

	[self.arrowImage drawInRect:NSMakeRect(popupFrame.origin.x + popupFrame.size.width - 13, popupFrame.origin.y + (popupFrame.size.height / 2) - 6, 7, 11)
					   fromRect:NSMakeRect(0.0, 0.0, self.arrowImage.size.width, self.arrowImage.size.height)
					  operation:NSCompositingOperationSourceOver
					   fraction:1.0
				 respectFlipped:YES
						  hints:nil];
	
	[self.borderColor set];
	
	NSRect rightLine = NSMakeRect(NSMaxX(cellFrame)-1.0, NSMinY(cellFrame), 1.0, NSHeight(cellFrame));
	NSRectFill(rightLine);
	
	
	// Draw the bottom border
	NSRect bottomLine = NSMakeRect(NSMinX(cellFrame), NSMaxY(cellFrame)-1.0, NSWidth(cellFrame), 1.0);
	NSRectFill(bottomLine);
	
	popupFrame.size.width -= 16 + 6;
	popupFrame.origin.x += 4;
	popupFrame.size.height -= 2;
	popupFrame.origin.y += 1;
	
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
