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

#import "MBTableGridFooterView.h"
#import "MBTableGrid.h"
#import "MBTableGridContentView.h"
#import "MBFooterTextCell.h"
#import "MBLevelIndicatorCell.h"

@interface MBTableGrid ()
- (MBTableGridContentView *)_contentView;
- (NSCell *)_footerCellForColumn:(NSUInteger)columnIndex;
- (id)_footerValueForColumn:(NSUInteger)columnIndex;
- (void)_setFooterValue:(id)value forColumn:(NSUInteger)columnIndex;
@end

@implementation MBTableGridFooterView

- (id)initWithFrame:(NSRect)frameRect
{
    if(self = [super initWithFrame:frameRect]) {
        _defaultCell = [[MBFooterTextCell alloc] initTextCell:@""];
        [_defaultCell setBordered:YES];
    }
    return self;
}

- (void)drawRect:(NSRect)rect {
	
	// Draw the column footers
	NSUInteger numberOfColumns = [self tableGrid].numberOfColumns;
	NSUInteger column = 0;
    NSColor *backgroundColor = [NSColor colorWithCalibratedWhite:0.91 alpha:1.0];
    
	while (column < numberOfColumns) {
		NSRect cellFrame = [self footerRectOfColumn:column];
		
		// Only draw the header if we need to
		if ([self needsToDrawRect:cellFrame]) {
            NSCell *_cell = [[self tableGrid] _footerCellForColumn:column];
            
            if (!_cell) {
                _cell = _defaultCell;
            }
            
            id objectValue = [[self tableGrid] _footerValueForColumn:column];
            
            if ([_cell isKindOfClass:[MBFooterPopupButtonCell class]]) {
                MBFooterPopupButtonCell *cell = (MBFooterPopupButtonCell *)_cell;
                NSInteger index = [cell indexOfItemWithTitle:objectValue];
                [_cell setObjectValue:@(index)];
            } else {
                [_cell setObjectValue:objectValue];
            }
            
            if ([_cell isKindOfClass:[MBFooterPopupButtonCell class]]) {
                
                MBFooterPopupButtonCell *cell = (MBFooterPopupButtonCell *)_cell;
                [cell drawWithFrame:cellFrame inView:self withBackgroundColor:backgroundColor];// Draw background color
                
            } else if ([_cell isKindOfClass:[MBLevelIndicatorCell class]]) {
                
                MBLevelIndicatorCell *cell = (MBLevelIndicatorCell *)_cell;
                
                cell.target = self;
                cell.action = @selector(updateLevelIndicator:);
                
                [cell drawWithFrame:cellFrame inView:[self tableGrid] withBackgroundColor:backgroundColor];// Draw background color
                
            } else {
                
                MBTableGridCell *cell = (MBTableGridCell *)_cell;
                
                [cell drawWithFrame:cellFrame inView:self withBackgroundColor:backgroundColor];// Draw background color
                
            }
            
            NSColor *sideColor = [NSColor colorWithDeviceWhite:1.0 alpha:0.4];
            NSColor *borderColor = [NSColor colorWithDeviceWhite:0.8 alpha:1.0];
            
            // Draw the side bevels
            NSRect sideLine = NSMakeRect(NSMinX(cellFrame), NSMinY(cellFrame), 1.0, NSHeight(cellFrame));
            [sideColor set];
            [[NSBezierPath bezierPathWithRect:sideLine] fill];
            sideLine.origin.x = NSMaxX(cellFrame)-2.0;
            [[NSBezierPath bezierPathWithRect:sideLine] fill];
            
            // Draw the right border
            NSRect borderLine = NSMakeRect(NSMaxX(cellFrame)-1, NSMinY(cellFrame), 1.0, NSHeight(cellFrame));
            [borderColor set];
            NSRectFill(borderLine);
            
            // Draw the bottom border
            NSRect bottomLine = NSMakeRect(NSMinX(cellFrame), NSMaxY(cellFrame)-1.0, NSWidth(cellFrame), 1.0);
            NSRectFill(bottomLine);
            
            // Draw the top border
            NSRect topLine = NSMakeRect(NSMinX(cellFrame), 0, NSWidth(cellFrame), 1.0);
            NSRectFill(topLine);
		}
		
		column++;
	}
	
}

- (void)updateLevelIndicator:(NSNumber *)value {
    NSInteger selectedColumn = [[self tableGrid].selectedColumnIndexes firstIndex];
    // sanity check to make sure we have an NSNumber.
    // I've observed that when the user lets go of the mouse,
    // the value parameter becomes the MBTableGridContentView
    // object for some reason.
    if ([value isKindOfClass:[NSNumber class]]) {
        [[self tableGrid] _setFooterValue:value forColumn:selectedColumn];
        NSRect cellFrame = [self footerRectOfColumn:selectedColumn];
        [[self tableGrid] setNeedsDisplayInRect:cellFrame];
    }
}

- (BOOL)isFlipped
{
	return YES;
}

- (void)mouseDown:(NSEvent *)theEvent
{
    NSPoint mouseLocationInContentView = [self convertPoint:[theEvent locationInWindow] fromView:nil];
    NSInteger mouseDownColumn = [self footerColumnAtPoint:mouseLocationInContentView];
    
    if (theEvent.clickCount == 1) {
        // Pass the event back to the MBTableGrid (Used to give First Responder status)
        [[self tableGrid] mouseDown:theEvent];
        
        editedColumn = mouseDownColumn;
        
        NSCell *cell = [[self tableGrid] _footerCellForColumn:mouseDownColumn];
        id currentValue = [[self tableGrid] _footerValueForColumn:editedColumn];
        
        if ([cell isKindOfClass:[MBFooterPopupButtonCell class]]) {
            editedPopupCell = [cell copy];
            NSRect cellFrame = [self footerRectOfColumn:editedColumn];
            
            editedPopupCell.menu.font = cell.menu.font;
            editedPopupCell.editable = YES;
            editedPopupCell.selectable = YES;
            
            NSMenu *menu = editedPopupCell.menu;
            
            for (NSMenuItem *item in menu.itemArray) {
                item.action = @selector(cellPopupMenuItemSelected:);
                item.target = self;
                
                if ([item.title isEqualToString:currentValue])
                {
                    [editedPopupCell selectItem:item];
                }
            }
			
			NSRect popupRect = cellFrame;
			popupRect.origin.x += cellFrame.size.width - editedPopupCell.menu.size.width;
			editedPopupCell.menu.font = [NSFont systemFontOfSize:[NSFont systemFontSizeForControlSize:NSSmallControlSize]];
            [editedPopupCell.menu popUpMenuPositioningItem:editedPopupCell.selectedItem atLocation:popupRect.origin inView:self];
        }
    }
    
    [self setNeedsDisplay:YES];
}

- (NSRect)adjustScroll:(NSRect)proposedVisibleRect
{
    NSRect modifiedRect = proposedVisibleRect;
    
    modifiedRect.origin.y = 0.0;
    
    return modifiedRect;
}

- (void)cellPopupMenuItemSelected:(NSMenuItem *)menuItem {
//    MBFooterPopupButtonCell *cell = (MBFooterPopupButtonCell *)[[self tableGrid] _footerCellForColumn:editedColumn];
    [editedPopupCell selectItemWithTitle:menuItem.title];
    [editedPopupCell synchronizeTitleAndSelectedItem];
    
    [[self tableGrid] _setFooterValue:menuItem.title forColumn:editedColumn];
    
    NSRect cellFrame = [self footerRectOfColumn:editedColumn];
    [[self tableGrid] setNeedsDisplayInRect:cellFrame];
    
    editedColumn = NSNotFound;
    editedPopupCell = nil;
}

#pragma mark -
#pragma mark Subclass Methods

- (MBTableGrid *)tableGrid
{
	return (MBTableGrid *)[[self enclosingScrollView] superview];
}

#pragma mark Layout Support

- (NSRect)footerRectOfColumn:(NSUInteger)columnIndex
{
	NSRect rect = [[[self tableGrid] _contentView] rectOfColumn:columnIndex];
	rect.size.height = MBTableGridColumnHeaderHeight;
	
	return rect;
}

- (NSInteger)footerColumnAtPoint:(NSPoint)aPoint
{
    return [[[self tableGrid] _contentView] columnAtPoint:aPoint];
}

@end
