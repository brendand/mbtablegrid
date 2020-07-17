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
#import "MBTableGridHeaderCell.h"

@class MBTableGrid;

/**
 * @brief		\c MBTableGridHeaderView deals with the
 *				display and interaction with grid headers.
 */
@interface MBTableGridHeaderView : NSView {
	MBTableGridHeaderCell *headerCell;
	MBTableGridHeaderOrientation orientation;
	
	/* Dragging */
	NSInteger mouseDownItem;
	NSPoint mouseDownLocation;
    NSPoint lastMouseDraggingLocation;
	BOOL shouldDragItems;
	BOOL isInDrag;
    
    /* Resizing */
    NSMutableArray *trackingAreas;
    BOOL canResize;
    BOOL isResizing;
    NSUInteger draggingColumnIndex;
	
	NSMutableDictionary *_groupRowIndexes;
	
}

/**
 * @name		The Grid View
 */
/**
 * @{
 */

/**
 * @brief		Returns the \c MBTableGrid the receiver 
 *				belongs to.
 */
- (MBTableGrid *)tableGrid;

/**
 * @}
 */

/**
 * @name		Display Properties
 */
/**
 * @{
 */

/**
 * @brief		The orientation of the receiver.
 */
@property (nonatomic) MBTableGridHeaderOrientation orientation;

/**
 * @brief		The ascending sort indicator image for the header cell
 */
@property (nonatomic, strong) NSImage *sortAscendingImage;

/**
 * @brief		The descending sort indicator image for the header cell
 */
@property (nonatomic, strong) NSImage *sortDescendingImage;

/**
 * @brief		The no sort indicator image for the header cell
 */
@property (nonatomic, strong) NSImage *sortUndeterminedImage;

/**
 * @brief		The autosave name for this grid
 */
@property (nonatomic) NSString *autosaveName;

/**
 * @brief		Sets the default font to use for content cells
 *
 */
@property(nonatomic, strong) NSFont *defaultCellFont;


/**
 * @brief		Indicates whether the receiver is enabled
 *
 * @details		The default is \c YES.
 *
 * @return		\c YES if the receiver allows the user
 *				to select any rows.
 *				Otherwise, \c NO.
 */
@property(nonatomic) BOOL isEditable;


@property (nonatomic, strong) NSMutableDictionary *columnAutoSaveProperties;

/**
 * @}
 */

/**
 * @name		Accessing Cells
 */
/**
 * @{
 */

/**
 * @brief		The receiver's cell.
 *
 * @details		\c MBTableGridHeaderView uses its header cell to
 *				draw row or column headers.
 *
 *				To change the appearance of the headers, you can
 *				use your own \c MBTableGridHeaderCell subclass.
 */
@property(strong) MBTableGridHeaderCell *headerCell;

/**
 * @}
 */

/**
 * @name		Layout Support
 */
/**
 * @{
 */

/**
 * @brief		Returns the rectangle containing the header tile for
 *				the column at \c columnIndex.
 * @param		columnIndex	The index of the column containing the
 *							header whose rectangle you want.
 * @return		A rectangle locating the header for the column at
 *				\c columnIndex. Returns \c NSZeroRect if \c columnIndex 
 *				lies outside the range of valid column indices for the 
 *				receiver.
 * @see			headerRectOfRow:
 */
- (NSRect)headerRectOfColumn:(NSUInteger)columnIndex;

/**
 * @brief		Returns the rectangle containing the header tile for
 *				the row at \c rowIndex.
 * @param		rowIndex	The index of the row containing the
 *							header whose rectangle you want.
 * @return		A rectangle locating the header for the row at
 *				\c rowIndex. Returns \c NSZeroRect if \c rowIndex 
 *				lies outside the range of valid column indices for the 
 *				receiver.
 * @see			headerRectOfColumn:
 */
- (NSRect)headerRectOfRow:(NSUInteger)rowIndex;

/**
 * @}
 */

@end
