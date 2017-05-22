//
//  TFUserDefaults.h
//  MBTableGrid
//
//  Created by David Sinclair on 2017-05-22.
//

#import <Foundation/Foundation.h>

@interface TFUserDefaults : NSObject

- (void)setObject:(nullable id)object forKey:(nonnull NSString *)key;
- (id _Nullable)objectForKey:(nonnull NSString *)key;

@end
