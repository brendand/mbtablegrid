//
//  TFUserDefaults.m
//  MBTableGrid
//
//  Created by David Sinclair on 2017-05-22.
//

#import "TFUserDefaults.h"

@implementation TFUserDefaults

- (void)setObject:(nullable id)object forKey:(nonnull NSString *)key {
    [[NSUserDefaults standardUserDefaults] setObject:object forKey:key];
}

- (id _Nullable)objectForKey:(nonnull NSString *)key {
    return [[NSUserDefaults standardUserDefaults] objectForKey:key];
}

@end
