//
//  MBLevelIndicatorCell.m
//  MBTableGrid
//
//  Created by Brendan Duddridge on 2014-11-17.
//
//

#import "MBLevelIndicatorCell.h"

@interface MBLevelIndicatorCell()
@property (nonatomic, weak) NSView *theControlView;
@property (nonatomic, strong) NSColor *borderColor;
@end

@implementation MBLevelIndicatorCell

- (instancetype)initWithLevelIndicatorStyle:(NSLevelIndicatorStyle)levelIndicatorStyle {
	self = [super initWithLevelIndicatorStyle:levelIndicatorStyle];
	if (self) {
		self.selectable = YES;
		self.editable = YES;
		if (@available(macOS 10.13, *)) {
			self.borderColor = [NSColor colorNamed:@"grid-line"];
		} else {
			self.borderColor = [NSColor gridColor];
		}
	}
	return self;
}

//-(BOOL)isHighlighted {
//	return YES;
//}

#pragma mark - MBTableGridEditable

- (BOOL)editOnFirstClick {
	return NO;
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView withBackgroundColor:(NSColor *)backgroundColor {
	[backgroundColor set];
	NSRectFill(cellFrame);
	
	[self drawWithFrame:cellFrame inView:controlView];
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
	
	NSRect rect = cellFrame;
	rect.origin.y -= 2;
	rect.origin.x += 4;
	[super drawWithFrame:rect inView:controlView];
	
	[self.borderColor set];
	
	NSRect rightLine = NSMakeRect(NSMaxX(cellFrame)-1.0, NSMinY(cellFrame), 1.0, NSHeight(cellFrame));
	NSRectFill(rightLine);
	
	
	// Draw the bottom border
	NSRect bottomLine = NSMakeRect(NSMinX(cellFrame), NSMaxY(cellFrame)-1.0, NSWidth(cellFrame), 1.0);
	NSRectFill(bottomLine);
	
}

- (NSView *)controlView {
	return self.theControlView;
}

static NSRect staticTrackingCellFrame;

- (BOOL)trackMouse:(NSEvent *)theEvent inRect:(NSRect)cellFrame ofView:(NSView *)controlView untilMouseUp:(BOOL)flag {
	self.theControlView = controlView;
	staticTrackingCellFrame = cellFrame;
	return [super trackMouse:theEvent inRect:cellFrame ofView:controlView untilMouseUp:flag];
}

- (void)updateValueForPoint:(NSPoint)point {
	CGFloat value;
	NSRect drawingRect = [self drawingRectForBounds:staticTrackingCellFrame];
	if ([self baseWritingDirection] == NSWritingDirectionRightToLeft) {
		value = (NSMaxX(drawingRect) - point.x) / NSWidth(drawingRect);
	} else {
		value = (point.x - NSMinX(drawingRect)) / NSWidth(drawingRect);
	}
	value = [self minValue] + value * ([self maxValue] - [self minValue]);
	
	switch (self.levelIndicatorStyle) {
		case NSDiscreteCapacityLevelIndicatorStyle:
		case NSRatingLevelIndicatorStyle:
			value = ceil(value);
		case NSRelevancyLevelIndicatorStyle:
		case NSContinuousCapacityLevelIndicatorStyle:
		default:
			break;
	}
	
	if (value < [self minValue]) {
		value = [self minValue];
	}
	
	if (value > [self maxValue]) {
		value = [self maxValue];
	}
	
	// call action on target
	// this technique prevents a warning about possible leaks because self.action is not known at compile time
	if (self.target && self.action) {
		IMP imp = [self.target methodForSelector:self.action];
		void (*func)(id, SEL, NSNumber *) = (void *)imp;
		func(self.target, self.action, @(value));
	}

}

- (BOOL)startTrackingAt:(NSPoint)startPoint inView:(NSView *)controlView {
	if (![self isEditable]) {
		return NO;
	} else {
		[self updateValueForPoint:startPoint];
		return YES;
	}
}

- (BOOL)continueTracking:(NSPoint)lastPoint at:(NSPoint)currentPoint inView:(NSView *)controlView {
	[self updateValueForPoint:currentPoint];
	return YES;
}

- (void)stopTracking:(NSPoint)lastPoint at:(NSPoint)stopPoint inView:(NSView *)controlView mouseIsUp:(BOOL)flag {
	[self updateValueForPoint:stopPoint];
}

@end
