//
//  MBGroupSummaryCell.m
//  MBTableGrid
//
//  Created by David Sinclair on 2017-05-24.
//

#import "MBGroupSummaryCell.h"

@implementation MBGroupSummaryCell

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
    NSColor *borderColor = [NSColor colorWithDeviceWhite:0.83 alpha:1.0];
    [borderColor set];
    
    // Draw the top border
    NSRect topLine = NSMakeRect(NSMinX(cellFrame), NSMinY(cellFrame), NSWidth(cellFrame), 1.0);
    NSRectFill(topLine);
    
    // Draw the bottom border
    NSRect bottomLine = NSMakeRect(NSMinX(cellFrame), NSMaxY(cellFrame) - 1.0, NSWidth(cellFrame), 1.0);
    NSRectFill(bottomLine);
    
    [self drawInteriorWithFrame:cellFrame inView:controlView];
}

@end
