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

#import "MBTableGridController.h"
#import "MBTableGridCell.h"
#import "MBPopupButtonCell.h"
#import "MBButtonCell.h"
#import "MBImageCell.h"
#import "MBLevelIndicatorCell.h"
#import "MBFooterTextCell.h"
#import "MBFooterPopupButtonCell.h"

NSString* kAutosavedColumnWidthKey = @"AutosavedColumnWidth";
NSString* kAutosavedColumnIndexKey = @"AutosavedColumnIndex";
NSString* kAutosavedColumnHiddenKey = @"AutosavedColumnHidden";

NSString * const PasteboardTypeColumnClass = @"pasteboardTypeColumnClass";

NSString * const ColumnCurrency = @"currency";
NSString * const ColumnDate = @"date";
NSString * const ColumnPopup = @"popup";
NSString * const ColumnCheckbox = @"checkbox";
NSString * const ColumnText1 = @"text1";
NSString * const ColumnText2 = @"text2";
NSString * const ColumnImage = @"image";
NSString * const ColumnText3 = @"text3";
NSString * const ColumnRating = @"rating";
NSString * const ColumnText4 = @"text4";

@interface NSMutableArray (SwappingAdditions)
- (void)moveObjectsAtIndexes:(NSIndexSet *)indexes toIndex:(NSUInteger)index;
@end

@interface MBTableGridController()
@property (nonatomic, strong) MBPopupButtonCell *popupCell;
@property (nonatomic, strong) MBTableGridCell *textCell;
@property (nonatomic, strong) MBButtonCell *checkboxCell;
@property (nonatomic, strong) MBImageCell *imageCell;
@property (nonatomic, strong) MBLevelIndicatorCell *ratingCell;
@property (nonatomic, strong) MBFooterTextCell *footerTextCell;
@property (nonatomic, strong) MBFooterPopupButtonCell *footerPopupCell;
@property (nonatomic, strong) NSDictionary *columnWidths;
@property (nonatomic, strong) NSMutableArray *columnIdentifiers;
@end

@implementation MBTableGridController

- (void)awakeFromNib 
{
    
    
    columnSampleWidths = @[@40, @50, @60, @70, @80, @90, @100, @110, @120, @130];
    
	columns = [[NSMutableArray alloc] initWithCapacity:10];
    
    self.columnIdentifiers = [@[ColumnCurrency, ColumnDate, ColumnPopup, ColumnCheckbox, ColumnText1, ColumnText2, ColumnImage, ColumnText3, ColumnRating, ColumnText4] mutableCopy];
    
	NSDictionary *infoDict = [[NSBundle mainBundle] infoDictionary];
	NSString *gridComponentID = [infoDict objectForKey:@"GridComponentID"];

	tableGrid.autosaveName = [NSString stringWithFormat:@"MBTableGrid Columns records-table-%@", gridComponentID];
	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	self.columnWidths = [defaults objectForKey:tableGrid.autosaveName];

	NSNumberFormatter *decimalFormatter = [[NSNumberFormatter alloc] init];
	decimalFormatter.numberStyle = NSNumberFormatterCurrencyStyle;
	decimalFormatter.lenient = YES;
	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	dateFormatter.dateStyle = NSDateFormatterShortStyle;
	dateFormatter.timeStyle = NSDateFormatterNoStyle;
    formatters = @{ColumnCurrency : decimalFormatter, ColumnDate : dateFormatter};
    
	// Add 10 columns & rows
    [self tableGrid:tableGrid addColumns:10 shouldReload:NO];
    [self tableGrid:tableGrid addRows:5000 shouldReload:NO];
	
	[tableGrid setSortAscendingImage:[NSImage imageNamed:@"sort-asc"] sortDescendingImage:[NSImage imageNamed:@"sort-desc"] sortUndeterminedImage:nil];
	
	[tableGrid reloadData];
	
	// Register to receive text strings
	[tableGrid registerForDraggedTypes:@[NSStringPboardType]];
	
	self.popupCell = [[MBPopupButtonCell alloc] initTextCell:@""];
	self.popupCell.bordered = NO;
	self.popupCell.controlSize = NSSmallControlSize;
	self.popupCell.font = [NSFont systemFontOfSize:[NSFont systemFontSizeForControlSize:NSSmallControlSize]];
	NSArray *availableObjectValues = @[ @"Action & Adventure", @"Comedy", @"Romance", @"Thriller" ];
	NSMenu *menu = [[NSMenu alloc] init];
    menu.font = self.popupCell.font;
	for (NSString *objectValue in availableObjectValues) {
		NSMenuItem *item = [menu addItemWithTitle:objectValue action:@selector(cellPopupMenuItemSelected:) keyEquivalent:@""];
		[item setTarget:self];
	}
	self.popupCell.menu = menu;
	
	
	self.textCell = [[MBTableGridCell alloc] initTextCell:@""];
	
	self.checkboxCell = [[MBButtonCell alloc] init];
	self.checkboxCell.state = NSOffState;
	[self.checkboxCell setButtonType:NSSwitchButton];
	
	self.imageCell = [[MBImageCell alloc] init];
	
	self.ratingCell = [[MBLevelIndicatorCell alloc] initWithLevelIndicatorStyle:NSRatingLevelIndicatorStyle];
	self.ratingCell.editable = YES;
	
    self.footerTextCell = [[MBFooterTextCell alloc] initTextCell:@""];
    
    self.footerPopupCell = [[MBFooterPopupButtonCell alloc] initTextCell:@""];
    self.footerPopupCell.bordered = NO;
    self.footerPopupCell.controlSize = NSSmallControlSize;
    self.footerPopupCell.font = [NSFont systemFontOfSize:[NSFont systemFontSizeForControlSize:NSSmallControlSize]];
    
    menu = [NSMenu new];
    menu.font = self.footerPopupCell.font;
    [menu addItemWithTitle:@"No Options" action:nil keyEquivalent:@""];
    self.footerPopupCell.menu = menu;
}

-(NSString *) genRandStringLength: (int) len
{
    
    // Create alphanumeric table
    NSString *letters = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
    
    // Create mutable string
    NSMutableString *randomString = [NSMutableString stringWithCapacity: len];
    
    // Add random character to string
    for (int i=0; i<len; i++) {
        
        [randomString appendFormat: @"%C", [letters characterAtIndex: arc4random() % [letters length]]];
        
    }
    
    // return string
    return randomString;
}

#pragma mark -
#pragma mark Protocol Methods

#pragma mark MBTableGridDataSource

- (NSUInteger)numberOfRowsInTableGrid:(MBTableGrid *)aTableGrid
{
    
	if ([columns count] > 0) {
		return [columns[0] count];
	}
	return 0;
}


- (NSUInteger)numberOfColumnsInTableGrid:(MBTableGrid *)aTableGrid
{
	return [columns count];
}

- (NSString *)tableGrid:(MBTableGrid *)aTableGrid headerStringForColumn:(NSUInteger)columnIndex {
	return [NSString stringWithFormat:@"Column %lu", columnIndex];
}

- (id)tableGrid:(MBTableGrid *)aTableGrid objectValueForColumn:(NSUInteger)columnIndex row:(NSUInteger)rowIndex
{
	if (columnIndex >= [columns count]) {
		return nil;
	}
	
	NSMutableArray *column = columns[columnIndex];
	
	if (rowIndex >= [column count]) {
		return nil;
	}
	
	id value = nil;
	
    NSString *columnIdentifier = self.columnIdentifiers[columnIndex];
    
	if (columnIdentifier == ColumnImage) {
		value = [NSImage imageNamed:@"rose.jpg"];
	} else {
		value = column[rowIndex];
	}
	
	return value;
}

- (BOOL)tableGrid:(MBTableGrid *)aTableGrid shouldEditColumn:(NSUInteger)columnIndex row:(NSUInteger)rowIndex {
	
	// can't edit the sample image column
	
//	if (columnIndex == 6) {
//		return NO;
//	} else {
//		return YES;
//	}
	
	return YES;
}

- (NSFormatter *)tableGrid:(MBTableGrid *)aTableGrid formatterForColumn:(NSUInteger)columnIndex
{
    NSString *columnIdentifier = self.columnIdentifiers[columnIndex];
    
	return formatters[columnIdentifier];
}

- (NSCell *)tableGrid:(MBTableGrid *)aTableGrid cellForColumn:(NSUInteger)columnIndex {
	NSCell *cell = nil;
    
    NSString *columnIdentifier = self.columnIdentifiers[columnIndex];
    
    if (columnIdentifier == ColumnPopup) {
		cell = self.popupCell;
	} else if (columnIdentifier == ColumnCheckbox) {
		cell = self.checkboxCell;
	} else if (columnIdentifier == ColumnImage) {
		cell = self.imageCell;
	} else if (columnIdentifier == ColumnRating) {
		cell = self.ratingCell;
	} else {
		cell = self.textCell;
	}
	
	return cell;
}

- (NSImage *)tableGrid:(MBTableGrid *)aTableGrid accessoryButtonImageForColumn:(NSUInteger)columnIndex row:(NSUInteger)row {
	
    NSString *columnIdentifier = self.columnIdentifiers[columnIndex];
    
	if (columnIdentifier != ColumnImage) {
		return nil;
	}
	
	if (tableGrid.selectedRowIndexes.count == 1 && [tableGrid.selectedRowIndexes containsIndex:row]) {
		NSImage *buttonImage = [NSImage imageNamed:@"acc-quicklook"];
		
		return buttonImage;
	} else {
		return nil;
	}
	
}

- (NSArray *)tableGrid:(MBTableGrid *)aTableGrid availableObjectValuesForColumn:(NSUInteger)columnIndex {
    
    NSString *columnIdentifier = self.columnIdentifiers[columnIndex];
    
	if (columnIdentifier == ColumnPopup) {
		return @[ @"Action & Adventure", @"Comedy", @"Romance", @"Thriller" ];
	}
	return nil;
}

- (NSArray *)tableGrid:(MBTableGrid *)aTableGrid autocompleteValuesForEditString:(NSString *)editString column:(NSUInteger)columnIndex row:(NSUInteger)rowIndex {
    
    NSString *columnIdentifier = self.columnIdentifiers[columnIndex];
    
    if (columnIdentifier == ColumnCurrency || columnIdentifier == ColumnDate || columnIdentifier == ColumnPopup || columnIdentifier == ColumnCheckbox || columnIdentifier == ColumnImage || columnIdentifier == ColumnRating || columnIndex >= [columns count]) {
        return nil;
    }
    
    NSMutableArray *completions = [NSMutableArray array];
    NSMutableArray *column = columns[columnIndex];
    
    for (NSString *value in column) {
        if ([[value lowercaseString] hasPrefix:[editString lowercaseString]]) {
            [completions addObject:value];
        }
    }
    
    return completions;
}

- (void)tableGrid:(MBTableGrid *)aTableGrid setObjectValue:(id)anObject forColumn:(NSUInteger)columnIndex row:(NSUInteger)rowIndex {
	if (columnIndex >= [columns count]) {
		return;
	}	
	
	NSMutableArray *column = columns[columnIndex];
	
	if (rowIndex >= [column count]) {
		return;
	}
	
	if (anObject == nil) {
		anObject = @"";
	}
	
	column[rowIndex] = anObject;
	
//	NSLog(@"col: %lu, row: %lu, obj: %@", columnIndex, rowIndex, anObject);

}


- (float)tableGrid:(MBTableGrid *)aTableGrid setWidthForColumn:(NSUInteger)columnIndex {
    
//    return (columnIndex < columnSampleWidths.count) ? [columnSampleWidths[columnIndex] floatValue] : 60;
	
	CGFloat width = 80;
	
	NSString *columnName = [NSString stringWithFormat:@"C-%lu", (long)columnIndex];
	NSDictionary *columnProperty = self.columnWidths[columnName];
	
	if (columnProperty) {
		width =  [columnProperty[kAutosavedColumnWidthKey] floatValue];
	}
	
	return width;
	
}

-(NSColor *)tableGrid:(MBTableGrid *)aTableGrid backgroundColorForColumn:(NSUInteger)columnIndex row:(NSUInteger)rowIndex {
    if (rowIndex % 2)
        return [NSColor colorWithDeviceWhite:0.950 alpha:1.000];
    else
        return nil;
}

#pragma mark Footer

- (void)addItemToMenu:(NSMenu *)menu withTitle:(NSString *)title;
{
    [menu addItemWithTitle:title action:@selector(cellPopupMenuItemSelected:) keyEquivalent:@""];
}

- (NSString *)formattedPrefix:(NSString *)prefix value:(id)value forTableGrid:(MBTableGrid *)aTableGrid column:(NSUInteger)columnIndex;
{
    NSFormatter *formatter = [self tableGrid:aTableGrid formatterForColumn:columnIndex];
    
    if (formatter) {
        value = [formatter stringForObjectValue:value];
    } else {
        value = [NSString stringWithFormat:@"%.0f", [value floatValue]];
    }
    
    return [NSString stringWithFormat:@"%@: %@", prefix, value];
}

- (NSString *)footerDefaultsKeyForColumn:(NSUInteger)columnIndex;
{
    return [NSString stringWithFormat:@"TableGrid-Footer-%ld", columnIndex];
}

- (NSCell *)tableGrid:(MBTableGrid *)aTableGrid footerCellForColumn:(NSUInteger)columnIndex;
{
    NSCell *cell = nil;
    NSString *columnIdentifier = self.columnIdentifiers[columnIndex];
    
    if (columnIdentifier == ColumnDate || columnIdentifier == ColumnPopup || columnIdentifier == ColumnCheckbox) {
        // Date, popup & checkbox: just showing the count
        cell = self.footerTextCell;
    } else if (columnIdentifier == ColumnImage) {
        // Image: nothing to show
        cell = nil;
    } else if (columnIdentifier == ColumnRating) {
        // Rating: average as a rating
        cell = self.ratingCell;
    } else if (columnIndex >= [columns count]) {
        // Invalid column
        return nil;
    } else {
        // All others: a popup of Total, Average, etc
        cell = self.footerPopupCell;
        
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"self != ''"];
        NSArray *column = [columns[columnIndex] filteredArrayUsingPredicate:predicate];
        
        // Rebuild the menu with dynamic values
        [cell.menu removeAllItems];
        
        [self addItemToMenu:cell.menu withTitle:[self formattedPrefix:@"Total" value:[column valueForKeyPath:@"@sum.floatValue"] forTableGrid:aTableGrid column:columnIndex]];
        [self addItemToMenu:cell.menu withTitle:[self formattedPrefix:@"Minimum" value:[column valueForKeyPath:@"@min.floatValue"] forTableGrid:aTableGrid column:columnIndex]];
        [self addItemToMenu:cell.menu withTitle:[self formattedPrefix:@"Maximum" value:[column valueForKeyPath:@"@max.floatValue"] forTableGrid:aTableGrid column:columnIndex]];
        [self addItemToMenu:cell.menu withTitle:[self formattedPrefix:@"Average" value:[column valueForKeyPath:@"@avg.floatValue"] forTableGrid:aTableGrid column:columnIndex]];
        [self addItemToMenu:cell.menu withTitle:[NSString stringWithFormat:@"Count: %li", [[column valueForKeyPath:@"@count"] integerValue]]];
    }
    
    return cell;
}

- (id)tableGrid:(MBTableGrid *)aTableGrid footerValueForColumn:(NSUInteger)columnIndex;
{
    if (columnIndex >= [columns count]) {
        return nil;
    }
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"self != ''"];
    NSArray *column = [columns[columnIndex] filteredArrayUsingPredicate:predicate];
    
    id value = nil;
    NSString *columnIdentifier = self.columnIdentifiers[columnIndex];
    
    if (columnIdentifier == ColumnDate || columnIdentifier == ColumnPopup || columnIdentifier == ColumnCheckbox) {
        // Date, popup & checkbox: just showing the count
        value = [NSString stringWithFormat:@"Count: %li", [[column valueForKeyPath:@"@count"] integerValue]];
    } else if (columnIdentifier == ColumnImage) {
        // Image: nothing to show
        value = nil;
    } else if (columnIdentifier == ColumnRating) {
        // Rating: average as a rating
        value = [column valueForKeyPath:@"@avg.floatValue"];
    } else {
        // All others: a popup of Total, Average, etc
        NSCell *cell = [self tableGrid:aTableGrid footerCellForColumn:columnIndex];
        NSUInteger itemIndex = [[NSUserDefaults standardUserDefaults] integerForKey:[self footerDefaultsKeyForColumn:columnIndex]];
        
        value = [cell.menu itemAtIndex:itemIndex].title;
        
        if (!value) {
            value = [cell.menu itemAtIndex:0].title;
        }
    }
    
    return value;
}

- (void)tableGrid:(MBTableGrid *)aTableGrid setFooterValue:(id)anObject forColumn:(NSUInteger)columnIndex;
{
    NSString *columnIdentifier = self.columnIdentifiers[columnIndex];
    
    if (columnIdentifier == ColumnDate || columnIdentifier == ColumnPopup || columnIdentifier == ColumnCheckbox || columnIdentifier == ColumnImage || columnIdentifier == ColumnRating || columnIndex >= [columns count]) {
        return;
    }
    
    NSCell *cell = [self tableGrid:aTableGrid footerCellForColumn:columnIndex];
    NSInteger itemIndex = [cell.menu indexOfItemWithTitle:anObject];
    
//    NSLog(@"set footer value: %@ (%@); for column: %@", anObject, @(itemIndex), @(columnIndex));  // log
    
    if (itemIndex >= 0) {
        [[NSUserDefaults standardUserDefaults] setInteger:itemIndex forKey:[self footerDefaultsKeyForColumn:columnIndex]];
    }
}

#pragma mark Dragging

- (BOOL)tableGrid:(MBTableGrid *)aTableGrid writeColumnsWithIndexes:(NSIndexSet *)columnIndexes toPasteboard:(NSPasteboard *)pboard
{
	return YES;
}

- (BOOL)tableGrid:(MBTableGrid *)aTableGrid canMoveColumns:(NSIndexSet *)columnIndexes toIndex:(NSUInteger)index
{
	// Allow any column movement
	return YES;
}

- (BOOL)tableGrid:(MBTableGrid *)aTableGrid moveColumns:(NSIndexSet *)columnIndexes toIndex:(NSUInteger)index
{
	[columns moveObjectsAtIndexes:columnIndexes toIndex:index];
    [self.columnIdentifiers moveObjectsAtIndexes:columnIndexes toIndex:index];
	return YES;
}

- (BOOL)tableGrid:(MBTableGrid *)aTableGrid writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard *)pboard
{
	return YES;
}

- (BOOL)tableGrid:(MBTableGrid *)aTableGrid canMoveRows:(NSIndexSet *)rowIndexes toIndex:(NSUInteger)index
{
	// Allow any row movement
	return YES;
}

- (BOOL)tableGrid:(MBTableGrid *)aTableGrid moveRows:(NSIndexSet *)rowIndexes toIndex:(NSUInteger)index
{
	for (NSMutableArray *column in columns) {
		[column moveObjectsAtIndexes:rowIndexes toIndex:index];
	}
	return YES;
}

- (NSDragOperation)tableGrid:(MBTableGrid *)aTableGrid validateDrop:(id <NSDraggingInfo>)info proposedColumn:(NSUInteger)columnIndex row:(NSUInteger)rowIndex
{
	return NSDragOperationCopy;
}

- (BOOL)tableGrid:(MBTableGrid *)aTableGrid acceptDrop:(id <NSDraggingInfo>)info column:(NSUInteger)columnIndex row:(NSUInteger)rowIndex
{
	NSPasteboard *pboard = [info draggingPasteboard];
	
	NSString *value = [pboard stringForType:NSStringPboardType];
	[self tableGrid:aTableGrid setObjectValue:value forColumn:columnIndex row:rowIndex];
	
	return YES;
}

#pragma mark Copy & Paste

- (void)tableGrid:(MBTableGrid *)aTableGrid copyCellsAtColumns:(NSIndexSet *)columnIndexes rows:(NSIndexSet *)rowIndexes
{
    NSMutableArray *colClasses = [NSMutableArray arrayWithCapacity:columnIndexes.count];
    
    [columnIndexes enumerateIndexesUsingBlock:^(NSUInteger columnIndex, BOOL *stop) {
        [colClasses addObject:[[self tableGrid:aTableGrid cellForColumn:columnIndex] className]];
    }];
    
	NSMutableArray *rowData = [NSMutableArray arrayWithCapacity:rowIndexes.count];
	
	[rowIndexes enumerateIndexesUsingBlock:^(NSUInteger rowIndex, BOOL *stop) {
		
		NSMutableArray *colData = [NSMutableArray arrayWithCapacity:columnIndexes.count];
        
		[columnIndexes enumerateIndexesUsingBlock:^(NSUInteger columnIndex, BOOL *stop) {
			
			NSArray *row = columns[columnIndex];
			id cellData = row[rowIndex];
            NSFormatter *formatter = [self tableGrid:aTableGrid formatterForColumn:columnIndex];
            
            if (formatter) {
                cellData = [formatter stringForObjectValue:cellData];
            }
            
			[colData addObject:cellData];
			
		}];
		
		NSString *rowString = [colData componentsJoinedByString:@"\t"];
		
		[rowData addObject:rowString];
		
	}];
	
	NSString *tsvString = [rowData componentsJoinedByString:@"\n"];
	
	NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
	
	[pasteboard clearContents];

	[pasteboard declareTypes:@[NSPasteboardTypeTabularText, NSPasteboardTypeString, PasteboardTypeColumnClass] owner:nil];
	[pasteboard setString:tsvString forType:NSPasteboardTypeTabularText];
	[pasteboard setString:tsvString forType:NSPasteboardTypeString];
    [pasteboard setPropertyList:colClasses forType:PasteboardTypeColumnClass];

}

- (void)tableGrid:(MBTableGrid *)aTableGrid pasteCellsAtColumns:(NSIndexSet *)columnIndexes rows:(NSIndexSet *)rowIndexes
{
    NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
    BOOL isSingleSelection = columnIndexes.count == 1 && rowIndexes.count == 1;
    NSString *tavString = [pasteboard stringForType:NSPasteboardTypeTabularText];
    
    if (!tavString.length) {
        tavString = [pasteboard stringForType:NSPasteboardTypeString];
    }
    
    if (!tavString.length) {
        return;
    }
    
    // Extract the rows and columns to a more convenient form
    NSMutableArray *rowArray = [NSMutableArray array];
    
    for (NSString *rowString in [tavString componentsSeparatedByString:@"\n"]) {
        
        NSMutableArray *columnArray = [NSMutableArray array];
        
        for (NSString *columnString in [rowString componentsSeparatedByString:@"\t"]) {
            
            [columnArray addObject:columnString];
        }
        
        [rowArray addObject:columnArray];
    }
    
    NSUInteger firstSelectedColumn = [columnIndexes firstIndex];
    NSUInteger firstSelectedRow = [rowIndexes firstIndex];
    NSUInteger numberOfExistingColumns = [columns count];
    NSUInteger numberOfExistingRows = [[columns firstObject] count];
    NSUInteger numberOfPastingColumns = [[rowArray firstObject] count];
    NSUInteger numberOfPastingRows = [rowArray count];
    
    // If pasting to a single cell, we want to paste all of the values, so add rows and columns if needed
    if (isSingleSelection) {
        NSInteger extraColumns = firstSelectedColumn + numberOfPastingColumns - numberOfExistingColumns;
        NSInteger extraRows = firstSelectedRow + numberOfPastingRows - numberOfExistingRows;
        
        if (extraColumns > 0) {
            // Add extra columns; a real controller could use the PasteboardTypeColumnClass values to add appropriate column types to the database
            [self tableGrid:aTableGrid addColumns:extraColumns shouldReload:NO];
        }
        
        if (extraRows > 0) {
            [self tableGrid:aTableGrid addRows:extraRows shouldReload:NO];
        }
    } else {
        numberOfPastingColumns = columnIndexes.count;
        numberOfPastingRows = rowIndexes.count;
    }
    
    // Insert the values
    [rowArray enumerateObjectsUsingBlock:^(NSArray *columnArray, NSUInteger rowOffset, BOOL *stopRows) {
        [columnArray enumerateObjectsUsingBlock:^(NSString *value, NSUInteger columnOffset, BOOL *stopColumns) {
            
            NSUInteger column = firstSelectedColumn + columnOffset;
            NSUInteger row = firstSelectedRow + rowOffset;
            
            NSFormatter *formatter = [self tableGrid:aTableGrid formatterForColumn:column];
            id obj = value;
            
            if (!formatter || [formatter getObjectValue:&obj forString:value errorDescription:nil]) {
                [self tableGrid:aTableGrid setObjectValue:obj forColumn:column row:row];
            }
            
            if (columnOffset == numberOfPastingColumns - 1) {
                *stopColumns = YES;
            }
        }];
        
        if (rowOffset == numberOfPastingRows - 1) {
            *stopRows = YES;
        }
    }];
}

#pragma mark Adding and Removing Columns & Rows

- (BOOL)tableGrid:(MBTableGrid *)aTableGrid addColumns:(NSUInteger)numberOfColumns shouldReload:(BOOL)shouldReload;
{
    // Default number of rows
    NSUInteger numberOfRows = 0;
    
    // If there are already other columns, get the number of rows from one of them
    if ([columns count] > 0) {
        numberOfRows = [columns[0] count];
    }
    
    for (NSUInteger column = 0; column < numberOfColumns; column++) {
        
        NSMutableArray *newColumn = [NSMutableArray array];
        
        for (NSUInteger row = 0; row < numberOfRows; row++) {
            // Insert blank items for each row
            [newColumn addObject:@""];
        }
        
        [columns addObject:newColumn];
        
        if (columns.count > self.columnIdentifiers.count) {
            [self.columnIdentifiers addObject:[NSString stringWithFormat:@"extra%@", @(columns.count)]];
        }
    }
    
    if (shouldReload) {
        [tableGrid reloadData];
    }
    
    return YES;
}

- (BOOL)tableGrid:(MBTableGrid *)aTableGrid addRows:(NSUInteger)numberOfRows;
{
    return [self tableGrid:aTableGrid addRows:numberOfRows shouldReload:YES];
}

- (BOOL)tableGrid:(MBTableGrid *)aTableGrid addRows:(NSUInteger)numberOfRows shouldReload:(BOOL)shouldReload;
{
    for (NSUInteger row = 0; row < numberOfRows; row++) {
        for (NSMutableArray *column in columns) {
            // Add a blank item to each row
            [column addObject:@""];
        }
    }
    
    [aTableGrid.columnRects removeAllObjects];
    
    if (shouldReload) {
        [aTableGrid reloadData];
    }
    
    return YES;
}

- (BOOL)tableGrid:(MBTableGrid *)aTableGrid removeRows:(NSIndexSet *)rowIndexes;
{
    for (NSMutableArray *column in columns) {
        [column removeObjectsAtIndexes:rowIndexes];
    }
    
    [aTableGrid reloadData];
    
    return YES;
}

#pragma mark MBTableGridDelegate

- (void)tableGridDidMoveRows:(NSNotification *)aNotification
{
	NSLog(@"moved");
}

- (void)tableGrid:(MBTableGrid *)aTableGrid userDidEnterInvalidStringInColumn:(NSUInteger)columnIndex row:(NSUInteger)rowIndex errorDescription:(NSString *)errorDescription {
	NSLog(@"Invalid input at %lu,%lu: %@", (unsigned long)columnIndex, (unsigned long)rowIndex, errorDescription);
}

- (void)tableGrid:(MBTableGrid *)aTableGrid accessoryButtonClicked:(NSUInteger)columnIndex row:(NSUInteger)rowIndex {
    NSString *columnIdentifier = self.columnIdentifiers[columnIndex];
    
	if (columnIdentifier == ColumnImage) {
		[self quickLookAction:nil];
	}
}

- (void)tableGrid:(MBTableGrid *)aTableGrid didAddRows:(NSIndexSet *)rowIndexes;
{
    // Add the rows to the database, or whatever is needed
}

#pragma mark - QuickLook

-(void)quickLookAction:(id)sender {
	//	[[NSApp mainWindow] makeFirstResponder:self];
	
	if ([QLPreviewPanel sharedPreviewPanelExists] && [[QLPreviewPanel sharedPreviewPanel] isVisible]) {
		[[QLPreviewPanel sharedPreviewPanel] orderOut:nil];
	} else {
		QLPreviewPanel *previewPanel = [QLPreviewPanel sharedPreviewPanel];
		previewPanel.dataSource = self;
		previewPanel.delegate = self;
		[previewPanel makeKeyAndOrderFront:sender];
	}
}


// Quick Look panel support

- (BOOL)acceptsPreviewPanelControl:(QLPreviewPanel *)panel; {
	return YES;
}

- (void)beginPreviewPanelControl:(QLPreviewPanel *)panel {
	// This document is now responsible of the preview panel
	// It is allowed to set the delegate, data source and refresh panel.
	
	panel.delegate = self;
	panel.dataSource = self;
}

- (void)endPreviewPanelControl:(QLPreviewPanel *)panel {
	panel.delegate = nil;
	panel.dataSource = nil;
}

// Quick Look panel data source

- (NSInteger)numberOfPreviewItemsInPreviewPanel:(QLPreviewPanel *)panel {
	return 1;
}

- (id <QLPreviewItem>)previewPanel:(QLPreviewPanel *)panel previewItemAtIndex:(NSInteger)index {
	NSFileCoordinator *coordinator = [[NSFileCoordinator alloc] initWithFilePresenter:nil];
	NSURL *fileURL = nil;
	__block NSURL *returnURL = nil;
	NSError *error = nil;
	fileURL = [[NSBundle mainBundle] URLForImageResource:@"rose"];
	
	[coordinator coordinateReadingItemAtURL:fileURL
									options:NSFileCoordinatorReadingWithoutChanges
									  error:&error
								 byAccessor:^(NSURL *newURL) {
									 returnURL = newURL;
								 }];
	
	return returnURL;
}

// This delegate method provides the rect on screen from which the panel will zoom.
- (NSRect)previewPanel:(QLPreviewPanel *)panel sourceFrameOnScreenForPreviewItem:(id <QLPreviewItem>)item {
	
	// convert selected cell rect to screen coordinates
	NSInteger selectedColumn = [tableGrid.selectedColumnIndexes firstIndex];
	NSInteger selectedRow = [tableGrid.selectedRowIndexes firstIndex];
	NSCell *selectedCell = [tableGrid selectedCell];
	
	NSRect photoPreviewFrame = [tableGrid frameOfCellAtColumn:selectedColumn row:selectedRow];
	NSRect rectInWinCoords = [selectedCell.controlView convertRect:photoPreviewFrame toView:nil];
	NSRect rectInScreenCoords = [[NSApp mainWindow] convertRectToScreen:rectInWinCoords];
	
	return rectInScreenCoords;
}


#pragma mark -
#pragma mark Subclass Methods

- (IBAction)addColumn:(id)sender
{
    [self tableGrid:tableGrid addColumns:1 shouldReload:YES];
}

- (IBAction)addRow:(id)sender
{
    [self tableGrid:tableGrid addRows:1 shouldReload:YES];
}

@end

@implementation NSMutableArray (SwappingAdditions)

- (void)moveObjectsAtIndexes:(NSIndexSet *)indexes toIndex:(NSUInteger)index
{
	NSArray *objects = [self objectsAtIndexes:indexes];
	
	// Determine the new indexes for the objects
	NSRange newRange = NSMakeRange(index, [indexes count]);
	if (index > [indexes firstIndex]) {
		newRange.location -= [indexes count];
	}
	NSIndexSet *newIndexes = [NSIndexSet indexSetWithIndexesInRange:newRange];
	
	// Determine where the original objects are
	NSIndexSet *originalIndexes = indexes;
	
	// Remove the objects from their original locations
	[self removeObjectsAtIndexes:originalIndexes];
	
	// Insert the objects at their new location
	[self insertObjects:objects atIndexes:newIndexes];
	
}

@end
