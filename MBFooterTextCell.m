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
    
    return [[NSAttributedString alloc] initWithString:self.title attributes:attributes];
}

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
    static CGFloat TEXT_PADDING = 6;
    NSRect textFrame;
    CGSize stringSize = self.attributedTitle.size;
    textFrame = NSMakeRect(cellFrame.origin.x + TEXT_PADDING, cellFrame.origin.y + (cellFrame.size.height - stringSize.height)/2, cellFrame.size.width - TEXT_PADDING, stringSize.height);
    
    [[NSGraphicsContext currentContext] saveGraphicsState];
    
    NSShadow *textShadow = [[NSShadow alloc] init];
    [textShadow setShadowOffset:NSMakeSize(0,-1)];
    [textShadow setShadowBlurRadius:0.0];
    [textShadow setShadowColor:[NSColor colorWithDeviceWhite:1.0 alpha:0.8]];
    [textShadow set];
    
    [self.attributedTitle drawWithRect:textFrame options:NSStringDrawingTruncatesLastVisibleLine | NSStringDrawingUsesLineFragmentOrigin];
    
    [[NSGraphicsContext currentContext] restoreGraphicsState];
    
}

@end
