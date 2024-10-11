import 'dart:async';

import 'package:agora_uikit/agora_uikit.dart';
import 'package:get/get.dart';

import '../../agora/agora_helper.dart';

class VideoCallController extends GetxController {
  Rx<String> imageUrl = Rx("");
  int? remainingSessions;
  final agora = AgoraHelper();

  Rx<bool> showButtons = Rx(true);

  Rx<bool> isCameraFront = Rx(true);

  Rx<Duration?> duration = Rx(null);

  @override
  void onReady() {
    super.onReady();
    start();
  }

  void getAgoraSession() async {
    var token = "";
    var mentorUid = 0; //response["mentorUserNo"];

    agora.setupAgoraEngine(
        token: token,
        mentorUid: mentorUid,
        clientRoleType: ClientRoleType.clientRoleBroadcaster);
  }

  Future<void> tappedScreenSharing() async {
    if (!agora.isSharing.value) {
      await agora.startScreenShare();
    } else {
      await agora.stopScreenShare(
          isAudio: agora.isMicOn.value, isVideo: agora.isVideoOn.value);
    }
  }

  Timer? _timer;

  var isExtended = false;

  void endTimer() {
    _timer?.cancel();
  }

  void end() {
    Get.back(result: true);
  }

  @override
  void onClose() {
    agora.leave();
    agora.isVideoOn.close();
    agora.isMicOn.close();
    duration.close();
    endTimer();
    super.onClose();
  }

  Future<void> start() async {
    var permissionResult = await Permission.microphone.request();
    // if (permissionResult != PermissionStatus.granted) return;
    getAgoraSession();
  }

  AgoraRtcEventHandlers getEventHandler() {
    return AgoraRtcEventHandlers(onError: (a, b) {
      print("Agora ${a} ${b}");
    });
  }

  void hitEndCall(Rx<bool> isHitting) {
    Get.back(result: true);
  }
}
