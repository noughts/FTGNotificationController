//
//  FTGNotificationController.m
//  FTGNotificationControllerDemo
//
//  Created by Khoa Pham on 6/19/14.
//  Copyright (c) 2014 Fantageek. All rights reserved.
//

#import "FTGNotificationController.h"

#import <libkern/OSAtomic.h>

#if !__has_feature(objc_arc)
#error This file must be compiled with ARC. Convert your project to ARC or specify the -fobjc-arc flag.
#endif

#pragma mark - FTGNotificationInfo

/**
 @abstract The notification observing info.
 @discussion Object equality is only used within the scope of a controller instance. Safely omit controller from equality definition.
 */
@interface FTGNotificationInfo : NSObject
@end

@implementation FTGNotificationInfo
{
@public
    __weak FTGNotificationController *_controller;
    NSString *_notificationName;
    __weak id _object;
    __weak NSOperationQueue *_queue;
    SEL _action;
    FTGNotificationBlock _block;
}

- (instancetype)initWithController:(FTGNotificationController *)controller
                  notificationName:(NSString *)notificationName
                            object:(id)object
                             queue:(NSOperationQueue *)queue
                             block:(FTGNotificationBlock)block
                            action:(SEL)action
{
    self = [super init];
    if (nil != self) {
        _controller = controller;
        _notificationName = [notificationName copy];
        _object = object;
        _queue = queue;
        _block = [block copy];
        _action = action;

    }
    return self;
}

- (instancetype)initWithController:(FTGNotificationController *)controller
                  notificationName:(NSString *)notificationName
                            object:(id)object
                             queue:(NSOperationQueue *)queue
                             block:(FTGNotificationBlock)block
{
    return [self initWithController:controller
                   notificationName:(NSString *)notificationName
                             object:object
                              queue:queue
                              block:block
                             action:nil];
}

- (instancetype)initWithController:(FTGNotificationController *)controller
                  notificationName:(NSString *)notificationName
                            object:(id)object
                            action:(SEL)action
{
    return [self initWithController:controller
                   notificationName:(NSString *)notificationName
                             object:object
                              queue:nil
                              block:nil
                             action:action];
}

- (instancetype)initWithController:(FTGNotificationController *)controller
                  notificationName:(NSString *)notificationName
                            object:(id)object
{
    return [self initWithController:controller
                   notificationName:(NSString *)notificationName
                             object:object
                              queue:nil
                              block:nil
                             action:nil];
}

- (NSString *)debugDescription
{
    NSMutableString *s = [NSMutableString stringWithFormat:@"<%@:%p\n", NSStringFromClass([self class]), self];

    [s appendFormat:@"notificationName:%@\n", _notificationName];
    [s appendFormat:@"object:%p\n", _object];
    [s appendFormat:@"action:%@\n", NSStringFromSelector(_action)];
    [s appendFormat:@"queue:%p\n", _queue];
    [s appendFormat:@"block:%p\n", _block];
    [s appendString:@">"];

    return s;
}

#pragma mark - Notification Handler
- (void)handleNotification:(NSNotification *)note
{
    // take strong reference to controller
    FTGNotificationController *controller = self->_controller;
    if (nil != controller) {
        // take strong reference to observer
        id observer = controller.observer;
        if (nil != observer) {
            // dispatch custom block or action
            if (self->_block) {
                if (!self->_queue || self->_queue == [NSOperationQueue mainQueue]) {
                    self->_block(note, observer);
                } else {
                    [self->_queue addOperationWithBlock:^{
                        self->_block(note, observer);
                    }];
                }
            } else if (self->_action) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                [observer performSelector:self->_action withObject:note];
#pragma clang diagnostic pop
            }
        }
    }
}

#pragma mark - Helper
- (BOOL)match:(FTGNotificationInfo *)anInfo
{
    BOOL matchController = [_controller isEqual:anInfo->_controller];
    BOOL matchNotificationName = !anInfo->_notificationName || [_notificationName isEqualToString:anInfo->_notificationName];
    BOOL matchObject = !anInfo->_object || [_object isEqual:anInfo->_object];

    return matchController && matchNotificationName && matchObject;
}

@end

#pragma mark - FTGNotificationSharedController

/**
 @abstract The shared KVO controller instance.
 @discussion Acts as a receptionist, receiving and forwarding KVO notifications.
 */
@interface FTGNotificationSharedController : NSObject

/** A shared instance that never deallocates. */
+ (instancetype)sharedController;

/** observe notification info */
- (void)observeNotificationInfo:(FTGNotificationInfo *)info;

/** unobserve notification info */
- (void)unobserveNotificationInfo:(FTGNotificationInfo *)info;

@end

@implementation FTGNotificationSharedController
{
    NSMutableArray *_sharedInfos;
    OSSpinLock _sharedLock;
}

+ (instancetype)sharedController
{
    static FTGNotificationSharedController *_controller = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _controller = [[FTGNotificationSharedController alloc] init];
    });
    return _controller;
}

- (instancetype)init
{
    self = [super init];
    if (nil != self) {
        _sharedInfos = [NSMutableArray array];
        _sharedLock = OS_SPINLOCK_INIT;
    }
    return self;
}

- (NSString *)debugDescription
{
    NSMutableString *s = [NSMutableString stringWithFormat:@"<%@:%p>\n", NSStringFromClass([self class]), self];

    [s appendFormat:@"notification infos: \n%@\n", _sharedInfos];

    return s;
}

- (void)observeNotificationInfo:(FTGNotificationInfo *)info
{
    if (nil == info) {
        return;
    }

    // register info
    OSSpinLockLock(&_sharedLock);

    [_sharedInfos addObject:info];

    OSSpinLockUnlock(&_sharedLock);

    // add observer
    [[NSNotificationCenter defaultCenter] addObserver:info
                                             selector:@selector(handleNotification:)
                                                 name:info->_notificationName
                                               object:info->_object];
}

- (void)unobserveNotificationInfo:(FTGNotificationInfo *)info
{
    if (nil == info) {
        return;
    }

    FTGNotificationInfo *registeredInfo = [self hasNotificationInfo:info];
    if (registeredInfo) {
        // unregister info
        OSSpinLockLock(&_sharedLock);

        [_sharedInfos removeObject:registeredInfo];

        OSSpinLockUnlock(&_sharedLock);

        // remove observer
        [[NSNotificationCenter defaultCenter] removeObserver:registeredInfo
                                                        name:registeredInfo->_notificationName
                                                      object:registeredInfo->_object];
    }
}

- (void)unobserveNotificationInfosForController:(FTGNotificationController *)controller
{
    NSArray *notificationInfosForController = [self notificationInfosForController:controller];
    for (FTGNotificationInfo *info in notificationInfosForController) {
        [self unobserveNotificationInfo:info];
    }
}

#pragma mark - Helper

- (NSArray *)notificationInfosForController:(FTGNotificationController *)controller
{
    OSSpinLockLock(&_sharedLock);

    NSMutableArray *notificationInfos = [NSMutableArray array];
    for (FTGNotificationInfo *info in _sharedInfos) {
        if ([info->_controller isEqual:controller]) {
            [notificationInfos addObject:info];
        }
    }

    OSSpinLockUnlock(&_sharedLock);

    return [NSArray arrayWithArray:notificationInfos];
}

- (FTGNotificationInfo *)hasNotificationInfo:(FTGNotificationInfo *)anInfo
{
    OSSpinLockLock(&_sharedLock);

    for (FTGNotificationInfo *info in _sharedInfos) {
        if ([info match:anInfo]) {
            OSSpinLockUnlock(&_sharedLock);
            return info;
        }
    }

    OSSpinLockUnlock(&_sharedLock);
    return nil;
}

@end

#pragma mark - FTGNotificationController

@implementation FTGNotificationController

#pragma mark - Lifecycle

+ (instancetype)controllerWithObserver:(id)observer
{
    return [[self alloc] initWithObserver:observer];
}

- (instancetype)initWithObserver:(id)observer
{
    self = [super init];
    if (nil != self) {
        _observer = observer;
    }

    return self;
}

- (void)dealloc
{
    [self unobserveAll];
}

- (NSString *)debugDescription
{
    NSMutableString *s = [NSMutableString stringWithFormat:@"<%@:%p>\n", NSStringFromClass([self class]), self];

    [s appendFormat:@"observer: <%@:%p>\n", NSStringFromClass([_observer class]), _observer];

    [s appendFormat:@"notification infos: \n%@", [self _notificationInfos]];

    return s;
}

#pragma mark - Utilities
- (void)submitNotificationInfoToObserve:(FTGNotificationInfo *)info
{
    [[FTGNotificationSharedController sharedController] observeNotificationInfo:info];
}

- (void)submitNotificationInfoToUnobserve:(FTGNotificationInfo *)info
{
    [[FTGNotificationSharedController sharedController] unobserveNotificationInfo:info];
}

- (void)submitAllToUnobserve
{
    [[FTGNotificationSharedController sharedController] unobserveNotificationInfosForController:self];
}

- (NSArray *)_notificationInfos
{
    return [[FTGNotificationSharedController sharedController] notificationInfosForController:self];
}

#pragma mark - API

- (void)observeNotificationName:(NSString *)notificationName
                         object:(id)object
                          queue:(NSOperationQueue *)queue
                          block:(FTGNotificationBlock)block
{
    NSAssert(block, @"missing required parameters block:%p", block);
    if (nil == block) {
        return;
    }

    // create info
    FTGNotificationInfo *info = [[FTGNotificationInfo alloc] initWithController:self
                                                               notificationName:notificationName
                                                                         object:object
                                                                          queue:queue
                                                                          block:block];
    // observe notification with info
    [self submitNotificationInfoToObserve:info];
}

- (void)observeNotificationNames:(NSArray *)notificationNames
                          object:(id)object
                           queue:(NSOperationQueue *)queue
                           block:(FTGNotificationBlock)block
{
    NSAssert(block, @"missing required parameters block:%p", block);
    if (nil == block) {
        return;
    }

    for (NSString *notificationName in notificationNames)
    {
        [self observeNotificationName:notificationName
                               object:object
                                queue:queue
                                block:block];
    }
}

- (void)observeNotificationName:(NSString *)notificationName
                         object:(id)object
                         action:(SEL)action
{
    NSAssert(nil != action, @"missing required parameters action:%@", NSStringFromSelector(action));
    NSAssert([_observer respondsToSelector:action], @"%@ does not respond to %@", _observer, NSStringFromSelector(action));
    if (nil == action) {
        return;
    }

    // create info
    FTGNotificationInfo *info = [[FTGNotificationInfo alloc] initWithController:self
                                                               notificationName:notificationName
                                                                         object:object
                                                                         action:action];

    // observe notification with info
    [self submitNotificationInfoToObserve:info];
}

- (void)observeNotificationNames:(NSArray *)notificationNames
                          object:(id)object
                          action:(SEL)action
{
    NSAssert(nil != action, @"missing required parameters action:%@", NSStringFromSelector(action));
    NSAssert([_observer respondsToSelector:action], @"%@ does not respond to %@", _observer, NSStringFromSelector(action));
    if (nil == action) {
        return;
    }

    for (NSString *notificationName in notificationNames)
    {
        [self observeNotificationName:notificationName
                               object:object
                               action:action];
    }
}

- (void)unobserveNotificationName:(NSString *)notificationName
                           object:(id)object
{
    // create representative info
    FTGNotificationInfo *info = [[FTGNotificationInfo alloc] initWithController:self
                                                               notificationName:notificationName
                                                                         object:object];
    // unobserve notification
    [self submitNotificationInfoToUnobserve:info];
}

- (void)unobserveAll
{
    [self submitAllToUnobserve];
}

@end
