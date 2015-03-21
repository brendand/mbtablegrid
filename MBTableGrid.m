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

#import "MBTableGrid.h"
#import "MBTableGridHeaderView.h"
#import "MBTableGridFooterView.h"
#import "MBTableGridHeaderCell.h"
#import "MBTableGridContentView.h"
#import "MBTableGridCell.h"
#import "MBImageCell.h"
#import "MBButtonCell.h"
#import "MBPopupButtonCell.h"

#pragma mark -
#pragma mark Constant Definitions
NSString *MBTableGridDidChangeSelectionNotification     = @"MBTableGridDidChangeSelectionNotification";
NSString *MBTableGridDidMoveColumnsNotification         = @"MBTableGridDidMoveColumnsNotification";
NSString *MBTableGridDidMoveRowsNotification            = @"MBTableGridDidMoveRowsNotification";
CGFloat MBTableHeaderMinimumColumnWidth = 60.0f;

#pragma mark -
#pragma mark Drag Types
NSString *MBTableGridColumnDataType = @"mbtablegrid.pasteboard.column";
NSString *MBTableGridRowDataType = @"mbtablegrid.pasteboard.row";

@interface MBTableGrid ()

@property (nonatomic, strong) NSUndoManager *cachedUndoManager;

@end

@interface MBTableGrid (Drawing)
- (void)_drawColumnHeaderBackgroundInRect:(NSRect)aRect;
- (void)_drawRowHeaderBackgroundInRect:(NSRect)aRect;
- (void)_drawCornerHeaderBackgroundInRect:(NSRect)aRect;
- (void)_drawCornerFooterBackgroundInRect:(NSRect)aRect;
@end

@interface MBTableGrid (DataAccessors)
- (NSString *)_headerStringForColumn:(NSUInteger)columnIndex;
- (NSString *)_headerStringForRow:(NSUInteger)rowIndex;
- (id)_objectValueForColumn:(NSUInteger)columnIndex row:(NSUInteger)rowIndex;
- (NSFormatter *)_formatterForColumn:(NSUInteger)columnIndex;
- (NSCell *)_cellForColumn:(NSUInteger)columnIndex;
- (NSImage *)_accessoryButtonImageForColumn:(NSUInteger)columnIndex row:(NSUInteger)rowIndex;
- (void)_accessoryButtonClicked:(NSUInteger)columnIndex row:(NSUInteger)rowIndex;
- (NSArray *)_availableObjectValuesForColumn:(NSUInteger)columnIndex;
- (NSArray *)_autocompleteValuesForEditString:(NSString *)editString column:(NSUInteger)columnIndex row:(NSUInteger)rowIndex;
- (void)_setObjectValue:(id)value forColumn:(NSUInteger)columnIndex row:(NSUInteger)rowIndex undoTitle:(NSString *)undoTitle;
- (float)_widthForColumn:(NSUInteger)columnIndex;
- (float)_setWidthForColumn:(NSUInteger)columnIndex;
- (id)_backgroundColorForColumn:(NSUInteger)columnIndex row:(NSUInteger)rowIndex;
- (BOOL)_canEditCellAtColumn:(NSUInteger)columnIndex row:(NSUInteger)rowIndex;
- (BOOL)_canFillCellAtColumn:(NSUInteger)columnIndex row:(NSUInteger)rowIndex;
- (void)_userDidEnterInvalidStringInColumn:(NSUInteger)columnIndex row:(NSUInteger)rowIndex errorDescription:(NSString *)errorDescription;
- (NSCell *)_footerCellForColumn:(NSUInteger)columnIndex;
- (id)_footerValueForColumn:(NSUInteger)columnIndex;
- (void)_setFooterValue:(id)value forColumn:(NSUInteger)columnIndex;
- (BOOL)_isGroupRow:(NSUInteger)rowIndex;
@end

@interface MBTableGrid (DragAndDrop)
- (void)_dragColumnsWithEvent:(NSEvent *)theEvent;
- (void)_dragRowsWithEvent:(NSEvent *)theEvent;
- (NSImage *)_imageForSelectedColumns;
- (NSImage *)_imageForSelectedRows;
- (NSUInteger)_dropColumnForPoint:(NSPoint)aPoint;
- (NSUInteger)_dropRowForPoint:(NSPoint)aPoint;
@end

@interface MBTableGrid (PrivateAccessors)
- (MBTableGridContentView *)_contentView;
- (void)_setStickyColumn:(MBTableGridEdge)stickyColumn row:(MBTableGridEdge)stickyRow;
- (MBTableGridEdge)_stickyColumn;
- (MBTableGridEdge)_stickyRow;
- (NSUndoManager *)_undoManager;
@end

@interface MBTableGridContentView (Private)
- (void)_setDraggingColumnOrRow:(BOOL)flag;
- (void)_setDropColumn:(NSInteger)columnIndex;
- (void)_setDropRow:(NSInteger)rowIndex;
@end

@implementation MBTableGrid

#pragma mark -
#pragma mark Initialization & Superclass Overrides

- (id)initWithFrame:(NSRect)frameRect {
	if (self = [super initWithFrame:frameRect]) {
		columnWidths = [NSMutableDictionary dictionary];
		columnIndexNames = [NSMutableArray array];

		// Post frame changed notifications
		[self setPostsFrameChangedNotifications:YES];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(viewFrameDidChange:) name:NSViewFrameDidChangeNotification object:self];

		// Set the default cell
		MBTableGridCell *defaultCell = [[MBTableGridCell alloc] initTextCell:@""];
		[defaultCell setBordered:YES];
		[defaultCell setScrollable:YES];
		[defaultCell setLineBreakMode:NSLineBreakByTruncatingTail];
		[self setCell:defaultCell];

		// Setup the column headers
		NSRect columnHeaderFrame = NSMakeRect(MBTableGridRowHeaderWidth, 0, frameRect.size.width - MBTableGridRowHeaderWidth, MBTableGridColumnHeaderHeight);

		columnHeaderScrollView = [[NSScrollView alloc] initWithFrame:columnHeaderFrame];
		columnHeaderView = [[MBTableGridHeaderView alloc] initWithFrame:NSMakeRect(0, 0, columnHeaderFrame.size.width, columnHeaderFrame.size.height)];
		//	[columnHeaderView setAutoresizingMask:NSViewWidthSizable];
		[columnHeaderView setOrientation:MBTableHeaderHorizontalOrientation];
		[columnHeaderScrollView setDocumentView:columnHeaderView];
		[columnHeaderScrollView setAutoresizingMask:NSViewWidthSizable];
		[columnHeaderScrollView setDrawsBackground:NO];
		[self addSubview:columnHeaderScrollView];

		// Setup the row headers
		NSRect rowHeaderFrame = NSMakeRect(0, MBTableGridColumnHeaderHeight, MBTableGridRowHeaderWidth, [self frame].size.height - MBTableGridColumnHeaderHeight * 2);
		rowHeaderScrollView = [[NSScrollView alloc] initWithFrame:rowHeaderFrame];
		rowHeaderView = [[MBTableGridHeaderView alloc] initWithFrame:NSMakeRect(0, 0, rowHeaderFrame.size.width, rowHeaderFrame.size.height)];
		//[rowHeaderView setAutoresizingMask:NSViewHeightSizable];
		[rowHeaderView setOrientation:MBTableHeaderVerticalOrientation];
		[rowHeaderScrollView setDocumentView:rowHeaderView];
		[rowHeaderScrollView setAutoresizingMask:NSViewHeightSizable];
		[rowHeaderScrollView setDrawsBackground:NO];
		[self addSubview:rowHeaderScrollView];
		
		// Setup the footer view
		NSRect columnFooterFrame = NSMakeRect(MBTableGridRowHeaderWidth, frameRect.size.height - MBTableGridColumnHeaderHeight, frameRect.size.width - MBTableGridRowHeaderWidth, MBTableGridColumnHeaderHeight);
		
		columnFooterScrollView = [[NSScrollView alloc] initWithFrame:columnFooterFrame];
		columnFooterView = [[MBTableGridFooterView alloc] initWithFrame:NSMakeRect(0, 0, columnFooterFrame.size.width, columnFooterFrame.size.height)];
//		[columnFooterView setAutoresizingMask:NSViewWidthSizable];
		[columnFooterScrollView setDocumentView:columnFooterView];
		[columnFooterScrollView setAutoresizingMask:(NSViewWidthSizable | NSViewMinYMargin)];
		[columnFooterScrollView setDrawsBackground:NO];
		[self addSubview:columnFooterScrollView];

		// Setup the content view
		NSRect contentFrame = NSMakeRect(MBTableGridRowHeaderWidth, MBTableGridColumnHeaderHeight, [self frame].size.width - MBTableGridRowHeaderWidth, [self frame].size.height - MBTableGridColumnHeaderHeight - MBTableGridColumnHeaderHeight);
		contentScrollView = [[NSScrollView alloc] initWithFrame:contentFrame];
		contentView = [[MBTableGridContentView alloc] initWithFrame:NSMakeRect(0, 0, contentFrame.size.width, contentFrame.size.height)];
		[contentScrollView setDocumentView:contentView];
		[contentScrollView setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];
		[contentScrollView setHasHorizontalScroller:YES];
		[contentScrollView setHasVerticalScroller:YES];
		[contentScrollView setAutohidesScrollers:YES];
		[contentScrollView setDrawsBackground:YES];
		contentScrollView.backgroundColor = [NSColor colorWithWhite:0.98 alpha:1.0];
		
		[self addSubview:contentScrollView];

		// We want to synchronize the scroll views
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(columnHeaderViewDidScroll:) name:NSViewBoundsDidChangeNotification object:[columnHeaderScrollView contentView]];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(rowHeaderViewDidScroll:) name:NSViewBoundsDidChangeNotification object:[rowHeaderScrollView contentView]];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(columnFooterViewDidScroll:) name:NSViewBoundsDidChangeNotification object:[columnFooterScrollView contentView]];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(contentViewDidScroll:) name:NSViewBoundsDidChangeNotification object:[contentScrollView contentView]];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didUndoOrRedo:) name:NSUndoManagerDidUndoChangeNotification object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didUndoOrRedo:) name:NSUndoManagerDidRedoChangeNotification object:nil];
        
		// Set the default selection
		_selectedColumnIndexes = [NSIndexSet indexSet];
		_selectedRowIndexes = [NSIndexSet indexSet];
		self.allowsMultipleSelection = YES;

		// Set the default sticky edges
		stickyColumnEdge = MBTableGridLeftEdge;
		stickyRowEdge = MBTableGridTopEdge;

		shouldOverrideModifiers = NO;
		
		self.columnRects = [NSMutableDictionary dictionary];
	}
	return self;
}

- (void)sortButtonClicked:(id)sender
{
	[columnHeaderView toggleSortButtonIcon:(NSButton*)sender];
}

- (void)awakeFromNib {
//	[self reloadData];
	[self registerForDraggedTypes:nil];
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (BOOL)isFlipped {
	return YES;
}

- (BOOL)canBecomeKeyView {
	return YES;
}

- (BOOL)acceptsFirstResponder {
	return YES;
}

/**
 * @brief		Sets the indicator image for the specified column.
 *				This is used for indicating which direction the
 *				column is being sorted by.
 *
 * @param		anImage			The sort indicator image.
 * @param		reverseImage	The reversed sort indicator image.
 *
 * @return		The header value for the row.
 */
- (void)setIndicatorImage:(NSImage *)anImage reverseImage:(NSImage*)reverseImg inColumns:(NSArray*)columns {
	MBTableGridHeaderView *headerView = [self columnHeaderView];
	headerView.indicatorImageColumns = columns;
	headerView.indicatorImage = anImage;
	headerView.indicatorReverseImage = reverseImg;


	[headerView placeSortButtons];
}

/**
 * @brief		Returns the sort indicator image
 *				for the specified column.
 *
 * @param		columnIndex		The index of the column.
 *
 * @return		The sort indicator image for the column.
 */
- (NSImage *)indicatorImageInColumn:(NSUInteger)columnIndex {
	NSImage *indicatorImage = nil;

	return indicatorImage;
}

- (void)setAutosaveName:(NSString *)autosaveName {
	_autosaveName = autosaveName;
	self.columnHeaderView.autosaveName = autosaveName;
}

- (void)drawRect:(NSRect)aRect {
	// If the view is the first responder, draw the focus ring
	NSResponder *firstResponder = [[self window] firstResponder];
	if (([[firstResponder class] isSubclassOfClass:[NSView class]] && [(NSView *)firstResponder isDescendantOf : self]) && [[self window] isKeyWindow]) {
		[[NSGraphicsContext currentContext] saveGraphicsState];
		NSSetFocusRingStyle(NSFocusRingOnly);

		[[NSBezierPath bezierPathWithRect:NSMakeRect(0, 0, [self frame].size.width, [self frame].size.height)] fill];

		[[NSGraphicsContext currentContext] restoreGraphicsState];
		[self setKeyboardFocusRingNeedsDisplayInRect:[self bounds]];
	}
	
	// Draw the corner header
	NSRect cornerRect = [self headerRectOfCorner];
	[self _drawCornerHeaderBackgroundInRect:cornerRect];

	// Draw the column header background
	NSRect columnHeaderRect = NSMakeRect(NSWidth(cornerRect), 0, [self frame].size.width - NSWidth(cornerRect), MBTableGridColumnHeaderHeight);
	[self _drawColumnHeaderBackgroundInRect:columnHeaderRect];

	// Draw the corner footer
	NSRect footerRect = [self footerRectOfCorner];
	[self _drawCornerFooterBackgroundInRect:footerRect];

	// Draw the row header background
	NSRect rowHeaderRect = NSMakeRect(0, NSMaxY(cornerRect), MBTableGridRowHeaderWidth, [self frame].size.height - MBTableGridColumnHeaderHeight * 2);
	[self _drawRowHeaderBackgroundInRect:rowHeaderRect];
}

- (void)setNeedsDisplay:(BOOL)needsDisplay {
    
    [super setNeedsDisplay:needsDisplay];
    
    [self.contentView setNeedsDisplay:needsDisplay];
    [columnHeaderView setNeedsDisplay:needsDisplay];
    [rowHeaderView setNeedsDisplay:needsDisplay];
    [columnFooterView setNeedsDisplay:needsDisplay];
}

#pragma mark Resize scrollview content size

- (CGFloat)resizeColumnWithIndex:(NSUInteger)columnIndex withDistance:(float)distance location:(NSPoint)location {
	// Get column key
	NSString *columnKey = nil;
	if ([columnIndexNames count] > columnIndex) {
		columnKey = columnIndexNames[columnIndex];
	}
	
	if (!columnKey) {
		columnKey = [NSString stringWithFormat:@"column%lu", columnIndex];
	}

	// Note that we only need this rect for its origin, which won't be changing, otherwise we'd need to flush the column rect cache first
	NSRect columnRect = [self rectOfColumn:columnIndex];

	// Flush rect cache for this column because we're changing its size
	// Note that we're doing this after calling rectOfColumn: because that would cache the rect before we change its width...
	[self.columnRects removeAllObjects];

	// Set new width of column
	CGFloat currentWidth = [columnWidths[columnKey] floatValue];
    CGFloat offset = 0.0;
	
    currentWidth += distance;
    
    CGFloat minColumnWidth = MBTableHeaderMinimumColumnWidth;
    
    if (columnHeaderView.indicatorImage && [columnHeaderView.indicatorImageColumns containsObject:[NSNumber numberWithInteger:columnIndex]]) {
        minColumnWidth += columnHeaderView.indicatorImage.size.width + 2.0f;
    }
    
    if (currentWidth < minColumnWidth) {
        currentWidth = minColumnWidth;
    }
	
    columnWidths[columnKey] = @(currentWidth);
    
    if (currentWidth == minColumnWidth) {
        offset = columnRect.origin.x - location.x + minColumnWidth - self.rowHeaderView.frame.size.width;
        distance = 0.0;
    }
    
    // Update views with new sizes
    [contentView setFrameSize:NSMakeSize(NSWidth(contentView.frame) + distance, NSHeight(contentView.frame))];
    [columnHeaderView setFrameSize:NSMakeSize(NSWidth(columnHeaderView.frame) + distance, NSHeight(columnHeaderView.frame))];
    [columnFooterView setFrameSize:NSMakeSize(NSWidth(columnFooterView.frame) + distance, NSHeight(columnFooterView.frame))];
    
    NSRect rectOfResizedAndVisibleRightwardColumns = NSMakeRect(columnRect.origin.x - rowHeaderView.bounds.size.width, 0, contentView.bounds.size.width - columnRect.origin.x, NSHeight(contentView.frame));
    [contentView setNeedsDisplayInRect:rectOfResizedAndVisibleRightwardColumns];
    
    NSRect rectOfResizedAndVisibleRightwardHeaders = NSMakeRect(columnRect.origin.x - rowHeaderView.bounds.size.width, 0, contentView.bounds.size.width - columnRect.origin.x, NSHeight(columnHeaderView.frame));
    [columnHeaderView setNeedsDisplayInRect:rectOfResizedAndVisibleRightwardHeaders];
    
    NSRect rectOfResizedAndVisibleRightwardFooters = NSMakeRect(columnRect.origin.x - rowHeaderView.bounds.size.width, 0, contentView.bounds.size.width - columnRect.origin.x, NSHeight(columnFooterView.frame));
    [columnFooterView setNeedsDisplayInRect:rectOfResizedAndVisibleRightwardFooters];
    
    return offset;
}

- (void)registerForDraggedTypes:(NSArray *)pboardTypes {
	// Add the column and row types to the array
	NSMutableArray *types = [NSMutableArray arrayWithArray:pboardTypes];

	if (!pboardTypes) {
		types = [NSMutableArray array];
	}
	[types addObjectsFromArray:@[MBTableGridColumnDataType, MBTableGridRowDataType]];

	[super registerForDraggedTypes:types];

	// Register the content view for everything
	[contentView registerForDraggedTypes:types];
}

#pragma mark Mouse Events

- (void)mouseDown:(NSEvent *)theEvent {
	// End editing (if necessary)
	[[self cell] endEditing:[[self window] fieldEditor:NO forObject:contentView]];

	// If we're not the first responder, we need to be
	if ([[self window] firstResponder] != self) {
		[[self window] makeFirstResponder:self];
	}
}

#pragma mark Keyboard Events

- (void)keyDown:(NSEvent *)theEvent {
	[self interpretKeyEvents:@[theEvent]];
}

/*- (void)interpretKeyEvents:(NSArray *)eventArray
   {

   }*/

#pragma mark NSResponder Event Handlers

- (void)copy:(id)sender {
	
	NSIndexSet *selectedColumns = [self selectedColumnIndexes];
	NSIndexSet *selectedRows = [self selectedRowIndexes];

    if ([[self delegate] respondsToSelector:@selector(tableGrid:copyCellsAtColumns:rows:)]) {
		[[self delegate] tableGrid:self copyCellsAtColumns:selectedColumns rows:selectedRows];
	}
}

- (void)paste:(id)sender {
	
    NSIndexSet *selectedColumns = [self selectedColumnIndexes];
    NSIndexSet *selectedRows = [self selectedRowIndexes];
    
    if ([[self delegate] respondsToSelector:@selector(tableGrid:pasteCellsAtColumns:rows:)]) {
        [[self delegate] tableGrid:self pasteCellsAtColumns:selectedColumns rows:selectedRows];
        [self reloadData];
    }
}

- (void)insertTab:(id)sender {
	// Pressing "Tab" moves to the next column
	[self moveRight:sender];
}

- (void)insertBacktab:(id)sender {
	// We want to change the selection, not expand it
	shouldOverrideModifiers = YES;

	// Pressing Shift+Tab moves to the previous column
	[self moveLeft:sender];
}

- (void)insertNewline:(id)sender {
	if ([[NSApp currentEvent] modifierFlags] & NSShiftKeyMask) {
		// Pressing Shift+Return moves to the previous row
		shouldOverrideModifiers = YES;
		[self moveUp:sender];
	}
	else {
		// Pressing Return moves to the next row
		[self moveDown:sender];
	}
}

- (void)moveUp:(id)sender {
	if (_numberOfRows == 0 || _numberOfColumns == 0) {
		return;
	}
	
	NSUInteger column = [self.selectedColumnIndexes firstIndex];
	NSUInteger row = [self.selectedRowIndexes firstIndex];

	// Accomodate for the sticky edges
	if (stickyColumnEdge == MBTableGridRightEdge) {
		column = [self.selectedColumnIndexes lastIndex];
	}
	if (stickyRowEdge == MBTableGridBottomEdge) {
		row = [self.selectedRowIndexes lastIndex];
	}

	// If we're already at the first row, do nothing
	if (row <= 0 || (row == 1 && [self _isGroupRow:row - 1]))
		return;

	if (row > 0) {
		// moving up, but previous row is a group row, so go to the previous non-group row
		BOOL isGroupRow = YES;
		while (row > 0 && isGroupRow) {
			isGroupRow = [self _isGroupRow:row - 1];
			if (isGroupRow) {
				row--;
			}
		}
		
		// If the Shift key was not held, move the selection
		self.selectedColumnIndexes = [NSIndexSet indexSetWithIndex:column];
		self.selectedRowIndexes = [NSIndexSet indexSetWithIndex:(row - 1)];

		NSRect cellRect = [self frameOfCellAtColumn:column row:row - 1];
		cellRect = [self convertRect:cellRect toView:self.contentView];
		if (!NSContainsRect(self.contentView.visibleRect, cellRect)) {
			cellRect.origin.x = self.contentView.visibleRect.origin.x;
			[self scrollToArea:cellRect animate:NO];
		}
		else {
			[self setNeedsDisplay:YES];
		}
	}
}

- (void)moveUpAndModifySelection:(id)sender {
	
	if (_numberOfRows == 0 || _numberOfColumns == 0) {
		return;
	}
	
	if (shouldOverrideModifiers) {
		[self moveLeft:sender];
		shouldOverrideModifiers = NO;
		return;
	}

	NSUInteger firstRow = [self.selectedRowIndexes firstIndex];
	NSUInteger lastRow = [self.selectedRowIndexes lastIndex];

	// If there is only one row selected, change the sticky edge to the bottom
	if ([self.selectedRowIndexes count] == 1) {
		stickyRowEdge = MBTableGridBottomEdge;
	}

	// We can't expand past the last row
	if (stickyRowEdge == MBTableGridBottomEdge && firstRow <= 0)
		return;

	if (stickyRowEdge == MBTableGridTopEdge) {
		// If the top edge is sticky, contract the selection
		lastRow--;
	}
	else if (stickyRowEdge == MBTableGridBottomEdge) {
		// If the bottom edge is sticky, expand the contraction
		firstRow--;
	}

	NSUInteger column = [self.selectedColumnIndexes firstIndex];

	if (firstRow - 1 > 0) {
		
		// moving up, but previous row is a group row, so go to the previous non-group row
		BOOL isGroupRow = YES;
		while (firstRow > 0 && isGroupRow) {
			isGroupRow = [self _isGroupRow:firstRow];
			if (isGroupRow) {
				firstRow--;
			}
		}

		self.selectedRowIndexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(firstRow, lastRow - firstRow + 1)];

		NSRect cellRect = [self frameOfCellAtColumn:column row:firstRow - 1];
		cellRect = [self convertRect:cellRect toView:contentScrollView.contentView];
		if (!NSContainsRect(self.contentView.visibleRect, cellRect)) {
			cellRect.origin.x = self.contentView.visibleRect.origin.x;
			[self scrollToArea:cellRect animate:NO];
		}
		else {
			[self setNeedsDisplay:YES];
		}
	}
}

- (void)moveDown:(id)sender {
	
	if (_numberOfRows == 0 || _numberOfColumns == 0) {
		return;
	}
	
	NSUInteger column = [self.selectedColumnIndexes firstIndex];
	NSUInteger row = [self.selectedRowIndexes firstIndex];

	// Accomodate for the sticky edges
	if (stickyColumnEdge == MBTableGridRightEdge) {
		column = [self.selectedColumnIndexes lastIndex];
	}
	if (stickyRowEdge == MBTableGridBottomEdge) {
		row = [self.selectedRowIndexes lastIndex];
	}

	// If we're already at the last row, do nothing
	if (row >= (_numberOfRows - 1) || (row == (_numberOfRows - 1) && [self _isGroupRow:row + 1]))
		return;

	if (row + 1 < [self numberOfRows]) {
		
		// moving down, but next row is a group row, so go to the next non-group row
		BOOL isGroupRow = YES;
		while (row + 1 < [self numberOfRows] && isGroupRow) {
			isGroupRow = [self _isGroupRow:row + 1];
			if (isGroupRow) {
				row++;
			}
		}

		// If the Shift key was not held, move the selection
		self.selectedColumnIndexes = [NSIndexSet indexSetWithIndex:column];
		self.selectedRowIndexes = [NSIndexSet indexSetWithIndex:(row + 1)];

		NSRect cellRect = [self frameOfCellAtColumn:column row:row + 1];
		cellRect = [self convertRect:cellRect toView:contentScrollView.contentView];
		if (!NSContainsRect(self.contentView.visibleRect, cellRect)) {
			cellRect.origin.y = cellRect.origin.y - self.contentView.visibleRect.size.height + cellRect.size.height;
			cellRect.origin.x = self.contentView.visibleRect.origin.x;
			[self scrollToArea:cellRect animate:NO];
		}
		else {
            [self setNeedsDisplay:YES];
		}
	}
}

- (void)moveDownAndModifySelection:(id)sender {
	
	if (_numberOfRows == 0 || _numberOfColumns == 0) {
		return;
	}
	
	if (shouldOverrideModifiers) {
		[self moveDown:sender];
		shouldOverrideModifiers = NO;
		return;
	}

	NSUInteger firstRow = [self.selectedRowIndexes firstIndex];
	NSUInteger lastRow = [self.selectedRowIndexes lastIndex];

	// If there is only one row selected, change the sticky edge to the top
	if ([self.selectedRowIndexes count] == 1) {
		stickyRowEdge = MBTableGridTopEdge;
	}

	// We can't expand past the last row
	if (stickyRowEdge == MBTableGridTopEdge && lastRow >= (_numberOfRows - 1))
		return;

	if (stickyRowEdge == MBTableGridTopEdge) {
		// If the top edge is sticky, contract the selection
		lastRow++;
	}
	else if (stickyRowEdge == MBTableGridBottomEdge) {
		// If the bottom edge is sticky, expand the contraction
		firstRow++;
	}

	NSUInteger column = [self.selectedColumnIndexes lastIndex];

	if (lastRow + 1 < [self numberOfRows]) {
		
		// moving down, but next row is a group row, so go to the next non-group row
		BOOL isGroupRow = YES;
		while (lastRow < [self numberOfRows] && isGroupRow) {
			isGroupRow = [self _isGroupRow:lastRow];
			if (isGroupRow) {
				lastRow++;
			}
		}

		self.selectedRowIndexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(firstRow, lastRow - firstRow + 1)];

		NSRect cellRect = [self frameOfCellAtColumn:column row:lastRow + 1];
		cellRect = [self convertRect:cellRect toView:contentScrollView.contentView];
		if (!NSContainsRect(self.contentView.visibleRect, cellRect)) {
			cellRect.origin.y = cellRect.origin.y - self.contentView.visibleRect.size.height + cellRect.size.height;
			cellRect.origin.x = self.contentView.visibleRect.origin.x;
			[self scrollToArea:cellRect animate:NO];
		}
		else {
            [self setNeedsDisplay:YES];
		}
	}
}

- (void)moveLeft:(id)sender {
	
	if (_numberOfRows == 0 || _numberOfColumns == 0) {
		return;
	}
	
	NSUInteger column = [self.selectedColumnIndexes firstIndex];
	NSUInteger row = [self.selectedRowIndexes firstIndex];

	// Accomodate for the sticky edges
	if (stickyColumnEdge == MBTableGridRightEdge) {
		column = [self.selectedColumnIndexes lastIndex];
	}
	if (stickyRowEdge == MBTableGridBottomEdge) {
		row = [self.selectedRowIndexes lastIndex];
	}

	if (column > 0) {
		NSRect cellRect = [self frameOfCellAtColumn:column - 1 row:row];
		cellRect = [self convertRect:cellRect toView:contentScrollView.contentView];
		if (!NSContainsRect(self.contentView.visibleRect, cellRect)) {
			cellRect.origin.y = self.contentView.visibleRect.origin.y;
			[self scrollToArea:cellRect animate:NO];
		}
		else {
            [self setNeedsDisplay:YES];
		}
	}

	// If we're already at the first column, do nothing
	if (column <= 0)
		return;

	// If the Shift key was not held, move the selection
	self.selectedColumnIndexes = [NSIndexSet indexSetWithIndex:(column - 1)];
	self.selectedRowIndexes = [NSIndexSet indexSetWithIndex:row];
}

- (void)moveLeftAndModifySelection:(id)sender {
	
	if (_numberOfRows == 0 || _numberOfColumns == 0) {
		return;
	}
	
	if (shouldOverrideModifiers) {
		[self moveLeft:sender];
		shouldOverrideModifiers = NO;
		return;
	}

	NSUInteger firstColumn = [self.selectedColumnIndexes firstIndex];
	NSUInteger lastColumn = [self.selectedColumnIndexes lastIndex];

	// If there is only one column selected, change the sticky edge to the right
	if ([self.selectedColumnIndexes count] == 1) {
		stickyColumnEdge = MBTableGridRightEdge;
	}

	NSUInteger row = [self.selectedRowIndexes firstIndex];

	if (firstColumn > 0) {
		NSRect cellRect = [self frameOfCellAtColumn:firstColumn - 1 row:row];
		cellRect = [self convertRect:cellRect toView:contentScrollView.contentView];
		if (!NSContainsRect(self.contentView.visibleRect, cellRect)) {
			cellRect.origin.y = self.contentView.visibleRect.origin.y;
			[self scrollToArea:cellRect animate:NO];
		}
		else {
            [self setNeedsDisplay:YES];
		}
	}


	// We can't expand past the first column
	if (stickyColumnEdge == MBTableGridRightEdge && firstColumn <= 0)
		return;

	if (stickyColumnEdge == MBTableGridLeftEdge) {
		// If the top edge is sticky, contract the selection
		lastColumn--;
	}
	else if (stickyColumnEdge == MBTableGridRightEdge) {
		// If the bottom edge is sticky, expand the contraction
		firstColumn--;
	}
	self.selectedColumnIndexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(firstColumn, lastColumn - firstColumn + 1)];
}

- (void)moveRight:(id)sender {
	
	if (_numberOfRows == 0 || _numberOfColumns == 0) {
		return;
	}
	
	NSUInteger column = [self.selectedColumnIndexes firstIndex];
	NSUInteger row = [self.selectedRowIndexes firstIndex];

	// Accomodate for the sticky edges
	if (stickyColumnEdge == MBTableGridRightEdge) {
		column = [self.selectedColumnIndexes lastIndex];
	}
	if (stickyRowEdge == MBTableGridBottomEdge) {
		row = [self.selectedRowIndexes lastIndex];
	}

	// If we're already at the last column, do nothing
	if (column >= (_numberOfColumns - 1))
		return;

	// If the Shift key was not held, move the selection
	self.selectedColumnIndexes = [NSIndexSet indexSetWithIndex:(column + 1)];
	self.selectedRowIndexes = [NSIndexSet indexSetWithIndex:row];

	if (column + 1 < [self numberOfColumns]) {
		NSRect cellRect = [self frameOfCellAtColumn:column + 1 row:row];
		cellRect = [self convertRect:cellRect toView:contentScrollView.contentView];
		if (!NSContainsRect(self.contentView.visibleRect, cellRect)) {
			cellRect.origin.x = cellRect.origin.x - self.contentView.visibleRect.size.width + cellRect.size.width;
			cellRect.origin.y = self.contentView.visibleRect.origin.y;
			[self scrollToArea:cellRect animate:NO];
		}
		else {
            [self setNeedsDisplay:YES];
		}
	}
}

- (void)moveRightAndModifySelection:(id)sender {
	
	if (_numberOfRows == 0 || _numberOfColumns == 0) {
		return;
	}
	
	if (shouldOverrideModifiers) {
		[self moveRight:sender];
		shouldOverrideModifiers = NO;
		return;
	}

	NSUInteger firstColumn = [self.selectedColumnIndexes firstIndex];
	NSUInteger lastColumn = [self.selectedColumnIndexes lastIndex];

	// If there is only one column selected, change the sticky edge to the right
	if ([self.selectedColumnIndexes count] == 1) {
		stickyColumnEdge = MBTableGridLeftEdge;
	}

	// We can't expand past the last column
	if (stickyColumnEdge == MBTableGridLeftEdge && lastColumn >= (_numberOfColumns - 1))
		return;

	if (stickyColumnEdge == MBTableGridLeftEdge) {
		// If the top edge is sticky, contract the selection
		lastColumn++;
	}
	else if (stickyColumnEdge == MBTableGridRightEdge) {
		// If the bottom edge is sticky, expand the contraction
		firstColumn++;
	}
	self.selectedColumnIndexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(firstColumn, lastColumn - firstColumn + 1)];

	NSUInteger row = [self.selectedRowIndexes lastIndex];

	if (lastColumn + 1 < [self numberOfColumns]) {
		NSRect cellRect = [self frameOfCellAtColumn:lastColumn + 1 row:row];
		cellRect = [self convertRect:cellRect toView:contentScrollView.contentView];
		if (!NSContainsRect(self.contentView.visibleRect, cellRect)) {
			cellRect.origin.x = cellRect.origin.x - self.contentView.visibleRect.size.width + cellRect.size.width;
			cellRect.origin.y = self.contentView.visibleRect.origin.y;
			[self scrollToArea:cellRect animate:NO];
		}
		else {
            [self setNeedsDisplay:YES];
		}
	}
}

- (void)scrollToArea:(NSRect)area animate:(BOOL)shouldAnimate {
	if (shouldAnimate) {
		[NSAnimationContext runAnimationGroup: ^(NSAnimationContext *context) {
		    [context setAllowsImplicitAnimation:YES];
		    [self.contentView scrollRectToVisible:area];
		} completionHandler: ^{
		}];
	}
	else {
//		[contentScrollView.contentView scrollRectToVisible:area];
		[contentScrollView.contentView scrollToPoint:area.origin];
        [self setNeedsDisplay:YES];
//		NSLog(@"area: %@", NSStringFromRect(area));
	}
}

- (void)selectAll:(id)sender {
	stickyColumnEdge = MBTableGridLeftEdge;
	stickyRowEdge = MBTableGridTopEdge;

	self.selectedColumnIndexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, _numberOfColumns)];
	self.selectedRowIndexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, _numberOfRows)];
}

- (void)deleteBackward:(id)sender {
	
	if (_numberOfRows == 0 || _numberOfColumns == 0) {
		return;
	}
	
	// Clear the contents of every selected cell
	NSUInteger column = [self.selectedColumnIndexes firstIndex];
	while (column <= [self.selectedColumnIndexes lastIndex]) {
		NSUInteger row = [self.selectedRowIndexes firstIndex];
		while (row <= [self.selectedRowIndexes lastIndex]) {
			[self _setObjectValue:nil forColumn:column row:row undoTitle:@"Clear"];
			row++;
		}
		column++;
	}
	[self reloadData];
}

- (void)insertText:(id)aString {
	NSUInteger column = [self.selectedColumnIndexes firstIndex];
	NSCell *selectedCell = [self _cellForColumn:column];
	
	if (![selectedCell isKindOfClass:[MBImageCell class]]) {
		[contentView editSelectedCell:self text:aString];
		
		if ([selectedCell isKindOfClass:[MBTableGridCell class]]) {
			// Insert the typed string into the field editor
			NSText *fieldEditor = [[self window] fieldEditor:YES forObject:contentView];
			fieldEditor.delegate = contentView;
			[fieldEditor setString:aString];
            
            // The textDidBeginEditing notification isn't sent yet, so invoke a custom method
            [contentView textDidBeginEditingWithEditor:fieldEditor];
		}
		
	} else {
		NSUInteger row = [self.selectedRowIndexes firstIndex];
		[self _accessoryButtonClicked:column row:row];
	}
	[self setNeedsDisplay:YES];

}

#pragma mark -
#pragma mark Notifications

- (void)viewFrameDidChange:(NSNotification *)aNotification {
	//[self reloadData];
}

- (void)syncronizeScrollView:(NSScrollView *)scrollView withChangedBoundsOrigin:(NSPoint)changedBoundsOrigin horizontal:(BOOL)horizontal {
    
    // Get the current origin
    NSPoint curOffset = [[scrollView contentView] bounds].origin;
    NSPoint newOffset = curOffset;
    
    if (horizontal) {
        newOffset.x = changedBoundsOrigin.x;
    } else {
        newOffset.y = changedBoundsOrigin.y;
    }
    
    // If the synced position is different from our current position, reposition the view
    if (!NSEqualPoints(curOffset, changedBoundsOrigin)) {
        [[scrollView contentView] scrollToPoint:newOffset];
        // We have to tell the NSScrollView to update its scrollers
        [scrollView reflectScrolledClipView:[scrollView contentView]];
    }
    
}

- (void)columnHeaderViewDidScroll:(NSNotification *)aNotification {
    
	NSView *changedView = [aNotification object];
	NSPoint changedBoundsOrigin = [changedView bounds].origin;

    [self syncronizeScrollView:contentScrollView withChangedBoundsOrigin:changedBoundsOrigin horizontal:YES];
    [self syncronizeScrollView:rowHeaderScrollView withChangedBoundsOrigin:changedBoundsOrigin horizontal:NO];
    [self syncronizeScrollView:columnFooterScrollView withChangedBoundsOrigin:changedBoundsOrigin horizontal:YES];
    
}

- (void)rowHeaderViewDidScroll:(NSNotification *)aNotification {
    
    NSView *changedView = [aNotification object];
    NSPoint changedBoundsOrigin = [changedView bounds].origin;
    
    [self syncronizeScrollView:contentScrollView withChangedBoundsOrigin:changedBoundsOrigin horizontal:NO];
    
}

- (void)columnFooterViewDidScroll:(NSNotification *)aNotification {
    
    NSView *changedView = [aNotification object];
    NSPoint changedBoundsOrigin = [changedView bounds].origin;
    
    [self syncronizeScrollView:contentScrollView withChangedBoundsOrigin:changedBoundsOrigin horizontal:YES];
    [self syncronizeScrollView:columnHeaderScrollView withChangedBoundsOrigin:changedBoundsOrigin horizontal:YES];
    [self syncronizeScrollView:rowHeaderScrollView withChangedBoundsOrigin:changedBoundsOrigin horizontal:NO];
    
}

- (void)contentViewDidScroll:(NSNotification *)aNotification {
    
    NSView *changedView = [aNotification object];
    NSPoint changedBoundsOrigin = [changedView bounds].origin;
    
    [self syncronizeScrollView:columnHeaderScrollView withChangedBoundsOrigin:changedBoundsOrigin horizontal:YES];
    [self syncronizeScrollView:rowHeaderScrollView withChangedBoundsOrigin:changedBoundsOrigin horizontal:NO];
    [self syncronizeScrollView:columnFooterScrollView withChangedBoundsOrigin:changedBoundsOrigin horizontal:YES];
    
}

- (void)didUndoOrRedo:(NSNotification *)aNotification {
    
    [self reloadData];
}

#pragma mark -
#pragma mark Protocol Methods

#pragma mark NSDraggingSource

-(NSDragOperation)draggingSession:(NSDraggingSession *)session sourceOperationMaskForDraggingContext:(NSDraggingContext)context {
    
    switch(context) {
        case NSDraggingContextOutsideApplication:
            return NSDragOperationNone;
            break;
            
        case NSDraggingContextWithinApplication:
        default:
            return NSDragOperationMove;
            break;
    }
}

#pragma mark NSDraggingDestination

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo> )sender {
	NSPasteboard *pboard = [sender draggingPasteboard];

	NSData *columnData = [pboard dataForType:MBTableGridColumnDataType];
	NSData *rowData = [pboard dataForType:MBTableGridRowDataType];

	if (columnData) {
		return NSDragOperationMove;
	}
	else if (rowData) {
		return NSDragOperationMove;
	}
	else {
		if ([[self dataSource] respondsToSelector:@selector(tableGrid:validateDrop:proposedColumn:row:)]) {
			NSPoint mouseLocation = [self convertPoint:[sender draggingLocation] fromView:nil];
			NSUInteger dropColumn = [self columnAtPoint:mouseLocation];
			NSUInteger dropRow = [self rowAtPoint:mouseLocation];

			NSDragOperation dragOperation = [[self dataSource] tableGrid:self validateDrop:sender proposedColumn:dropColumn row:dropRow];

			// If the drag is okay, highlight the appropriate cell
			if (dragOperation != NSDragOperationNone) {
				[contentView _setDropColumn:dropColumn];
				[contentView _setDropRow:dropRow];
			}

			return dragOperation;
		}
	}

	return NSDragOperationNone;
}

- (NSDragOperation)draggingUpdated:(id <NSDraggingInfo> )sender {
	NSPasteboard *pboard = [sender draggingPasteboard];
	NSData *columnData = [pboard dataForType:MBTableGridColumnDataType];
	NSData *rowData = [pboard dataForType:MBTableGridRowDataType];
	NSPoint mouseLocation = [self convertPoint:[sender draggingLocation] fromView:nil];

	if (columnData) {
		// If we're dragging a column

		NSUInteger dropColumn = [self _dropColumnForPoint:mouseLocation];

		if (dropColumn == NSNotFound) {
			return NSDragOperationNone;
		}

		NSIndexSet *draggedColumns = (NSIndexSet *)[NSKeyedUnarchiver unarchiveObjectWithData:columnData];

		BOOL canDrop = NO;
		if ([[self dataSource] respondsToSelector:@selector(tableGrid:canMoveColumns:toIndex:)]) {
			canDrop = [[self dataSource] tableGrid:self canMoveColumns:draggedColumns toIndex:dropColumn];
		}

		[contentView _setDraggingColumnOrRow:YES];

		if (canDrop) {
			[contentView _setDropColumn:dropColumn];
			return NSDragOperationMove;
		}
		else {
			[contentView _setDropColumn:NSNotFound];
		}
	}
	else if (rowData) {
		// If we're dragging a row

		NSUInteger dropRow = [self _dropRowForPoint:mouseLocation];

		if (dropRow == NSNotFound) {
			return NSDragOperationNone;
		}

		NSIndexSet *draggedRows = (NSIndexSet *)[NSKeyedUnarchiver unarchiveObjectWithData:rowData];

		BOOL canDrop = NO;
		if ([[self dataSource] respondsToSelector:@selector(tableGrid:canMoveRows:toIndex:)]) {
			canDrop = [[self dataSource] tableGrid:self canMoveRows:draggedRows toIndex:dropRow];
		}

		[contentView _setDraggingColumnOrRow:YES];

		if (canDrop) {
			[contentView _setDropRow:dropRow];
			return NSDragOperationMove;
		}
		else {
			[contentView _setDropRow:NSNotFound];
		}
	}
	else {
		if ([[self dataSource] respondsToSelector:@selector(tableGrid:validateDrop:proposedColumn:row:)]) {
			NSUInteger dropColumn = [self columnAtPoint:mouseLocation];
			NSUInteger dropRow = [self rowAtPoint:mouseLocation];

			[contentView _setDraggingColumnOrRow:NO];

			NSDragOperation dragOperation = [[self dataSource] tableGrid:self validateDrop:sender proposedColumn:dropColumn row:dropRow];

			// If the drag is okay, highlight the appropriate cell
			if (dragOperation != NSDragOperationNone) {
				[contentView _setDropColumn:dropColumn];
				[contentView _setDropRow:dropRow];
			}

			return dragOperation;
		}
	}
	return NSDragOperationNone;
}

- (void)draggingExited:(id <NSDraggingInfo> )sender {
	[contentView _setDropColumn:NSNotFound];
	[contentView _setDropRow:NSNotFound];
}

- (void)draggingEnded:(id <NSDraggingInfo> )sender {
	[contentView _setDropColumn:NSNotFound];
	[contentView _setDropRow:NSNotFound];
}

- (BOOL)prepareForDragOperation:(id <NSDraggingInfo> )sender {
	return YES;
}

- (BOOL)performDragOperation:(id <NSDraggingInfo> )sender {
	NSPasteboard *pboard = [sender draggingPasteboard];
	NSData *columnData = [pboard dataForType:MBTableGridColumnDataType];
	NSData *rowData = [pboard dataForType:MBTableGridRowDataType];
	NSPoint mouseLocation = [self convertPoint:[sender draggingLocation] fromView:nil];

	if (columnData) {
		// If we're dragging a column
		if ([[self dataSource] respondsToSelector:@selector(tableGrid:moveColumns:toIndex:)]) {
			// Get which columns are being dragged
			NSIndexSet *draggedColumns = (NSIndexSet *)[NSKeyedUnarchiver unarchiveObjectWithData:columnData];

			// Get the index to move the columns to
			NSUInteger dropColumn = [self _dropColumnForPoint:mouseLocation];

			// Tell the data source to move the columns
			BOOL didDrag = [[self dataSource] tableGrid:self moveColumns:draggedColumns toIndex:dropColumn];

			if (didDrag) {
				NSUInteger startIndex = dropColumn;
				NSUInteger length = [draggedColumns count];

				if (dropColumn > [draggedColumns firstIndex]) {
					startIndex -= [draggedColumns count];
				}

				NSIndexSet *newColumns = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(startIndex, length)];

				// Post the notification
				[[NSNotificationCenter defaultCenter] postNotificationName:MBTableGridDidMoveColumnsNotification object:self userInfo:@{ @"OldColumns": draggedColumns, @"NewColumns": newColumns }];

				// Change the selection to reflect the newly-dragged columns
				self.selectedColumnIndexes = newColumns;
			}

			return didDrag;
		}
	}
	else if (rowData) {
		// If we're dragging a row
		if ([[self dataSource] respondsToSelector:@selector(tableGrid:moveRows:toIndex:)]) {
			// Get which rows are being dragged
			NSIndexSet *draggedRows = (NSIndexSet *)[NSKeyedUnarchiver unarchiveObjectWithData:rowData];

			// Get the index to move the rows to
			NSUInteger dropRow = [self _dropRowForPoint:mouseLocation];

			// Tell the data source to move the rows
			BOOL didDrag = [[self dataSource] tableGrid:self moveRows:draggedRows toIndex:dropRow];

			if (didDrag) {
				NSUInteger startIndex = dropRow;
				NSUInteger length = [draggedRows count];

				if (dropRow > [draggedRows firstIndex]) {
					startIndex -= [draggedRows count];
				}

				NSIndexSet *newRows = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(startIndex, length)];

				// Post the notification
				[[NSNotificationCenter defaultCenter] postNotificationName:MBTableGridDidMoveRowsNotification object:self userInfo:@{ @"OldRows": draggedRows, @"NewRows": newRows }];

				// Change the selection to reflect the newly-dragged rows
				self.selectedRowIndexes = newRows;
			}

			return didDrag;
		}
	}
	else {
		if ([[self dataSource] respondsToSelector:@selector(tableGrid:acceptDrop:column:row:)]) {
			NSUInteger dropColumn = [self columnAtPoint:mouseLocation];
			NSUInteger dropRow = [self rowAtPoint:mouseLocation];

			// Pass the drag to the data source
			BOOL didPerformDrag = [[self dataSource] tableGrid:self acceptDrop:sender column:dropColumn row:dropRow];

			return didPerformDrag;
		}
	}

	return NO;
}

- (void)concludeDragOperation:(id <NSDraggingInfo> )sender {
	[contentView _setDropColumn:NSNotFound];
	[contentView _setDropRow:NSNotFound];
}

#pragma mark -
#pragma mark Subclass Methods

#pragma mark Dimensions


#pragma mark Reloading the Grid

- (void)populateColumnInfo {
    if (columnIndexNames.count < _numberOfColumns) {
        for (NSUInteger columnIndex = columnIndexNames.count; columnIndex < _numberOfColumns; columnIndex++) {
            NSString *column = [NSString stringWithFormat:@"column%lu", columnIndex];
            columnIndexNames[columnIndex] = column;
        }
    }
}

- (void)reloadData {
	// Set number of columns
	if ([[self dataSource] respondsToSelector:@selector(numberOfColumnsInTableGrid:)]) {
		_numberOfColumns =  [[self dataSource] numberOfColumnsInTableGrid:self];
	}
	else {
		_numberOfColumns = 0;
	}

	// Set number of rows
	if ([[self dataSource] respondsToSelector:@selector(numberOfRowsInTableGrid:)]) {
		_numberOfRows =  [[self dataSource] numberOfRowsInTableGrid:self];
	}
	else {
		_numberOfRows = 0;
	}
	
	// When data are reloaded, it is possible that previous internal data refer to rows or columns that are no longer
	// valid, so we validate them here.
	
	// Validate selectedRowIndexes
	{
		// Assume everything is fine
		NSIndexSet *validatedRowIndexes = _selectedRowIndexes;
		
		if (_numberOfRows == 0 || (_numberOfRows == 1 && [self _isGroupRow:0])) {
			validatedRowIndexes = [NSIndexSet indexSet];
		} else if ([_selectedRowIndexes count] == 0) {
			if ([self _isGroupRow:0]) {
				validatedRowIndexes = [NSIndexSet indexSetWithIndex:1];
			} else {
				validatedRowIndexes = [NSIndexSet indexSetWithIndex:0];
			}
		} else if ([_selectedRowIndexes firstIndex] >= _numberOfRows || [_selectedRowIndexes lastIndex] >= _numberOfRows) {
			// Select an existing row close to the first previously selected row
			NSUInteger rowToSelect = MIN([_selectedRowIndexes firstIndex], _numberOfRows - 1);
			validatedRowIndexes = [NSIndexSet indexSetWithIndex:rowToSelect];
		}
		
		[self setSelectedRowIndexes:validatedRowIndexes];
	}
	
	// Validate selectedColumnIndexes
	{
		// Assume everything is fine
		NSIndexSet *validatedColumnIndexes = _selectedColumnIndexes;
		
		if (_numberOfColumns == 0) {
			validatedColumnIndexes = [NSIndexSet indexSet];
		} else if ([_selectedColumnIndexes count] == 0) {
			validatedColumnIndexes = [NSIndexSet indexSetWithIndex:0];
		} else if ([_selectedColumnIndexes firstIndex] >= _numberOfColumns || [_selectedColumnIndexes lastIndex] >= _numberOfColumns) {
			// Select an existing column close to the first previously selected column
			NSUInteger columnToSelect = MIN([_selectedColumnIndexes firstIndex], _numberOfColumns - 1);
			validatedColumnIndexes = [NSIndexSet indexSetWithIndex:columnToSelect];
		}
		
		[self setSelectedColumnIndexes:validatedColumnIndexes];
	}

	columnWidths = [NSMutableDictionary new];
	[self.columnRects removeAllObjects];
	
    [self populateColumnInfo];
	
	// Update the content view's size
	NSRect contentRect = NSZeroRect;
	
	if (_numberOfColumns > 0 && _numberOfRows > 0) {
		NSUInteger lastColumn = _numberOfColumns-1; // _numberOfColumns must be > 0
		NSUInteger lastRow = _numberOfRows-1; // _numberOfRows must be > 0
		NSRect bottomRightCellFrame = [contentView frameOfCellAtColumn:lastColumn row:lastRow];
		
		contentRect = NSMakeRect([contentView frame].origin.x, [contentView frame].origin.y, NSMaxX(bottomRightCellFrame), NSMaxY(bottomRightCellFrame));
	}
	
	[contentView setFrameSize:contentRect.size];
	

	// Update the column header view's size
	NSRect columnHeaderFrame = [columnHeaderView frame];
	columnHeaderFrame.size.width = contentRect.size.width;
	if (![[contentScrollView verticalScroller] isHidden]) {
		columnHeaderFrame.size.width += [NSScroller scrollerWidthForControlSize:NSRegularControlSize
																  scrollerStyle:NSScrollerStyleOverlay];
	}
	[columnHeaderView setFrameSize:columnHeaderFrame.size];

	// Update the row header view's size
	NSRect rowHeaderFrame = [rowHeaderView frame];
	rowHeaderFrame.size.height = contentRect.size.height;
	if (![[contentScrollView horizontalScroller] isHidden]) {
		columnHeaderFrame.size.height += [NSScroller scrollerWidthForControlSize:NSRegularControlSize
																   scrollerStyle:NSScrollerStyleOverlay];
	}
	[rowHeaderView setFrameSize:rowHeaderFrame.size];

	NSRect columnFooterFrame = [columnFooterView frame];
	columnFooterFrame.size.width = contentRect.size.width;
	if (![[contentScrollView verticalScroller] isHidden]) {
		columnFooterFrame.size.width += [NSScroller scrollerWidthForControlSize:NSRegularControlSize
																  scrollerStyle:NSScrollerStyleOverlay];
	}
	[columnFooterView setFrameSize:columnHeaderFrame.size];
	
	contentView.groupRowIndexes = nil;
    
	[self setNeedsDisplay:YES];
}

#pragma mark Layout Support

- (NSRect)rectOfColumn:(NSUInteger)columnIndex {
	NSRect rect = [self convertRect:[contentView rectOfColumn:columnIndex] fromView:contentView];
	rect.origin.y = 0;
	rect.size.height += MBTableGridColumnHeaderHeight;
	if (rect.size.height > [self frame].size.height) {
		rect.size.height = [self frame].size.height;

		// If the scrollbar is visible, don't include it in the rect
		if (![[contentScrollView horizontalScroller] isHidden]) {
			rect.size.height -= [NSScroller scrollerWidthForControlSize:NSRegularControlSize
														  scrollerStyle:NSScrollerStyleOverlay];
		}
	}

	return rect;
}

- (NSRect)rectOfRow:(NSUInteger)rowIndex {
	NSRect rect = [self convertRect:[contentView rectOfRow:rowIndex] fromView:contentView];
	rect.origin.x = 0;
	rect.size.width += MBTableGridRowHeaderWidth;

	return rect;
}

- (NSRect)frameOfCellAtColumn:(NSUInteger)columnIndex row:(NSUInteger)rowIndex {
	return [self convertRect:[contentView frameOfCellAtColumn:columnIndex row:rowIndex] fromView:contentView];
}

- (NSRect)headerRectOfColumn:(NSUInteger)columnIndex {
	return [self convertRect:[columnHeaderView headerRectOfColumn:columnIndex] fromView:columnHeaderView];
}

- (NSRect)headerRectOfRow:(NSUInteger)rowIndex {
	return [self convertRect:[rowHeaderView headerRectOfColumn:rowIndex] fromView:rowHeaderView];
}

- (NSRect)headerRectOfCorner {
	NSRect rect = NSMakeRect(0, 0, MBTableGridRowHeaderWidth, MBTableGridColumnHeaderHeight);
	return rect;
}

- (NSRect)footerRectOfCorner {
	NSRect rect = NSMakeRect(0, [self frame].size.height - MBTableGridColumnHeaderHeight, MBTableGridRowHeaderWidth, MBTableGridColumnHeaderHeight);
	return rect;
}

- (NSInteger)columnAtPoint:(NSPoint)aPoint {
	NSInteger column = 0;
	while (column < _numberOfColumns) {
		NSRect columnFrame = [self rectOfColumn:column];
		if (NSPointInRect(aPoint, columnFrame)) {
			return column;
		}
		column++;
	}
	return NSNotFound;
}

- (NSInteger)rowAtPoint:(NSPoint)aPoint {
	NSInteger row = 0;
	while (row < _numberOfRows) {
		NSRect rowFrame = [self rectOfRow:row];
		if (NSPointInRect(aPoint, rowFrame)) {
			return row;
		}
		row++;
	}
	return NSNotFound;
}

#pragma mark Auxiliary Views

- (MBTableGridHeaderView *)columnHeaderView {
	return columnHeaderView;
}

- (MBTableGridHeaderView *)rowHeaderView {
	return rowHeaderView;
}

- (MBTableGridContentView *)contentView {
	return contentView;
}

#pragma mark - Overridden Property Accessors

- (void)setSelectedColumnIndexes:(NSIndexSet *)anIndexSet {
	if (anIndexSet == _selectedColumnIndexes)
		return;


	// first, enumerate all the old inndexes, and call setNeedsdisplaayInRect on them.
//	[selectedColumnIndexes enumerateIndexesUsingBlock: ^(NSUInteger column, BOOL *stop) {
//	    [selectedRowIndexes enumerateIndexesUsingBlock: ^(NSUInteger row, BOOL *stop) {
//	        NSRect oldRect = [self frameOfCellAtColumn:column row:row];
//	        [self setNeedsDisplayInRect:oldRect];
//		}];
//	}];

	// Allow the delegate to validate the selection
	if ([[self delegate] respondsToSelector:@selector(tableGrid:willSelectColumnsAtIndexPath:)]) {
		anIndexSet = [[self delegate] tableGrid:self willSelectColumnsAtIndexPath:anIndexSet];
	}

	_selectedColumnIndexes = anIndexSet;

	[self setNeedsDisplay:YES];
	// then, enumerate all the new inndexes, and call setNeedsdisplaayInRect on them.
//	[selectedColumnIndexes enumerateIndexesUsingBlock: ^(NSUInteger column, BOOL *stop) {
//	    [selectedRowIndexes enumerateIndexesUsingBlock: ^(NSUInteger row, BOOL *stop) {
//	        NSRect oldRect = [self frameOfCellAtColumn:column row:row];
//	        [self setNeedsDisplayInRect:oldRect];
//		}];
//	}];

	// Post the notification
	[[NSNotificationCenter defaultCenter] postNotificationName:MBTableGridDidChangeSelectionNotification object:self];
}

- (void)setSelectedRowIndexes:(NSIndexSet *)anIndexSet {
	if (anIndexSet == _selectedColumnIndexes)
		return;


	// Allow the delegate to validate the selection
	if ([[self delegate] respondsToSelector:@selector(tableGrid:willSelectRowsAtIndexPath:)]) {
		anIndexSet = [[self delegate] tableGrid:self willSelectRowsAtIndexPath:anIndexSet];
	}

	_selectedRowIndexes = anIndexSet;

	[self setNeedsDisplay:YES];

	// Post the notification
	[[NSNotificationCenter defaultCenter] postNotificationName:MBTableGridDidChangeSelectionNotification object:self];
}

- (void)setDelegate:(id <MBTableGridDelegate> )anObject {
	if (anObject == _delegate)
		return;

	if (_delegate) {
		// Unregister the delegate for relavent notifications
		[[NSNotificationCenter defaultCenter] removeObserver:_delegate name:MBTableGridDidChangeSelectionNotification object:self];
		[[NSNotificationCenter defaultCenter] removeObserver:_delegate name:MBTableGridDidMoveColumnsNotification object:self];
		[[NSNotificationCenter defaultCenter] removeObserver:_delegate name:MBTableGridDidMoveRowsNotification object:self];
	}

	_delegate = anObject;

	// Register the new delegate for relavent notifications
	if ([_delegate respondsToSelector:@selector(tableGridDidChangeSelection:)]) {
		[[NSNotificationCenter defaultCenter] addObserver:_delegate selector:@selector(tableGridDidChangeSelection:) name:MBTableGridDidChangeSelectionNotification object:self];
	}
	if ([_delegate respondsToSelector:@selector(tableGridDidMoveColumns:)]) {
		[[NSNotificationCenter defaultCenter] addObserver:_delegate selector:@selector(tableGridDidMoveColumns:) name:MBTableGridDidMoveColumnsNotification object:self];
	}
	if ([_delegate respondsToSelector:@selector(tableGridDidMoveRows:)]) {
		[[NSNotificationCenter defaultCenter] addObserver:_delegate selector:@selector(tableGridDidMoveRows:) name:MBTableGridDidMoveRowsNotification object:self];
	}
}

@end

@implementation MBTableGrid (Drawing)

- (void)_drawColumnHeaderBackgroundInRect:(NSRect)aRect {
	if ([self needsToDrawRect:aRect]) {
		NSColor *topGradientTop = [NSColor colorWithDeviceWhite:1 alpha:1.0];
		NSColor *topGradientBottom = [NSColor colorWithDeviceWhite:1 alpha:1.0];
		NSColor *bottomGradientTop = [NSColor colorWithDeviceWhite:1 alpha:1.0];
		NSColor *bottomGradientBottom = [NSColor colorWithDeviceWhite:1 alpha:1.0];
		NSColor *topColor = [NSColor colorWithDeviceWhite:1 alpha:1.0];
		NSColor *borderColor = [NSColor colorWithDeviceWhite:0.8 alpha:1.0];

		NSGradient *topGradient = [[NSGradient alloc] initWithColors:@[topGradientTop, topGradientBottom]];
		NSGradient *bottomGradient = [[NSGradient alloc] initWithColors:@[bottomGradientTop, bottomGradientBottom]];

		NSRect topRect = NSMakeRect(NSMinX(aRect), 0, NSWidth(aRect), NSHeight(aRect) / 2);
		NSRect bottomRect = NSMakeRect(NSMinX(aRect), NSMidY(aRect) - 0.5, NSWidth(aRect), NSHeight(aRect) / 2 + 0.5);

		// Draw the gradients
		[topGradient drawInRect:topRect angle:90.0];
		[bottomGradient drawInRect:bottomRect angle:90.0];

		// Draw the top bevel line
		NSRect topLine = NSMakeRect(NSMinX(aRect), NSMinY(aRect), NSWidth(aRect), 1.0);
		[topColor set];
		NSRectFill(topLine);

		// Draw the bottom border
		[borderColor set];
		NSRect bottomLine = NSMakeRect(NSMinX(aRect), NSMaxY(aRect) - 1.0, NSWidth(aRect), 1.0);
		NSRectFill(bottomLine);
	}
}

- (void)_drawRowHeaderBackgroundInRect:(NSRect)aRect {
	if ([self needsToDrawRect:aRect]) {
		NSColor *sideColor = [NSColor colorWithDeviceWhite:1.0 alpha:0.4];
		NSColor *borderColor = [NSColor colorWithDeviceWhite:0.8 alpha:1.0];

		// Draw the left bevel line
		NSRect leftLine = NSMakeRect(NSMinX(aRect), NSMinY(aRect), 1.0, NSHeight(aRect));
		[sideColor set];
		[[NSBezierPath bezierPathWithRect:leftLine] fill];

		// Draw the right border
		[borderColor set];
		NSRect rightLine = NSMakeRect(NSMaxX(aRect) - 1, NSMinY(aRect), 1.0, NSHeight(aRect));
		NSRectFill(rightLine);
	}
}

- (void)_drawCornerHeaderBackgroundInRect:(NSRect)aRect {
	if ([self needsToDrawRect:aRect]) {
		NSColor *topColor = [NSColor colorWithDeviceWhite:0.9 alpha:1.0];
		NSColor *sideColor = [NSColor colorWithDeviceWhite:0.8 alpha:0.4];
		NSColor *borderColor = [NSColor colorWithDeviceWhite:0.8 alpha:1.0];

		// Draw the top bevel line
		NSRect topLine = NSMakeRect(NSMinX(aRect), NSMinY(aRect), NSWidth(aRect), 1.0);
		[topColor set];
		NSRectFill(topLine);

		// Draw the left bevel line
		NSRect leftLine = NSMakeRect(NSMinX(aRect), NSMinY(aRect), 1.0, NSHeight(aRect));
		[sideColor set];
		[[NSBezierPath bezierPathWithRect:leftLine] fill];

		// Draw the right border
		[borderColor set];
		NSRect borderLine = NSMakeRect(NSMaxX(aRect) - 1, NSMinY(aRect), 1.0, NSHeight(aRect));
		NSRectFill(borderLine);

		// Draw the bottom border
		NSRect bottomLine = NSMakeRect(NSMinX(aRect), NSMaxY(aRect) - 1.0, NSWidth(aRect), 1.0);
		NSRectFill(bottomLine);
	}
}

- (void)_drawCornerFooterBackgroundInRect:(NSRect)aRect {
	if ([self needsToDrawRect:aRect]) {
		NSColor *topColor = [NSColor colorWithDeviceWhite:0.8 alpha:1.000];
		NSColor *sideColor = [NSColor colorWithDeviceWhite:1.0 alpha:0.4];
		NSColor *borderColor = [NSColor colorWithDeviceWhite:0.8 alpha:1.000];
		
		// Draw the top bevel line
		NSRect topLine = NSMakeRect(NSMinX(aRect), NSMinY(aRect), NSWidth(aRect), 1.0);
		[topColor set];
		NSRectFill(topLine);
		
		// Draw the left bevel line
		NSRect leftLine = NSMakeRect(NSMinX(aRect), NSMinY(aRect), 1.0, NSHeight(aRect));
		[sideColor set];
		[[NSBezierPath bezierPathWithRect:leftLine] fill];
		
		// Draw the right border
		[borderColor set];
		NSRect borderLine = NSMakeRect(NSMaxX(aRect) - 1, NSMinY(aRect), 1.0, NSHeight(aRect));
		NSRectFill(borderLine);
		
		// Draw the bottom border
		NSRect bottomLine = NSMakeRect(NSMinX(aRect), NSMaxY(aRect) - 1.0, NSWidth(aRect), 1.0);
		NSRectFill(bottomLine);
	}
}

@end

@implementation MBTableGrid (DataAccessors)

- (NSString *)_headerStringForColumn:(NSUInteger)columnIndex {
	// Ask the data source
	if ([[self dataSource] respondsToSelector:@selector(tableGrid:headerStringForColumn:)]) {
		return [[self dataSource] tableGrid:self headerStringForColumn:columnIndex];
	}

	char alphabetChar = columnIndex + 'A';
	return [NSString stringWithFormat:@"%c", alphabetChar];
}

- (NSString *)_headerStringForRow:(NSUInteger)rowIndex {
	// Ask the data source
	if ([[self dataSource] respondsToSelector:@selector(tableGrid:headerStringForRow:)]) {
		return [[self dataSource] tableGrid:self headerStringForRow:rowIndex];
	}

	return [NSString stringWithFormat:@"%lu", (rowIndex + 1)];
}

- (id)_objectValueForColumn:(NSUInteger)columnIndex row:(NSUInteger)rowIndex {
	if ([[self dataSource] respondsToSelector:@selector(tableGrid:objectValueForColumn:row:)]) {
		id value = [[self dataSource] tableGrid:self objectValueForColumn:columnIndex row:rowIndex];
		return value;
	}
	else {
		NSLog(@"WARNING: MBTableGrid data source does not implement tableGrid:objectValueForColumn:row:");
	}
	return nil;
}

- (NSImage *)_accessoryButtonImageForColumn:(NSUInteger)columnIndex row:(NSUInteger)rowIndex {
	if ([[self dataSource] respondsToSelector:@selector(tableGrid:accessoryButtonImageForColumn:row:)]) {
		return [[self dataSource] tableGrid:self accessoryButtonImageForColumn:columnIndex row:rowIndex];
	}
	return nil;
}

- (NSFormatter *)_formatterForColumn:(NSUInteger)columnIndex {
    if ([[self dataSource] respondsToSelector:@selector(tableGrid:formatterForColumn:)]) {
        return [[self dataSource] tableGrid:self formatterForColumn:columnIndex];
    }
	return nil;
}

- (NSCell *)_cellForColumn:(NSUInteger)columnIndex {
	if (_numberOfColumns > 0) {
		if ([[self dataSource] respondsToSelector:@selector(tableGrid:cellForColumn:)]) {
			return [[self dataSource] tableGrid:self cellForColumn:columnIndex];
		}
	}
	return nil;
}

- (NSArray *)_availableObjectValuesForColumn:(NSUInteger)columnIndex {
	if ([[self dataSource] respondsToSelector:@selector(tableGrid:availableObjectValuesForColumn:)]) {
		return [[self dataSource] tableGrid:self availableObjectValuesForColumn:columnIndex];
	}
	return nil;
}

- (NSArray *)_autocompleteValuesForEditString:(NSString *)editString column:(NSUInteger)columnIndex row:(NSUInteger)rowIndex {
    if ([[self dataSource] respondsToSelector:@selector(tableGrid:autocompleteValuesForEditString:column:row:)]) {
        return [[self dataSource] tableGrid:self autocompleteValuesForEditString:editString column:columnIndex row:rowIndex];
    }
    return nil;
}

- (id)_backgroundColorForColumn:(NSUInteger)columnIndex row:(NSUInteger)rowIndex {
	if ([[self dataSource] respondsToSelector:@selector(tableGrid:backgroundColorForColumn:row:)]) {
		return [[self dataSource] tableGrid:self backgroundColorForColumn:columnIndex row:rowIndex];
	}
	else {
		NSLog(@"WARNING: MBTableGrid data source does not implement tableGrid:backgroundColorForColumn:row:");
	}
	return nil;
}

- (void)_setObjectValue:(id)value forColumn:(NSUInteger)columnIndex row:(NSUInteger)rowIndex undoTitle:(NSString *)undoTitle {
	if ([[self dataSource] respondsToSelector:@selector(tableGrid:setObjectValue:forColumn:row:)]) {
        
        NSUndoManager *undoManager = [self _undoManager];
        id oldValue = [self _objectValueForColumn:columnIndex row:rowIndex];
        
        [[undoManager prepareWithInvocationTarget:self] _setObjectValue:oldValue forColumn:columnIndex row:rowIndex undoTitle:undoTitle];
        undoManager.actionName = undoTitle;
        
		[[self dataSource] tableGrid:self setObjectValue:value forColumn:columnIndex row:rowIndex];
	}
}

- (float)_widthForColumn:(NSUInteger)columnIndex {
	NSString *column = nil;
	if ([columnIndexNames count] > columnIndex) {
		column = columnIndexNames[columnIndex];
	}

	if (!column) {
		column = [NSString stringWithFormat:@"column%lu", columnIndex];
		columnIndexNames[columnIndex] = column;
	}

	if (columnWidths[column]) {
		return [columnWidths[column] floatValue];
	}
	else {
		return [self _setWidthForColumn:columnIndex];
	}
}

- (float)_setWidthForColumn:(NSUInteger)columnIndex {
	if ([[self dataSource] respondsToSelector:@selector(tableGrid:setWidthForColumn:)]) {
		NSString *column = [NSString stringWithFormat:@"column%lu", columnIndex];

		float width = [[self dataSource] tableGrid:self setWidthForColumn:columnIndex];
		columnWidths[column] = COLUMNFLOATSIZE(width);

		columnIndexNames[columnIndex] = column;

		return width;
	}
	else {
		return MBTableGridColumnHeaderWidth;
	}
}

- (BOOL)_canEditCellAtColumn:(NSUInteger)columnIndex row:(NSUInteger)rowIndex {
	// Can't edit if the data source doesn't implement the method
	if (![[self dataSource] respondsToSelector:@selector(tableGrid:setObjectValue:forColumn:row:)]) {
		return NO;
	}

	// Ask the delegate if the cell is editable
	if ([[self delegate] respondsToSelector:@selector(tableGrid:shouldEditColumn:row:)]) {
		return [[self delegate] tableGrid:self shouldEditColumn:columnIndex row:rowIndex];
	}

	return YES;
}

- (BOOL)_canFillCellAtColumn:(NSUInteger)columnIndex row:(NSUInteger)rowIndex {
	// Can't edit if the data source doesn't implement the method
	if (![[self dataSource] respondsToSelector:@selector(tableGrid:setObjectValue:forColumn:row:)]) {
		return NO;
	}
	
	// Ask the delegate if the cell is fillable
	if ([[self delegate] respondsToSelector:@selector(tableGrid:shouldFillColumn:row:)]) {
		return [[self delegate] tableGrid:self shouldFillColumn:columnIndex row:rowIndex];
	}
	
	return YES;
}

- (void)_fillInColumn:(NSUInteger)column fromRow:(NSUInteger)row numberOfRowsWhenStarting:(NSUInteger)numberOfRowsWhenStartingFilling {
    
    NSInteger numberOfRows = self.numberOfRows;
    BOOL addedRows = numberOfRows > numberOfRowsWhenStartingFilling;
    NSIndexSet *addedRowIndexes = nil;
    
    if (addedRows) {
        addedRowIndexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(numberOfRowsWhenStartingFilling, numberOfRows - numberOfRowsWhenStartingFilling)];
    }
    
    [[[self _undoManager] prepareWithInvocationTarget:self] _undoFillInColumn:column filledRows:self.selectedRowIndexes addedRows:addedRowIndexes];
    
    id value = [self _objectValueForColumn:column row:row];
    
    [self.selectedRowIndexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        [self _setObjectValue:[value copy] forColumn:column row:idx undoTitle:@"Fill"];
    }];
    
    // If rows were added, tell the delegate
    if (addedRows && [self.delegate respondsToSelector:@selector(tableGrid:didAddRows:)]) {
        [self.delegate tableGrid:self didAddRows:addedRowIndexes];
    }
}

- (void)_undoFillInColumn:(NSUInteger)column filledRows:(NSIndexSet *)filledRowIndexes addedRows:(NSIndexSet *)addedRowIndexes {
    
    [[[self _undoManager] prepareWithInvocationTarget:self] _redoFillInColumn:column filledRows:filledRowIndexes addedRows:addedRowIndexes];
    
    if (addedRowIndexes && [self.dataSource respondsToSelector:@selector(tableGrid:removeRows:)]) {
        [self.dataSource tableGrid:self removeRows:addedRowIndexes];
    }
    
    self.selectedColumnIndexes = [NSIndexSet indexSetWithIndex:column];
    self.selectedRowIndexes = [NSIndexSet indexSetWithIndex:filledRowIndexes.firstIndex];
}

- (void)_redoFillInColumn:(NSUInteger)column filledRows:(NSIndexSet *)filledRowIndexes addedRows:(NSIndexSet *)addedRowIndexes {
    
    [[[self _undoManager] prepareWithInvocationTarget:self] _undoFillInColumn:column filledRows:filledRowIndexes addedRows:addedRowIndexes];
    
    if (addedRowIndexes && [self.dataSource respondsToSelector:@selector(tableGrid:addRows:)]) {
        [self.dataSource tableGrid:self addRows:addedRowIndexes.count];
    }
    
    self.selectedColumnIndexes = [NSIndexSet indexSetWithIndex:column];
    self.selectedRowIndexes = filledRowIndexes;
}

- (void)_userDidEnterInvalidStringInColumn:(NSUInteger)columnIndex row:(NSUInteger)rowIndex errorDescription:(NSString *)errorDescription {
    if ([[self delegate] respondsToSelector:@selector(tableGrid:userDidEnterInvalidStringInColumn:row:errorDescription:)]) {
        [[self delegate] tableGrid:self userDidEnterInvalidStringInColumn:columnIndex row:rowIndex errorDescription:errorDescription];
    }
}

- (void)_accessoryButtonClicked:(NSUInteger)columnIndex row:(NSUInteger)rowIndex {
	if ([[self delegate] respondsToSelector:@selector(tableGrid:accessoryButtonClicked:row:)]) {
		[[self delegate] tableGrid:self accessoryButtonClicked:columnIndex row:rowIndex];
	}
}

- (BOOL)_isGroupRow:(NSUInteger)rowIndex {
	// Ask the delegate if the cell is fillable
	if ([[self delegate] respondsToSelector:@selector(tableGrid:isGroupRow:)]) {
		return [[self delegate] tableGrid:self isGroupRow:rowIndex];
	}
	
	return NO;
}

#pragma mark Footer

- (NSCell *)_footerCellForColumn:(NSUInteger)columnIndex {
    if ([[self dataSource] respondsToSelector:@selector(tableGrid:footerCellForColumn:)]) {
        return [[self dataSource] tableGrid:self footerCellForColumn:columnIndex];
    }
    return nil;
}

- (id)_footerValueForColumn:(NSUInteger)columnIndex {
    if ([[self dataSource] respondsToSelector:@selector(tableGrid:footerValueForColumn:)]) {
        id value = [[self dataSource] tableGrid:self footerValueForColumn:columnIndex];
        return value;
    }
    return nil;
}

- (void)_setFooterValue:(id)value forColumn:(NSUInteger)columnIndex {
    if ([[self dataSource] respondsToSelector:@selector(tableGrid:setFooterValue:forColumn:)]) {
        [[self dataSource] tableGrid:self setFooterValue:value forColumn:columnIndex];
    }
}

@end

@implementation MBTableGrid (PrivateAccessors)

- (MBTableGridContentView *)_contentView {
	return contentView;
}

- (void)_setStickyColumn:(MBTableGridEdge)stickyColumn row:(MBTableGridEdge)stickyRow {
	stickyColumnEdge = stickyColumn;
	stickyRowEdge = stickyRow;
}

- (MBTableGridEdge)_stickyColumn {
	return stickyColumnEdge;
}

- (MBTableGridEdge)_stickyRow {
	return stickyRowEdge;
}

- (NSUndoManager *)_undoManager {
    if (!self.cachedUndoManager && [[self delegate] respondsToSelector:@selector(undoManagerForTableGrid:)]) {
        self.cachedUndoManager = [[self delegate] undoManagerForTableGrid:self];
    }
    
    if (!self.cachedUndoManager) {
        self.cachedUndoManager = self.window.undoManager;
    }
    
    return self.cachedUndoManager;
}

@end

@implementation MBTableGrid (DragAndDrop)

- (void)_dragColumnsWithEvent:(NSEvent *)theEvent {
	NSImage *dragImage = [self _imageForSelectedColumns];

	NSRect firstSelectedColumn = [self rectOfColumn:[self.selectedColumnIndexes firstIndex]];
	NSPoint location = firstSelectedColumn.origin;
    
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:self.selectedColumnIndexes];
    NSPasteboardItem *pbItem = [[NSPasteboardItem alloc] initWithPasteboardPropertyList:data ofType:MBTableGridColumnDataType];
    NSDraggingItem *item = [[NSDraggingItem alloc] initWithPasteboardWriter:pbItem];
    
    NSRect dragImageFrame = NSMakeRect(location.x, location.y, dragImage.size.width, dragImage.size.height);
    [item setDraggingFrame:dragImageFrame contents:dragImage];
    id source = (id <NSDraggingSource>) self;
    
    [self beginDraggingSessionWithItems:@[item] event:theEvent source:source];
}

- (void)_dragRowsWithEvent:(NSEvent *)theEvent {
	NSImage *dragImage = [self _imageForSelectedRows];
    
	NSRect firstSelectedRow = [self rectOfRow:[self.selectedRowIndexes firstIndex]];
	NSPoint location = firstSelectedRow.origin;
    
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:self.selectedRowIndexes];
    NSPasteboardItem *pbItem = [[NSPasteboardItem alloc] initWithPasteboardPropertyList:data ofType:MBTableGridRowDataType];
    NSDraggingItem *item = [[NSDraggingItem alloc] initWithPasteboardWriter:pbItem];
    
    NSRect dragImageFrame = NSMakeRect(location.x, location.y, dragImage.size.width, dragImage.size.height);
    [item setDraggingFrame:dragImageFrame contents:dragImage];
    id source = (id <NSDraggingSource>) self;
    
    [self beginDraggingSessionWithItems:@[item] event:theEvent source:source];
}

- (NSImage *)_imageForSelectedColumns {
	NSRect firstColumnFrame = [self rectOfColumn:[self.selectedColumnIndexes firstIndex]];
	NSRect lastColumnFrame = [self rectOfColumn:[self.selectedColumnIndexes lastIndex]];
	NSRect columnsFrame = NSMakeRect(NSMinX(firstColumnFrame), NSMinY(firstColumnFrame), NSMaxX(lastColumnFrame) - NSMinX(firstColumnFrame), NSHeight(firstColumnFrame));
	// Extend the frame to show the left border
	columnsFrame.origin.x -= 1.0;
	columnsFrame.size.width += 1.0;

	// Take a snapshot of the view
	NSImage *opaqueImage = [[NSImage alloc] initWithData:[self dataWithPDFInsideRect:columnsFrame]];

	// Create the translucent drag image
	NSImage *finalImage = [[NSImage alloc] initWithSize:[opaqueImage size]];
	[finalImage lockFocus];
#if MAC_OS_X_VERSION_MIN_REQUIRED < MAC_OS_X_VERSION_10_8
	[opaqueImage compositeToPoint:NSZeroPoint operation:NSCompositeCopy fraction:0.7];
#else
	[opaqueImage drawAtPoint:NSZeroPoint fromRect:NSZeroRect operation:NSCompositeCopy fraction:0.7];
#endif
	[finalImage unlockFocus];

	return finalImage;
}

- (NSImage *)_imageForSelectedRows {
	NSRect firstRowFrame = [self rectOfRow:[self.selectedRowIndexes firstIndex]];
	NSRect lastRowFrame = [self rectOfRow:[self.selectedRowIndexes lastIndex]];
	NSRect rowsFrame = NSMakeRect(NSMinX(firstRowFrame), NSMinY(firstRowFrame), NSWidth(firstRowFrame), NSMaxY(lastRowFrame) - NSMinY(firstRowFrame));
	// Extend the frame to show the top border
	rowsFrame.origin.y -= 1.0;
	rowsFrame.size.height += 1.0;

	// Take a snapshot of the view
	NSImage *opaqueImage = [[NSImage alloc] initWithData:[self dataWithPDFInsideRect:rowsFrame]];

	// Create the translucent drag image
	NSImage *finalImage = [[NSImage alloc] initWithSize:[opaqueImage size]];
	[finalImage lockFocus];
#if MAC_OS_X_VERSION_MIN_REQUIRED < MAC_OS_X_VERSION_10_8
	[opaqueImage compositeToPoint:NSZeroPoint operation:NSCompositeCopy fraction:0.7];
#else
	[opaqueImage drawAtPoint:NSZeroPoint fromRect:NSZeroRect operation:NSCompositeCopy fraction:0.7];
#endif
	[finalImage unlockFocus];

	return finalImage;
}

- (NSUInteger)_dropColumnForPoint:(NSPoint)aPoint {
	NSUInteger column = [self columnAtPoint:aPoint];

	if (column == NSNotFound) {
		return NSNotFound;
	}

	// If we're in the right half of the column, we intent to drop on the right side
	NSRect columnFrame = [self rectOfColumn:column];
	columnFrame.size.width /= 2;
	if (!NSPointInRect(aPoint, columnFrame)) {
		column++;
	}

	return column;
}

- (NSUInteger)_dropRowForPoint:(NSPoint)aPoint {
	NSUInteger row = [self rowAtPoint:aPoint];

	if (row == NSNotFound) {
		return NSNotFound;
	}

	// If we're in the bottom half of the row, we intent to drop on the bottom side
	NSRect rowFrame = [self rectOfRow:row];
	rowFrame.size.height /= 2;

	if (!NSPointInRect(aPoint, rowFrame)) {
		row++;
	}

	return row;
}

@end
