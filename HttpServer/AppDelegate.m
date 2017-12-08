//
//  AppDelegate.m
//  HttpServer
//
//  Created by wz on 2017/12/7.
//  Copyright © 2017年 wz. All rights reserved.
//

#import "AppDelegate.h"
#import "GCDAsyncUdpSocket.h"
#import "GCDAsyncSocket.h"
#import "TcpSocket.h"

@interface AppDelegate ()


@property (nonatomic, strong) GCDAsyncUdpSocket *socket;

@property (nonatomic, strong) GCDAsyncSocket *serverSocket;

@property (nonatomic, strong) GCDAsyncSocket *clientSocket;
@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    [self tcpSocket];
  
    
    return YES;
}


- (void)tcpSocket {
    
    self.serverSocket = [[GCDAsyncSocket alloc]initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    [self.serverSocket enableBackgroundingOnSocket];
    NSError * error = nil;
    [self.serverSocket acceptOnPort:8080 error:&error];
}


#pragma mark - tcp socket delegate

- (void)socket:(GCDAsyncSocket *)sock didAcceptNewSocket:(GCDAsyncSocket *)newSocket
{

    [newSocket writeData:[self endData] withTimeout:-1 tag:0];
    self.clientSocket = newSocket;
//    [self.clientSocket disconnectAfterWriting];

   
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err;
{
    NSLog(@"连接失败,要怎么做,你自己看着办吧");
    NSLog(@"%@", err);
}
- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag
{
    NSLog(@"可通过参数中的tag值管理发送的数据，想怎么管理，您看着办");
//    [self.clientSocket disconnectAfterWriting];
    [sock readDataToData:[GCDAsyncSocket CRLFData] withTimeout:-1 tag:0];
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
    
    NSData *strData = [data subdataWithRange:NSMakeRange(0, [data length] - 2)];
    NSString *msg = [[NSString alloc] initWithData:strData encoding:NSUTF8StringEncoding];
    NSLog(@"接收到消息  %@,要怎么处理，您看着办",msg);
    [sock writeData:data withTimeout:-1 tag:-1];
    [self.clientSocket disconnectAfterReadingAndWriting];
}


- (NSData *)endData {
    
    NSMutableString *dataStr = [NSMutableString string];
    [dataStr appendString:@"HTTP/1.1 200 OK"];
    [dataStr appendString:@"Server: nginx/1.12.2"];
    [dataStr appendString:@"Date: Fri, 08 Dec 2017 02:40:55 GMT"];
    [dataStr appendString:@"Content-Type: application/json"];
    [dataStr appendString:@"X-Powered-By: Express"];
    [dataStr appendString:@"Transfer-Encoding: chunked"];
    [dataStr appendString:@"Proxy-Connection: Keep-alive"];
    [dataStr appendString:@"\r\n"];
    [dataStr appendString:@"{\"code\":0,\"msg\":\"success\",\"data\":{}}"];
    [dataStr appendString:@"\r\n"];
    [dataStr appendString:@"\r\n"];
    
    return [dataStr dataUsingEncoding:(NSUTF8StringEncoding)];
}


- (void)udpSocket {
    
    GCDAsyncUdpSocket *socket = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
    
    NSError *error = nil;
    
    //绑定本地端口
    [socket bindToPort:8080 error:&error];
    
    if (error) {
        NSLog(@"1:%@",error);
        return;
    }
    
    if (error) {
        NSLog(@"2:%@",error);
        return;
    }
    
    //开始接收数据(不然会收不到数据)
    [socket beginReceiving:&error];
    
    if (error) {
        NSLog(@"3:%@",error);
        return;
    }
    
    self.socket = socket;
    
    //重复发送广播
//    NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(broadcast) userInfo:nil repeats:YES];
    
    
//    [timer fire];
}

#pragma mark - udp socket delegate



/**
 * By design, UDP is a connectionless protocol, and connecting is not needed.
 * However, you may optionally choose to connect to a particular host for reasons
 * outlined in the documentation for the various connect methods listed above.
 *
 * This method is called if one of the connect methods are invoked, and the connection is successful.
 **/
- (void)udpSocket:(GCDAsyncUdpSocket *)sock didConnectToAddress:(NSData *)address {
    NSLog(@"%s", __func__);
}

/**
 * By design, UDP is a connectionless protocol, and connecting is not needed.
 * However, you may optionally choose to connect to a particular host for reasons
 * outlined in the documentation for the various connect methods listed above.
 *
 * This method is called if one of the connect methods are invoked, and the connection fails.
 * This may happen, for example, if a domain name is given for the host and the domain name is unable to be resolved.
 **/
- (void)udpSocket:(GCDAsyncUdpSocket *)sock didNotConnect:(NSError * _Nullable)error {
    NSLog(@"%s", __func__);
}

/**
 * Called when the datagram with the given tag has been sent.
 **/
- (void)udpSocket:(GCDAsyncUdpSocket *)sock didSendDataWithTag:(long)tag {
    NSLog(@"%s", __func__);
}

/**
 * Called if an error occurs while trying to send a datagram.
 * This could be due to a timeout, or something more serious such as the data being too large to fit in a sigle packet.
 **/
- (void)udpSocket:(GCDAsyncUdpSocket *)sock didNotSendDataWithTag:(long)tag dueToError:(NSError * _Nullable)error {
    NSLog(@"%s", __func__);
}


/**
 * Called when the socket is closed.
 **/
- (void)udpSocketDidClose:(GCDAsyncUdpSocket *)sock withError:(NSError  * _Nullable)error {
    NSLog(@"%s", __func__);
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didReceiveData:(NSData *)data fromAddress:(NSData *)address withFilterContext:(id)filterContext{
    
    NSString *msg = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    NSLog(@"%@",msg);
}



- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}


@end
