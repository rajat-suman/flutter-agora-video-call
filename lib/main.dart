import 'package:flutter/material.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';

import 'app_routes.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        themeMode: ThemeMode.light,
        title: 'Agora Video Call',
        // initialBinding: InitialBindings(),
        initialRoute: AppRoutes.initialRoute,
        // checkUser() ? AppRoutes.homePage : AppRoutes.initialRoute,
        getPages: AppRoutes.pages,
        transitionDuration: Duration.zero);
// return GetMaterialApp(
//   title: 'Flutter Demo',
//   theme: ThemeData(
//     colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
//     useMaterial3: true,
//   ),
//   // home: const MyHomePage(title: 'Flutter Demo Home Page'),
//   navigatorKey: NavigatorService.navigatorKey,
//   debugShowCheckedModeBanner: false,
//   builder: (context, child) => child!,
//   routes: {
//     '/': (context) => MyHomePage(title: 'Flutter Demo Home Page'),
//     '/second': (context) => VideoCallScreen(),
//   },
// );
  }
}
