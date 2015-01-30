//
//  SyncAsyncRunner.h
//  
//  A class to assist with testing Asynchronous operations.
// 
//  Instances of this class act as a drop in replacement for any asynchronous delegate
//  through dynamic proxying.
//
//  The "waitForResponseFromTarget..." methods block until this object receives some sort of callback.
//
//	Alternatively, call -stopWaiting in your delegate/block/notification callback to stop
//	blocking manuall.
//
//  Created by Nidal Fakhouri on 1/29/15.
//  Copyright (c) 2015 nidalfakhouri. All rights reserved.
//

// <mnp> code from: https://github.com/vickeryj/Demo-Reader
// <mnp 2012-Sep-13: updated for ARC

#import <Foundation/Foundation.h>


@interface SyncAsyncRunner : NSObject

// The dynamic proxy target. This is optional, but necessary if you actually
//  want to receive the callbacks that this object is proxying.
@property (nonatomic, weak) id callbackDelegate;

// How long to wait in seconds for a callback before declaring the
//  operation to be timed out. Defaults to 20.
@property (nonatomic, assign) NSTimeInterval timeout;

// How often to poll for completion; increase this from default value if the
//  long operation loses too much time because of completion polling
@property (nonatomic, assign) NSTimeInterval timeoutResolution;

- (BOOL)waitForResponse;
- (BOOL)waitForResponseFromTarget:(id)messageTarget toMessage:(SEL)message;
- (BOOL)waitForResponseFromTarget:(id)messageTarget toMessage:(SEL)message withObjects:(id)firstArg,...;

- (void)stopWaiting;
- (void)reset;

@end
