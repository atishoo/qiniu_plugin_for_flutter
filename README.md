# qiniu_storage_plugin

感谢lishuhao的源码，对返回值做了一些修改

七牛云对象存储SDK，兼容iOS和Android
- 上传大文件
- 进度监听
- 取消上传

### 官方文档
- [iOS](https://developer.qiniu.com/kodo/sdk/1240/objc)
- [Android](https://developer.qiniu.com/kodo/sdk/1236/android)

### 使用方法
```dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:qiniu_storage_plugin/qiniu_plugin.dart';

void main() => runApp(new MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => new _MyAppState();
}

class _MyAppState extends State<MyApp> {
  double _process = 0.0;

  @override
  void initState() {
    super.initState();
  }

  _onUpload() async {
    String token = '从服务端获取的token';
    File file = await ImagePicker.pickVideo(source: ImageSource.camera);
    if (file == null) {
      return;
    }
    final qiniu = new QiniuStorage();
    //监听上传进度
    qiniu.onChanged().listen((dynamic percent) {
      double p = percent;
      setState(() {
        _process = p;
      });
      print(percent);
    });

    String key = DateTime.now().millisecondsSinceEpoch.toString() +
        '.' +
        file.path.split('.').last;
    //上传文件
    bool upresult = await qiniu.upload(file.path, token, key);
    print(upresult);//result为Map，包含result，data两个键值，result为1，则上传成功，0表示上传失败，data为数组，数组内固定两个值且均为字符串
  }

  //取消上传
  _onCancel() {
    qiniu.cancelUpload();
  }

  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      home: new Scaffold(
        appBar: new AppBar(
          title: const Text('七牛云存储SDK demo'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: new Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              LinearProgressIndicator(
                value: _process,
              ),
              RaisedButton(
                child: Text('上传'),
                onPressed: _onUpload,
              ),
              RaisedButton(
                child: Text('取消上传'),
                onPressed: _onCancel,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

### 上传的返回值
为Map，包含result，data两个键值，result为1，则上传成功，0表示上传失败，data为数组，数组内固定两个值且均为字符串
如：
```json
{"result": 1, "data": ["{ver:7.3.15,ResponseInfo:1585488889146607,status:200, reqId:ZzcAAAAJ0pm7zAAW, xlog:X-Log, xvia:, host:upload.qiniup.com, path:/, ip:223.112.103.86, port:443, duration:142 s, time:1585492175, sent:80713,error:null}", '{"type":".jpg","path":"avatar_1_1585492174","size":79652,"property":"367*367"}']}
```