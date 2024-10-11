import 'package:agora_video_call/home/binding/home_binding.dart';
import 'package:agora_video_call/home/home.dart';
import 'package:agora_video_call/video_call/binding/video_call_binding.dart';
import 'package:agora_video_call/video_call/video_call_screen.dart';
import 'package:get/get.dart';

class AppRoutes {
  static const String initialRoute = '/initialRoute';
  static const String videoCallRoute = '/videoCallRoute';

  static List<GetPage> pages = [
    GetPage(name: initialRoute, page: () => Home(), bindings: [HomeBinding()]),
    GetPage(
        name: videoCallRoute,
        page: () => VideoCallScreen(),
        bindings: [VideoCallBinding()]),
  ];
}
