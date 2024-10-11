import 'package:agora_video_call/app_routes.dart';
import 'package:agora_video_call/home/controller/home_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class Home extends GetWidget<HomeController> {
  Home({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text("Welcome"),
      ),
      body: Center(
          child: ElevatedButton(
              onPressed: () {
                Get.toNamed(AppRoutes.videoCallRoute);
              },
              child: const Text(
                  "Join Call"))), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
