import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

import '../custom_image_view.dart';

class AgoraHelper {
  String? channelName = "TEST_SCREEN_SHARE";
  String appId = "1e25187033a74bf3ab10056a6540231e";
  String? token;

  Rx<bool> isVideoOn = Rx(true);
  Rx<bool> isMicOn = Rx(true);
  Rx<bool> isSharing = Rx(false);

  // bool sharingStarted = false;

  int? uid;
  int? mentorUid;
  int? _visibleUid;
  bool isJoined = false; // Indicates if the local user has joined the channel
  RtcEngine? agoraEngine; // Agora engine instance

  Rx<Widget?> mentorView = Rx(null);

  List<User> usersInCallExceptFullView = [];

  var lastUserSwitched = 0;

  int getVisibleUserId() {
    return _visibleUid ?? (mentorUid == getUserNo() ? -1 : mentorUid) ?? 0;
  }

  Future<void> setupAgoraEngine(
      {String? token,
      int? uid,
      required ClientRoleType clientRoleType,
      required mentorUid}) async {
    this.token = token;
    this.uid = uid ?? 101;
    this.mentorUid = mentorUid;
    // Retrieve or request camera and microphone permissions
    await [Permission.microphone, Permission.camera].request();

    // Create an instance of the Agora engine
    agoraEngine = createAgoraRtcEngine();
    await agoraEngine?.initialize(RtcEngineContext(
      appId: this.appId,
      channelProfile: ChannelProfileType.channelProfileCommunication,
    ));
    await agoraEngine?.enableVideo();

    await agoraEngine?.enableAudioVolumeIndication(
        interval: 1000, smooth: 3, reportVad: true);

    // Register the event handler
    agoraEngine?.registerEventHandler(getEventHandler());
    await agoraEngine?.enableWebSdkInteroperability(true);
    // await agoraEngine?.setParameters(
    //     '''{\"che.video.lowBitRateStreamParameter\":{\"width\":320,\"height\":180,\"frameRate\":15,\"bitRate\":140}}''');

    await agoraEngine?.joinChannel(
        token: token ?? "",
        channelId: channelName ?? "",
        uid: this.uid!,
        options: ChannelMediaOptions(// clientRoleType: clientRoleType,
            ));
  }

  RtcEngineEventHandler getEventHandler() {
    return RtcEngineEventHandler(
      // Occurs when the network connection state changes
      onConnectionStateChanged: (RtcConnection connection,
          ConnectionStateType state, ConnectionChangedReasonType reason) {
        if (reason ==
            ConnectionChangedReasonType.connectionChangedLeaveChannel) {
          isJoined = false;
        }
        // Notify the UI
        Map<String, dynamic> eventArgs = {};
        eventArgs["connection"] = connection;
        eventArgs["state"] = state;
        eventArgs["reason"] = reason;
        eventCallback("onConnectionStateChanged", eventArgs);
      },
      // Occurs when a local user joins a channel
      onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
        isJoined = true;
        messageCallback(
            "Local user uid:${connection.localUid} joined the channel");
        // Notify the UI
        Map<String, dynamic> eventArgs = {};
        eventArgs["connection"] = connection;
        eventArgs["elapsed"] = elapsed;
        eventCallback("onJoinChannelSuccess", eventArgs);
        uid = connection.localUid;
        // remoteViewId.add(User(uid ?? 0, false));
      },
      // Occurs when a remote user joins the channel
      onUserJoined:
          (RtcConnection connection, int remoteUid, int elapsed) async {
        messageCallback("Remote user uid:$remoteUid joined the channel");
        // Notify the UI
        Map<String, dynamic> eventArgs = {};
        eventArgs["connection"] = connection;
        eventArgs["remoteUid"] = remoteUid;
        eventArgs["elapsed"] = elapsed;

        eventCallback("onUserJoined", eventArgs);
        await addRemoteView(remoteUid: remoteUid);
      },
      // Occurs when a remote user leaves the channel
      onUserOffline: (RtcConnection connection, int remoteUid,
          UserOfflineReasonType reason) {
        messageCallback("Remote user uid:$remoteUid left the channel");
        // Notify the UI
        Map<String, dynamic> eventArgs = {};
        eventArgs["connection"] = connection;
        eventArgs["remoteUid"] = remoteUid;
        eventArgs["reason"] = reason;
        eventCallback("onUserOffline", eventArgs);
        findAndRemoveId(remoteUid: remoteUid);
      },
      onRemoteVideoStateChanged: (RtcConnection connection,
          int remoteUid,
          RemoteVideoState state,
          RemoteVideoStateReason reason,
          int elapsed) async {
        messageCallback("onRemoteVideoStats ${state}");

        await updateRemoteView(remoteUid: remoteUid, state: state);
      },
      onLocalVideoStateChanged: (VideoSourceType source,
          LocalVideoStreamState state, LocalVideoStreamReason reason) async {
        messageCallback("onLocalVideoStateChanged ${source} ${reason}");
        if (!(source == VideoSourceType.videoSourceScreen ||
            source == VideoSourceType.videoSourceScreenPrimary)) {
          var local = localVideoView(localUid: uid, sourceType: source);
          if (state == LocalVideoStreamState.localVideoStreamStateEncoding) {
            handleBlurLocal(local);
          } else if (state ==
              LocalVideoStreamState.localVideoStreamStateStopped) {
            handleBlurLocal(local, skipElse: true, isBlur: true);
          }
          return;
        }

        switch (state) {
          // case LocalVideoStreamState.localVideoStreamStateCapturing:
          case LocalVideoStreamState.localVideoStreamStateEncoding:
            isSharing.value = true;
            break;
          case LocalVideoStreamState.localVideoStreamStateStopped:
            isSharing.value = false;
            break;
          case LocalVideoStreamState.localVideoStreamStateFailed:
            await stopScreenShare(
                isAudio: isMicOn.value, isVideo: isVideoOn.value);
            break;
          default:
            break;
        }
      },
    );
  }

  void handleBlurLocal(Widget local,
      {bool skipElse = false, bool isBlur = false}) async {
    var indexOfUser =
        usersInCallExceptFullView.indexWhere((element) => element.uid == uid);
    if (indexOfUser != -1) {
      var item = usersInCallExceptFullView[indexOfUser];
      item.remoteWidget.value =
          isBlur ? remoteVideoView(remoteUid: uid!, isBlur: true) : local;
    } else if (_visibleUid == uid) {
      mentorView.value =
          isBlur ? remoteVideoView(remoteUid: uid!, isBlur: true) : local;
    } else if (!skipElse) {
      await addRemoteView(remoteUid: uid!, view: local, isLocalUser: true);
    }
  }

  Widget remoteVideoView(
      {VideoSourceType? sourceType,
      bool isBlur = false,
      required int? remoteUid}) {
    return Container(
      child: Stack(
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CustomImageView(
                height: 200,
                width: 200,
                imagePath: "ImageConstant.imgVector",
                fit: BoxFit.contain,
              ),
            ),
          ),
          if (!isBlur)
            AgoraVideoView(
              controller: VideoViewController.remote(
                rtcEngine: agoraEngine!,
                canvas: VideoCanvas(uid: remoteUid, sourceType: sourceType),
                connection: RtcConnection(channelId: channelName),
              ),
            ),
        ],
      ),
    );
  }

  Widget localVideoView({int? localUid, VideoSourceType? sourceType}) {
    // RtcRemoteView.SurfaceView(channelId: channelName, uid: remoteUid);

    if (agoraEngine == null) return Container();
    return AgoraVideoView(
      controller: VideoViewController(
        rtcEngine: agoraEngine!,
        canvas: VideoCanvas(
            uid: 0, sourceType: sourceType), // Use uid = 0 for local view
      ),
    );
  }

  Future<void> leave() async {
    // mentorView.close();
    usersInCallExceptFullView.forEach((action) {
      action.remoteWidget.close();
    });

    // Leave the channel
    if (agoraEngine != null) {
      await agoraEngine!.leaveChannel();
    }
    isJoined = false;

    // Destroy the Agora engine instance
    destroyAgoraEngine();
  }

  void destroyAgoraEngine() async {
    // Release the RtcEngine instance to free up resources
    if (agoraEngine != null) {
      agoraEngine?.release();
      mentorView.value = null;
      agoraEngine = null;
    }
  }

  void messageCallback(String s) {
    print("messageCallback $s");
  }

  void eventCallback(String s, Map<String, dynamic> eventArgs) {
    print("eventCallback $s $eventArgs");
  }

  Future<void> startScreenShare() async {
    print("Screen Capturing");

    await agoraEngine?.startScreenCapture(const ScreenCaptureParameters2(
      captureAudio: true,
      captureVideo: true,
    ));
    await agoraEngine?.startPreview(
      sourceType: VideoSourceType.videoSourceScreen,
    );

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      var result =
          await _iosScreenShareChannel.invokeMethod("startScreenSharing");
      print("$result");
    }
    await onStartScreenShared();
    return;
  }

  Future<void> onStartScreenShared() async {
    await agoraEngine?.updateChannelMediaOptions(
      const ChannelMediaOptions(
        publishScreenTrack: true,
        publishSecondaryScreenTrack: true,
        publishCameraTrack: false,
        publishMicrophoneTrack: true,
        publishScreenCaptureAudio: true,
        publishScreenCaptureVideo: true,
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
      ),
    );
    return;
  }

  stopScreenShare({
    required bool isAudio,
    required bool isVideo,
  }) async {
    // screenSharing.value = null;
    await agoraEngine?.stopScreenCapture();
    if (isVideo) await agoraEngine?.enableVideo();
    if (isAudio) await agoraEngine?.enableAudio();
    await agoraEngine?.startPreview(
        sourceType: VideoSourceType.videoSourceCamera);
    await agoraEngine?.updateChannelMediaOptions(
      ChannelMediaOptions(
        publishScreenTrack: false,
        publishSecondaryScreenTrack: false,
        publishCameraTrack: isVideo,
        publishMicrophoneTrack: isAudio,
        publishScreenCaptureAudio: false,
        publishScreenCaptureVideo: false,
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
      ),
    );
    var result = await _iosScreenShareChannel.invokeMethod("stopScreenSharing");
  }

  final MethodChannel _iosScreenShareChannel =
      const MethodChannel('example_screensharing_ios');

  Future<bool> updateRemoteView(
      {required int remoteUid, RemoteVideoState? state}) async {
    try {
      var viewToAdd = remoteVideoView(
          remoteUid: remoteUid,
          isBlur: state == RemoteVideoState.remoteVideoStateStopped);
      if (remoteUid == getVisibleUserId()) {
        mentorView.value = viewToAdd;
      } else {
        var indexOfUser = usersInCallExceptFullView
            .indexWhere((element) => element.uid == remoteUid);
        if (indexOfUser != -1) {
          usersInCallExceptFullView[indexOfUser].remoteWidget.value = viewToAdd;
        }
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> addRemoteView(
      {required int remoteUid, Widget? view, bool isLocalUser = false}) async {
    try {
      print("remoteUid${remoteUid}");

      var viewToAdd = view ?? remoteVideoView(remoteUid: remoteUid);

      var indexOfUser = usersInCallExceptFullView
          .indexWhere((element) => element.uid == remoteUid);

      if (indexOfUser == -1) {
        usersInCallExceptFullView
            .add(User(remoteUid, Rx(false), Rx(viewToAdd)));
      }
      /*else {
        usersInCallExceptMe[indexOfUser].remoteWidget.value = viewToAdd;
      }*/

      if (_visibleUid == null) {
        var indexOfVisible = usersInCallExceptFullView.indexWhere((element) =>
            element.uid == getVisibleUserId() || element.uid != getUserNo());
        if (indexOfVisible != -1) {
          //Mentor/otherUser is there is call already
          var user = usersInCallExceptFullView.removeAt(indexOfVisible);
          mentorView.value = user.remoteWidget.value;
          _visibleUid = user.uid;
        }
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  findAndRemoveId({required int remoteUid}) {
    try {
      var index = usersInCallExceptFullView
          .indexWhere((element) => element.uid == remoteUid);
      if (index != -1) usersInCallExceptFullView.removeAt(index);
      if (remoteUid == getVisibleUserId()) {
        setNextVisible();
      }
    } catch (e) {}
  }

  void setNextVisible() {
    if (usersInCallExceptFullView.length == 1) {
      mentorView.value = Container(
        width: Get.width,
        height: Get.height,
        color: Colors.black.withOpacity(0.20),
        child: Center(
          child: Text("No one is there on call"),
        ),
      );
      _visibleUid = null;
    } else {
      var nextUserIndex = usersInCallExceptFullView
          .indexWhere((element) => element.uid != getUserNo());
      var nextUser = usersInCallExceptFullView.removeAt(nextUserIndex);
      mentorView.value = nextUser.remoteWidget.value;
      _visibleUid = nextUser.uid;
    }
  }

  int getUserNo() {
    return int.parse("0");
  }
}

class User {
  int uid; //reference to user uid

  Rx<bool> isSpeaking; // reference to whether the user is speaking

  Rx<Widget?> remoteWidget; // reference to view of the user

  User(this.uid, this.isSpeaking, this.remoteWidget);

  @override
  String toString() {
    return 'User{uid: $uid, isSpeaking: ${isSpeaking.value}}';
  }
}
