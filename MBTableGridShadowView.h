//
//  MBTableGridShadowView.h
//  MBTableGrid
//
//  Created by David Sinclair on 2016-09-15.
//

#import <Cocoa/Cocoa.h>
#import "MBTableGridHeaderCell.h"

#define MBTableGridShadowWidth 5.0
#define MBTableGridShadowHeight 5.0

@class MBTableGrid;

@interface MBTableGridShadowView : NSView

/**
 * @brief		The orientation of the receiver.
 */
@property MBTableGridHeaderOrientation orientation;

@end

