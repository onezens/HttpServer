//
//  TcpSocket.m
//  HttpServer
//
//  Created by wz on 2017/12/8.
//  Copyright © 2017年 wz. All rights reserved.
//

#import "TcpSocket.h"
#import <UIKit/UIKit.h>

#import "GCDAsyncSocket.h"


#define WELCOME_MSG  0
#define ECHO_MSG     1
#define WARNING_MSG  2

#define READ_TIMEOUT 15.0
#define READ_TIMEOUT_EXTENSION 10.0

#define FORMAT(format, ...) [NSString stringWithFormat:(format), ##__VA_ARGS__]

@interface TcpSocket()
{
    dispatch_queue_t socketQueue;
    
    GCDAsyncSocket *listenSocket;
    NSMutableArray *connectedSockets;
    
    BOOL isRunning;
    
}
@end


@implementation TcpSocket


- (id)init
{
    if((self = [super init]))
    {
        // Setup our logging framework.
        
    
        
        // Setup our socket.
        // The socket will invoke our delegate methods using the usual delegate paradigm.
        // However, it will invoke the delegate methods on a specified GCD delegate dispatch queue.
        //
        // Now we can configure the delegate dispatch queues however we want.
        // We could simply use the main dispatc queue, so the delegate methods are invoked on the main thread.
        // Or we could use a dedicated dispatch queue, which could be helpful if we were doing a lot of processing.
        //
        // The best approach for your application will depend upon convenience, requirements and performance.
        
        socketQueue = dispatch_queue_create("socketQueue", NULL);
        
        listenSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:socketQueue];
        
        // Setup an array to store all accepted client connections
        connectedSockets = [[NSMutableArray alloc] initWithCapacity:1];
        
        isRunning = NO;
    }
    return self;
}




- (void)logError:(NSString *)msg
{
    
    NSLog(@"logError: %@", msg);
}

- (void)logInfo:(NSString *)msg
{
    NSLog(@"logInfo : %@", msg);
}

- (void)logMessage:(NSString *)msg
{
    NSLog(@"logMessage: %@", msg);
}

- (void)startStop
{
    if(!isRunning)
    {
        int port = 8081;
        
        NSError *error = nil;
        if(![listenSocket acceptOnPort:port error:&error])
        {
            [self logError:FORMAT(@"Error starting server: %@", error)];
            return;
        }
        
        [self logInfo:FORMAT(@"Echo server started on port %hu", [listenSocket localPort])];
        isRunning = YES;
        
    }
    else
    {
        // Stop accepting connections
        [listenSocket disconnect];
        
        // Stop any client connections
        @synchronized(connectedSockets)
        {
            NSUInteger i;
            for (i = 0; i < [connectedSockets count]; i++)
            {
                // Call disconnect on the socket,
                // which will invoke the socketDidDisconnect: method,
                // which will remove the socket from the list.
                [[connectedSockets objectAtIndex:i] disconnect];
            }
        }
        
        [self logInfo:@"Stopped Echo server"];
        isRunning = false;
        
    }
}

- (void)socket:(GCDAsyncSocket *)sock didAcceptNewSocket:(GCDAsyncSocket *)newSocket
{
    // This method is executed on the socketQueue (not the main thread)
    
    @synchronized(connectedSockets)
    {
        [connectedSockets addObject:newSocket];
    }
    
    NSString *host = [newSocket connectedHost];
    UInt16 port = [newSocket connectedPort];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        @autoreleasepool {
            
            [self logInfo:FORMAT(@"Accepted client %@:%hu", host, port)];
            
        }
    });
    
    NSString *welcomeMsg = @"Welcome to the AsyncSocket Echo Server\r\n";
    NSData *welcomeData = [welcomeMsg dataUsingEncoding:NSUTF8StringEncoding];
    
    [newSocket writeData:welcomeData withTimeout:-1 tag:WELCOME_MSG];
    
    [newSocket readDataToData:[GCDAsyncSocket CRLFData] withTimeout:READ_TIMEOUT tag:0];
}

- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag
{
    // This method is executed on the socketQueue (not the main thread)
    
    if (tag == ECHO_MSG)
    {
        [sock readDataToData:[GCDAsyncSocket CRLFData] withTimeout:READ_TIMEOUT tag:0];
    }
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
    // This method is executed on the socketQueue (not the main thread)
    
    dispatch_async(dispatch_get_main_queue(), ^{
        @autoreleasepool {
            
            NSData *strData = [data subdataWithRange:NSMakeRange(0, [data length] - 2)];
            NSString *msg = [[NSString alloc] initWithData:strData encoding:NSUTF8StringEncoding];
            if (msg)
            {
                [self logMessage:msg];
            }
            else
            {
                [self logError:@"Error converting received data into UTF-8 String"];
            }
            
        }
    });
    
    // Echo message back to client
    [sock writeData:data withTimeout:-1 tag:ECHO_MSG];
}

/**
 * This method is called if a read has timed out.
 * It allows us to optionally extend the timeout.
 * We use this method to issue a warning to the user prior to disconnecting them.
 **/
- (NSTimeInterval)socket:(GCDAsyncSocket *)sock shouldTimeoutReadWithTag:(long)tag
                 elapsed:(NSTimeInterval)elapsed
               bytesDone:(NSUInteger)length
{
    if (elapsed <= READ_TIMEOUT)
    {
        NSString *warningMsg = @"Are you still there?\r\n";
        NSData *warningData = [warningMsg dataUsingEncoding:NSUTF8StringEncoding];
        
        [sock writeData:warningData withTimeout:-1 tag:WARNING_MSG];
        
        return READ_TIMEOUT_EXTENSION;
    }
    
    return 0.0;
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err
{
    if (sock != listenSocket)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            @autoreleasepool {
                
                [self logInfo:FORMAT(@"Client Disconnected")];
                
            }
        });
        
        @synchronized(connectedSockets)
        {
            [connectedSockets removeObject:sock];
        }
    }
}





@end
