import 'dart:async';

import 'package:flutter/services.dart';

typedef onData = void Function(dynamic event);

class QiniuStorage {
  static const MethodChannel _channel =
      const MethodChannel('qiniu_plugin');
  static const EventChannel _eventChannel =
      const EventChannel('qiniu_plugin_event');

  Stream _onChanged;

  Stream onChanged() {
    if (_onChanged == null) {
      _onChanged = _eventChannel.receiveBroadcastStream();
    }
    return _onChanged;
  }

  ///上传
  ///
  /// key 保存到七牛的文件名
  Future<Map> upload(String filepath, String token, String key) async {
    var res = await _channel.invokeMethod('upload',
        <String, String>{"filepath": filepath, "token": token, "key": key});
    return res;
  }

  /// 取消上传
  static cancelUpload() {
    _channel.invokeMethod('cancelUpload');
  }
}
