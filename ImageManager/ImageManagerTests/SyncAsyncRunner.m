//
//  SyncAsyncRunner.m
//  
//  Created by Nidal Fakhouri on 1/29/15.
//  Copyright (c) 2015 nidalfakhouri. All rights reserved.
//

#import "SyncAsyncRunner.h"

@interface SyncAsyncRunner ()

@property (nonatomic, assign) BOOL callbackReceived;

@end


@implementation SyncAsyncRunner

@synthesize callbackDelegate, timeout, timeoutResolution;

- (id)init
{
	self = [super init];
	if (self != nil) {
		self.timeout = 20;
        self.timeoutResolution = 0.01f;
	}
	return self;
}


- (BOOL)waitForCallback {
    NSDate *startTime = [NSDate date];
	NSRunLoop *rl = [NSRunLoop currentRunLoop];
	while ([[NSDate date] timeIntervalSinceDate:startTime] < timeout && !self.callbackReceived)
	{
		//wait for a callback to happen while spinning the run loop by hand
		[rl runUntilDate:[NSDate dateWithTimeIntervalSinceNow:self.timeoutResolution]];
	}
	return self.callbackReceived;
}

- (BOOL)waitForResponse{
    return [self waitForCallback];
}

- (BOOL)waitForResponseFromTarget:(id)messageTarget toMessage:(SEL)message {
    self.callbackReceived = NO;
    
    // some #pragma-fu to disable warning about performSelector with unknown selector causing a leak
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    
	[messageTarget performSelector:message];
    
#pragma clang diagnostic pop
	
	return [self waitForCallback];
}

- (BOOL)waitForResponseFromTarget:(id)messageTarget toMessage:(SEL)message withObjects:(id)firstArg,... {
    self.callbackReceived = NO;
    
	//create an NSInvocation for the message we are trying to
	NSMethodSignature *methodSignature = [messageTarget methodSignatureForSelector:message];
	NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:methodSignature];
	[invocation setTarget:messageTarget];
	[invocation setSelector:message];
	
	NSInteger numArguments = [methodSignature numberOfArguments];
	if (numArguments > 2) {
		[invocation setArgument:&firstArg atIndex:2]; //we start at idx 2 to account for the hidden "self" and "cmd" args
		if (numArguments > 3) {
			va_list arglist;
			va_start(arglist, firstArg);
			for (int i = 3 ; i < numArguments; i++) {//start at 3
				id arg = va_arg(arglist,id);
				[invocation setArgument:&arg atIndex:i];
			}
			va_end(arglist);
		}
		[invocation retainArguments];
	}
	
	[invocation invoke];
	
	return [self waitForCallback];
	
}

- (void)stopWaiting
{
    self.callbackReceived = YES;
}

- (void)reset
{
    self.callbackReceived = NO;
}

- (BOOL)respondsToSelector:(SEL)aSelector {
    BOOL respondsToSelector = [super respondsToSelector:aSelector];
    if (!respondsToSelector) {
        respondsToSelector = [callbackDelegate respondsToSelector:aSelector];
    }
    return respondsToSelector;
}

//handle all callbacks
-(NSMethodSignature*)methodSignatureForSelector:(SEL)selector
{
	NSMethodSignature *signature;
	signature = [super methodSignatureForSelector:selector];
	if (nil == signature) {
		signature = [self.callbackDelegate methodSignatureForSelector:selector];
	}
	if (nil == signature) {
		signature = [NSMethodSignature signatureWithObjCTypes:"@^v^c"];
	}
	return signature;
}

- (void)forwardInvocation:(NSInvocation *)anInvocation {
    [self stopWaiting];
	if (nil != self.callbackDelegate) {
		[anInvocation setTarget:self.callbackDelegate];
		[anInvocation invoke];
	}
}


@end
