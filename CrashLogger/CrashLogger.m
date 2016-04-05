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
#include <libkern/OSAtomic.h>
#include <execinfo.h>

NSString * const UncaughtExceptionHandlerSignalExceptionName = @"UncaughtExceptionHandlerSignalExceptionName";
NSString * const UncaughtExceptionHandlerSignalKey = @"UncaughtExceptionHandlerSignalKey";
NSString * const UncaughtExceptionHandlerAddressesKey = @"UncaughtExceptionHandlerAddressesKey";

volatile int32_t UncaughtExceptionCount = 0;
const int32_t UncaughtExceptionMaximum = 10;

const NSInteger UncaughtExceptionHandlerSkipAddressCount = 4;
const NSInteger UncaughtExceptionHandlerReportAddressCount = 5;

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

+ (NSArray *)backtrace
{
    void* callstack[128];
    int frames = backtrace(callstack, 128);
    char **strs = backtrace_symbols(callstack, frames);
    
    int i;
    NSMutableArray *backtrace = [NSMutableArray arrayWithCapacity:frames];
    for (
         i = UncaughtExceptionHandlerSkipAddressCount;
         i < UncaughtExceptionHandlerSkipAddressCount +
         UncaughtExceptionHandlerReportAddressCount;
         i++)
    {
        [backtrace addObject:[NSString stringWithUTF8String:strs[i]]];
    }
    free(strs);
    
    return backtrace;
}

void SignalHandler(int signal)
{
    int32_t exceptionCount = OSAtomicIncrement32(&UncaughtExceptionCount);
    if (exceptionCount > UncaughtExceptionMaximum)
    {
        return;
    }
    
    NSMutableDictionary *userInfo =
    [NSMutableDictionary
     dictionaryWithObject:[NSNumber numberWithInt:signal]
     forKey:UncaughtExceptionHandlerSignalKey];
    
    NSArray *callStack = [CrashLogger backtrace];
    [userInfo
     setObject:callStack
     forKey:UncaughtExceptionHandlerAddressesKey];
    
    UncaughtExceptionHandler([NSException
                              exceptionWithName:UncaughtExceptionHandlerSignalExceptionName
                              reason:
                              [NSString stringWithFormat:
                               NSLocalizedString(@"Signal %d was raised.", nil),
                               signal]
                              userInfo:
                              [NSDictionary
                               dictionaryWithObject:[NSNumber numberWithInt:signal]
                               forKey:UncaughtExceptionHandlerSignalKey]]);
}

+ (CrashLogger *)sharedInstance
{
    static CrashLogger*_sharedInstance = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        _sharedInstance = [[CrashLogger alloc] initPrivate];
    });
    return _sharedInstance;
}

- (instancetype)init
{
    @throw [NSException exceptionWithName:@"Do not init CrashLogger"
                                   reason:@"You should use [CrashLogger sharedInstance]"
                                 userInfo:nil];
    return nil;
}

- (instancetype)initPrivate
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
    signal(SIGABRT, SignalHandler);
    signal(SIGILL, SignalHandler);
    signal(SIGSEGV, SignalHandler);
    signal(SIGFPE, SignalHandler);
    signal(SIGBUS, SignalHandler);
    signal(SIGPIPE, SignalHandler);
}

-(void)remuseHandler
{
    NSSetUncaughtExceptionHandler (_uncaughtExceptionHandler);
    signal(SIGABRT, SIG_DFL);
    signal(SIGILL, SIG_DFL);
    signal(SIGSEGV, SIG_DFL);
    signal(SIGFPE, SIG_DFL);
    signal(SIGBUS, SIG_DFL);
    signal(SIGPIPE, SIG_DFL);
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
