import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'routes.dart'; // Import the routes file

void main() {
  runApp(const NetPulseApp());
}

class NetPulseApp extends StatelessWidget {
  const NetPulseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'NetPulse',
      initialRoute: AppRoutes.splash,
      getPages: AppRoutes.pages,
      home: const Scaffold(
        body: Center(child: Text('NetPulse Skeleton')),
      ),
    );
  }
}