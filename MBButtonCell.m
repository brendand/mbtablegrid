//
//  MBButtonCell.m
//  MBTableGrid
//
//  Created by Brendan Duddridge on 2014-10-28.
//
//

#import "MBButtonCell.h"

@implementation MBButtonCell

#pragma mark - Lifecycle

- (instancetype)init {
	self = [super init];
	if (self) {
		self.title = nil;
		[self setBordered:NO];
		[self setBezeled:NO];
		[self setBackgroundColor:[NSColor clearColor]];
	}
	return self;
}

#pragma mark - MBTableGridEditable

- (BOOL)editOnFirstClick {
    return YES;
}

#pragma mark - NSCell

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView withBackgroundColor:(NSColor *)backgroundColor
{
    self.backgroundColor = backgroundColor;
	
	[backgroundColor set];
	NSRectFill(cellFrame);
	
	[self drawWithFrame:cellFrame inView:controlView];
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
	NSRect popupFrame = [self centeredButtonRectInCellFrame:cellFrame];
	[super drawWithFrame:popupFrame inView:controlView];
	
	NSColor *borderColor = [NSColor colorWithDeviceWhite:0.83 alpha:1.0];
	[borderColor set];
	
	// Draw the right border
	NSRect rightLine = NSMakeRect(NSMaxX(cellFrame)-1.0, NSMinY(cellFrame), 1.0, NSHeight(cellFrame));
	NSRectFill(rightLine);
	
	// Draw the bottom border
	NSRect bottomLine = NSMakeRect(NSMinX(cellFrame), NSMaxY(cellFrame)-1.0, NSWidth(cellFrame), 1.0);
	NSRectFill(bottomLine);
	
	//	[self drawInteriorWithFrame:cellFrame inView:controlView];
}

- (NSColor *)highlightColorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
	// Do not draw any highlight.
	return nil;
}

- (NSCellHitResult)hitTestForEvent:(NSEvent *)event inRect:(NSRect)cellFrame ofView:(NSView *)controlView {
    NSRect centeredButtonRect = [self centeredButtonRectInCellFrame:cellFrame];
	// controlView is our MBTableGridContentView. But to get the right coordinates,
	// we need to get them from the NSScrollView's coordinate system. The superview
	// of the controlView is the NSClipView and the superview of that is the NSScrollView.
    CGPoint eventLocationInControlView = [controlView.superview.superview convertPoint:event.locationInWindow fromView:nil];
    return CGRectContainsPoint(centeredButtonRect, eventLocationInControlView) ? NSCellHitContentArea : NSCellHitNone;
}

#pragma mark - Private

- (NSRect)centeredButtonRectInCellFrame:(NSRect)cellFrame {
    NSRect centeredFrame = cellFrame;
    centeredFrame.size.width = 16;
    centeredFrame.size.height = 16;
    centeredFrame.origin.x = cellFrame.origin.x + (cellFrame.size.width - centeredFrame.size.width) / 2;
    centeredFrame.origin.y = cellFrame.origin.y + (cellFrame.size.height - centeredFrame.size.height) / 2;
    return centeredFrame;
}

@end
