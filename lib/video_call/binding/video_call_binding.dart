import 'package:get/get.dart';

import '../controller/video_call_controller.dart';

class VideoCallBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => VideoCallController());
  }
}
