//
//  MBAutoCompleteWindow.m
//  Tap Forms Mac
//
//  Created by Brendan Duddridge on 2017-12-25.
//  Copyright © 2017 Tap Zapp Software Inc. All rights reserved.
//

#import "MBAutoCompleteWindow.h"

@interface MBAutoCompleteWindow()<NSTableViewDelegate, NSTableViewDataSource>
@property (nonatomic, strong) NSTableView *tableView;
@property (nonatomic, strong) NSScrollView *scrollView;
@end

@implementation MBAutoCompleteWindow

@synthesize completions = _completions;

- (instancetype)initWithContentRect:(NSRect)contentRect styleMask:(NSWindowStyleMask)style backing:(NSBackingStoreType)backingStoreType defer:(BOOL)flag {

	MBAutoCompleteWindow *this = [super initWithContentRect:contentRect styleMask:style backing:backingStoreType defer:flag];

	this.hasShadow = YES;
	this.backgroundColor = [NSColor windowBackgroundColor];
	return this;
}

- (void)setCompletions:(NSArray<NSString *> *)completions {
	_completions = completions;
	
	if (!self.tableView) {
	
		NSTableColumn *column1 = [[NSTableColumn alloc] initWithIdentifier:@"text"];
		[column1 setEditable:NO];
		[column1 setWidth:self.frame.size.width - 15];
		
		NSRect bounds = self.frame;
		bounds.origin.x = 0;
		bounds.origin.y = 0;
		NSTableView *tableView = [[NSTableView alloc] initWithFrame:bounds];
		self.tableView = tableView;
		[tableView setSelectionHighlightStyle:NSTableViewSelectionHighlightStyleRegular];
		[tableView setBackgroundColor:[NSColor clearColor]];
		[tableView setIntercellSpacing:NSMakeSize(12, 0)];
		[tableView setHeaderView:nil];
		[tableView setRefusesFirstResponder:NO];
		[tableView addTableColumn:column1];
		[tableView setDelegate:self];
		[tableView setDataSource:self];
		
		NSScrollView *tableScrollView = [[NSScrollView alloc] initWithFrame:bounds];
		[tableScrollView setDrawsBackground:NO];
		[tableScrollView setDocumentView:tableView];
		[tableScrollView setHasVerticalScroller:YES];
		tableScrollView.autoresizesSubviews = YES;
		self.scrollView = tableScrollView;
		
		[self.contentView addSubview:tableScrollView];

		self.contentView.autoresizesSubviews = YES;

		[self.tableView scrollToBeginningOfDocument:nil];
	}
	
	[self.tableView setFrameSize:self.frame.size];
	[self.scrollView setFrameSize:self.frame.size];
	[self.tableView reloadData];
	[self.scrollView flashScrollers];
}

- (void)moveRowDown:(id)sender {
	NSInteger selectedRow = self.tableView.selectedRow;
	
	if (selectedRow < 0 || selectedRow == NSNotFound) {
		selectedRow = 0;
	} else if (self.tableView.selectedRow < self.completions.count) {
		selectedRow++;
	}
	
	if (selectedRow < self.completions.count) {
		[self.tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:selectedRow] byExtendingSelection:NO];
		[self.tableView scrollRowToVisible:selectedRow];
		[self makeFirstResponder:self.tableView];
	}

	NSLog(@"movedown in table");
}

- (void)moveRowUp:(id)sender {
	NSInteger selectedRow = self.tableView.selectedRow;
	
	if (selectedRow <= 0 || selectedRow == NSNotFound) {
		selectedRow = 0;
	} else if (self.tableView.selectedRow < self.completions.count) {
		selectedRow--;
	}
	
	[self.tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:selectedRow] byExtendingSelection:NO];
	[self.tableView scrollRowToVisible:selectedRow];
	
	NSLog(@"moveup in table");
}

#pragma mark - table delegates

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
	return self.completions.count;
}

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row {
	return 21;
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
	
	NSString *string = nil;
	
	if (row < self.completions.count) {
		string = self.completions[row];
	}
	
	NSTableCellView *cellView = [tableView makeViewWithIdentifier:@"AutoCompleteCell" owner:self];
	if (cellView == nil) {
		cellView = [[NSTableCellView alloc] initWithFrame:NSZeroRect];
		NSTextField *textField = [[NSTextField alloc] initWithFrame:NSZeroRect];
		textField.textColor = [NSColor controlTextColor];
		textField.font = [NSFont systemFontOfSize:[NSFont systemFontSizeForControlSize:NSControlSizeRegular]];
		textField.bezeled = NO;
		textField.drawsBackground = NO;
		textField.editable = NO;
		textField.selectable = NO;
		textField.lineBreakMode = NSLineBreakByTruncatingTail;
		
		[cellView addSubview:textField];
		cellView.autoresizesSubviews = YES;
		
		textField.translatesAutoresizingMaskIntoConstraints = NO;
		[cellView.leadingAnchor constraintEqualToAnchor:textField.leadingAnchor].active = YES;
		[cellView.topAnchor constraintEqualToAnchor:textField.topAnchor].active = YES;
		[cellView.trailingAnchor constraintEqualToAnchor:textField.trailingAnchor].active = YES;
		[cellView.bottomAnchor constraintEqualToAnchor:textField.bottomAnchor].active = YES;
		
		cellView.textField = textField;
		cellView.identifier = @"AutoCompleteCell";
	}
	
	cellView.textField.objectValue = string;
	
	return cellView;
	
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification {
	if ([self.selectionDelegate respondsToSelector:@selector(didSelectValue:)]) {
		NSInteger completionIndex = self.tableView.selectedRow;
		if (completionIndex < self.completions.count) {
			NSString *value = self.completions[completionIndex];
			[self.selectionDelegate didSelectValue:value];
		}
	}
}

#pragma mark - delegate methods

- (void)insert:(id)sender {
	if ([self.selectionDelegate respondsToSelector:@selector(didSelectValue:)]) {
		NSInteger completionIndex = self.tableView.selectedRow;
		if (completionIndex < self.completions.count) {
			NSString *value = self.completions[completionIndex];
			[self.selectionDelegate didSelectValue:value];
		}
	}
}

@end
