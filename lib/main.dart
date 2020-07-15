import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:fyp/screens/wrapper.dart';
import 'package:fyp/services/auth.dart';
import 'package:provider/provider.dart';

import 'models/user.dart';

List<CameraDescription> cameras;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  cameras = await availableCameras();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamProvider<User>.value(
      value: AuthService().user,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'SPOTHOLE',
        home: Wrapper(),
      ),
    );
  }
}