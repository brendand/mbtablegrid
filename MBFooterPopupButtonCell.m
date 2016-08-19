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

#import "MBFooterPopupButtonCell.h"

@implementation MBFooterPopupButtonCell

- (NSAttributedString *)attributedTitle
{
	NSFont *font = self.font;
	NSColor *color = [NSColor controlTextColor];
	NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
	paragraphStyle.alignment = self.alignment;
	paragraphStyle.lineBreakMode = self.lineBreakMode;
	NSDictionary *attributes = @{NSFontAttributeName : font, NSForegroundColorAttributeName : color,
								 NSParagraphStyleAttributeName : paragraphStyle};

	return [[NSAttributedString alloc] initWithString:self.title attributes:attributes];
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView withBackgroundColor:(NSColor *)backgroundColor {
	
	[backgroundColor set];
	NSRectFill(cellFrame);
	
	cellFrame.size.width -= 4;
	[self drawWithFrame:cellFrame inView:controlView];
}

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
	static CGFloat TEXT_PADDING = 6;
	static CGFloat POPUP_ARROWS_PADDING = 12;
	NSRect textFrame;
	CGSize stringSize = self.attributedTitle.size;
	textFrame = NSMakeRect(cellFrame.origin.x + TEXT_PADDING, cellFrame.origin.y + (cellFrame.size.height - stringSize.height)/2, cellFrame.size.width - TEXT_PADDING - POPUP_ARROWS_PADDING, stringSize.height);

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
