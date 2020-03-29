#import "QiniuStoragePlugin.h"
#import "QiniuSDK.h"

@interface QiniuStoragePlugin() <FlutterStreamHandler>

@property BOOL isCanceled;
@property FlutterEventSink eventSink;

@end

@implementation QiniuStoragePlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    NSString *eventChannelName  = @"qiniu_plugin_event";
  FlutterMethodChannel* channel = [FlutterMethodChannel
      methodChannelWithName:@"qiniu_plugin"
            binaryMessenger:[registrar messenger]];
    
    FlutterEventChannel *eventChannel = [FlutterEventChannel eventChannelWithName:eventChannelName binaryMessenger:registrar.messenger];
  QiniuStoragePlugin* instance = [[QiniuStoragePlugin alloc] init];
  [registrar addMethodCallDelegate:instance channel:channel];
    [eventChannel setStreamHandler:instance];
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
  if ([@"getPlatformVersion" isEqualToString:call.method]) {
    result([@"iOS " stringByAppendingString:[[UIDevice currentDevice] systemVersion]]);
  }else if ([@"upload" isEqualToString:call.method]){
      [self upload:call result:result];
  } else if ([@"cancelUpload" isEqualToString:call.method]){
      [self cancelUpload:call result:result];
  }else {
    result(FlutterMethodNotImplemented);
  }
}

- (void)upload:(FlutterMethodCall*)call result:(FlutterResult)result{
    self.isCanceled = FALSE;
    
    NSString *filepath = call.arguments[@"filepath"];
    NSString *key = call.arguments[@"key"];
    NSString *token = call.arguments[@"token"];
    
    QNUploadOption *opt = [[QNUploadOption alloc] initWithMime:nil progressHandler:^(NSString *key, float percent) {
        NSLog(@"progress %f",percent);
        if (self.eventSink != nil) {
            self.eventSink(@(percent));
        }
    } params:nil checkCrc:NO cancellationSignal:^BOOL{
        return self.isCanceled;
    }];
    
    QNUploadManager *manager = [[QNUploadManager alloc] init];
    [manager putFile:filepath key:key token:token complete:^(QNResponseInfo *info, NSString *key, NSDictionary *resp) {
        NSLog(@"info %@", info);
        NSLog(@"resp %@",resp);
        
        NSError *error = nil;
        NSData *jsonData = nil;
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        [resp enumerateKeysAndObjectsUsingBlock:^(id _Nonnull key, id _Nonnull obj, BOOL * _Nonnull stop) {
          NSString *keyString = nil;
          NSString *valueString = nil;
          if ([key isKindOfClass:[NSString class]]) {
            keyString = key;
          }else{
            keyString = [NSString stringWithFormat:@"%@",key];
          }
         
          if ([obj isKindOfClass:[NSString class]]) {
            valueString = obj;
          }else{
            valueString = [NSString stringWithFormat:@"%@",obj];
          }
         
          [dict setObject:valueString forKey:keyString];
        }];
        jsonData = [NSJSONSerialization dataWithJSONObject:dict options:NSJSONWritingPrettyPrinted error:&error];
        NSString *respString = @"";
        if ([jsonData length] != 0 && error == nil) {
          respString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        }
        
        result(@{@"result":info.isOK?@(1):@(0), @"data":@[[info description], respString]});
    } option:(QNUploadOption *) opt];
}

- (void)cancelUpload:(FlutterMethodCall*)call result:(FlutterResult)result{
    self.isCanceled = TRUE;
}

- (FlutterError * _Nullable)onCancelWithArguments:(id _Nullable)arguments {
    self.isCanceled = TRUE;
    self.eventSink = nil;
    return nil;
}

- (FlutterError * _Nullable)onListenWithArguments:(id _Nullable)arguments eventSink:(nonnull FlutterEventSink)events {
    self.isCanceled = FALSE;
    self.eventSink = events;
    return nil;
}

@end
