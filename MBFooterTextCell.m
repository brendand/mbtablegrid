//
//  MBFooterTextCell.m
//  MBTableGrid
//
//  Created by David Sinclair on 2015-02-27.
//

#import "MBFooterTextCell.h"

@implementation MBFooterTextCell

- (NSAttributedString *)attributedTitle
{
 	NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
	paragraphStyle.alignment = self.alignment;
	
    NSDictionary *attributes = @{NSFontAttributeName : self.font, NSForegroundColorAttributeName : self.textColor,
								 NSParagraphStyleAttributeName : paragraphStyle};
	
	NSString *value = self.objectValue;
	if (!value) {
		value = @"";
	}
	
    return [[NSAttributedString alloc] initWithString:value attributes:attributes];
}

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
    static CGFloat TEXT_PADDING = 6;
    NSRect textFrame;
	NSAttributedString *title = [self attributedTitle];
    CGSize stringSize = title.size;
    textFrame = NSMakeRect(cellFrame.origin.x + TEXT_PADDING, cellFrame.origin.y + (cellFrame.size.height - stringSize.height)/2 - 1, cellFrame.size.width - TEXT_PADDING, stringSize.height);

    [[NSGraphicsContext currentContext] saveGraphicsState];

    [title drawWithRect:textFrame options:NSStringDrawingTruncatesLastVisibleLine | NSStringDrawingUsesLineFragmentOrigin];

    [[NSGraphicsContext currentContext] restoreGraphicsState];

}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
	
	[self.borderColor set];
	
	NSRect rightLine = NSMakeRect(NSMaxX(cellFrame)-1.0, NSMinY(cellFrame), 1.0, NSHeight(cellFrame));
	NSRectFill(rightLine);
	
	if (self.accessoryButtonImage) {
		NSRect accessoryButtonFrame = cellFrame;
		accessoryButtonFrame.size.width = 16.0;
		accessoryButtonFrame.size.height = 16.0;
		accessoryButtonFrame.origin.x = cellFrame.origin.x + cellFrame.size.width - accessoryButtonFrame.size.width - 4;
		
		// adjust rect for top border
		accessoryButtonFrame.origin.y = cellFrame.origin.y + ceilf(cellFrame.size.height / 2) - ceilf(self.accessoryButtonImage.size.height / 2);
		
		// draw the accessory image
		
		[self.accessoryButtonImage drawInRect:accessoryButtonFrame
									 fromRect:NSZeroRect
									operation:NSCompositingOperationSourceOver
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


@end
