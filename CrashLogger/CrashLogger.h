//
//  CrashLogger.h
//  CrashLoggerDemo
//
//  Created by YourtionGuo on 1/26/15.
//  Copyright (c) 2015 GYX. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CrashLogger : NSObject
+ (CrashLogger *)sharedInstance;
- (void)setHandler;
- (void)remuseHandler;
- (NSDictionary *)getCashLog;
- (BOOL)deleteCashLog;
@end
