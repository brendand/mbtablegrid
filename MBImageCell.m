//
//  MBImageCell.m
//  MBTableGrid
//
//  Created by Brendan Duddridge on 2014-11-13.
//
//

#import "MBImageCell.h"

@interface MBImageCell()
@property (nonatomic, strong) NSColor *borderColor;
@end

@implementation MBImageCell

- (instancetype)init {
	self = [super init];
	if (self) {
		[self setBordered:NO];
		[self setBezeled:NO];
		if (@available(macOS 10.13, *)) {
			self.borderColor = [NSColor colorNamed:@"grid-line"];
		} else {
			self.borderColor = [NSColor gridColor];
		}
	}
	return self;
}

#pragma mark - MBTableGridEditable

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView withBackgroundColor:(NSColor *)backgroundColor {
	[backgroundColor set];
	NSRect rect = cellFrame;
	NSRectFill(rect);
	
	[self drawWithFrame:cellFrame inView:controlView];
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
	
	[self.borderColor set];
	
	NSRect rightLine = NSMakeRect(NSMaxX(cellFrame)-1.0, NSMinY(cellFrame), 1.0, NSHeight(cellFrame));
	NSRectFill(rightLine);
	
	// Draw the bottom border
	NSRect bottomLine = NSMakeRect(NSMinX(cellFrame), NSMaxY(cellFrame)-1.0, NSWidth(cellFrame), 1.0);
	NSRectFill(bottomLine);
	
	
	cellFrame.origin.y += 1;
	cellFrame.size.height -= 3;
	
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
		
	}
	
	// adjust cellFrame to make room for accessory button so it's never overlapped
	// with a little bit of padding.
	
	cellFrame.size.width -= 16 + 2;
	
	[self drawInteriorWithFrame:cellFrame inView:controlView];
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
