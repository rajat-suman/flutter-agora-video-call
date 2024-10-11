import 'package:agora_video_call/video_call/controller/video_call_controller.dart';
import 'package:agora_video_call/video_call/widgets/video_call_control_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../image_constant.dart';

class VideoCallScreen extends StatefulWidget {
  VideoCallScreen({Key? key}) : super(key: key);

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  var controller = VideoCallController();
  @override
  Widget build(BuildContext context) {
    return Container(
      child: _withWillPopScope(),
    );
  }

  _withWillPopScope() {
    return WillPopScope(
      onWillPop: () async {
        // controller.end();
        return false;
      },
      child: _videoCallWidget(),
    );
  }

  _videoCallWidget() {
    return Scaffold(
      backgroundColor: Colors.grey,
      body: Obx(
        () => GestureDetector(
          onTap: () {
            // controller.showButtons.value = !controller.showButtons.value;
          },
          child: Stack(
            // children: [],
            children: [
              if (controller.agora.isSharing.value)
                Container(
                  color: Colors.black.withOpacity(.20),
                  child: Align(
                    alignment: Alignment.center,
                    child: Text("Sharing Screen"),
                  ),
                ),
              if (!controller.agora.isSharing.value)
                Container(
                  width: Get.width,
                  height: Get.height,
                  color: Colors.black.withOpacity(.20),
                  child: Center(
                    child: controller.agora.mentorView.value ??
                        Text('lbl_waiting_for_the_others_to_join'.tr),
                  ),
                ),
              if (controller.showButtons.value &&
                  !controller.agora.isSharing.value)
                Container(
                  margin: EdgeInsets.only(top: 43),
                  height: 100,
                  width: Get.width,
                  alignment: Alignment.centerLeft,
                  child: ListView.builder(
                    itemBuilder: (context, index) {
                      var model =
                          controller.agora.usersInCallExceptFullView[index];
                      return Obx(
                        () => FittedBox(
                          fit: BoxFit.cover,
                          child: Container(
                              height: 100,
                              width: 100,
                              decoration: BoxDecoration(
                                color: Colors.black,
                                border: Border.all(
                                  color: model.isSpeaking.value
                                      ? Colors.orange
                                      : Colors.transparent,
                                  width: model.isSpeaking.value ? 3 : 0,
                                ),
                                // borderRadius: BorderRadius.circular(10.h)
                              ),
                              child: model.remoteWidget.value),
                        ),
                      );
                    },
                    itemCount:
                        controller.agora.usersInCallExceptFullView.length,
                    scrollDirection: Axis.horizontal,
                  ),
                ),
              if (controller.showButtons.value) controls(),
            ],
          ),
        ),
      ),
    );
  }

  Widget controls() {
    return Container(
      alignment: Alignment.bottomCenter,
      width: Get.width,
      margin: EdgeInsets.symmetric(horizontal: 24, vertical: 30),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            controller.duration.value
                    ?.toString()
                    .split('.')
                    .first
                    .padLeft(8, "0") ??
                "",
          ),
          SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              VideoCallControlWidget(
                  isSelected: !controller.agora.isSharing.value,
                  color: getColor(isOn: !controller.agora.isSharing.value),
                  onTap: (isSelected) {
                    controller.tappedScreenSharing();
                  },
                  image: ImageConstant.agoraShare),
              SizedBox(width: 12),
              VideoCallControlWidget(
                  isSelected: controller.agora.isVideoOn.value,
                  color: getColor(isOn: controller.agora.isVideoOn.value),
                  onTap: (isSelected) {
                    controller.agora.agoraEngine?.enableLocalVideo(isSelected);
                    controller.agora.isVideoOn.value = isSelected;
                  },
                  image: ImageConstant.agoraVideo),
              SizedBox(width: 12),
              VideoCallControlWidget(
                  isSelected: controller.agora.isMicOn.value,
                  color: getColor(isOn: controller.agora.isMicOn.value),
                  onTap: (isSelected) {
                    controller.agora.agoraEngine?.enableLocalAudio(isSelected);
                    controller.agora.isMicOn.value = isSelected;
                  },
                  image: ImageConstant.agoraMic),
              SizedBox(width: 12),
              VideoCallControlWidget(
                  color: getColor(isOn: controller.isCameraFront.value),
                  onTap: (isSelected) {
                    controller.agora.agoraEngine?.switchCamera();
                  },
                  image: ImageConstant.agoraSwap),
              SizedBox(width: 12),
              VideoCallControlWidget(
                  color: Colors.red,
                  onTap: (isSelected) {
                    controller.end();
                  },
                  image: ImageConstant.agoraEndCall),
            ],
          ),
        ],
      ),
    );
  }

  Color getColor({required bool isOn}) {
    if (isOn)
      return Colors.grey; //Color(0xffFFFFFF).withOpacity(0.45);
    else
      return Colors.red;
  }
}
