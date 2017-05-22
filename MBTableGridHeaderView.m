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

#import "MBTableGridHeaderView.h"
#import "MBTableGrid.h"
#import "MBTableGridContentView.h"

NSString* kAutosavedColumnWidthKey = @"AutosavedColumnWidth";
NSString* kAutosavedColumnIndexKey = @"AutosavedColumnIndex";
NSString* kAutosavedColumnHiddenKey = @"AutosavedColumnHidden";

#define kSortIndicatorXInset		4.0  	/* Number of pixels to inset the drawing of the indicator from the right edge */

@interface MBTableGrid (Private)
- (NSString *)_headerStringForColumn:(NSUInteger)columnIndex;
- (NSString *)_headerStringForRow:(NSUInteger)rowIndex;
- (MBTableGridContentView *)_contentView;
- (void)_dragColumnsWithEvent:(NSEvent *)theEvent;
- (void)_dragRowsWithEvent:(NSEvent *)theEvent;
- (void)sortButtonClickedOnColumn:(NSUInteger)columnIndex;
- (BOOL)_isGroupRow:(NSUInteger)rowIndex;
- (NSColor *)_tagColorForRow:(NSUInteger)rowIndex;
- (MBSortDirection)_sortDirectionForColumn:(NSUInteger)columnIndex;
@end

@interface MBTableGridHeaderView()

@property (nonatomic, weak) MBTableGrid *cachedTableGrid;

@end

@implementation MBTableGridHeaderView

@synthesize orientation;
@synthesize headerCell;

- (id)initWithFrame:(NSRect)frameRect
{
	if(self = [super initWithFrame:frameRect]) {
		// Setup the header cell
		headerCell = [[MBTableGridHeaderCell alloc] init];
		
		// We haven't clicked any item
		mouseDownItem = -1;
		
		// Initially, we're not dragging anything
		shouldDragItems = NO;
		isInDrag = NO;
        
        // No resize at start
        canResize = NO;
        isResizing = NO;
	}
	return self;
}

- (void)drawRect:(NSRect)rect
{
	if (self.orientation == MBTableHeaderHorizontalOrientation) {
        
		// Draw the column headers
		NSUInteger numberOfColumns = [self tableGrid].numberOfColumns;
		[headerCell setOrientation:self.orientation];
		NSUInteger column = 0;
		while (column < numberOfColumns) {
			NSRect headerRect = [self headerRectOfColumn:column];
			
			// Only draw the header if we need to
			if ([self needsToDrawRect:headerRect]) {
				// Check if any part of the selection is in this column
				NSIndexSet *selectedColumns = [[self tableGrid] selectedColumnIndexes];
				if ([selectedColumns containsIndex:column]) {
					[headerCell setState:NSOnState];
				} else {
					[headerCell setState:NSOffState];
				}
				
				MBSortDirection sortDirection = [[self tableGrid] _sortDirectionForColumn:column];
				switch (sortDirection) {
					case MBSortAscending:
						[headerCell setSortIndicatorImage:self.sortAscendingImage];
						break;
					case MBSortDescending:
						[headerCell setSortIndicatorImage:self.sortDescendingImage];
						break;
					case MBSortUndetermined:
						[headerCell setSortIndicatorImage:self.sortUndeterminedImage];
						break;
					default:
						[headerCell setSortIndicatorImage:nil];
						break;
				}
				
				NSString *stringValue = [[self tableGrid] _headerStringForColumn:column];
				if (stringValue) {
					[headerCell setStringValue:stringValue];
				}
                
                BOOL isFrozenColumn = self != [self tableGrid].frozenColumnHeaderView && [[self tableGrid] isFrozenColumn:column];
                
                if (isFrozenColumn) {
                    [[NSColor whiteColor] set];
                    NSRectFill(headerRect);
                } else {
                    [headerCell drawWithFrame:headerRect inView:self];
                }
                
			}
			
			column++;
		}
        
	} else if (self.orientation == MBTableHeaderVerticalOrientation) {
		
		// Draw the row headers
		NSUInteger numberOfRows = [self tableGrid].numberOfRows;
		[headerCell setOrientation:self.orientation];
		NSUInteger row = 0;
		NSUInteger rowNumber = 0;
		while(row < numberOfRows) {
			NSRect headerRect = [self headerRectOfRow:row];
			BOOL isGroupRow = [[[[self tableGrid] contentView] groupRowIndexes] objectForKey:@(row)] != nil;

			// Only draw the header if we need to
			if ([self needsToDrawRect:headerRect]) {
                
				// Check if any part of the selection is in this column
				NSIndexSet *selectedRows = [[self tableGrid] selectedRowIndexes];
				if ([selectedRows containsIndex:row]) {
					[headerCell setState:NSOnState];
				} else {
					[headerCell setState:NSOffState];
				}
				
				if (!isGroupRow) {
					NSString *headerValue = [[self tableGrid] _headerStringForRow:rowNumber];
					[headerCell setStringValue:headerValue];
				} else {
					[headerCell setStringValue:@""];
				}
				
				NSColor *rowTagColor = [[self tableGrid] _tagColorForRow:row];
				headerCell.rowTagColor = rowTagColor;
				
				[headerCell drawWithFrame:headerRect inView:self];
			}
			
			if (!isGroupRow) {
				rowNumber++;
			}
			row++;
		}
	}
}

- (BOOL)isFlipped
{
	return YES;
}

- (void)updateTrackingAreas
{
    [super updateTrackingAreas];
    
    if (self.orientation == MBTableHeaderHorizontalOrientation) {
        // Remove all tracking areas
        if (trackingAreas) {
            for (NSTrackingArea *trackingArea in trackingAreas) {
                [self removeTrackingArea:trackingArea];
            }
        }
        
        // reset tracking array
        trackingAreas = [NSMutableArray array];
        
        NSUInteger numberOfColumns = [self tableGrid].numberOfColumns;
        NSUInteger column = 0;
        
        while (column < numberOfColumns) {
            NSRect headerRect = [self headerRectOfColumn:column];
            
            // Create new tracking area for resizing columns
            NSRect resizeRect = NSMakeRect(NSMinX(headerRect) + NSWidth(headerRect) - 2, NSMinY(headerRect), 5, NSHeight(headerRect));
            NSTrackingArea *resizeTrackingArea = [[NSTrackingArea alloc] initWithRect:resizeRect options:(NSTrackingMouseEnteredAndExited | NSTrackingActiveAlways) owner:self userInfo:nil];
            
            // keep track of tracking areas and add tracking to view
            [trackingAreas addObject:resizeTrackingArea];
            [self addTrackingArea:resizeTrackingArea];
            
            column++;
        }
    }
}

- (void)mouseDown:(NSEvent *)theEvent
{
    
	// Get the location of the click
	NSPoint loc = [self convertPoint:[theEvent locationInWindow] fromView:nil];
	mouseDownLocation = loc;
	NSInteger column = [[self tableGrid] columnAtPoint:[self convertPoint:loc toView:[self tableGrid]]];
	NSInteger row = [[self tableGrid] rowAtPoint:[self convertPoint:loc toView:[self tableGrid]]];
	
	if (self.orientation == MBTableHeaderVerticalOrientation && [[self tableGrid] _isGroupRow:row]) {
		return;
	}
	
    if (canResize) {
        
        // Set resize column index
        draggingColumnIndex = [[self tableGrid] columnAtPoint:[self convertPoint:NSMakePoint(loc.x - 3, loc.y) toView:[self tableGrid]]];
        lastMouseDraggingLocation = loc;
        isResizing = YES;
        
    } else {
    
        // For single clicks,
        if([theEvent clickCount] == 1) {
            if(([theEvent modifierFlags] & NSShiftKeyMask) && [self tableGrid].allowsMultipleSelection) {
                // If the shift key was held down, extend the selection
            } else {
                // No modifier keys, so change the selection
                if(self.orientation == MBTableHeaderHorizontalOrientation) {
                    mouseDownItem = column;
					
					if ([[self tableGrid] _sortDirectionForColumn:column]) {
						NSRect cellFrame = [self headerRectOfColumn:column];
						NSCellHitResult hitResult = [self.headerCell hitTestForEvent:theEvent inRect:cellFrame ofView:self];
						if (hitResult != NSCellHitNone) {
							[[self tableGrid] sortButtonClickedOnColumn:column];
						} else {
							if([[self tableGrid].selectedColumnIndexes containsIndex:column] && [[self tableGrid].selectedRowIndexes count] == [self tableGrid].numberOfRows) {
								// Allow the user to drag the column
								shouldDragItems = YES;
							} else {
								[self tableGrid].selectedColumnIndexes = [NSIndexSet indexSetWithIndex:column];
								// Select every row
								
								NSMutableIndexSet *indexSet = [[NSMutableIndexSet alloc] init];
								NSInteger rowCount = [self tableGrid].numberOfRows;
								
								for (NSInteger row = 0; row < rowCount; row++) {
									BOOL isGroupRow = [[[[self tableGrid] contentView] groupRowIndexes] objectForKey:@(row)] != nil;
									if (!isGroupRow) {
										[indexSet addIndex:row];
									}
								}
								
								[self tableGrid].selectedRowIndexes = indexSet;
								
							}
						}
					}
					
					
				} else if(self.orientation == MBTableHeaderVerticalOrientation) {
                    mouseDownItem = row;
                    
                    if([[self tableGrid].selectedRowIndexes containsIndex:row] && [[self tableGrid].selectedColumnIndexes count] == [self tableGrid].numberOfColumns) {
                        // Allow the user to drag the row
                        shouldDragItems = YES;
                    } else {
                        [self tableGrid].selectedRowIndexes = [NSMutableIndexSet indexSetWithIndex:row];
                        // Select every column
                        [self tableGrid].selectedColumnIndexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0,[self tableGrid].numberOfColumns)];
                    }
                }
            }
        } else if ([theEvent clickCount] == 2) {
			
		}
        
        // Pass the event back to the MBTableGrid (Used to give First Responder status)
        [[self tableGrid] mouseDown:theEvent];
        
    }
}

- (void)mouseDragged:(NSEvent *)theEvent
{	
	// Get the location of the mouse
	NSPoint loc = [self convertPoint:[theEvent locationInWindow] fromView:nil];
	CGFloat deltaX = fabs(loc.x - mouseDownLocation.x);
	CGFloat deltaY = fabs(loc.y - mouseDownLocation.y);
	    
    if (canResize) {
        
        [[NSCursor resizeLeftRightCursor] set];
        [[self window] disableCursorRects];
        
        // Set drag distance
		CGFloat dragDistance = loc.x - lastMouseDraggingLocation.x;
		
		lastMouseDraggingLocation = loc;
		
		// Resize column and resize views
		
		if (draggingColumnIndex != NSNotFound) {
			CGFloat offset = [self.tableGrid resizeColumnWithIndex:draggingColumnIndex withDistance:dragDistance location:loc];
			lastMouseDraggingLocation.x += offset;
			
			if (offset != 0.0) {
				[[NSCursor resizeRightCursor] set];
			} else {
				[[NSCursor resizeLeftRightCursor] set];
			}
		}
		
    } else {
		
        // Drag operation doesn't start until the mouse has moved more than 5 points
        CGFloat dragThreshold = 5.0;
        
        // If we've met the conditions for a drag operation,
        if (shouldDragItems && mouseDownItem >= 0 && (deltaX >= dragThreshold || deltaY >= dragThreshold)) {
            if (self.orientation == MBTableHeaderHorizontalOrientation) {
                [[self tableGrid] _dragColumnsWithEvent:theEvent];
            } else if (self.orientation == MBTableHeaderVerticalOrientation) {
                [[self tableGrid] _dragRowsWithEvent:theEvent];
            }
            
            // We've responded to the drag, so don't respond again during this drag session
            shouldDragItems = NO;
            
            // Flag that we are currently dragging items
            isInDrag = YES;
        }
        // Otherwise, extend the selection (if possible)
        else if (mouseDownItem >= 0 && !isInDrag && !shouldDragItems) {
            // Determine which item is under the mouse
            NSInteger itemUnderMouse = -1;
            if (self.orientation == MBTableHeaderHorizontalOrientation) {
                itemUnderMouse = [[self tableGrid] columnAtPoint:[self convertPoint:loc toView:[self tableGrid]]];
            } else if(self.orientation == MBTableHeaderVerticalOrientation) {
                itemUnderMouse = [[self tableGrid] rowAtPoint:[self convertPoint:loc toView:[self tableGrid]]];
            }
            
            // If there's nothing under the mouse, bail out (something went wrong)
            if (itemUnderMouse < 0 || itemUnderMouse == NSNotFound)
                return;
            
            // Calculate the range of items to select
            NSInteger firstItemToSelect = mouseDownItem;
            NSInteger numberOfItemsToSelect = itemUnderMouse - mouseDownItem + 1;
            if(itemUnderMouse < mouseDownItem) {
                firstItemToSelect = itemUnderMouse;
                numberOfItemsToSelect = mouseDownItem - itemUnderMouse + 1;
            }
			
			// Set the selected items
			if (firstItemToSelect != NSNotFound && firstItemToSelect >= 0 && numberOfItemsToSelect > 0 && numberOfItemsToSelect != NSNotFound) {
				if (self.orientation == MBTableHeaderHorizontalOrientation) {
					[self tableGrid].selectedColumnIndexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(firstItemToSelect, numberOfItemsToSelect)];
				} else if (self.orientation == MBTableHeaderVerticalOrientation) {
					[self tableGrid].selectedRowIndexes = [NSMutableIndexSet indexSetWithIndexesInRange:NSMakeRange(firstItemToSelect, numberOfItemsToSelect)];
				}
			}
		}
		
    }
}

- (void)mouseUp:(NSEvent *)theEvent
{
    
    if (canResize) {
		
		[self autoSaveColumnProperties];
		
		NSString *draggedColumn = [NSString stringWithFormat:@"C-%lu", draggingColumnIndex];
		
		NSNumber *width = columnAutoSaveProperties[draggedColumn][kAutosavedColumnWidthKey];
		NSDictionary *userInfo = nil;
		
		if (width) {
			userInfo = @{@"columnIndex" : @(draggingColumnIndex),
						 @"width" : width};
		}
		
		isResizing = NO;
		
        [[self window] enableCursorRects];
        [[self window] resetCursorRects];
        
		// update cache of column rects
		
		[[self tableGrid].columnRects removeAllObjects];
		
		if ([[[self tableGrid] delegate] respondsToSelector:@selector(tableGridDidResizeColumn:)]) {
		
			// Post the notification
			
			[[NSNotificationCenter defaultCenter] postNotificationName:MBTableGridDidResizeColumnNotification object:[self tableGrid] userInfo:userInfo];

		}
		
    } else {
        
        // If we only clicked on a header that was part of a bigger selection, select it
        if(shouldDragItems && !isInDrag) {
            if (self.orientation == MBTableHeaderHorizontalOrientation) {
                [self tableGrid].selectedColumnIndexes = [NSIndexSet indexSetWithIndex:mouseDownItem];
                // Select every row
				NSMutableIndexSet *indexSet = [[NSMutableIndexSet alloc] init];
				
				NSInteger rowCount = [self tableGrid].numberOfRows;
				for (NSInteger row = 0; row < rowCount; row++) {
					BOOL isGroupRow = [[[[self tableGrid] contentView] groupRowIndexes] objectForKey:@(row)] != nil;
					if (!isGroupRow) {
						[indexSet addIndex:row];
					}
				}
				
				[self tableGrid].selectedRowIndexes = indexSet;
				
				
            } else if (self.orientation == MBTableHeaderVerticalOrientation) {
                [self tableGrid].selectedRowIndexes = [NSMutableIndexSet indexSetWithIndex:mouseDownItem];
                // Select every column
                [self tableGrid].selectedColumnIndexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0,[self tableGrid].numberOfColumns)];
            }
        }
        // Reset the pressed item
        mouseDownItem = -1;
        
        // In case it didn't already happen, reset the drag flags
        shouldDragItems = NO;
        isInDrag = NO;
        
        // Reset the location
        mouseDownLocation = NSZeroPoint;
        
    }
}

- (void)mouseEntered:(NSEvent *)theEvent
{
    
    // Change to resize cursor
    [[NSCursor resizeLeftRightCursor] set];
    canResize = YES;
    
}

- (void)mouseExited:(NSEvent *)theEvent
{
    
    
    if (!isResizing) {
        
        // Revert to normal cursor
        [[NSCursor arrowCursor] set];
        canResize = NO;
        
    }
    
}

- (NSRect)adjustScroll:(NSRect)proposedVisibleRect
{
    NSRect modifiedRect = proposedVisibleRect;
    
    if (self.orientation == MBTableHeaderHorizontalOrientation) {
        modifiedRect.origin.y = 0.0;
    }
    
    return modifiedRect;
}

- (void)autoSaveColumnProperties {
	if (!columnAutoSaveProperties) {
		columnAutoSaveProperties = [NSMutableDictionary dictionary];
	}
	
	[self.tableGrid.columnRects enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
		NSValue *rectValue = obj;
		NSRect rect = [rectValue rectValue];
		NSDictionary *columnDict = @{kAutosavedColumnWidthKey : @(rect.size.width),
									 kAutosavedColumnHiddenKey : @NO};
		columnAutoSaveProperties[[NSString stringWithFormat:@"C-%@", key]] = columnDict;
	}];
	
	if (self.autosaveName) {
		[self.documentDefaults setObject:columnAutoSaveProperties.mutableCopy forKey:self.autosaveName];
	}
}

#pragma mark -
#pragma mark Subclass Methods

- (MBTableGrid *)tableGrid
{
    if (!self.cachedTableGrid) {
        NSScrollView *scrollView = self.enclosingScrollView;
        
        // Will be nil for the floating view:
        if (!scrollView) {
            scrollView = (NSScrollView *)self.superview.superview;
        }
        
        self.cachedTableGrid = (MBTableGrid *)scrollView.superview;
    }
    
    return self.cachedTableGrid;
}

#pragma mark Layout Support

- (NSRect)headerRectOfColumn:(NSUInteger)columnIndex
{
	NSRect rect = [[[self tableGrid] _contentView] rectOfColumn:columnIndex];
	rect.size.height = MBTableGridColumnHeaderHeight;
	
	return rect;
}

- (NSRect)headerRectOfRow:(NSUInteger)rowIndex
{
	NSRect rect = [[[self tableGrid] _contentView] rectOfRow:rowIndex];
	rect.size.width = MBTableGridRowHeaderWidth;
	
	return rect;
}

@end
