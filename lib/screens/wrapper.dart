import 'package:flutter/material.dart';
import 'package:fyp/models/user.dart';
import 'package:fyp/screens/authenticate/authenticate.dart';
import 'package:fyp/screens/home/home.dart';
import 'package:provider/provider.dart';

class Wrapper extends StatelessWidget {

  Wrapper();
  @override
  Widget build(BuildContext context) {
    
    final user = Provider.of<User>(context);

    //return either home or authentication screens
    if (user == null) {
      return Authenticate();
    }
    else {
      return Home();
    }
  }
}