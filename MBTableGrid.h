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

#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>

typedef enum : NSUInteger {
	MBSortNone,
	MBSortAscending,
	MBSortDescending,
	MBSortUndetermined
} MBSortDirection;

@class MBTableGridHeaderView, MBTableGridFooterView, MBTableGridHeaderCell, MBTableGridContentView, MBTableGridShadowView;
@protocol MBTableGridDelegate, MBTableGridDataSource;

/* Notifications */

/**
 * @brief		Posted after an MBTableGrid object's selection changes.
 *				The notification object is the table grid whose selection
 *				changed. This notification does not contain a userInfo
 *				dictionary.
 *
 * @details		This notification will often be posted twice for a single
 *				selection change (once for the column selection and once 
 *				for the row selection). As such, any methods called in
 *				response to this notification should be especially efficient.
 */
APPKIT_EXTERN NSString *MBTableGridDidChangeSelectionNotification;
APPKIT_EXTERN NSString *MBTableGridDidChangeColumnSelectionNotification;
APPKIT_EXTERN NSString *MBTableGridDidChangeRowSelectionNotification;

/**
 * @brief		Posted after one or more columns are moved by user action
 *				in an MBTableGrid object. The notification object is
 *				the table grid in which the column(s) moved. The \c userInfo
 *				dictionary contains the following information:
 *				- \c @"OldColumns": An NSIndexSet containing the columns'
 *					original indices.
 *				- \c @"NewColumns": An NSIndexSet containing the columns'
 *					new indices.
 */
APPKIT_EXTERN NSString *MBTableGridDidMoveColumnsNotification;

/**
 * @brief		Posted after one or more rows are moved by user action
 *				in an MBTableGrid object. The notification object is
 *				the table grid in which the row(s) moved. The userInfo
 *				dictionary contains the following information:
 *				- \c @"OldRows": An NSIndexSet containing the rows'
 *					original indices.
 *				- \c @"NewRows": An NSIndexSet containing the rows'
 *					new indices.
 */
APPKIT_EXTERN NSString *MBTableGridDidMoveRowsNotification;
APPKIT_EXTERN NSString *MBTableGridDidResizeColumnNotification;

APPKIT_EXTERN NSString *MBTableGridColumnDataType;
APPKIT_EXTERN NSString *MBTableGridRowDataType;

/**
 * @brief		Just a little bit of padding to make resizing the last column easier.
 */
APPKIT_EXTERN CGFloat MBTableGridContentViewPadding;

typedef NS_ENUM(NSInteger, MBTableGridEdge) {
	MBTableGridLeftEdge		= 0,
	MBTableGridRightEdge	= 1,
	MBTableGridTopEdge		= 3,
	MBTableGridBottomEdge	= 4
};

typedef NS_ENUM(NSUInteger, MBHorizontalEdge) {
	MBHorizontalEdgeLeft,
	MBHorizontalEdgeRight
};

typedef NS_ENUM(NSUInteger, MBVerticalEdge) {
	MBVerticalEdgeTop,
	MBVerticalEdgeBottom
};

/**
 * @brief		MBTableGrid (sometimes referred to as a table grid)
 *				is a means of displaying tabular data in a spreadsheet
 *				format.
 *
 * @details		An MBTableGrid object must have an object that acts
 *				as a data source and may optionally have an object which
 *				acts as a delegate. The data source must adopt the
 *				MBTableGridDataSource protocol, and the delegate must
 *				adopt the MBTableGridDelegate protocol. The data source
 *				provides information that MBTableGrid needs to construct
 *				the table grid and facillitates the insertion, deletion, and
 *				reordering of data within it. The delegate optionally provides
 *				formatting and validation information. For more information
 *				on these, see the MBTableGridDataSource and MBTableGridDelegate
 *				protocols.
 *
 *				MBTableGrid and its methods actually encompass
 *				several subviews, including MBTableGridContentView
 *				(which handles the display, selection, and editing of
 *				cells) and MBTableGridHeaderView (which handles
 *				the display, selection, and dragging of column and
 *				row headers). In general, however, it is not necessary
 *				to interact with these views directly.
 *
 * @author		Matthew Ball
 */
@interface MBTableGrid : NSControl <NSDraggingSource, NSDraggingDestination> {
	/* Headers */
	MBTableGridHeaderCell *headerCell;
	
	/* Headers */
	NSScrollView *columnHeaderScrollView;
    MBTableGridHeaderView *columnHeaderView;
	MBTableGridHeaderView *frozenColumnHeaderView;
	NSScrollView *rowHeaderScrollView;
	MBTableGridHeaderView *rowHeaderView;
    
    /* Shadows */
    MBTableGridShadowView *columnShadowView;
    MBTableGridShadowView *rowShadowView;
	
	/* Footer */
	NSScrollView *columnFooterScrollView;
	MBTableGridFooterView *columnFooterView;
    MBTableGridFooterView *frozenColumnFooterView;
	
	/* Content */
	NSScrollView *contentScrollView;
    MBTableGridContentView *contentView;
    
    /* Frozen Content */
    NSScrollView *frozenContentScrollView;
    MBTableGridContentView *frozenContentView;
    
	/* Behavior */
	BOOL shouldOverrideModifiers;
	
	/* Sticky Edges (for Shift+Arrow expansions) */
	MBTableGridEdge stickyColumnEdge;
	MBTableGridEdge stickyRowEdge;
    
    NSMutableDictionary *columnWidths;
	NSMutableArray *columnIndexNames;
	
	NSUInteger firstSelectedRow;
}

#pragma mark -
#pragma mark Reloading the Grid

/**
 * @name		Reloading the Grid
 */
/**
 * @{
 */

/**
 * @brief		Marks the receiver as needing redisplay, so
 *				it will reload the data for visible cells and
 *				draw the new values.
 *
 * @details		This method forces redraw of all the visible
 *				cells in the receiver. If you want to update
 *				the value in a single cell, column, or row,
 *				it is more efficient to use \c frameOfCellAtColumn:row:,
 *				\c rectOfColumn:, or \c rectOfRow: in conjunction with
 *				\c setNeedsDisplayInRect:.
 *
 * @see			frameOfCellAtColumn:row:
 * @see			rectOfColumn:
 * @see			rectOfRow:
 */
- (void)reloadData;

#pragma mark -
#pragma mark Selecting Rows and Columns

/**
 * @brief		Scrolls the grid to the specified row
 *
 * @param		rowIndex		The row to scroll to
 * @param		shouldAnimate	Whether the grid should animate the scrolling to the row.
 *
 */
- (void)scrollToRow:(NSUInteger)rowIndex animate:(BOOL)shouldAnimate;

/**
 * @brief		Selects the specified rows
 *
 * @param		rowIndexes		The rows to select
 *
 */
- (void)selectRowIndexes:(NSIndexSet *)rowIndexes;

/**
 * @brief		Selects the specified row
 *
 * @param		rowIndex		The row to select
 *
 */
- (void)selectRow:(NSUInteger)rowIndex;

/**
 * @brief		Selects the specified row and column
 *
 * @param		rowIndex		The row to select
 * @param		columnIndex		The column to select
 *
 */
- (void)selectRow:(NSUInteger)rowIndex column:(NSUInteger)columnIndex;

/**
 * @brief		Double-clicks the specified row or column
 *
 * @param		rowIndex		The row to select
 * @param		columnIndex		The column to select
 *
 */
- (void)doubleClickRow:(NSUInteger)rowIndex;
- (void)doubleClickColumn:(NSUInteger)columnIndex;

/**
 * @brief		Moves the selection down one row
 *
 */
- (void)moveDown:(id)sender;

/**
 * @brief		Moves the selection up one row
 *
 */
- (void)moveUp:(id)sender;

/**
 * @brief		Initiates the fill down operation
 *
 */
- (void)fillDown:(id)sender;

/**
 * @brief		Initiates the fill up operation
 *
 */
- (void)fillUp:(id)sender;

/**
 * @}
 */

#pragma mark - 
#pragma mark Resize column

/**
 * @name		Resize column
 */
/**
 * @{
 */

/**
 * @brief		Live resizes column
 *
 * @details		This method resizes the column and updates the views
 *
 * @return		The amount that the distance is beyond the minimum size
 *
 */
- (CGFloat)resizeColumnWithIndex:(NSUInteger)columnIndex withDistance:(float)distance location:(NSPoint)location;

/**
 * @brief		Cache of column rects
 *
 * @return		A mutable dictionary containing the records for all the rows keyed by column index number
 *
 */

@property (nonatomic, strong) NSMutableDictionary *columnRects;


/**
 * @}
 */

#pragma mark -
#pragma mark Selecting Columns and Rows

/**
 * @name		Selecting Columns and Rows
 */
/**
 * @{
 */

/**
 * @brief		Returns an index set containing the indexes of
 *				the selected columns.
 *
 * @return		An index set containing the indexes of the
 *				selected columns.
 *
 * @see			selectedRowIndexes
 * @see			selectCellsInColumns:rows:
 */
@property(nonatomic, strong) NSIndexSet *selectedColumnIndexes;

/**
 * @brief		Returns an index set containing the indexes of
 *				the selected rows.
 *
 * @return		An index set containing the indexes of the
 *				selected rows.
 *
 * @see			selectedColumnIndexes
 * @see			selectCellsInColumns:rows:
 */
@property(nonatomic, strong) NSMutableIndexSet *selectedRowIndexes;

/**
 * @}
 */

#pragma mark -
#pragma mark Dimensions

/**
 * @name		Dimensions
 */
/**
 * @{
 */

/**
 * @brief		Returns the number of rows in the receiver.
 *
 * @return		The number of rows in the receiver.
 *
 * @see			numberOfColumns
 */

@property (nonatomic, assign) NSUInteger numberOfRows;

/**
 * @brief		Returns the number of columns in the receiver.
 *
 * @return		The number of rows in the receiver.
 *
 * @see			numberOfRows
 */

@property (nonatomic, assign) NSUInteger numberOfColumns;

#pragma mar -
#pragma mark Sort Indicators

/**
 * @brief		Sets the indicator image for the specified column.
 *				This is used for indicating which direction the
 *				column is being sorted by.
 *
 * @param		anImage			The sort indicator image.
 * @param		reverseImage	The reversed sort indicator image.
 * @param		inColumns		Array of columns.
 *
 * @return		The header value for the row.
 */
- (void)setSortAscendingImage:(NSImage *)ascendingImage sortDescendingImage:(NSImage*)descendingImage sortUndeterminedImage:(NSImage *)undeterminedImage;

/**
 * @brief		Returns the sort indicator image
 *				for the specified column.
 *
 * @param		columnIndex		The index of the column.
 *
 * @return		The sort indicator image for the column.
 */
- (NSImage *)indicatorImageInColumn:(NSUInteger)columnIndex;

/**
 * @}
 */

#pragma mark -
#pragma mark Configuring Behavior

/**
 * @name		Configuring Behavior
 */
/**
 * @{
 */

/**
 * @brief		Indicates whether the receiver allows
 *				the user to select more than one cell at
 *				a time.
 *
 * @details		The default is \c YES. You can select multiple
 *				cells programmatically regardless of this setting.
 *
 * @return		\c YES if the receiver allows the user
 *				to select more than one cell at a time.
 *				Otherwise, \c NO.
 */
@property(assign) BOOL allowsMultipleSelection;

/**
 * @brief		Indicates whether the receiver is enabled
 *
 * @details		The default is \c YES.
 *
 * @return		\c YES if the receiver allows the user
 *				to select any rows.
 *				Otherwise, \c NO.
 */
@property(assign, nonatomic) BOOL isEditable;


/**
 * @brief		Sets the default font to use for content cells
 *
 */
@property(nonatomic, strong) NSFont *defaultCellFont;


/**
 * @brief		The autosave name for this grid
 */
@property (nonatomic) NSString *autosaveName;

- (void)copy:(id)sender;

/**
 * @brief		Indicates whether the footer is hidden or visible
 *
 * @details		The default is \c YES.
 *
 * @return		\c YES if the footer is hidden.
 */
@property (nonatomic) BOOL footerHidden;

/**
 * @brief		Returns the number of frozen columns in the receiver.
 *
 * @return		The number of frozen columns in the receiver.
 *
 * @see			freezeColumns
 */

@property (nonatomic) NSUInteger numberOfFrozenColumns;

/**
 * @brief		Returns whether or not some columns are frozen.
 *
 * @return		Whether or not some columns are frozen.
 *
 * @see			numberOfFrozenColumns
 */

@property (nonatomic) BOOL freezeColumns;

/**
 * @brief		Whether or not summary rows should be displayed for groups, providing subtotals of the groups.
 *
 * @return		Whether or not summary rows should be displayed for groups.
 */

@property (nonatomic) BOOL includeGroupSummaryRows;

/**
 * @brief		Whether or not ONLY summary rows should be displayed for groups, providing subtotals of the groups.
 *
 * @return		Whether or not summary rows should be displayed for groups.
 */

@property (nonatomic) BOOL includeOnlyGroupSummaryRows;

/**
 * @}
 */

#pragma mark -
#pragma mark Managing the Delegate and the Data Source
/**
 * @name		Managing the Delegate and the Data Source
 */
/**
 * @{
 */

/**
 * @brief		The object that provides the data displayed by
 *				the grid.
 *
 * @details		The data source must adopt the \c MBTableGridDataSource
 *				protocol. The data source is not retained.
 *
 * @see			delegate
 */
@property(nonatomic, weak) IBOutlet id <MBTableGridDataSource> dataSource;

/**
 * @brief		The object that acts as the delegate of the 
 *				receiving table grid.
 *
 * @details		The delegate must adopt the \c MBTableGridDelegate
 *				protocol. The delegate is not retained.
 *
 * @see			dataSource
 */
@property(nonatomic, weak) IBOutlet id <MBTableGridDelegate> delegate;

/**
 * @}
 */

#pragma mark -
#pragma mark Layout Support
/**
 * @name		Layout Support
 */
/**
 * @{
 */

/**
 * @brief		Returns the rectangle containing the column at
 *				a given index.
 *
 * @param		columnIndex	The index of a column in the receiver.
 *
 * @return		The rectangle containing the column at \c columnIndex.
 *				Returns \c NSZeroRect if \c columnIndex lies outside
 *				the range of valid column indices for the receiver.
 *
 * @see			frameOfCellAtColumn:row:
 * @see			rectOfRow:
 * @see			headerRectOfColumn:
 */
- (NSRect)rectOfColumn:(NSUInteger)columnIndex;

/**
 * @brief		Returns the rectangle containing the row at a
 *				given index.
 *
 * @param		rowIndex	The index of a row in the receiver.
 *
 * @return		The rectangle containing the row at \c rowIndex.
 *				Returns \c NSZeroRect if \c rowIndex lies outside
 *				the range of valid column indices for the receiver.
 *
 * @see			frameOfCellAtColumn:row:
 * @see			rectOfColumn:
 * @see			headerRectOfRow:
 */
- (NSRect)rectOfRow:(NSUInteger)rowIndex;

/**
 * @brief		Returns a rectangle locating the cell that lies at
 *				the intersection of \c columnIndex and \c rowIndex.
 *
 * @param		columnIndex	The index of the column containing the cell
 *							whose rectangle you want.
 * @param		rowIndex	The index of the row containing the cell
 *							whose rectangle you want.
 *
 * @return		A rectangle locating the cell that lies at the intersection
 *				of \c columnIndex and \c rowIndex. Returns \c NSZeroRect if
 *				\c columnIndex or \c rowIndex is greater than the number of
 *				columns or rows in the receiver.
 *
 * @see			rectOfColumn:
 * @see			rectOfRow:
 * @see			headerRectOfColumn:
 * @see			headerRectOfRow:
 */
- (NSRect)frameOfCellAtColumn:(NSUInteger)columnIndex row:(NSUInteger)rowIndex;

/**
 * @brief		Returns the rectangle containing the header tile for
 *				the column at \c columnIndex.
 *
 * @param		columnIndex	The index of the column containing the
 *							header whose rectangle you want.
 *
 * @return		A rectangle locating the header for the column at
 *				\c columnIndex. Returns \c NSZeroRect if \c columnIndex 
 *				lies outside the range of valid column indices for the 
 *				receiver.
 *
 * @see			headerRectOfRow:
 * @see			headerRectOfCorner
 */
- (NSRect)headerRectOfColumn:(NSUInteger)columnIndex;

/**
 * @brief		Returns the rectangle containing the header tile for
 *				the row at \c rowIndex.
 *
 * @param		rowIndex	The index of the row containing the
 *							header whose rectangle you want.
 *
 * @return		A rectangle locating the header for the row at
 *				\c rowIndex. Returns \c NSZeroRect if \c rowIndex 
 *				lies outside the range of valid column indices for the 
 *				receiver.
 *
 * @see			headerRectOfColumn:
 * @see			headerRectOfCorner
 */
- (NSRect)headerRectOfRow:(NSUInteger)rowIndex;

/**
 * @brief		Returns the rectangle containing the corner which
 *				divides the row headers from the column headers.
 *
 * @return		A rectangle locating the corner separating rows
 *				from columns.
 *
 * @see			headerRectOfColumn:
 * @see			headerRectOfRow:
 */
- (NSRect)headerRectOfCorner;

/**
 * @brief		Returns the index of the column a given point lies in.
 *
 * @param		aPoint		A point in the coordinate system of the receiver.
 *
 * @return		The index of the column \c aPoint lies in, or \c NSNotFound if \c aPoint
 *				lies outside the receiver's bounds.
 *
 * @see			rowAtPoint:
 */
- (NSInteger)columnAtPoint:(NSPoint)aPoint;

/**
 * @brief		Returns the index of the row a given point lies in.
 *
 * @param		aPoint		A point in the coordinate system of the receiver.
 *
 * @return		The index of the row \c aPoint lies in, or \c NSNotFound if \c aPoint
 *				lies outside the receiver's bounds.
 *
 * @see			columnAtPoint:
 */
- (NSInteger)rowAtPoint:(NSPoint)aPoint;

/**
 * @brief		Returns the index of the group heading row for a given row.
 *
 * @param		rowIndex	The index of a row.
 *
 * @return		The index of the group heading that contains the row, or \c NSNotFound if there are no group headings before this row.
 */
- (NSInteger)groupHeadingRowForRow:(NSInteger)rowIndex;

/**
 * @}
 */

#pragma mark -
#pragma mark Auxiliary Views
/**
 * @name		Auxiliary Views
 */
/**
 * @{
 */

/**
 * @brief		Returns the \c MBTableGridHeaderView object used
 *				to draw headers over columns.
 *
 * @return		The \c MBTableGridHeaderView object used to draw
 *				column headers.
 *
 * @see			rowHeaderView
 */
- (MBTableGridHeaderView *)columnHeaderView;

/**
 * @brief		Returns the \c MBTableGridHeaderView object used
 *				to draw headers over frozen columns.
 *
 * @return		The \c MBTableGridHeaderView object used to draw
 *				frozen column headers.
 *
 * @see			rowHeaderView
 */
- (MBTableGridHeaderView *)frozenColumnHeaderView;

/**
 * @brief		Returns the \c MBTableGridFooterView object used
 *				to draw footers below frozen columns.
 *
 * @return		The \c MBTableGridFooterView object used to draw
 *				frozen column footers.
 *
 * @see			frozenColumnHeaderView
 */
- (MBTableGridFooterView *)frozenColumnFooterView;

/**
 * @brief		Returns the \c MBTableGridHeaderView object used
 *				to draw headers beside rows.
 *
 * @return		The \c MBTableGridHeaderView object used to draw
 *				column headers.
 *
 * @see			columnHeaderView
 */
- (MBTableGridHeaderView *)rowHeaderView;

/**
 * @brief		Returns the \c MBTableGridShadowView object used
 *				to draw a shadow next to the column header or frozen columns.
 *
 * @return		The \c MBTableGridShadowView object used to draw
 *				a shadow.
 *
 * @see			rowShadowView
 */
- (MBTableGridShadowView *)columnShadowView;

/**
 * @brief		Returns the \c MBTableGridShadowView object used
 *				to draw a shadow below the row header.
 *
 * @return		The \c MBTableGridShadowView object used to draw
 *				a shadow.
 *
 * @see			columnShadowView
 */
- (MBTableGridShadowView *)rowShadowView;

/**
 * @brief		Returns the receiver's content view.
 *
 * @details		An \c MBTableGrid object uses its content view to
 *				draw the individual cells. It is enclosed in a
 *				scroll view to allow for scrolling.
 *
 * @return		The receiver's content view.
 */
- (MBTableGridContentView *)contentView;

/**
 * @brief		Returns the receiver's frozen content view.
 *
 * @details		An \c MBTableGrid object uses its content view to
 *				draw the individual cells. It is enclosed in a
 *				scroll view to allow for scrolling.  This one
 *				is used for any frozen columns.
 *
 * @return		The receiver's frozen content view.
 */
- (MBTableGridContentView *)frozenContentView;

/**
 * @brief		Returns whether or not a column is frozen.
 *
 * @details		A column is frozen if frozen columns are enabled via
 *              the freezeColumns property, and the column is within
 *              the numberOfFrozenColumns.
 *
 * @return		YES if the column is frozen, NO if not.
 */
- (BOOL)isFrozenColumn:(NSUInteger)column;

/**
 * @brief		Scrolls between frozen and unfrozen columns, if needed.
 *
 * @details		If moving between a frozen column and an unfrozen one,
 *              this will scroll to reveal the adjacent column, as needed.
 *
 * @return      YES if scrolling was appropriate.
 */
- (BOOL)scrollForFrozenColumnsFromColumn:(NSUInteger)fromColumn right:(BOOL)right;

/**
 * @}
 */

@end

#pragma mark -

@protocol MBTableGridPopupMenu <NSObject>

- (void)cellPopupMenuItemSelected:(NSMenuItem *)menuItem;

@end

#pragma mark -

/**
 * @brief		The \c MBTableGridDataSource protocol is adopted
 *				by an object that mediates the data model for an
 *				\c MBTableGrid object. 
 *
 * @details		As a representative of the data model, the data 
 *				source supplies no information about the grid's
 *				appearance or behavior. Rather, the grid's
 *				delegate (adopting the \c MBTableGridDelegate
 *				protocol) can provide that information.
 */
@protocol MBTableGridDataSource <NSObject>

@required

#pragma mark -
#pragma mark Dimensions

/**
 * @name		Dimensions
 */
/**
 * @{
 */

@required

/**
 * @brief		Returns the number of rows managed for \c aTableGrid
 *				by the data source object.
 *
 * @param		aTableGrid		The table grid that sent the message.
 *
 * @return		The number of rows in \c aTableGrid.
 *
 * @see			numberOfColumnsInTableGrid:
 */
- (NSUInteger)numberOfRowsInTableGrid:(MBTableGrid *)aTableGrid;

/**
 * @brief		Returns the number of rows managed for \c aTableGrid
 *				by the data source object.
 *
 * @param		aTableGrid		The table grid that sent the message.
 *
 * @return		The number of rows in \c aTableGrid.
 *
 * @see			numberOfRowsInTableGrid:
 */
- (NSUInteger)numberOfColumnsInTableGrid:(MBTableGrid *)aTableGrid;

/**
 * @}
 */

/**
 * @name		Accessing Cell Values
 */
/**
 * @{
 */

@required

/**
 * @brief		Returns the data object associated with the specified column and row.
 *
 * @param		aTableGrid		The table grid that sent the message.
 * @param		columnIndex		A column in \c aTableGrid.
 * @param		rowIndex		A row in \c aTableGrid.
 *
 * @return		The object for the specified cell of the view.
 *
 * @see			tableGrid:setObjectValue:forColumn:row:
 */
- (id)tableGrid:(MBTableGrid *)aTableGrid objectValueForColumn:(NSUInteger)columnIndex row:(NSUInteger)rowIndex;

@optional

/**
 *  @brief      Returns the formatter associated with the specified column.
 *
 *  @param      aTableGrid  The table grid that sent the message.
 *  @param      columnIndex A column in \c aTableGrid.
 *
 *  @return     The formatter for the specified column to use when displaying cell values
 */
- (NSFormatter *)tableGrid:(MBTableGrid *)aTableGrid formatterForColumn:(NSUInteger)columnIndex;

@optional

/**
 *  @brief      Returns the cell associated with the specified column.
 *
 *  @param      aTableGrid  The table grid that sent the message.
 *  @param      columnIndex A column in \c aTableGrid.
 *
 *  @return     The cell for the specified column
 */
- (NSCell *)tableGrid:(MBTableGrid *)aTableGrid cellForColumn:(NSUInteger)columnIndex;

@optional

/**
 *  @brief      Returns the cell's accessory button with the specified column and row
 *
 *  @param      aTableGrid  The table grid that sent the message.
 *  @param      columnIndex A column in \c aTableGrid.
 *  @
 *
 *  @return     The cell for the specified column
 */
- (NSImage *)tableGrid:(MBTableGrid *)aTableGrid accessoryButtonImageForColumn:(NSUInteger)columnIndex row:(NSUInteger)row;

@optional

/**
 *  @brief
 *
 *  @param aTableGrid  The table grid that sent the message.
 *  @param columnIndex A column in \c aTableGrid.
 *
 *  @return An array of possible object values to represent in a popup button for a given column. Return nil if the cells in the column should not be edited with a popup button of available values, but should instead allow freeform string input. The count of the returned array should match that returned in tableGrid:availableUserStringsForColumn:.
 */
- (NSArray *)tableGrid:(MBTableGrid *)aTableGrid availableObjectValuesForColumn:(NSUInteger)columnIndex;

@optional

/**
 *  @brief      Offer auto-completion strings based on the user input.
 *
 *  @param      aTableGrid      The table grid that sent the message.
 *  @param      value           The text the user entered in the cell editor.
 *  @param      columnIndex     A column in \c aTableGrid.
 *  @param		rowIndex		A row in \c aTableGrid.
 *
 *  @return An array of strings to offer as auto-completion matches for the user-entered text for a given column and row. The returned strings should generally be based on the other values in the column that have the same prefix as the given text. Return nil or an empty array if no auto-completion strings should be offered.
 */
- (NSArray *)tableGrid:(MBTableGrid *)aTableGrid autocompleteValuesForEditString:(NSString *)editString column:(NSUInteger)columnIndex row:(NSUInteger)rowIndex;

@optional

/**
 * @brief		Returns the background color for the specified column and row.
 *
 * @param		aTableGrid		The table grid that sent the message.
 * @param		columnIndex		A column in \c aTableGrid.
 * @param		rowIndex		A row in \c aTableGrid.
 *
 * @return		The background color for the specified cell of the view.
 */
- (NSColor *)tableGrid:(MBTableGrid *)aTableGrid backgroundColorForColumn:(NSUInteger)columnIndex row:(NSUInteger)rowIndex;

/**
 * @brief		Returns the frozen background color for the specified column and row.
 *
 * @param		aTableGrid		The table grid that sent the message.
 * @param		columnIndex		A column in \c aTableGrid.
 * @param		rowIndex		A row in \c aTableGrid.
 *
 * @return		The frozen background color for the specified cell of the view.
 */
- (NSColor *)tableGrid:(MBTableGrid *)aTableGrid frozenBackgroundColorForColumn:(NSUInteger)columnIndex row:(NSUInteger)rowIndex;

/**
 * @brief		Returns the group summary background color for the specified column and row.
 *
 * @param		aTableGrid		The table grid that sent the message.
 * @param		columnIndex		A column in \c aTableGrid.
 * @param		rowIndex		A row in \c aTableGrid.
 *
 * @return		The group summary background color for the specified cell of the view.
 */
- (NSColor *)tableGrid:(MBTableGrid *)aTableGrid groupSummaryBackgroundColorForColumn:(NSUInteger)columnIndex row:(NSUInteger)rowIndex;

@optional

/**
 * @brief		Returns the text color for the specified column and row.
 *
 * @param		aTableGrid		The table grid that sent the message.
 * @param		columnIndex		A column in \c aTableGrid.
 * @param		rowIndex		A row in \c aTableGrid.
 *
 * @return		The text color for the specified cell of the view.
 */
- (NSColor *)tableGrid:(MBTableGrid *)aTableGrid textColorForColumn:(NSUInteger)columnIndex row:(NSUInteger)rowIndex;

@optional

/**
 * @brief		Sets the sata object for an item in a given row in a given column.
 *
 * @details		Although this method is optional, it must be implemented in order
 *				to enable grid editing.
 *
 * @param		aTableGrid		The table grid that sent the message.
 * @param		anObject		The new value for the item.
 * @param		columnIndex		A column in \c aTableGrid.
 * @param		rowIndex		A row in \c aTableGrid.
 *
 * @see			tableGrid:objectValueForColumn:row:
 */
- (void)tableGrid:(MBTableGrid *)aTableGrid setObjectValue:(id)anObject forColumn:(NSUInteger)columnIndex row:(NSUInteger)rowIndex;

@optional

/**
 * @brief		Returnd the width of given column.
 *
 * @param		aTableGrid		The table grid that sent the message.
 * @param		columnIndex		A column in \c aTableGrid.
 *
 * @see			tableGrid:setWidthForColumn:
 */
- (float)tableGrid:(MBTableGrid *)aTableGrid widthForColumn:(NSUInteger)columnIndex;

@optional

/**
 * @brief		Sets the column width for the given column.
 *
 * @param		aTableGrid		The table grid that sent the message.
 * @param		columnIndex		A column in \c aTableGrid.
 *
  * @see			tableGrid:widthForColumn:
 */
- (float)tableGrid:(MBTableGrid *)aTableGrid setWidthForColumn:(NSUInteger)columnIndex;

/**
 *  @brief      Asks the delegate for the tag color to be displayed on the very left of the specified row
 *
 *  @param      aTableGrid       The table grid that contains the cell.
 *  @param      rowIndexes       Row indexes of the cells being copied.
 */
- (NSColor *)tableGrid:(MBTableGrid *)aTableGrid tagColorForRow:(NSUInteger)rowIndex;

#pragma mark Group

@optional

/**
 *  @brief      Asks the delegate if the specified row is a group row. A group row has only one cell
 *              that spans across the entire row.
 *
 *  @param      aTableGrid       The table grid that contains the cell.
 *  @param      rowIndexes       Row indexes of the cells being copied.
 */
- (BOOL)tableGrid:(MBTableGrid *)aTableGrid isGroupRow:(NSUInteger)rowIndex;

/**
 *  @brief      Returns the cell for the group summary of the specified column & row.
 *
 * @details		Optional; if not implemented, or returns nil, an empty summary is
 *				displayed for this column & row.
 *
 *  @param      aTableGrid      The table grid that sent the message.
 *  @param      columnIndex     A column in \c aTableGrid.
 *  @param		rowIndex		A row in \c aTableGrid.
 *
 *  @return     The summary cell for the specified column & row.
 */
- (NSCell *)tableGrid:(MBTableGrid *)aTableGrid groupSummaryCellForColumn:(NSUInteger)columnIndex row:(NSUInteger)rowIndex;

/**
 *  @brief      A chance to update the cell for the group summary of the specified column & row.
 *
 * @details		Optional; if not implemented, the summary uses default attributes.
 *
 *  @param      aTableGrid      The table grid that sent the message.
 *  @param      cell            The summary cell for the specified column & row.
 *  @param      columnIndex     A column in \c aTableGrid.
 *  @param		rowIndex		A row in \c aTableGrid.
 */
- (void)tableGrid:(MBTableGrid *)aTableGrid updateGroupSummaryCell:(NSCell *)cell forColumn:(NSUInteger)columnIndex row:(NSUInteger)rowIndex;

/**
 * @brief		Returns the data object for the group summary of the specified column & row.
 *
 * @details		Optional; if not implemented, or returns nil, an empty summary is
 *				displayed for this column & row.
 *
 * @param		aTableGrid		The table grid that sent the message.
 * @param		columnIndex		A column in \c aTableGrid.
 * @param		rowIndex		A row in \c aTableGrid.
 *
 * @return		The object for the specified summary of the view.
 */
- (id)tableGrid:(MBTableGrid *)aTableGrid groupSummaryValueForColumn:(NSUInteger)columnIndex row:(NSUInteger)rowIndex;

/**
 * @}
 */

/**
 * @name		Header Values
 */
/**
 * @{
 */

#pragma mark Header

@optional

/**
 * @brief		Returns the value which should be displayed in the header
 *				for the specified column.
 *
 * @param		aTableGrid		The table grid that sent the message.
 * @param		columnIndex		The index of the column.
 *
 * @return		The header value for the column.
 *
 * @see			tableGrid:headerStringForRow:
 */
- (NSString *)tableGrid:(MBTableGrid *)aTableGrid headerStringForColumn:(NSUInteger)columnIndex;

/**
 * @brief		Returns the value which should be displayed in the header
 *				for the specified row.
 *
 * @param		aTableGrid		The table grid that sent the message.
 * @param		rowIndex		The index of the row.
 *
 * @return		The header value for the row.
 *
 * @see			tableGrid:headerStringForColumn:
 */
- (NSString *)tableGrid:(MBTableGrid *)aTableGrid headerStringForRow:(NSUInteger)rowIndex;

/**
 * @brief		Returns the value which should be displayed in the header
 *				for the specified row.
 *
 * @param		aTableGrid		The table grid that sent the message.
 * @param		rowIndex		The index of the row.
 *
 * @return		The header value for the row.
 *
 * @see			tableGrid:headerStringForColumn:
 */
- (MBSortDirection)tableGrid:(MBTableGrid *)aTableGrid sortDirectionForColumn:(NSUInteger)columnIndex;


/**
 * @}
 */

#pragma mark Footer

@optional

/**
 *  @brief      Returns the cell for the footer of the specified column.
 *
 * @details		Optional; if not implemented, or returns nil, an empty footer is
 *				displayed for this column.
 *
 *  @param      aTableGrid  The table grid that sent the message.
 *  @param      columnIndex A column in \c aTableGrid.
 *
 *  @return     The cell for the specified column footer.
 */
- (NSCell *)tableGrid:(MBTableGrid *)aTableGrid footerCellForColumn:(NSUInteger)columnIndex;

/**
 * @brief		Returns the data object for the footer of the specified column.
 *
 * @details		Optional; if not implemented, or returns nil, an empty footer is
 *				displayed for this column.
 *
 * @param		aTableGrid		The table grid that sent the message.
 * @param		columnIndex		A column in \c aTableGrid.
 *
 * @return		The object for the specified footer of the view.
 *
 * @see			tableGrid:setFooterValue:forColumn:
 */
- (id)tableGrid:(MBTableGrid *)aTableGrid footerValueForColumn:(NSUInteger)columnIndex;

/**
 * @brief		Sets the data object for the footer of the specified column.
 *
 * @details		Optional, but should be implemented for popup-based footer cells.
 *
 * @param		aTableGrid		The table grid that sent the message.
 * @param		anObject		The new value for the item.
 * @param		columnIndex		A column in \c aTableGrid.
 *
 * @see			tableGrid:footerValueForColumn:
 */
- (void)tableGrid:(MBTableGrid *)aTableGrid setFooterValue:(id)anObject forColumn:(NSUInteger)columnIndex;

#pragma mark -
#pragma mark Dragging

/**
 * @name		Dragging
 */
/**
 * @{
 */

@optional

#pragma mark Columns

/**
 * @brief		Returns a Boolean value that indicates whether a column drag operation is allowed.
 *
 * @details		Invoked by \c aTableGrid after it has been determined that a drag should begin,
 *				but before the drag has been started.
 *
 *				To refuse the drag, return \c NO. To start a drag, return \c YES and place the
 *				drag data onto pboard.
 *
 *				If this method returns \c YES, the table grid will automatically place the
 *				relavent information onto the pasteboard for simply reordering columns. Therefore,
 *				you only need to place data onto the pasteboard if you want to enable some other
 *				kind of dragging behavior (such as dragging into the finder as a CSV file).
 *
 * @param		aTableGrid		The table grid that sent the message.
 * @param		columnIndexes	An index set of column numbers that will be participating
 *								in the drag.
 * @param		pboard			The pasteboard to which to write the drag data.
 *
 * @return		\c YES if the drag operation is allowed, \c NO otherwise.
 *
 * @see			tableGrid:writeColumnsWithIndexes:toPasteboard:
 */
- (BOOL)tableGrid:(MBTableGrid *)aTableGrid writeColumnsWithIndexes:(NSIndexSet *)columnIndexes toPasteboard:(NSPasteboard *)pboard;

/**
 * @brief		Returns a Boolean value indicating whether the proposed columns can be
 *				moved to the specified index.
 * 
 * @details		This method is invoked by \c MBTableGrid during drag operations. It allows
 *				the data source to define valid drop targets for columns.
 *
 * @param		aTableGrid		The table grid that sent the message.
 * @param		columnIndexes	An index set describing the columns which
 *								are currently being dragged.
 * @param		index			The proposed index where the columns should
 *								be moved.
 *
 * @return		\c YES if \c columnIndex is a valid drop target, \c NO otherwise.
 *
 * @see			tableGrid:moveColumns:toIndex:
 * @see			tableGrid:canMoveRows:toIndex:
 */
- (BOOL)tableGrid:(MBTableGrid *)aTableGrid canMoveColumns:(NSIndexSet *)columnIndexes toIndex:(NSUInteger)index;

/**
 * @brief		Returns a Boolean value indicating whether the proposed columns
 *				were moved to the specified index.
 *
 * @details		The data source should take care of modifiying the data model to
 *				reflect the changed column order.
 *
 * @param		aTableGrid		The table grid that sent the message.
 * @param		columnIndexes	An index set describing the columns which were dragged.
 * @param		index			The index where the columns should be moved.
 *
 * @return		\c YES if the move was successful, otherwise \c NO.
 *
 * @see			tableGrid:canMoveColumns:toIndex:
 * @see			tableGrid:moveRows:toIndex:
 */
- (BOOL)tableGrid:(MBTableGrid *)aTableGrid moveColumns:(NSIndexSet *)columnIndexes toIndex:(NSUInteger)index;

#pragma mark Rows

/**
 * @brief		Returns a Boolean value that indicates whether a row drag operation is allowed.
 *
 * @details		Invoked by \c aTableGrid after it has been determined that a drag should begin,
 *				but before the drag has been started.
 *
 *				To refuse the drag, return \c NO. To start a drag, return \c YES and place the
 *				drag data onto \c pboard.
 *
 *				If this method returns \c YES, the table grid will automatically place the
 *				relavent information onto the pasteboard for simply reordering rows. Therefore,
 *				you only need to place data onto the pasteboard if you want to enable some other
 *				kind of dragging behavior (such as dragging into the finder as a CSV).
 *
 * @param		aTableGrid		The table grid that sent the message.
 * @param		rowIndexes		An index set of row numbers that will be participating
 *								in the drag.
 * @param		pboard			The pasteboard to which to write the drag data.
 *
 * @return		\c YES if the drag operation is allowed, \c NO otherwise.
 *
 * @see			tableGrid:writeColumnsWithIndexes:toPasteboard:
 */
- (BOOL)tableGrid:(MBTableGrid *)aTableGrid writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard *)pboard;

/**
 * @brief		Returns a Boolean value indicating whether the proposed rows can be
 *				moved to the specified index.
 * 
 * @details		This method is invoked by \c MBTableGrid during drag operations. It allows
 *				the data source to define valid drop targets for rows.
 *
 * @param		aTableGrid		The table grid that sent the message.
 * @param		rowIndexes		An index set describing the rows which
 *								are currently being dragged.
 * @param		index			The proposed index where the rows should
 *								be moved.
 *
 * @return		\c YES if \c rowIndex is a valid drop target, \c NO otherwise.
 *
 * @see			tableGrid:moveRows:toIndex:
 * @see			tableGrid:canMoveColumns:toIndex:
 */
- (BOOL)tableGrid:(MBTableGrid *)aTableGrid canMoveRows:(NSIndexSet *)rowIndexes toIndex:(NSUInteger)index;

/**
 * @brief		Returns a Boolean value indicating whether the proposed rows
 *				were moved to the specified index.
 *
 * @details		The data source should take care of modifiying the data model to
 *				reflect the changed row order.
 *
 * @param		aTableGrid		The table grid that sent the message.
 * @param		rowIndexes		An index set describing the rows which were dragged.
 * @param		index			The index where the rows should be moved.
 *
 * @return		\c YES if the move was successful, otherwise \c NO.
 *
 * @see			tableGrid:canMoveRows:toIndex:
 * @see			tableGrid:moveColumns:toIndex:
 */
- (BOOL)tableGrid:(MBTableGrid *)aTableGrid moveRows:(NSIndexSet *)rowIndexes toIndex:(NSUInteger)index;

#pragma mark Other Values

/**
 * @brief		Used by \c aTableGrid to determine a valid drop target.
 *
 * @param		aTableGrid		The table grid that sent the message.
 * @param		info			An object that contains more information about
 *								this dragging operation.
 * @param		columnIndex		The index of the proposed target column.
 * @param		rowIndex		The index of the proposed target row.
 *
 * @return		The dragging operation the data source will perform.
 *
 * @see			tableGrid:acceptDrop:column:row:
 */
- (NSDragOperation)tableGrid:(MBTableGrid *)aTableGrid validateDrop:(id <NSDraggingInfo>)info proposedColumn:(NSUInteger)columnIndex row:(NSUInteger)rowIndex;

/**
 * @brief		Invoked by \c aTableGrid when the mouse button is released over
 *				a table grid that previously decided to allow a drop.
 *
 * @details		The data source should incorporate the data from the dragging
 *				pasteboard in the implementation of this method. You can get the
 *				data for the drop operation from \c info using the \c draggingPasteboard
 *				method.
 *
 * @param		aTableGrid		The table grid that sent the message.
 * @param		info			An object that contains more information about
 *								this dragging operation.
 * @param		columnIndex		The index of the proposed target column.
 * @param		rowIndex		The index of the proposed target row.
 *
 * @return		\c YES if the drop was successful, otherwise \c NO.
 *
 * @see			tableGrid:validateDrop:proposedColumn:row:
 */
- (BOOL)tableGrid:(MBTableGrid *)aTableGrid acceptDrop:(id <NSDraggingInfo>)info column:(NSUInteger)columnIndex row:(NSUInteger)rowIndex;

#pragma mark -
#pragma mark Adding and Removing Rows

@optional

/**
 * @brief		Returns a Boolean value indicating whether the rows
 *				were successfully added.
 *
 * @details		The data source should take care of modifiying the data model to
 *				add the rows.
 *
 * @param		aTableGrid		The table grid that sent the message.
 * @param		numberOfRows	The number of rows to add.
 *
 * @return		\c YES if the add was successful, otherwise \c NO.
 *
 * @see			tableGrid:removeRows:
 */
- (BOOL)tableGrid:(MBTableGrid *)aTableGrid addRows:(NSUInteger)numberOfRows;

/**
 * @brief		Returns a Boolean value indicating whether the specified rows
 *				were removed.
 *
 * @details		The data source should take care of modifiying the data model to
 *				reflect the removed rows.
 *
 * @param		aTableGrid		The table grid that sent the message.
 * @param		rowIndexes		An index set describing the rows to remove.
 *
 * @return		\c YES if the removal was successful, otherwise \c NO.
 *
 * @see			tableGrid:addRows:
 */
- (BOOL)tableGrid:(MBTableGrid *)aTableGrid removeRows:(NSIndexSet *)rowIndexes;

/**
 * @}
 */

@end

#pragma mark -

/**
 * @brief		The delegate of an \c MBTableGrid object must adopt the
 *				\c MBTableGridDelegate protocol. Optional methods of the
 *				protocol allow the delegate to validate selections and data
 *				modifications and provide formatting information.
 */
@protocol MBTableGridDelegate <NSObject>

// Being a delegate, the entire protocol is optional
@optional

#pragma mark -
#pragma mark Managing Selections
/**
 * @name		Managing Selections
 */
/**
 * @{
 */

/**
 * @brief		Tells the delegate that the specified columns are about to be
 *				selected.
 *
 * @param		aTableGrid		The table grid object informing the delegate
 *								about the impending selection.
 * @param		indexPath		An index path locating the columns in \c aTableGrid.
 *
 * @return		An index path which confirms or alters the impending selection.
 *				Return an \c NSIndexPath object other than \c indexPath if you want
 *				different columns to be selected.
 *
 * @see			tableGrid:willSelectRowsAtIndexPath:
 */
- (NSIndexSet *)tableGrid:(MBTableGrid *)aTableGrid willSelectColumnsAtIndexPath:(NSIndexSet *)indexPath;

/**
 * @brief		Tells the delegate that the specified rows are about to be
 *				selected.
 *
 * @param		aTableGrid		The table grid object informing the delegate
 *								about the impending selection.
 * @param		indexPath		An index path locating the rows in \c aTableGrid.
 *
 * @return		An index path which confirms or alters the impending selection.
 *				Return an \c NSIndexPath object other than \c indexPath if you want
 *				different rows to be selected.
 *
 * @see			tableGrid:willSelectColumnsAtIndexPath:
 */
- (NSMutableIndexSet *)tableGrid:(MBTableGrid *)aTableGrid willSelectRowsAtIndexPath:(NSMutableIndexSet *)indexPath;

/**
 * @brief		Informs the delegate that the table grid's selection has changed.
 *
 * @details		\c aNotification is an \c MBTableGridDidChangeSelectionNotification.
 */
- (void)tableGridDidChangeSelection:(NSNotification *)aNotification DEPRECATED_ATTRIBUTE DEPRECATED_MSG_ATTRIBUTE("Use tableGridDidChangeColumnSelection: or tableGridDidChangeRowSelection methods instead.");

/**
 * @brief		Informs the delegate that the table grid's column selection has changed.
 *
 * @details		\c aNotification is an \c MBTableGridDidChangeSelectionNotification.
 */
- (void)tableGridDidChangeColumnSelection:(NSNotification *)aNotification;

/**
 * @brief		Informs the delegate that the table grid's row selection has changed.
 *
 * @details		\c aNotification is an \c MBTableGridDidChangeSelectionNotification.
 */
- (void)tableGridDidChangeRowSelection:(NSNotification *)aNotification;


/**
 * @brief		Tells the delegate that the specified column header was double-clicked
 *
 * @param		aTableGrid		The table grid object informing the delegate
 *								about the double-click event
 * @param		columnIndex		The selected column in \c aTableGrid.
 *
 *
 * @see			tableGrid:willSelectColumnsAtIndexPath:
 */
- (void)tableGrid:(MBTableGrid *)aTableGrid didDoubleClickColumn:(NSUInteger)columnIndex;

/**
 * @brief		Tells the delegate that the specified row header was double-clicked
 *
 * @param		aTableGrid		The table grid object informing the delegate
 *								about the double-click event
 * @param		columnIndex		The selected row in \c aTableGrid.
 */
- (void)tableGrid:(MBTableGrid *)aTableGrid didDoubleClickRow:(NSUInteger)rowIndex;

/**
* @ brief		Tells the delegate that the separator between column with index 'columnIndex' and that with 'columnIndex + 1' was double-clicked.
*
* @param		aTableGrid		The table grid object informing the delegate
*								about the double-click event
* @param		columnIndex		The selected column in \c aTableGrid.
*/
- (void)tableGrid:(MBTableGrid *)aTableGrid didDoubleClickSeparatorForColumn:(NSUInteger)columnIndex;


/**
 * @brief		Called when the sort indicator button is clicked
 *				in the column header.
 *
 * @param		aTableGrid		The table grid that sent the message.
 * @param		columnIndex		The index of the column.
 *
 */
- (void)tableGrid:(MBTableGrid *)aTableGrid didSortColumn:(NSUInteger)columnIndex;

/**
 * @}
 */

#pragma mark -
#pragma mark Moving Columns and Rows

/**
 * @name		Moving Columns and Rows
 */
/**
 * @{
 */

/**
 * @brief		Informs the delegate that columns were moved by user action in
 *				the table grid.
 *
 * @details		\c aNotification is an \c MBTableGridDidMoveColumnsNotification.
 *
 * @see			tableGridDidMoveRows:
 */
- (void)tableGridDidMoveColumns:(NSNotification *)aNotification;

/**
 * @brief		Informs the delegate that rows were moved by user action in
 *				the table grid.
 *
 * @details		\c aNotification is an \c MBTableGridDidMoveRowsNotification.
 *
 * @see			tableGridDidMoveColumns:
 */
- (void)tableGridDidMoveRows:(NSNotification *)aNotification;

/**
 * @brief		Called when the user lets go of the mouse after resizing a column.
 *
 * @details		\c aNotification is an \c MBTableGridDidResizeColumnNotification.
 *
 */
- (void)tableGridDidResizeColumn:(NSNotification *)aNotification;

/**
 * @}
 */

#pragma mark -
#pragma mark Editing Cells

/**
 * @name		Editing Cells
 */
/**
 * @{
 */

/**
 * @brief		Asks the delegate if the specified cell can be edited.
 *
 * @details		The delegate can implement this method to disallow editing of
 *				specific cells.
 *
 * @param		aTableGrid		The table grid which will edit the cell.
 * @param		columnIndex		The column of the cell.
 * @param		rowIndex		The row of the cell.
 *
 * @return		\c YES to permit \c aTableGrid to edit the specified cell, \c NO to deny permission.
 */
- (BOOL)tableGrid:(MBTableGrid *)aTableGrid shouldEditColumn:(NSUInteger)columnIndex row:(NSUInteger)rowIndex;

/**
 *  @brief      Asks the delegate if the specified cell can be filled.
 *
 *  @param      aTableGrid       The table grid that contains the cell.
 *  @param      columnIndexes    Column indexes of the cells being copied.
 *  @param      rowIndexes       Row indexes of the cells being copied.
 */
- (BOOL)tableGrid:(MBTableGrid *)aTableGrid shouldFillColumn:(NSUInteger)columnIndex row:(NSUInteger)rowIndex;

/**
 *  @brief      Informs the delegate that an invalid string was entered in a cell
 *
 *  @param      aTableGrid       The table grid that contains the cell
 *  @param      columnIndex      The column of the cell
 *  @param      rowIndex         The row of the cell
 *  @param      errorDescription The error description of why the string was invalid
 */
- (void)tableGrid:(MBTableGrid *)aTableGrid userDidEnterInvalidStringInColumn:(NSUInteger)columnIndex row:(NSUInteger)rowIndex errorDescription:(NSString *)errorDescription;

/**
 *  @brief      Informs the delegate that an accessory button was clicked
 *
 *  @param      aTableGrid       The table grid that contains the cell
 *  @param      columnIndex      The column of the cell
 *  @param      rowIndex         The row of the cell
 */
- (void)tableGrid:(MBTableGrid *)aTableGrid accessoryButtonClicked:(NSUInteger)columnIndex row:(NSUInteger)rowIndex;

/**
 *  @brief      Informs the delegate of the cells that should be copied to the clipboard.
 *
 *  @param      aTableGrid       The table grid that contains the cell.
 *  @param      columnIndexes    Column indexes of the cells being copied.
 *  @param      rowIndexes       Row indexes of the cells being copied.
 */
- (void)tableGrid:(MBTableGrid *)aTableGrid copyCellsAtColumns:(NSIndexSet *)columnIndexes rows:(NSIndexSet *)rowIndexes;

/**
 *  @brief      Informs the delegate of the cells that should be pasted from the clipboard.
 *
 *  @param      aTableGrid       The table grid that contains the cell.
 *  @param      columnIndexes    Column indexes of the cells being copied.
 *  @param      rowIndexes       Row indexes of the cells being copied.
 */
- (void)tableGrid:(MBTableGrid *)aTableGrid pasteCellsAtColumns:(NSIndexSet *)columnIndexes rows:(NSIndexSet *)rowIndexes;

/**
 * @}
 */

#pragma mark Adding Rows

/**
 * @brief		Tells the delegate that the specified rows were added.
 *
 * @param		aTableGrid		The table grid object informing the delegate
 *								about the added rows.
 * @param		rowIndexes		An index set describing the rows that were added.
 */
- (void)tableGrid:(MBTableGrid *)aTableGrid didAddRows:(NSIndexSet *)rowIndexes;

#pragma mark Undo

/**
 * @brief		Enables the delegate to provide an undo manager; if not implemented or nil is returned, the window's one is used.
 *
 * @param		aTableGrid		The table grid object.
 */
- (NSUndoManager *)undoManagerForTableGrid:(MBTableGrid *)aTableGrid;

#pragma mark Autosaving

/**
 * @brief		Asks the delegate for the previously autosaved column properties.
 *
 * @param		aTableGrid          The table grid object asking the delegate.
 * @return      The column properties that were autosaved.
 */
- (NSDictionary *)tableGridAutosavedColumnProperties:(MBTableGrid *)aTableGrid;

/**
 * @brief		Tells the delegate that the column properties was autosaved.
 *
 * @param		aTableGrid          The table grid object informing the delegate.
 * @param		columnProperties	The column properties being autosaved.
 */
- (void)tableGrid:(MBTableGrid *)aTableGrid didAutosaveColumnProperties:(NSDictionary *)columnProperties;

@end
