//
//  AppDelegate.m
//  ServerSocketReopenBug
//
//  Created by Diego Pereira on 3/16/15.
//  Copyright (c) 2015 Conflux. All rights reserved.
//

#import "AppDelegate.h"
#import <sys/socket.h>
#import <netinet/in.h>
#import <arpa/inet.h>

static void _handleConnect(CFSocketRef socket, CFSocketCallBackType type, CFDataRef address, const void* data, void* info)
{
    NSLog(@"Connected ...");
    close(*(CFSocketNativeHandle*)data);
    NSLog(@"Closed ...");
}

@interface AppDelegate ()

@end

@implementation AppDelegate {
    CFRunLoopSourceRef _source;
    CFSocketRef _serverSocket;
    CFRunLoopRef _socketRunLoop;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    
    CFRunLoopRemoveSource(self->_socketRunLoop, self->_source, kCFRunLoopCommonModes);
    CFRunLoopSourceInvalidate(self->_source);
    CFRelease(self->_source);
    self->_source = nil;
    
    CFSocketInvalidate(self->_serverSocket);
    CFRelease(self->_serverSocket);
    self->_serverSocket = nil;
    
    CFRunLoopStop(self->_socketRunLoop);
    
    NSLog(@"RELASED SUCCESSFULLY!");
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    CFSocketContext ctx = {0, (__bridge void*)self, NULL, NULL, NULL};
    self->_serverSocket = CFSocketCreate(kCFAllocatorDefault,
                                        PF_INET,
                                        SOCK_STREAM,
                                        IPPROTO_TCP,
                                        kCFSocketAcceptCallBack, _handleConnect, &ctx);
    
    NSLog(@"Socket created %u", self->_serverSocket != NULL);
    
    struct sockaddr_in sin;
    memset(&sin, 0, sizeof(sin));
    sin.sin_len = sizeof(sin);
    sin.sin_family = AF_INET;
    sin.sin_port = htons(30000);
    sin.sin_addr.s_addr= INADDR_ANY;
    
    CFDataRef sincfd = CFDataCreate(kCFAllocatorDefault,
                                    (UInt8 *)&sin,
                                    sizeof(sin));
    CFSocketSetAddress(self->_serverSocket, sincfd);
    CFRelease(sincfd);
    

    self->_source = CFSocketCreateRunLoopSource(kCFAllocatorDefault,
                                               self->_serverSocket,
                                               0);
    
    NSLog(@"Created source %u", self->_source != NULL);
    
    self->_socketRunLoop = CFRunLoopGetCurrent();
    CFRunLoopAddSource(self->_socketRunLoop,
                       self->_source,
                       kCFRunLoopCommonModes);
    
    NSLog(@"Registered into run loop");
    NSLog(@"Socket is %s", CFSocketIsValid(self->_serverSocket) ? "valid" : "invalid");
    NSLog(@"Source is %s", CFRunLoopSourceIsValid(self->_source) ? "valid" : "invalid");
}

@end

