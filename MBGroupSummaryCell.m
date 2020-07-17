//
//  MBGroupSummaryCell.m
//  MBTableGrid
//
//  Created by David Sinclair on 2017-05-24.
//

#import "MBGroupSummaryCell.h"

@implementation MBGroupSummaryCell

- (NSAttributedString *)attributedTitle
{
	NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
	paragraphStyle.alignment = self.alignment;
	
	NSDictionary *attributes = @{NSFontAttributeName : self.font, NSForegroundColorAttributeName : self.textColor,
								 NSParagraphStyleAttributeName : paragraphStyle};
	
	return [[NSAttributedString alloc] initWithString:self.title attributes:attributes];
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{

	[self.borderColor set];
    
    // Draw the right border
	if (self.isLastColumn) {
		NSRect rightLine = NSMakeRect(NSMaxX(cellFrame) - 1, NSMinY(cellFrame), 1.0, NSHeight(cellFrame));
		NSRectFill(rightLine);
	}
	
    // Draw the bottom border
    NSRect bottomLine = NSMakeRect(NSMinX(cellFrame), NSMaxY(cellFrame) - 1.0, NSWidth(cellFrame), 1.0);
    NSRectFill(bottomLine);
	
	cellFrame.size.width -= 6;
    [self drawInteriorWithFrame:cellFrame inView:controlView];
}

@end
