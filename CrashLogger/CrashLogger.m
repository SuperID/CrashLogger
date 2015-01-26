//
//  CrashLogger.m
//  CrashLoggerDemo
//
//  Created by YourtionGuo on 1/26/15.
//  Copyright (c) 2015 GYX. All rights reserved.
//

#import "CrashLogger.h"
#import <UIKit/UIDevice.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <CoreTelephony/CTCarrier.h>

NSString *logPathUrl() {
    return [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject]stringByAppendingPathComponent:@"Exception.txt"];
}

void UncaughtExceptionHandler(NSException *exception) {
    
    NSMutableDictionary *log = [[NSMutableDictionary alloc]init];
    [log setObject:[NSDate date] forKey:@"date"];
    
    // exception info
    NSArray *arr = [exception callStackSymbols];
    NSString *reason = [exception reason];
    NSString *name = [exception name];
    [log setObject:name forKey:@"name"];
    [log setObject:reason forKey:@"reason"];
    [log setObject:[arr componentsJoinedByString:@"\n"] forKey:@"log"];
    
    // Device info
    [log setObject:[UIDevice currentDevice].model forKey:@"device"];
    [log setObject:[UIDevice currentDevice].systemVersion forKey:@"osversion"];

    // batteryLevel info
    [[UIDevice currentDevice] setBatteryMonitoringEnabled:YES];
    [log setObject:[NSNumber numberWithFloat:[UIDevice currentDevice].batteryLevel*100] forKey:@"batteryLevel"];
    [[UIDevice currentDevice] setBatteryMonitoringEnabled:NO];
    
    // Network info
    CTTelephonyNetworkInfo *networkInfo = [[CTTelephonyNetworkInfo alloc] init];
    CTCarrier *carrier = [networkInfo subscriberCellularProvider];
    [log setObject:networkInfo.currentRadioAccessTechnology forKey:@"networkInfo"];
    [log setObject:carrier.carrierName forKey:@"carrierName"];
    [log setObject:carrier.isoCountryCode forKey:@"isoCountryCode"];
    [log setObject:carrier.mobileCountryCode forKey:@"mobileCountryCode"];
    
    NSString *path = logPathUrl();
    NSDictionary *logfile = [NSDictionary dictionaryWithDictionary:log];
    [logfile writeToFile:path atomically:YES];
}

@implementation CrashLogger{
    NSUncaughtExceptionHandler *_uncaughtExceptionHandler;
}

+ (CrashLogger *)sharedInstance
{
    static CrashLogger*_sharedInstance = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        _sharedInstance = [[CrashLogger alloc] init];
    });
    return _sharedInstance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _uncaughtExceptionHandler = NSGetUncaughtExceptionHandler();
    }
    return self;
}

-(NSString *)applicationDocumentsDirectory {
    return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
}

- (void)setHandler
{
    if(isatty(STDOUT_FILENO)) {
        return;
    }
    
    UIDevice *device = [UIDevice currentDevice];
    if([[device model] hasSuffix:@"Simulator"]){
        return;
    }
    
    NSSetUncaughtExceptionHandler (&UncaughtExceptionHandler);
}

-(void)remuseHandler
{
    NSSetUncaughtExceptionHandler (_uncaughtExceptionHandler);
}

-(NSDictionary *)getCashLog
{
    return [NSDictionary dictionaryWithContentsOfFile:logPathUrl()];
}

-(BOOL)deleteCashLog
{
    if ([[NSFileManager defaultManager] fileExistsAtPath:logPathUrl()]) {
        NSFileManager *fileManager = [NSFileManager defaultManager];
        return [fileManager removeItemAtPath:logPathUrl() error:NULL];
    }else{
        return YES;
    }
}

@end
