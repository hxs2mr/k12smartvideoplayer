import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:smartplayer_native_view/smartplayer.dart';
import 'package:smartplayer_native_view/smartplayer_plugin.dart';

void main() => runApp(new MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => new _MyAppState();
}

class _MyAppState extends State<MyApp> {
  SmartPlayerController player;
  double aspectRatio = 4.0 / 3.0;

  //输入需要播放的RTMP/RTSP url
  TextEditingController playback_url_controller_ = TextEditingController();

  //Event事件回调显示
  TextEditingController event_controller_ = TextEditingController();

  bool is_playing_ = false;
  bool is_mute_ = false;

  var rotate_degrees_ = 0;

  Widget smartPlayerView() {
    return SmartPlayerWidget(
      onSmartPlayerCreated: onSmartPlayerCreated,
    );
  }

  @override
  void initState() {
    print("initState called..");
    super.initState();
  }

  @override
  void didChangeDependencies() {
    print('didChangeDependencies called..');
    super.didChangeDependencies();
  }

  @override
  void deactivate() {
    print('deactivate called..');
    super.deactivate();
  }

  @override
  void dispose() {
    print("dispose called..");
    player.dispose();
    event_controller_.dispose();
    playback_url_controller_.dispose();


    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
          appBar: AppBar(
            title: const Text('flutter直播测试'),
          ),
          body: new SingleChildScrollView(
            child: new Column(
              children: <Widget>[
                new Container(
                  color: Colors.black,
                  child: AspectRatio(
                    child: smartPlayerView(),
                    aspectRatio: aspectRatio,
                  ),
                ),
                new TextField(
                  controller: playback_url_controller_,
                  keyboardType: TextInputType.text,
                  decoration: InputDecoration(
                    contentPadding: EdgeInsets.all(10.0),
                    icon: Icon(Icons.link),
                    labelText: '请输入RTSP/RTMP url',
                  ),
                  autofocus: false,
                ),
                new Row(
                  children: [
                    new RaisedButton(
                        onPressed: this.onSmartPlayerStartPlay,
                        child: new Text("开始播放")),
                    new Container(width: 20),
                    new RaisedButton(
                        onPressed: this.onSmartPlayerStopPlay,
                        child: new Text("停止播放")),
                    new Container(width: 20),
                    new RaisedButton(
                        onPressed: this.onSmartPlayerMute,
                        child: new Text("静音")),
                  ],
                ),
                new Row(
                  children: [
                    new RaisedButton(
                        onPressed: this.onSmartPlayerSwitchUrl,
                        child: new Text("切换URL")),
                    new Container(width: 20),
                    new RaisedButton(
                        onPressed: this.onSmartPlayerSetRotation,
                        child: new Text("旋转View")),
                  ],
                ),
                new TextField(
                  controller: event_controller_,
                  keyboardType: TextInputType.text,
                  decoration: InputDecoration(
                    contentPadding: EdgeInsets.all(10.0),
                    icon: Icon(Icons.event_note),
                    labelText: 'Event状态回调',
                  ),
                  autofocus: false,
                ),
              ],
            ),
          )),
    );
  }

  void _eventCallback(int code, String param1, String param2, String param3) {
    String event_str;

    switch (code) {
      case EVENTID.EVENT_DANIULIVE_ERC_PLAYER_STARTED:
        event_str = "开始..";
        break;
      case EVENTID.EVENT_DANIULIVE_ERC_PLAYER_CONNECTING:
        event_str = "连接中..";
        break;
      case EVENTID.EVENT_DANIULIVE_ERC_PLAYER_CONNECTION_FAILED:
        event_str = "连接失败..";
        break;
      case EVENTID.EVENT_DANIULIVE_ERC_PLAYER_CONNECTED:
        event_str = "连接成功..";
        break;
      case EVENTID.EVENT_DANIULIVE_ERC_PLAYER_DISCONNECTED:
        event_str = "连接断开..";
        break;
      case EVENTID.EVENT_DANIULIVE_ERC_PLAYER_STOP:
        event_str = "停止播放..";
        break;
      case EVENTID.EVENT_DANIULIVE_ERC_PLAYER_RESOLUTION_INFO:
        event_str = "分辨率信息: width: " + param1 + ", height: " + param2;
        setState(() {
          aspectRatio = double.parse(param1) / double.parse(param2);
          print('change aspectRatio:$aspectRatio');
        });
        break;
      case EVENTID.EVENT_DANIULIVE_ERC_PLAYER_NO_MEDIADATA_RECEIVED:
        event_str = "收不到媒体数据，可能是url错误..";
        break;
      case EVENTID.EVENT_DANIULIVE_ERC_PLAYER_SWITCH_URL:
        event_str = "切换播放URL..";
        break;
      case EVENTID.EVENT_DANIULIVE_ERC_PLAYER_CAPTURE_IMAGE:
        event_str = "快照: " + param1 + " 路径: " + param3;

        if (int.parse(param1) == 0) {
          print("截取快照成功。.");
        } else {
          print("截取快照失败。.");
        }
        break;
      case EVENTID.EVENT_DANIULIVE_ERC_PLAYER_RECORDER_START_NEW_FILE:
        event_str = "[record] new file: " + param3;
        break;
      case EVENTID.EVENT_DANIULIVE_ERC_PLAYER_ONE_RECORDER_FILE_FINISHED:
        event_str = "[record] record finished: " + param3;
        break;
      case EVENTID.EVENT_DANIULIVE_ERC_PLAYER_START_BUFFERING:
      //event_str = "Start Buffering";
        break;
      case EVENTID.EVENT_DANIULIVE_ERC_PLAYER_BUFFERING:
        event_str = "Buffering: " + param1 + "%";
        break;
      case EVENTID.EVENT_DANIULIVE_ERC_PLAYER_STOP_BUFFERING:
      //event_str = "Stop Buffering";
        break;
      case EVENTID.EVENT_DANIULIVE_ERC_PLAYER_DOWNLOAD_SPEED:
        event_str = "download_speed:" +
            (double.parse(param1) * 8 / 1000).toStringAsFixed(0) +
            "kbps" +
            ", " +
            (double.parse(param1) / 1024).toStringAsFixed(0) +
            "KB/s";
        break;
    }

    event_controller_.text = event_str;
  }

  void onSmartPlayerCreated(SmartPlayerController controller) async {
    player = controller;
    player.setEventCallback(_eventCallback);

    var ret = -1;

    //设置video decoder模式
    var is_video_hw_decoder = 0;
    if (defaultTargetPlatform == TargetPlatform.android)
    {
      ret = await player.setVideoDecoderMode(is_video_hw_decoder);
    }
    else if(defaultTargetPlatform == TargetPlatform.iOS)
    {
      is_video_hw_decoder = 1;
      ret = await player.setVideoDecoderMode(is_video_hw_decoder);
    }

    //设置缓冲时间
    var play_buffer = 100;
    ret = await player.setBuffer(play_buffer);

    //设置快速启动
    var is_fast_startup = 1;
    ret = await player.setFastStartup(is_fast_startup);

    //是否开启低延迟模式
    var is_low_latency_mode = 0;
    ret = await player.setPlayerLowLatencyMode(is_low_latency_mode);

    //set report download speed(默认5秒一次回调 用户可自行调整report间隔)
    ret = await player.setReportDownloadSpeed(1, 2);

    //设置RTSP超时时间
    var rtsp_timeout = 10;
    ret = await player.setRTSPTimeout(rtsp_timeout);

    var is_auto_switch_tcp_udp = 1;
    ret = await player.setRTSPAutoSwitchTcpUdp(is_auto_switch_tcp_udp);

    // 设置RTSP TCP模式
    //ret = await player.setRTSPTcpMode(1);

    //第一次启动 为方便测试 设置个初始url
    playback_url_controller_.text = "rtmp://live.hkstv.hk.lxdns.com/live/hks1";
  }

  Future<void> onSmartPlayerStartPlay() async {
    var ret = -1;

    if (playback_url_controller_.text.length < 8) {
      playback_url_controller_.text =
      "rtmp://live.hkstv.hk.lxdns.com/live/hks1"; //给个初始url
    }

    //实时静音设置
    ret = await player.setMute(is_mute_ ? 1 : 0);

    if (!is_playing_) {
      ret = await player.setUrl(playback_url_controller_.text);
      ret = await player.startPlay();

      if (ret == 0) {
        is_playing_ = true;
      }
    }
  }

  Future<void> onSmartPlayerStopPlay() async {
    if (is_playing_) {
      await player.stopPlay();
      playback_url_controller_.clear();
      is_playing_ = false;
      is_mute_ = false;
    }
  }

  Future<void> onSmartPlayerMute() async {
    if (is_playing_) {
      is_mute_ = !is_mute_;
      await player.setMute(is_mute_ ? 1 : 0);
    }
  }

  Future<void> onSmartPlayerSwitchUrl() async {
    if (is_playing_) {
      if (playback_url_controller_.text.length < 8) {
        playback_url_controller_.text =
        "rtmp://live.hkstv.hk.lxdns.com/live/hks1";
      }

      await player.switchPlaybackUrl(playback_url_controller_.text);
    }
  }

  Future<void> onSmartPlayerSetRotation() async {
    if (is_playing_) {
      rotate_degrees_ += 90;
      rotate_degrees_ = rotate_degrees_ % 360;

      if (0 == rotate_degrees_) {
        print("旋转90度");
      } else if (90 == rotate_degrees_) {
        print("旋转180度");
      } else if (180 == rotate_degrees_) {
        print("旋转270度");
      } else if (270 == rotate_degrees_) {
        print("不旋转");
      }

      await player.setRotation(rotate_degrees_);
    }
  }
}
