//
//  MBAutoCompleteWindow.h
//  Tap Forms Mac
//
//  Created by Brendan Duddridge on 2017-12-25.
//  Copyright © 2017 Tap Zapp Software Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol MBAutoSelectDelegate <NSObject>
- (void)didSelectValue:(NSString *)value;
@end

@interface MBAutoCompleteWindow : NSPanel

@property (nonatomic, weak) id<MBAutoSelectDelegate> selectionDelegate;
@property (nonatomic, strong) NSArray<NSString *> *completions;

- (void)moveRowDown:(id)sender;
- (void)moveRowUp:(id)sender;

@end
