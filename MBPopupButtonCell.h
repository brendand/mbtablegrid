//
//  MBPopupButtonCell.h
//  MBTableGrid
//
//  Created by Brendan Duddridge on 2014-10-27.
//
//

#import <Cocoa/Cocoa.h>

@interface MBPopupButtonCell : NSComboBoxCell {
	NSImage *_arrowImage;
	NSImage *_highlightedArrowImage;
	BOOL _drawHighlightedArrowImage;
}

@property (nonatomic, strong) NSImage *accessoryButtonImage;

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView withBackgroundColor:(NSColor *)backgroundColor;

- (void)synchronizeTitleAndSelectedItem;
- (NSInteger)indexOfItemWithTitle:(NSString *)aTitle;

@end
